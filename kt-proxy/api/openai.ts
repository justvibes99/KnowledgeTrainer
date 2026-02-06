export const config = {
  runtime: "edge",
};

export default async function handler(req: Request): Promise<Response> {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: corsHeaders(),
    });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders(), "content-type": "application/json" },
    });
  }

  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    return new Response(
      JSON.stringify({ error: "Server misconfigured: missing OpenAI API key" }),
      {
        status: 500,
        headers: { ...corsHeaders(), "content-type": "application/json" },
      }
    );
  }

  try {
    const body = await req.text();
    if (!body) {
      return new Response(JSON.stringify({ error: "Missing request body" }), {
        status: 400,
        headers: { ...corsHeaders(), "content-type": "application/json" },
      });
    }

    const parsed = JSON.parse(body);
    parsed.stream = true;
    parsed.stream_options = { include_usage: true };
    const streamBody = JSON.stringify(parsed);

    const openaiRes = await fetch(
      "https://api.openai.com/v1/chat/completions",
      {
        method: "POST",
        headers: {
          "content-type": "application/json",
          authorization: `Bearer ${apiKey}`,
        },
        body: streamBody,
      }
    );

    if (!openaiRes.ok) {
      const errorBody = await openaiRes.text();
      return new Response(errorBody, {
        status: openaiRes.status,
        headers: { ...corsHeaders(), "content-type": "application/json" },
      });
    }

    const reader = openaiRes.body?.getReader();
    if (!reader) {
      return new Response(JSON.stringify({ error: "No response body" }), {
        status: 502,
        headers: { ...corsHeaders(), "content-type": "application/json" },
      });
    }

    const encoder = new TextEncoder();
    const { readable, writable } = new TransformStream();
    const writer = writable.getWriter();

    (async () => {
      const keepalive = setInterval(
        () => writer.write(encoder.encode(" ")).catch(() => {}),
        2000
      );

      const decoder = new TextDecoder();
      let buffer = "";
      let fullContent = "";
      let completionId = "";
      let model = "";
      let promptTokens = 0;
      let completionTokens = 0;
      let finishReason = "";

      try {
        while (true) {
          const { done, value } = await reader.read();
          if (done) break;

          buffer += decoder.decode(value, { stream: true });
          const lines = buffer.split("\n");
          buffer = lines.pop() || "";

          for (const line of lines) {
            if (!line.startsWith("data: ")) continue;
            const data = line.slice(6).trim();
            if (data === "[DONE]") continue;

            try {
              const event = JSON.parse(data);

              if (event.id) completionId = event.id;
              if (event.model) model = event.model;

              if (event.usage) {
                promptTokens = event.usage.prompt_tokens || 0;
                completionTokens = event.usage.completion_tokens || 0;
              }

              if (event.choices?.[0]?.delta?.content) {
                fullContent += event.choices[0].delta.content;
              }

              if (event.choices?.[0]?.finish_reason) {
                finishReason = event.choices[0].finish_reason;
              }
            } catch {
              // skip unparseable lines
            }
          }
        }
      } finally {
        clearInterval(keepalive);
      }

      const result = {
        id: completionId,
        object: "chat.completion",
        model,
        choices: [
          {
            index: 0,
            message: { role: "assistant", content: fullContent },
            finish_reason: finishReason || "stop",
          },
        ],
        usage: {
          prompt_tokens: promptTokens,
          completion_tokens: completionTokens,
          total_tokens: promptTokens + completionTokens,
        },
      };

      await writer.write(encoder.encode(JSON.stringify(result)));
      await writer.close();
    })();

    return new Response(readable, {
      status: 200,
      headers: {
        ...corsHeaders(),
        "content-type": "application/json",
        "cache-control": "no-store",
      },
    });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    return new Response(
      JSON.stringify({ error: "Proxy error", detail: message }),
      {
        status: 500,
        headers: { ...corsHeaders(), "content-type": "application/json" },
      }
    );
  }
}

function corsHeaders(): Record<string, string> {
  return {
    "access-control-allow-origin": "*",
    "access-control-allow-methods": "POST, OPTIONS",
    "access-control-allow-headers": "content-type",
  };
}

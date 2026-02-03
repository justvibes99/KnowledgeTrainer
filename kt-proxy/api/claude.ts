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

  const apiKey = process.env.ANTHROPIC_API_KEY;
  if (!apiKey) {
    return new Response(
      JSON.stringify({ error: "Server misconfigured: missing API key" }),
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

    // Inject stream: true into the request body
    const parsed = JSON.parse(body);
    parsed.stream = true;
    const streamBody = JSON.stringify(parsed);

    const anthropicRes = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-api-key": apiKey,
        "anthropic-version": "2023-06-01",
      },
      body: streamBody,
    });

    if (!anthropicRes.ok) {
      const errorBody = await anthropicRes.text();
      return new Response(errorBody, {
        status: anthropicRes.status,
        headers: { ...corsHeaders(), "content-type": "application/json" },
      });
    }

    // Read the full streamed response and assemble it into a standard Messages response
    const reader = anthropicRes.body?.getReader();
    if (!reader) {
      return new Response(JSON.stringify({ error: "No response body" }), {
        status: 502,
        headers: { ...corsHeaders(), "content-type": "application/json" },
      });
    }

    const decoder = new TextDecoder();
    let buffer = "";
    let fullText = "";
    let messageId = "";
    let model = "";
    let inputTokens = 0;
    let outputTokens = 0;
    let stopReason = "";

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

          if (event.type === "message_start" && event.message) {
            messageId = event.message.id || "";
            model = event.message.model || "";
            if (event.message.usage) {
              inputTokens = event.message.usage.input_tokens || 0;
            }
          } else if (event.type === "content_block_delta" && event.delta?.text) {
            fullText += event.delta.text;
          } else if (event.type === "message_delta" && event.usage) {
            outputTokens = event.usage.output_tokens || 0;
            stopReason = event.delta?.stop_reason || "end_turn";
          }
        } catch {
          // skip unparseable lines
        }
      }
    }

    // Return a standard non-streamed Messages API response
    const result = {
      id: messageId,
      type: "message",
      role: "assistant",
      model,
      content: [{ type: "text", text: fullText }],
      stop_reason: stopReason || "end_turn",
      stop_sequence: null,
      usage: { input_tokens: inputTokens, output_tokens: outputTokens },
    };

    return new Response(JSON.stringify(result), {
      status: 200,
      headers: { ...corsHeaders(), "content-type": "application/json" },
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

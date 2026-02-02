export const config = { runtime: "edge" };

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

  let body: string;
  try {
    body = await req.text();
    if (!body) throw new Error("empty");
  } catch {
    return new Response(JSON.stringify({ error: "Missing request body" }), {
      status: 400,
      headers: { ...corsHeaders(), "content-type": "application/json" },
    });
  }

  const anthropicRes = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "x-api-key": apiKey,
      "anthropic-version": "2023-06-01",
    },
    body,
  });

  const responseBody = await anthropicRes.text();

  return new Response(responseBody, {
    status: anthropicRes.status,
    headers: {
      ...corsHeaders(),
      "content-type": "application/json",
    },
  });
}

function corsHeaders(): Record<string, string> {
  return {
    "access-control-allow-origin": "*",
    "access-control-allow-methods": "POST, OPTIONS",
    "access-control-allow-headers": "content-type",
  };
}

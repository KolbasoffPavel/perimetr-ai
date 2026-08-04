// Cloudflare Worker — прокси между приложением ПЕРИМЕТР и Anthropic API.
// Ключ Anthropic хранится ТОЛЬКО здесь, на сервере (в секретах Cloudflare),
// и никогда не попадает в код или сборку Flutter-приложения.

export default {
async fetch(request, env) {
if (request.method === 'OPTIONS') {
return new Response(null, { headers: corsHeaders() });
}

if (request.method !== 'POST') {
return new Response('Method not allowed', { status: 405, headers: corsHeaders() });
}

const clientSecret = request.headers.get('x-app-secret');
if (env.APP_SHARED_SECRET && clientSecret !== env.APP_SHARED_SECRET) {
return new Response(JSON.stringify({ error: 'Unauthorized' }), {
status: 401,
headers: corsHeaders(),
});
}

try {
const body = await request.text();

const upstream = await fetch('https://api.anthropic.com/v1/messages', {
method: 'POST',
headers: {
'content-type': 'application/json',
'x-api-key': env.ANTHROPIC_API_KEY,
'anthropic-version': '2023-06-01',
},
body,
});

const responseBody = await upstream.text();

return new Response(responseBody, {
status: upstream.status,
headers: { ...corsHeaders(), 'content-type': 'application/json' },
});
} catch (err) {
return new Response(JSON.stringify({ error: String(err) }), {
status: 500,
headers: corsHeaders(),
});
}
},
};

function corsHeaders() {
return {
'Access-Control-Allow-Origin': '*',
'Access-Control-Allow-Methods': 'POST, OPTIONS',
'Access-Control-Allow-Headers': 'content-type, x-app-secret',
};
}

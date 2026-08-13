// Cloudflare Worker — прокси между приложением ПЕРИМЕТР и Anthropic API.
// Ключ Anthropic хранится ТОЛЬКО здесь, на сервере (в секретах Cloudflare),
// и никогда не попадает в код или сборку Flutter-приложения.

export default {
async fetch(request, env) {
if (request.method === 'OPTIONS') {
return new Response(null, { headers: corsHeaders() });
}

const url = new URL(request.url);
const clientSecret = request.headers.get('x-app-secret') || url.searchParams.get('secret');
if (env.APP_SHARED_SECRET && clientSecret !== env.APP_SHARED_SECRET) {
return new Response(JSON.stringify({ error: 'Unauthorized' }), {
status: 401,
headers: corsHeaders(),
});
}

// Приложение присылает сюда отчёты о крашах (см. AiService.reportCrash) —
// сохраняем их в KV, чтобы их можно было прочитать через GET /crash-reports.
if (url.pathname === '/crash-report' && request.method === 'POST') {
try {
const payload = await request.text();
const id = String(Date.now()) + '-' + Math.random().toString(36).slice(2, 8);
if (env.ESTIMATES) {
await env.ESTIMATES.put('crash:' + id, payload, { expirationTtl: 60 * 60 * 24 * 30 });
}
return new Response(JSON.stringify({ ok: true }), { headers: corsHeaders() });
} catch (err) {
return new Response(JSON.stringify({ error: String(err) }), { status: 500, headers: corsHeaders() });
}
}

// Чтение сохранённых отчётов о крашах — для диагностики.
if (url.pathname === '/crash-reports' && request.method === 'GET') {
if (!env.ESTIMATES) {
return new Response(JSON.stringify({ error: 'KV не настроен' }), { status: 500, headers: corsHeaders() });
}
const list = await env.ESTIMATES.list({ prefix: 'crash:', limit: 30 });
const items = await Promise.all(
list.keys.map(async (k) => ({ key: k.name, value: await env.ESTIMATES.get(k.name) }))
);
return new Response(JSON.stringify({ items }), { headers: { ...corsHeaders(), 'content-type': 'application/json' } });
}

if (request.method !== 'POST') {
return new Response('Method not allowed', { status: 405, headers: corsHeaders() });
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
'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
'Access-Control-Allow-Headers': 'content-type, x-app-secret',
};
}

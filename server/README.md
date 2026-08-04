# Прокси-сервер для ключа Anthropic — инструкция по развёртыванию

## Зачем

Приложение больше не хранит и не отправляет ключ Anthropic напрямую.
Вместо этого оно обращается к вашему собственному серверу (Cloudflare
Worker), а сервер уже сам добавляет ключ и пересылает запрос в Anthropic.
Ключ виден только на сервере — в секретах Cloudflare, не в коде и не в
собранном APK.

## Шаг 1. Аккаунт Cloudflare

1. Зарегистрироваться на https://dash.cloudflare.com/sign-up (бесплатно)
2. В боковом меню -> Workers & Pages -> Create -> Create Worker
3. Дать имя, например perimetr-ai-proxy -> Deploy (сначала с шаблоном по умолчанию — сейчас заменим код)

## Шаг 2. Вставить код

1. На странице воркера нажать Edit code
2. Стереть содержимое редактора и вставить всё содержимое файла worker.js из этой папки
3. Deploy

## Шаг 3. Добавить секреты

1. На странице воркера -> вкладка Settings -> Variables and Secrets
2. Add -> тип Secret:
   - Имя: ANTHROPIC_API_KEY
   - Значение: ваш ключ Anthropic (начинается с sk-ant-...) — получить можно в консоли Anthropic на https://console.anthropic.com/settings/keys
3. Ещё раз Add -> тип Secret:
   - Имя: APP_SHARED_SECRET
   - Значение: любая случайная строка подлиннее (например 32 случайных символа) — это НЕ ключ Anthropic, просто общий пароль между приложением и сервером
4. Save

## Шаг 4. Получить адрес сервера

На странице воркера в самом верху будет ссылка вида:
https://perimetr-ai-proxy.ВАШ-АККАУНТ.workers.dev

Скопируйте её и передайте её вместе со значением APP_SHARED_SECRET — я обновлю lib/services/ai_service.dart, чтобы приложение стучалось на этот адрес.

## Проверка

curl -X POST https://perimetr-ai-proxy.ВАШ-АККАУНТ.workers.dev -H "content-type: application/json" -H "x-app-secret: ВАШ_APP_SHARED_SECRET" -d '{"model":"claude-sonnet-4-5-20250929","max_tokens":100,"messages":[{"role":"user","content":"Привет"}]}'

Если пришёл осмысленный ответ от Claude — всё настроено верно.

## Бесплатный лимит

Cloudflare Workers бесплатный тариф — 100 000 запросов в день, для одного приложения этого более чем достаточно.

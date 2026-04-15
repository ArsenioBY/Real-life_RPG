# 🎮 Arseny RPG Beta — Инструкция по запуску

## Что внутри

| Файл | Назначение |
|---|---|
| `index.html` | Полное приложение |
| `sw.js` | Service Worker (PWA) |
| `manifest.json` | PWA манифест |
| `icon.svg` | Иконка приложения |
| `supabase_setup.sql` | SQL для создания базы данных |

---

## Шаг 1 — Создай Supabase проект (5 минут)

1. Зайди на [supabase.com](https://supabase.com) → **Start your project**
2. Создай аккаунт (GitHub или email)
3. **New project** → название `arseny-rpg` → выбери регион (Frankfurt — ближайший к Тбилиси)
4. Подожди ~2 минуты пока проект создаётся
5. Зайди в **SQL Editor** → **New query**
6. Скопируй содержимое `supabase_setup.sql` → вставь → **Run**
7. Убедись что написало "Success. No rows returned"

---

## Шаг 2 — Получи ключи (1 минута)

В Supabase Dashboard:
- **Project Settings** → **API**
- Скопируй **Project URL** (вида `https://xxxx.supabase.co`)
- Скопируй **anon public** key 

---

## Шаг 3 — Вставь ключи в приложение (1 минута)

Открой `index.html`, найди эти строки (в начале `<script>`):

```javascript
const SUPABASE_URL = 'YOUR_SUPABASE_URL';
const SUPABASE_KEY = 'YOUR_SUPABASE_ANON_KEY';
```

Замени на свои значения:

```javascript
const SUPABASE_URL = 'https://xxxx.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

---

## Шаг 4 — Настрой email для magic link (2 минуты)

В Supabase Dashboard:
- **Authentication** → **Providers** → **Email** — должен быть включён
- **Authentication** → **URL Configuration**:
  - **Site URL** — укажи URL где будет работать приложение (например `https://arseny-rpg.vercel.app`)
  - Если тестируешь локально: `http://localhost:3000`

---

## Шаг 5 — Задеплой на Vercel (3 минуты)

### Вариант A: через drag & drop (самый быстрый)
1. Зайди на [vercel.com](https://vercel.com) → войди через GitHub
2. **Add New** → **Project** → перетащи папку `arseny-rpg-beta`
3. Deploy → через 30 секунд готово
4. Скопируй URL вида `https://arseny-rpg-xxxx.vercel.app`
5. Вставь этот URL в Supabase → Authentication → Site URL

### Вариант B: через GitHub
1. Создай repo на GitHub, загрузи файлы
2. На vercel.com → Import from GitHub → выбери repo → Deploy

---

## Шаг 6 — Установи как PWA на iPhone

1. Открой URL приложения в **Safari** на iPhone
2. Нажми кнопку **Share** (квадрат со стрелкой вверх)
3. **Add to Home Screen** → **Add**
4. Приложение появится на рабочем столе как нативное

### На macOS:
1. Открой URL в **Chrome** или **Edge**
2. В адресной строке нажми иконку установки (компьютер со стрелкой)
3. **Install**

---

## Шаг 7 — Миграция данных из старого прототипа

Если хочешь перенести прогресс из старого приложения:

1. Открой старое приложение
2. Перейди во вкладку **Ещё** → нажми **Экспортировать бэкап** (скопируй JSON)
3. В новом приложении зайди и залогинься
4. Открой консоль браузера (F12) и выполни:

```javascript
// Вставь твой JSON в переменную old
const old = { /* сюда вставь JSON из старого приложения */ };

// Обновим state
G.stat_str = old.stats?.str || G.stat_str;
G.stat_int = old.stats?.int || G.stat_int;
G.stat_gld = old.stats?.gld || G.stat_gld;
G.stat_vit = old.stats?.vit || G.stat_vit;
G.stat_dex = old.stats?.dex || G.stat_dex;
G.stat_cha = old.stats?.cha || G.stat_cha;
G.total_xp = old.totalXP || 0;
G.gel_earned = old.totalGEL || 0;
G.gel_balance = old.totalGEL || 0;
G.streak = old.streak || 0;
G.streak_best = old.streak || 0;
await save();
renderAll();
console.log('Готово! Данные перенесены.');
```

---

## Аккаунты для beta

| Пользователь | Email | Роль |
|---|---|---|
| Арсений | твой email | Главный пользователь |
| Валя | Валин email | Второй beta-пользователь |

Каждый пользователь входит через **magic link** — ссылка приходит на email, действует 1 час. После первого входа браузер/телефон запоминает сессию.

---

## Если что-то не работает

**Supabase ошибка "row level security"** → убедись что SQL из `supabase_setup.sql` выполнен полностью

**Magic link не приходит** → проверь папку Spam; убедись что Site URL в Supabase настроен правильно

**Данные не сохраняются** → открой консоль браузера (F12), посмотри ошибки; убедись что SUPABASE_URL и SUPABASE_KEY вставлены правильно

**PWA не устанавливается на iPhone** → открывай только через Safari, не через Chrome/Firefox

---

## Что добавлено в beta vs прототип

| Фича | Прототип | Beta |
|---|---|---|
| Два пользователя | ❌ | ✅ |
| Облачное хранение | ❌ localStorage | ✅ Supabase |
| Синхронизация между устройствами | ❌ | ✅ |
| Rolling GEL balance | ❌ смешанный | ✅ gelBalance + gelEarned |
| Week bonus +80₾ | ❌ | ✅ |
| Редактирование любых задач | ❌ | ✅ |
| Редактирование наград | ❌ | ✅ |
| Ручная корректировка баланса | ❌ | ✅ |
| Онбординг для нового пользователя | ❌ | ✅ |
| PWA (установка на телефон) | ✅ | ✅ |
| Темная тема | ✅ | ✅ |
| Все старые механики | ✅ | ✅ |

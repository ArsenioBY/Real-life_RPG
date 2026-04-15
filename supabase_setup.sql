-- ═══════════════════════════════════════════════════════════════
-- ARSENY RPG BETA — Supabase Database Setup
-- Run this in Supabase SQL Editor (Project → SQL Editor → New query)
-- ═══════════════════════════════════════════════════════════════

-- 1. PROFILES
create table if not exists profiles (
  id uuid primary key default gen_random_uuid(),
  email text unique not null,
  name text not null default 'Player',
  avatar_emoji text not null default '⚔️',
  created_at timestamptz default now()
);

-- 2. USER STATE (one row per profile — the main game state)
create table if not exists user_state (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid references profiles(id) on delete cascade unique not null,
  -- Stats
  stat_str int not null default 50,
  stat_int int not null default 47,
  stat_gld int not null default 34,
  stat_vit int not null default 32,
  stat_dex int not null default 15,
  stat_cha int not null default 20,
  -- XP & GEL
  total_xp int not null default 0,
  gel_earned numeric(10,2) not null default 0,   -- всего заработано (never decreases)
  gel_balance numeric(10,2) not null default 0,  -- текущий баланс (decreases on redeem)
  pool_day numeric(10,2) not null default 0,     -- earned today (resets daily)
  pool_week numeric(10,2) not null default 0,    -- earned this week (resets weekly)
  pool_qtr numeric(10,2) not null default 0,     -- earned this quarter
  -- Streak
  streak int not null default 0,
  streak_best int not null default 0,
  streak_last_date text default '',
  -- Bonus flags
  day_bonus_given boolean not null default false,
  week_bonus_given boolean not null default false,
  -- Goals
  goal_weight numeric(5,1) default 120,
  goal_salary numeric(8,2) default 2300,
  -- Daily planning
  tomorrow_task text default '',
  last_day_date text default '',
  last_week_date text default '',  -- for week reset tracking
  updated_at timestamptz default now()
);

-- 3. TASKS (unified model — replaces baseTasks/workTasks/personalTasks/weekTasks/quarterQ)
create table if not exists tasks (
  id text primary key,  -- keep existing IDs like 'b1', 'w1' etc
  profile_id uuid references profiles(id) on delete cascade not null,
  name text not null,
  xp_base int not null default 20,
  gel_base numeric(5,2) not null default 1.5,
  stat text not null default 'gld' check (stat in ('str','int','gld','vit','dex','cha')),
  priority text not null default 'p3' check (priority in ('p1','p2','p3','p4')),
  section text not null default 'personal' check (section in ('work','personal','base')),
  task_type text not null default 'daily' check (task_type in ('daily','weekly','quarterly','oneoff')),
  week_day text default null,   -- 'Mon','Tue' etc for weekly tasks
  quarter text default null,    -- 'Q2 2026' for quarterly
  time_hint text default '',    -- '09:00'
  status text not null default 'pending' check (status in ('pending','done','deferred','skipped','archived')),
  defer_penalty boolean not null default false,
  is_recurring boolean not null default true,
  archive_reason text default null,
  created_at timestamptz default now(),
  completed_at timestamptz default null
);

-- 4. REWARDS (editable by user)
create table if not exists rewards (
  id text primary key,
  profile_id uuid references profiles(id) on delete cascade not null,
  name text not null,
  gel_cost numeric(6,2) not null,
  period text not null default 'any' check (period in ('day','week','quarter','any')),
  is_active boolean not null default true,
  created_at timestamptz default now()
);

-- 5. EVENT LOG (XP + GEL history)
create table if not exists event_log (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid references profiles(id) on delete cascade not null,
  task_name text default '',
  xp int not null default 0,
  gel numeric(6,2) not null default 0,
  event_type text not null default 'task' check (event_type in ('task','bonus_day','bonus_week','bonus_qtr','redeem')),
  created_at timestamptz default now()
);

-- 6. CHECKINS
create table if not exists checkins (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid references profiles(id) on delete cascade not null,
  date text not null,
  mood int not null default 3,
  mood_emoji text not null default '🙂',
  note text default '',
  tomorrow_task text default '',
  earned_gel numeric(6,2) default 0,
  tasks_done int default 0,
  created_at timestamptz default now()
);

-- 7. SPENT LOG (reward redemptions)
create table if not exists spent_log (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid references profiles(id) on delete cascade not null,
  reward_name text not null,
  gel_cost numeric(6,2) not null,
  created_at timestamptz default now()
);

-- ═══════════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY — each user sees only their own data
-- ═══════════════════════════════════════════════════════════════

alter table profiles enable row level security;
alter table user_state enable row level security;
alter table tasks enable row level security;
alter table rewards enable row level security;
alter table event_log enable row level security;
alter table checkins enable row level security;
alter table spent_log enable row level security;

-- Profiles: user sees only their own profile
create policy "profiles_own" on profiles
  for all using (id = (select id from profiles where email = auth.email() limit 1));

-- User state: scoped by profile
create policy "user_state_own" on user_state
  for all using (profile_id = (select id from profiles where email = auth.email() limit 1));

-- Tasks: scoped by profile
create policy "tasks_own" on tasks
  for all using (profile_id = (select id from profiles where email = auth.email() limit 1));

-- Rewards: scoped by profile
create policy "rewards_own" on rewards
  for all using (profile_id = (select id from profiles where email = auth.email() limit 1));

-- Event log: scoped by profile
create policy "event_log_own" on event_log
  for all using (profile_id = (select id from profiles where email = auth.email() limit 1));

-- Checkins: scoped by profile
create policy "checkins_own" on checkins
  for all using (profile_id = (select id from profiles where email = auth.email() limit 1));

-- Spent log: scoped by profile
create policy "spent_log_own" on spent_log
  for all using (profile_id = (select id from profiles where email = auth.email() limit 1));

-- ═══════════════════════════════════════════════════════════════
-- UPDATED_AT trigger for user_state
-- ═══════════════════════════════════════════════════════════════

create or replace function update_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger user_state_updated_at
  before update on user_state
  for each row execute function update_updated_at();

-- ═══════════════════════════════════════════════════════════════
-- DONE. Run this, then copy your Supabase URL and anon key
-- into the app config section.
-- ═══════════════════════════════════════════════════════════════

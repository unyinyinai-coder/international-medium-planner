-- Run once in Supabase SQL editor. Set admin role ONLY using the SQL editor.
create table if not exists public.school_roles (user_id uuid primary key references auth.users(id) on delete cascade, role text not null check(role in ('teacher','admin')) default 'teacher');
create table if not exists public.teaching_plans (id text primary key, owner_id uuid not null references auth.users(id), content jsonb not null, updated_at timestamptz not null default now(), deleted boolean not null default false);
create index if not exists teaching_plans_owner_idx on public.teaching_plans(owner_id);
alter table public.school_roles enable row level security;
alter table public.teaching_plans enable row level security;
create policy roles_self_read on public.school_roles for select to authenticated using (user_id=auth.uid());
create policy plans_read on public.teaching_plans for select to authenticated using (owner_id=auth.uid() or exists(select 1 from public.school_roles r where r.user_id=auth.uid() and r.role='admin'));
create policy plans_insert on public.teaching_plans for insert to authenticated with check (owner_id=auth.uid());
create policy plans_update on public.teaching_plans for update to authenticated using(owner_id=auth.uid()) with check(owner_id=auth.uid());
-- After creating users in Supabase Authentication, assign administrator by SQL editor only:
-- insert into public.school_roles(user_id,role) values ('ADMIN_AUTH_USER_UUID','admin') on conflict(user_id) do update set role='admin';
-- Never put the service_role key in browser code.

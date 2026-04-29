-- =============================================
-- مصروفاتي — Supabase Database Schema
-- انسخ هذا كله والصقه في SQL Editor في Supabase
-- =============================================

-- Enable extensions
create extension if not exists "uuid-ossp";

-- =============================================
-- 1. جدول الملفات الشخصية (يمتد auth.users)
-- =============================================
create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  email text unique not null,
  name text default '',
  is_super_admin boolean default false,
  created_at timestamptz default now()
);

-- دالة: إنشاء profile تلقائياً عند التسجيل
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, name)
  values (new.id, new.email, coalesce(new.raw_user_meta_data->>'name', ''));
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- =============================================
-- 2. جدول المجموعات
-- =============================================
create table public.groups (
  id uuid default uuid_generate_v4() primary key,
  name text not null,
  owner_id uuid references public.profiles(id) on delete cascade not null,
  invite_code text unique default substring(md5(random()::text), 1, 8),
  created_at timestamptz default now()
);

-- =============================================
-- 3. جدول أعضاء المجموعات
-- =============================================
create table public.group_members (
  id uuid default uuid_generate_v4() primary key,
  group_id uuid references public.groups(id) on delete cascade not null,
  user_id uuid references public.profiles(id) on delete cascade not null,
  role text check (role in ('owner', 'editor', 'viewer')) not null default 'viewer',
  joined_at timestamptz default now(),
  unique(group_id, user_id)
);

-- =============================================
-- 4. إعدادات المجموعة (الميزانية، بداية الشهر)
-- =============================================
create table public.group_settings (
  group_id uuid references public.groups(id) on delete cascade primary key,
  month_start bigint,
  month_auto boolean default true,
  updated_at timestamptz default now()
);

-- =============================================
-- 5. جدول المصروفات
-- =============================================
create table public.expenses (
  id uuid default uuid_generate_v4() primary key,
  group_id uuid references public.groups(id) on delete cascade not null,
  added_by uuid references public.profiles(id) not null,
  name text not null,
  amount decimal(12,2) not null check (amount > 0),
  category text default '',
  src text default 'manual' check (src in ('manual', 'voice')),
  created_at timestamptz default now()
);

-- =============================================
-- 6. جدول الالتزامات الشهرية
-- =============================================
create table public.commitments (
  id uuid default uuid_generate_v4() primary key,
  group_id uuid references public.groups(id) on delete cascade not null,
  name text not null,
  budget decimal(12,2) default 0,
  type text check (type in ('simple', 'list')) default 'list',
  month_key text not null,
  is_paid boolean default false,
  paid_amount decimal(12,2) default 0,
  paid_at timestamptz,
  is_archived boolean default false,
  created_at timestamptz default now()
);

-- =============================================
-- 7. جدول أصناف الالتزامات
-- =============================================
create table public.commitment_items (
  id uuid default uuid_generate_v4() primary key,
  commitment_id uuid references public.commitments(id) on delete cascade not null,
  name text not null,
  category text default '',
  qty decimal(10,3) default 1,
  price decimal(12,2) not null check (price >= 0),
  stock text default 'full',
  src text default 'manual' check (src in ('manual', 'voice', 'image')),
  created_at timestamptz default now()
);

-- =============================================
-- 8. جدول الميزانية
-- =============================================
create table public.budget_entries (
  id uuid default uuid_generate_v4() primary key,
  group_id uuid references public.groups(id) on delete cascade not null,
  added_by uuid references public.profiles(id) not null,
  amount decimal(12,2) not null check (amount > 0),
  note text default '',
  month_key text,
  created_at timestamptz default now()
);

-- =============================================
-- 9. سجل التعديلات (Audit Log)
-- =============================================
create table public.audit_log (
  id uuid default uuid_generate_v4() primary key,
  group_id uuid references public.groups(id) on delete set null,
  user_id uuid references public.profiles(id) on delete set null,
  user_email text,
  user_name text,
  action text not null,
  entity_type text,
  entity_name text,
  details jsonb default '{}',
  created_at timestamptz default now()
);

-- =============================================
-- Row Level Security (RLS)
-- =============================================
alter table public.profiles enable row level security;
alter table public.groups enable row level security;
alter table public.group_members enable row level security;
alter table public.group_settings enable row level security;
alter table public.expenses enable row level security;
alter table public.commitments enable row level security;
alter table public.commitment_items enable row level security;
alter table public.budget_entries enable row level security;
alter table public.audit_log enable row level security;

-- =============================================
-- دوال مساعدة
-- =============================================
create or replace function public.is_group_member(gid uuid)
returns boolean as $$
  select exists(
    select 1 from public.group_members
    where group_id = gid and user_id = auth.uid()
  );
$$ language sql security definer stable;

create or replace function public.get_group_role(gid uuid)
returns text as $$
  select role from public.group_members
  where group_id = gid and user_id = auth.uid()
  limit 1;
$$ language sql security definer stable;

create or replace function public.is_super_admin()
returns boolean as $$
  select coalesce(
    (select is_super_admin from public.profiles where id = auth.uid()),
    false
  );
$$ language sql security definer stable;

-- =============================================
-- سياسات RLS — Profiles
-- =============================================
create policy "profiles_select" on public.profiles for select
  using (id = auth.uid() or public.is_super_admin());

create policy "profiles_insert" on public.profiles for insert
  with check (id = auth.uid());

create policy "profiles_update" on public.profiles for update
  using (id = auth.uid());

-- =============================================
-- سياسات RLS — Groups
-- =============================================
create policy "groups_select" on public.groups for select
  using (public.is_group_member(id) or owner_id = auth.uid() or public.is_super_admin());

create policy "groups_insert" on public.groups for insert
  with check (owner_id = auth.uid());

create policy "groups_update" on public.groups for update
  using (owner_id = auth.uid() or public.is_super_admin());

create policy "groups_delete" on public.groups for delete
  using (owner_id = auth.uid() or public.is_super_admin());

-- =============================================
-- سياسات RLS — Group Members
-- =============================================
create policy "members_select" on public.group_members for select
  using (public.is_group_member(group_id) or public.is_super_admin());

create policy "members_insert" on public.group_members for insert
  with check (
    user_id = auth.uid() or
    group_id in (select id from public.groups where owner_id = auth.uid()) or
    public.is_super_admin()
  );

create policy "members_update" on public.group_members for update
  using (
    group_id in (select id from public.groups where owner_id = auth.uid()) or
    public.is_super_admin()
  );

create policy "members_delete" on public.group_members for delete
  using (
    user_id = auth.uid() or
    group_id in (select id from public.groups where owner_id = auth.uid()) or
    public.is_super_admin()
  );

-- =============================================
-- سياسات RLS — Group Settings
-- =============================================
create policy "settings_select" on public.group_settings for select
  using (public.is_group_member(group_id) or public.is_super_admin());

create policy "settings_write" on public.group_settings for all
  using (
    group_id in (select id from public.groups where owner_id = auth.uid()) or
    public.is_super_admin()
  );

-- =============================================
-- سياسات RLS — Expenses
-- =============================================
create policy "expenses_select" on public.expenses for select
  using (public.is_group_member(group_id) or public.is_super_admin());

create policy "expenses_insert" on public.expenses for insert
  with check (
    public.get_group_role(group_id) in ('owner', 'editor') and
    added_by = auth.uid()
  );

create policy "expenses_update" on public.expenses for update
  using (public.get_group_role(group_id) in ('owner', 'editor'));

create policy "expenses_delete" on public.expenses for delete
  using (public.get_group_role(group_id) = 'owner' or public.is_super_admin());

-- =============================================
-- سياسات RLS — Commitments
-- =============================================
create policy "commitments_select" on public.commitments for select
  using (public.is_group_member(group_id) or public.is_super_admin());

create policy "commitments_insert" on public.commitments for insert
  with check (public.get_group_role(group_id) in ('owner', 'editor'));

create policy "commitments_update" on public.commitments for update
  using (public.get_group_role(group_id) in ('owner', 'editor'));

create policy "commitments_delete" on public.commitments for delete
  using (public.get_group_role(group_id) = 'owner' or public.is_super_admin());

-- =============================================
-- سياسات RLS — Commitment Items
-- =============================================
create policy "items_select" on public.commitment_items for select
  using (
    commitment_id in (
      select id from public.commitments where public.is_group_member(group_id)
    ) or public.is_super_admin()
  );

create policy "items_insert" on public.commitment_items for insert
  with check (
    commitment_id in (
      select id from public.commitments
      where public.get_group_role(group_id) in ('owner', 'editor')
    )
  );

create policy "items_update" on public.commitment_items for update
  using (
    commitment_id in (
      select id from public.commitments
      where public.get_group_role(group_id) in ('owner', 'editor')
    )
  );

create policy "items_delete" on public.commitment_items for delete
  using (
    commitment_id in (
      select id from public.commitments
      where public.get_group_role(group_id) = 'owner'
    ) or public.is_super_admin()
  );

-- =============================================
-- سياسات RLS — Budget Entries
-- =============================================
create policy "budget_select" on public.budget_entries for select
  using (public.is_group_member(group_id) or public.is_super_admin());

create policy "budget_insert" on public.budget_entries for insert
  with check (
    public.get_group_role(group_id) in ('owner', 'editor') and
    added_by = auth.uid()
  );

create policy "budget_delete" on public.budget_entries for delete
  using (public.get_group_role(group_id) = 'owner' or public.is_super_admin());

-- =============================================
-- سياسات RLS — Audit Log
-- =============================================
create policy "audit_select" on public.audit_log for select
  using (public.is_group_member(group_id) or public.is_super_admin());

create policy "audit_insert" on public.audit_log for insert
  with check (user_id = auth.uid());

-- =============================================
-- تعيين Super Admin (شغّل هذا بعد أول تسجيل دخول)
-- =============================================
-- update public.profiles
-- set is_super_admin = true
-- where email = 'mansor.learning@gmail.com';

-- =============================================
-- MIGRATION: صلاحيات تفصيلية للأعضاء
-- شغّل هذا في Supabase SQL Editor إذا سبق وأنشأت الجداول
-- =============================================
alter table public.group_members
  add column if not exists can_view_expenses    boolean default true,
  add column if not exists can_edit_expenses    boolean default false,
  add column if not exists can_view_commitments boolean default true,
  add column if not exists can_edit_commitments boolean default false;

-- السماح لأي مستخدم مسجل بالبحث عن مستخدمين آخرين (للإضافة للمجموعة)
drop policy if exists "profiles_select" on public.profiles;
create policy "profiles_select" on public.profiles for select
  using (auth.uid() is not null);

-- =============================================
-- MIGRATION: صلاحيات نظام الأعمال (Business Permissions)
-- شغّل هذا في Supabase SQL Editor
-- =============================================
alter table public.group_members
  add column if not exists can_add_sales         boolean default true,
  add column if not exists can_edit_sales        boolean default false,
  add column if not exists can_view_reports      boolean default true,
  add column if not exists can_manage_purchases  boolean default false,
  add column if not exists can_view_treasury     boolean default true,
  add column if not exists can_edit_treasury     boolean default false;

-- جدول المبيعات لنظام الأعمال
create table if not exists public.sales (
  id uuid default uuid_generate_v4() primary key,
  group_id uuid references public.groups(id) on delete cascade not null,
  added_by uuid references public.profiles(id) not null,
  product text not null,
  qty decimal(10,3) default 1,
  price decimal(12,2) not null check (price >= 0),
  total decimal(12,2) not null check (total >= 0),
  src text default 'manual' check (src in ('manual', 'voice')),
  created_at timestamptz default now()
);

alter table public.sales enable row level security;

create policy "sales_select" on public.sales for select
  using (public.is_group_member(group_id) or public.is_super_admin());

create policy "sales_insert" on public.sales for insert
  with check (
    public.get_group_role(group_id) in ('owner','editor') and
    added_by = auth.uid()
  );

create policy "sales_update" on public.sales for update
  using (public.get_group_role(group_id) in ('owner','editor'));

create policy "sales_delete" on public.sales for delete
  using (public.get_group_role(group_id) = 'owner' or public.is_super_admin());

-- account_type في profiles
alter table public.profiles
  add column if not exists account_type text default 'personal';

-- =============================================
-- MIGRATION: جدول الخزنة (Treasury)
-- شغّل هذا في Supabase SQL Editor
-- =============================================
create table if not exists public.biz_treasury (
  id uuid default uuid_generate_v4() primary key,
  group_id uuid references public.groups(id) on delete cascade not null,
  added_by uuid references public.profiles(id) not null,
  type text check (type in ('deposit','withdrawal')) not null,
  amount decimal(12,2) not null check (amount > 0),
  note text default '',
  created_at timestamptz default now()
);

alter table public.biz_treasury enable row level security;

create policy "treasury_select" on public.biz_treasury for select
  using (public.is_group_member(group_id) or public.is_super_admin());

create policy "treasury_insert" on public.biz_treasury for insert
  with check (
    public.get_group_role(group_id) in ('owner','editor') and
    added_by = auth.uid()
  );

create policy "treasury_delete" on public.biz_treasury for delete
  using (
    public.get_group_role(group_id) = 'owner' or public.is_super_admin()
  );

-- نوع السحب (شخصي / مشتريات) + نوع الإرجاع
alter table public.biz_treasury
  add column if not exists withdrawal_type text default 'personal';

-- إذا كان الحقل موجوداً بـ constraint قديم، حدّثه:
alter table public.biz_treasury
  drop constraint if exists biz_treasury_withdrawal_type_check;
alter table public.biz_treasury
  add constraint biz_treasury_withdrawal_type_check
    check (withdrawal_type in ('personal','purchases','purchase_return'));

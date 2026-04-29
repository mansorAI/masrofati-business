# مصروفاتي — نظام الأعمال 🏪

> **مشروع مستقل** منفصل عن النظام الشخصي — لكنهما يشتركان في نفس Supabase project وقاعدة البيانات.
> النظام الشخصي موجود في مشروع منفصل خاص به.

🌐 **الموقع:** [masrofati-business.vercel.app](https://masrofati-business.vercel.app)
🔐 **تسجيل الدخول:** [masrofati-business.vercel.app/login-biz.html](https://masrofati-business.vercel.app/login-biz.html)
⚙️ **لوحة التحكم:** [masrofati-business.vercel.app/admin.html](https://masrofati-business.vercel.app/admin.html)
📦 **GitHub:** [github.com/mansorAI/masrofati-business](https://github.com/mansorAI/masrofati-business)

---

## مميزات نظام الأعمال (`business.html`)

- **تسجيل الدخول** عبر `login-biz.html` — مستقل عن النظام الشخصي
- **توجيه ذكي:** إذا كان `account_type = 'business'` أو المستخدم موظف في مجموعة أعمال → `business.html`، إذا كان شخصياً يعطي رسالة خطأ
- **نظام الفروع** — أنشئ فرعاً أو انضم برمز دعوة، إضافة أعضاء بالاسم أو البريد
- **صلاحيات تفصيلية لكل موظف** — المالك يحدد لكل شخص:
  - إضافة مبيعات / تعديلها
  - رؤية التقارير
  - إدارة المشتريات
  - رؤية الخزنة / التعديل عليها
- **المبيعات** — تسجيل يدوي أو صوتي، اسم المنتج + الكمية + السعر + طريقة الدفع (نقدي / شبكة)
- **ضريبة القيمة المضافة 15%** — تفعيل/إيقاف بزر واحد، الحساب `VAT = total × 15/115` (استخراج من سعر شامل)
- **فاتورة ضريبية ZATCA** — QR Code بتشفير TLV Base64 — طباعة مباشرة أو PDF
- **المشتريات** — نظام الالتزامات مع دعم اسم المورد ورفع فاتورة المورد لـ Supabase Storage
- **الخزنة** — إيداع / سحب (شخصي / مشتريات / إرجاع مشتريات) مع طريقة الدفع (نقدي / شبكة)
- **تقارير الخزنة** — أيام الأسبوع ← أسابيع الشهر ← الأشهر الماضية، كل شريط قابل للطي
- **تحميل متوازٍ** — بيانات المبيعات والمشتريات والخزنة بـ `Promise.all` (~66% أسرع)
- **الإدخال الصوتي** — قل: `"قهوة 15"` أو `"عصير 3 بـ 20 ريال"`
- **اقتراح تلقائي (Autocomplete)** — في جميع حقول الاسم
- **واجهة عربية RTL** مع خط Tajawal — تصميم داكن

---

## الصفحات

| الصفحة | الوصف |
|--------|-------|
| 🏠 الرئيسية | ملخص المبيعات اليومية + إجمالي الخزنة |
| 💰 المبيعات | تسجيل مبيعة + قائمة مبيعات اليوم + تقارير |
| 🛒 المشتريات | كروت الالتزامات الشهرية + رفع فاتورة المورد |
| 🏦 الخزنة | إيداع / سحب + تقارير الخزنة |
| 👥 الفرع | إدارة الأعضاء والصلاحيات |

---

## إضافة مبيعة

| الطريقة | التفاصيل |
|---------|---------|
| ✏️ يدوي | اسم المنتج + الكمية + السعر + طريقة الدفع (نقدي/شبكة) |
| 🎙️ صوتي | قل: `"قهوة 15"` أو `"عصير 3 بـ 20 ريال"` |

---

## المشتريات الشهرية

| الإجراء | الطريقة |
|---------|---------|
| إضافة صنف يدوي | اسم + فئة + كمية + سعر |
| إضافة صنف صوتي | قل: `"شامبو 25 ريال"` |
| تحليل فاتورة | التقط صورة → يستخرج الأصناف تلقائياً |
| تعديل صنف | اضغط على الصف في الجدول |
| رفع فاتورة المورد | اختر ملف → يُرفع لـ Supabase Storage |
| تسجيل دفعة | يحسب الإجمالي تلقائياً |

---

## الصلاحيات

| الدور | الصلاحيات |
|-------|-----------|
| 👑 مالك | كامل — إضافة / تعديل / حذف / إدارة الأعضاء |
| ✏️ محرر | إضافة وتعديل حسب الصلاحيات المفعّلة |
| 👁️ مشاهد | عرض فقط |

> الموظفون: حسابهم `account_type = 'personal'` لكن يُوجَّهون لـ `business.html` بسبب عضويتهم في مجموعة أعمال

---

## لوحة التحكم (للمدير فقط)

الرابط: `/admin.html` — يتطلب حساباً بصلاحية `is_super_admin`
اللوحة **مشتركة** بين النظامين مع مبدّل للتنقل بينهما.

### مبدّل النظامين
في أعلى الـ sidebar زرّان:
```
[ 👤 الشخصي ]  [ 🏪 الأعمال ]
```
كل نظام يعرض مستخدميه ومجموعاته فقط — لا يوجد تداخل.

### تصنيف المستخدمين
- **🏪 أعمال:** حسابات `account_type = 'business'` + موظفون (أعضاء في مجموعات أعمال)
- **👤 شخصي:** الباقون — من لم يُضافوا لأي مجموعة أعمال

| القسم | الشخصي | الأعمال |
|-------|--------|---------|
| 👥 المستخدمون | ✅ مفلتر | ✅ مفلتر |
| 📁 المجموعات | ✅ مفلتر | ✅ مفلتر |
| 🏷️ الفئات العالمية | ✅ | ❌ مخفي |
| ⚡ الميزات | ✅ | ✅ |
| 📢 الإعلانات | ✅ | ✅ |

---

## التقنيات

| التقنية | الغرض |
|---------|--------|
| HTML5 / CSS3 / Vanilla JS | الواجهة — بدون frameworks |
| Supabase | قاعدة البيانات + Auth + RLS + Storage |
| Vercel | استضافة ونشر تلقائي من GitHub |
| GitHub | [mansorAI/masrofati-business](https://github.com/mansorAI/masrofati-business) |
| Web Speech API | التعرف الصوتي بالعربية |
| Claude API (Haiku) | تحليل صور فواتير المشتريات |
| Supabase Edge Functions | وسيط آمن بين الموقع وـ Claude API |
| qrcodejs (CDN) | توليد QR Code للفاتورة الضريبية ZATCA |
| Supabase Storage | رفع وتخزين فواتير الموردين |
| Google Fonts (Tajawal) | الخط العربي |

---

## هيكل الملفات

| الملف | الوصف |
|-------|-------|
| `index.html` | صفحة تسجيل الدخول المشتركة (شخصي + أعمال) |
| `login-biz.html` | صفحة تسجيل الدخول المستقلة لنظام الأعمال |
| `business.html` | واجهة نظام الأعمال |
| `admin.html` | لوحة تحكم المدير — مبدّل بين النظامين |
| `schema.sql` | مخطط قاعدة البيانات الكامل |

---

## قاعدة البيانات (Supabase)

> قاعدة بيانات **مشتركة** مع النظام الشخصي — نفس Supabase project.
> العزل عبر `group_id` — التوجيه بعد الدخول عبر `account_type` + العضوية.

| الجدول | الوصف |
|--------|-------|
| `profiles` | ملفات المستخدمين + `account_type` + super_admin |
| `groups` | الفروع/المجموعات + رمز الدعوة |
| `group_members` | الأعضاء + الدور + الصلاحيات التفصيلية |
| `group_settings` | إعدادات الفرع: `biz_name` + `vat_number` + `vat_enabled` |
| `sales` | سجلات المبيعات |
| `commitments` | فئات المشتريات + `supplier_name` + `invoice_url` |
| `commitment_items` | أصناف كل فئة مشتريات |
| `biz_treasury` | الخزنة (إيداع / سحب) + `withdrawal_type` + `payment_method` |
| `app_settings` | إعدادات التطبيق العامة |
| `audit_log` | سجل التعديلات |

---

## Migrations — شغّلها بالترتيب في Supabase SQL Editor

### 1. نوع الحساب + جدول المبيعات
```sql
alter table public.profiles
  add column if not exists account_type text default 'personal';

create table public.sales (
  id uuid default uuid_generate_v4() primary key,
  group_id uuid references public.groups(id) on delete cascade not null,
  added_by uuid references public.profiles(id) not null,
  product text not null,
  qty decimal(10,3) default 1,
  price decimal(12,2) not null check (price >= 0),
  total decimal(12,2) not null,
  src text default 'manual' check (src in ('manual','voice')),
  created_at timestamptz default now()
);
alter table public.sales enable row level security;
create policy "sales_select" on public.sales for select
  using (public.is_group_member(group_id) or public.is_super_admin());
create policy "sales_insert" on public.sales for insert
  with check (public.get_group_role(group_id) in ('owner','editor') and added_by = auth.uid());
create policy "sales_update" on public.sales for update
  using (public.get_group_role(group_id) in ('owner','editor'));
create policy "sales_delete" on public.sales for delete
  using (public.get_group_role(group_id) = 'owner' or public.is_super_admin());
```

### 2. صلاحيات نظام الأعمال
```sql
alter table public.group_members
  add column if not exists can_add_sales         boolean default true,
  add column if not exists can_edit_sales        boolean default false,
  add column if not exists can_view_reports      boolean default true,
  add column if not exists can_manage_purchases  boolean default false,
  add column if not exists can_view_treasury     boolean default true,
  add column if not exists can_edit_treasury     boolean default false;
```

### 3. الخزنة (biz_treasury)
```sql
create table if not exists public.biz_treasury (
  id uuid default uuid_generate_v4() primary key,
  group_id uuid references public.groups(id) on delete cascade not null,
  added_by uuid references public.profiles(id) not null,
  type text check (type in ('deposit','withdrawal')) not null,
  amount decimal(12,2) not null check (amount > 0),
  note text default '',
  withdrawal_type text default 'personal',
  created_at timestamptz default now()
);
alter table public.biz_treasury enable row level security;
create policy "treasury_select" on public.biz_treasury for select
  using (public.is_group_member(group_id) or public.is_super_admin());
create policy "treasury_insert" on public.biz_treasury for insert
  with check (public.get_group_role(group_id) in ('owner','editor') and added_by = auth.uid());
create policy "treasury_delete" on public.biz_treasury for delete
  using (public.get_group_role(group_id) = 'owner' or public.is_super_admin());

alter table public.biz_treasury
  drop constraint if exists biz_treasury_withdrawal_type_check;
alter table public.biz_treasury
  add constraint biz_treasury_withdrawal_type_check
    check (withdrawal_type in ('personal','purchases','purchase_return'));
```

### 4. طريقة الدفع + ضريبة القيمة المضافة
```sql
alter table public.sales
  add column if not exists payment_method text default 'card';
alter table public.biz_treasury
  add column if not exists payment_method text default 'card';

alter table public.group_settings
  add column if not exists vat_enabled boolean default false;
```

### 5. الفاتورة الضريبية ZATCA + فواتير الموردين
```sql
alter table public.group_settings
  add column if not exists biz_name    text default '',
  add column if not exists vat_number  text default '';

alter table public.commitments
  add column if not exists supplier_name text,
  add column if not exists invoice_url   text;
```

> **Supabase Storage:** أنشئ bucket باسم `purchase-invoices` ثم أضف:
> ```sql
> create policy "public read purchase invoices"
>   on storage.objects for select using (bucket_id = 'purchase-invoices');
> create policy "auth upload purchase invoices"
>   on storage.objects for insert
>   with check (bucket_id = 'purchase-invoices' and auth.uid() is not null);
> ```

---

## ملاحظات تقنية

- **مشروع مستقل:** الكود منفصل — قاعدة البيانات مشتركة فقط عبر نفس Supabase project
- **login-biz.html:** تسجيل الدخول للأعمال فقط — التسجيل يضع `account_type = 'business'` تلقائياً — إذا دخل حساب شخصي يعطي خطأ ويوجه لـ `index.html`
- **مبدّل لوحة التحكم:** يُحمَّل كل البيانات مرة واحدة (Promise.all) ثم يُفلتر محلياً عند التبديل — لا طلبات إضافية
- **تصنيف الموظفين:** الموظف `account_type = 'personal'` لكن عضو في مجموعة أعمال → يظهر في تاب الأعمال بـ badge "شخصي" (نوع حسابه الأصلي)
- **توجيه ذكي:** بعد تسجيل الدخول يقرأ `account_type` أولاً، ثم يتحقق من العضوية في مجموعة أعمال
- **ضريبة القيمة المضافة:** `VAT = total × 15/115` — تفعيل/إيقاف بزر واحد — مشترك لكل الفرع
- **فاتورة ZATCA:** TLV Base64 encoding — رقم الفاتورة من ترتيب المبيعات بدون تخزين في DB
- **فواتير المشتريات:** Supabase Storage — المسار: `{group_id}/{timestamp}.{ext}`
- **Supabase Redirect URLs:** يجب إضافة `https://masrofati-business.vercel.app/**` في Authentication → URL Configuration

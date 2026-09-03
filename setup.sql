-- =========================================================
-- KAVELO ORDER - SEDJATI COFFEE
-- Supabase Database Setup
-- =========================================================
-- Cara pakai:
-- 1. Buat project Supabase BARU khusus untuk Sedjati Coffee
--    (jangan pakai project client sebelumnya).
-- 2. Buka Project > SQL Editor > New Query.
-- 3. Copy-paste seluruh isi file ini, lalu Run.
-- 4. Ambil "Project URL" dan "anon public key" dari
--    Project Settings > API, lalu isi ke SUPABASE_URL dan
--    SUPABASE_ANON_KEY di index.html.
-- =========================================================


-- ---------------------------------------------------------
-- 1. TABLE: orders
-- ---------------------------------------------------------

create table if not exists public.orders (
    id             uuid primary key default gen_random_uuid(),
    order_number   bigserial,
    table_number   text not null,
    items          jsonb not null,
    notes          text,
    total          numeric not null default 0,
    status         text not null default 'new'
                   check (status in ('new', 'accepted', 'completed', 'cancelled')),
    created_at     timestamptz not null default now()
);

create index if not exists orders_created_at_idx on public.orders (created_at desc);
create index if not exists orders_status_idx on public.orders (status);


-- ---------------------------------------------------------
-- 2. ROW LEVEL SECURITY
-- ---------------------------------------------------------
-- Catatan penting:
-- Admin dashboard di project ini memakai proteksi PIN di sisi
-- frontend saja (bukan login/auth sungguhan), sama seperti
-- template Kavelo Order sebelumnya. Karena itu, anon key perlu
-- izin SELECT dan UPDATE pada tabel orders agar dashboard bisa
-- membaca & mengubah status pesanan. INSERT dilakukan hanya
-- lewat function create_order (security definer) di bawah,
-- bukan langsung dari tabel.

alter table public.orders enable row level security;

drop policy if exists "Public can read orders" on public.orders;
create policy "Public can read orders"
    on public.orders
    for select
    to anon
    using (true);

drop policy if exists "Public can update order status" on public.orders;
create policy "Public can update order status"
    on public.orders
    for update
    to anon
    using (true)
    with check (true);

-- Tidak ada policy INSERT/DELETE untuk anon secara langsung.
-- Insert order hanya boleh lewat RPC create_order di bawah ini.


-- ---------------------------------------------------------
-- 3. FUNCTION: create_order
-- ---------------------------------------------------------
-- Dipanggil dari customer (index.html) lewat supabaseClient.rpc().
-- security definer supaya bisa insert walau anon tidak punya
-- izin INSERT langsung ke tabel.

create or replace function public.create_order(
    p_table_number text,
    p_items        jsonb,
    p_total        numeric,
    p_notes        text default null
)
returns bigint
language plpgsql
security definer
set search_path = public
as $$
declare
    v_order_number bigint;
begin
    if p_table_number is null or length(trim(p_table_number)) = 0 then
        raise exception 'Nomor meja wajib diisi.';
    end if;

    if p_items is null or p_items = '{}'::jsonb then
        raise exception 'Keranjang tidak boleh kosong.';
    end if;

    insert into public.orders (table_number, items, total, notes, status)
    values (p_table_number, p_items, coalesce(p_total, 0), p_notes, 'new')
    returning order_number into v_order_number;

    return v_order_number;
end;
$$;

grant execute on function public.create_order(text, jsonb, numeric, text) to anon;


-- ---------------------------------------------------------
-- 4. REALTIME
-- ---------------------------------------------------------
-- Mengaktifkan realtime update untuk dashboard admin
-- (status "New -> Accepted -> Completed" langsung update tanpa refresh).

alter publication supabase_realtime add table public.orders;


-- ---------------------------------------------------------
-- SELESAI
-- ---------------------------------------------------------
-- Setelah menjalankan script ini:
-- - Tabel "orders" siap menerima order dari customer.
-- - RPC "create_order" siap dipanggil dari frontend.
-- - Realtime aktif untuk dashboard admin.

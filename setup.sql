-- ============================================================
-- RECEBER · Igreja Vidas — Setup do Supabase
-- Cole tudo no SQL Editor do Supabase e clique em RUN
-- ============================================================

create table if not exists rec_visitantes (
  id uuid primary key default gen_random_uuid(),
  criado_em timestamptz not null default now(),
  nome text not null,
  whatsapp text not null,
  culto text,
  pedido_categorias text[] not null default '{}',
  pedido_descricao text,
  boas_vindas boolean not null default false
);

create table if not exists rec_decisoes (
  id uuid primary key default gen_random_uuid(),
  criado_em timestamptz not null default now(),
  nome text not null,
  whatsapp text not null,
  endereco text,
  motivo text not null,
  rede text not null,
  status text not null default 'novo',
  lider text,
  obs text
);

create index if not exists idx_rec_vis_data on rec_visitantes (criado_em desc);
create index if not exists idx_rec_dec_data on rec_decisoes (criado_em desc);
create index if not exists idx_rec_dec_rede on rec_decisoes (rede, status);

alter table rec_visitantes enable row level security;
alter table rec_decisoes enable row level security;

-- Fichas públicas: qualquer pessoa pode inserir
create policy "rec_vis_insert" on rec_visitantes for insert to anon with check (true);
create policy "rec_dec_insert" on rec_decisoes for insert to anon with check (true);

-- Painel (protegido por PIN no app): leitura e atualização
create policy "rec_vis_select" on rec_visitantes for select to anon using (true);
create policy "rec_vis_update" on rec_visitantes for update to anon using (true) with check (true);
create policy "rec_dec_select" on rec_decisoes for select to anon using (true);
create policy "rec_dec_update" on rec_decisoes for update to anon using (true) with check (true);

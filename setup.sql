-- ============================================================
-- RECEBER · Igreja Vidas — Segurança do banco (versão 2)
--
-- ANTES DE RODAR: crie os dois usuários em
--   Authentication → Users → Add user → Create new user
--     receber-total@igrejavidas.app   (senha de acesso total)
--     receber-ficha@igrejavidas.app   (senha só da ficha de decisão)
--   marcando "Auto Confirm User".
--
-- DEPOIS: cole tudo no SQL Editor do Supabase e clique em RUN.
-- Pode rodar de novo sem problema (por exemplo, se recriar um usuário).
-- ============================================================

-- 1) Tabelas (só cria se ainda não existirem; os dados atuais são mantidos)
create table if not exists public.rec_visitantes (
  id uuid primary key default gen_random_uuid(),
  criado_em timestamptz not null default now(),
  nome text not null,
  whatsapp text not null,
  culto text,
  pedido_categorias text[] not null default '{}',
  pedido_descricao text,
  boas_vindas boolean not null default false
);

create table if not exists public.rec_decisoes (
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

create index if not exists idx_rec_vis_data on public.rec_visitantes (criado_em desc);
create index if not exists idx_rec_dec_data on public.rec_decisoes (criado_em desc);
create index if not exists idx_rec_dec_rede on public.rec_decisoes (rede, status);

-- 2) Quem é quem: liga cada usuário ao seu papel.
--    Esta tabela não pode ser lida nem alterada pelo app; só por este script.
create table if not exists public.rec_acesso (
  user_id uuid primary key references auth.users(id) on delete cascade,
  papel text not null check (papel in ('total','ficha'))
);
alter table public.rec_acesso enable row level security;
revoke all on public.rec_acesso from anon, authenticated;

delete from public.rec_acesso;
insert into public.rec_acesso (user_id, papel)
  select id, 'total' from auth.users where lower(email) = 'receber-total@igrejavidas.app';
insert into public.rec_acesso (user_id, papel)
  select id, 'ficha' from auth.users where lower(email) = 'receber-ficha@igrejavidas.app';

-- Devolve o papel de quem está logado ('total', 'ficha' ou nada)
create or replace function public.rec_papel()
returns text
language sql stable security definer
set search_path = public
as $$
  select papel from public.rec_acesso where user_id = auth.uid()
$$;
revoke all on function public.rec_papel() from public;
grant execute on function public.rec_papel() to anon, authenticated;

-- 3) Apaga TODAS as regras antigas (as abertas a qualquer pessoa)
alter table public.rec_visitantes enable row level security;
alter table public.rec_decisoes  enable row level security;

do $$
declare p record;
begin
  for p in select policyname, tablename from pg_policies
           where schemaname = 'public' and tablename in ('rec_visitantes','rec_decisoes')
  loop
    execute format('drop policy %I on public.%I', p.policyname, p.tablename);
  end loop;
end $$;

-- 4) Permissões de base
revoke all on public.rec_visitantes from anon, authenticated;
revoke all on public.rec_decisoes  from anon, authenticated;
grant insert on public.rec_visitantes to anon, authenticated;
grant select, update, delete on public.rec_visitantes to authenticated;
grant select, insert, update, delete on public.rec_decisoes to authenticated;

-- 5) Regras novas
-- Ficha de visitante: qualquer pessoa ENVIA, ninguém sem a senha total LÊ.
create policy "vis_enviar"  on public.rec_visitantes for insert to anon, authenticated with check (true);
create policy "vis_ler"     on public.rec_visitantes for select to authenticated using (public.rec_papel() = 'total');
create policy "vis_editar"  on public.rec_visitantes for update to authenticated using (public.rec_papel() = 'total') with check (public.rec_papel() = 'total');
create policy "vis_apagar"  on public.rec_visitantes for delete to authenticated using (public.rec_papel() = 'total');

-- Ficha de decisão: senha da ficha só ENVIA fichas novas; senha total faz tudo.
create policy "dec_enviar"  on public.rec_decisoes for insert to authenticated
  with check (public.rec_papel() = 'total' or (public.rec_papel() = 'ficha' and status = 'novo'));
create policy "dec_ler"     on public.rec_decisoes for select to authenticated using (public.rec_papel() = 'total');
create policy "dec_editar"  on public.rec_decisoes for update to authenticated using (public.rec_papel() = 'total') with check (public.rec_papel() = 'total');
create policy "dec_apagar"  on public.rec_decisoes for delete to authenticated using (public.rec_papel() = 'total');

-- 6) Conferência: deve mostrar 2 linhas, "total" e "ficha".
select u.email, a.papel
from public.rec_acesso a join auth.users u on u.id = a.user_id
order by a.papel desc;

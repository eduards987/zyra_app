-- =====================================================================
-- Zyra - Segurança do banco (RLS, status de pagamento e perfil)
-- Rode no Supabase: SQL Editor > cole este arquivo > Run
-- (ou `supabase db push` se usar a CLI).
-- O script é idempotente: pode ser executado mais de uma vez.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. TRANSACTIONS: status do pagamento
--    'pending' = cobrança criada | 'paid' = confirmada pelo provedor
-- ---------------------------------------------------------------------
alter table public.transactions
  add column if not exists status text;

-- Transações antigas (criadas antes deste controle) ficam como pagas
-- para não zerar o histórico existente.
update public.transactions set status = 'paid' where status is null;

alter table public.transactions
  alter column status set default 'pending',
  alter column status set not null;

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'transactions_status_check') then
    alter table public.transactions
      add constraint transactions_status_check
      check (status in ('pending', 'paid', 'failed', 'canceled'));
  end if;
  if not exists (select 1 from pg_constraint where conname = 'transactions_amount_check') then
    alter table public.transactions
      add constraint transactions_amount_check
      check (amount > 0 and amount <= 50000) not valid;
  end if;
end $$;

-- user_id sempre preenchido com o usuário logado, se o app não enviar.
alter table public.transactions
  alter column user_id set default auth.uid();

create index if not exists transactions_user_created_idx
  on public.transactions (user_id, created_at desc);

-- ---------------------------------------------------------------------
-- 2. RLS em TRANSACTIONS
--    Cada usuário só vê e cria as PRÓPRIAS transações, sempre pendentes.
--    Ninguém altera ou apaga pelo app: só o servidor (service_role,
--    que ignora RLS) muda o status para 'paid' via webhook.
-- ---------------------------------------------------------------------
alter table public.transactions enable row level security;

drop policy if exists "transactions_select_own" on public.transactions;
create policy "transactions_select_own"
  on public.transactions for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists "transactions_insert_own_pending" on public.transactions;
create policy "transactions_insert_own_pending"
  on public.transactions for insert
  to authenticated
  with check (user_id = auth.uid() and status = 'pending');

-- (sem políticas de UPDATE/DELETE = bloqueado para o app)

-- ---------------------------------------------------------------------
-- 3. USERS (perfil): RLS + criação automática no cadastro
-- ---------------------------------------------------------------------
alter table public.users enable row level security;

drop policy if exists "users_select_own" on public.users;
create policy "users_select_own"
  on public.users for select
  to authenticated
  using (id = auth.uid());

drop policy if exists "users_update_own" on public.users;
create policy "users_update_own"
  on public.users for update
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

-- O perfil é criado pelo banco quando a conta nasce no Auth.
-- Por isso o app não precisa (nem consegue) inserir em public.users.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.users (id, email, nome)
  values (new.id, new.email, '')
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

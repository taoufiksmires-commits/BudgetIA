-- ============================================================
--  BudgetIA — Schéma Supabase (PostgreSQL)
--  À coller dans Supabase → SQL Editor → Run.
--  Modèle "foyer partagé" : tout compte connecté voit les mêmes données.
--  (Pour isoler par utilisateur, voir la note RLS en bas de fichier.)
-- ============================================================

-- ---------- Référentiel : catégories ----------
create table if not exists categories (
  id   text primary key,
  nom  text not null
);

-- ---------- Budgets ----------
create table if not exists budgets (
  id          uuid primary key default gen_random_uuid(),
  nom         text not null,
  type        text not null default 'recurrent' check (type in ('ponctuel','recurrent')),
  periodicite text default 'mensuel',
  alloue      numeric default 0,
  statut      text not null default 'ouvert' check (statut in ('ouvert','cloture')),
  couleur     text default '#2dd4bf',
  description text default '',
  debut       date default current_date,
  created_at  timestamptz default now()
);

-- ---------- Tickets (achats) ----------
create table if not exists tickets (
  id         uuid primary key default gen_random_uuid(),
  enseigne   text default 'Achat',
  date       date not null default current_date,
  source     text default 'manuel',          -- 'manuel' | 'scan'
  total      numeric default 0,
  created_at timestamptz default now()
);

-- ---------- Articles (lignes d'achat) ----------
create table if not exists articles (
  id            uuid primary key default gen_random_uuid(),
  ticket_id     uuid references tickets(id) on delete cascade,
  libelle       text not null,
  quantite      numeric default 1,
  prix_unitaire numeric default 0,
  prix_total    numeric default 0,
  budget_id     uuid references budgets(id) on delete set null,
  categorie_id  text references categories(id),
  created_at    timestamptz default now()
);

-- ---------- Mémoire d'affectation (apprentissage sans IA) ----------
create table if not exists memoire_affectation (
  libelle_normalise text primary key,
  budget_id         uuid references budgets(id) on delete set null,
  categorie_id      text,
  maj               timestamptz default now()
);

-- ---------- Index ----------
create index if not exists idx_articles_budget on articles(budget_id);
create index if not exists idx_articles_ticket on articles(ticket_id);
create index if not exists idx_articles_cat    on articles(categorie_id);
create index if not exists idx_tickets_date    on tickets(date);

-- ---------- Catégories par défaut ----------
insert into categories (id, nom) values
  ('alim','Alimentation'),
  ('hygiene','Hygiène & entretien'),
  ('travaux','Travaux & matériaux'),
  ('outillage','Outillage'),
  ('elec','Électricité'),
  ('plomberie','Plomberie'),
  ('deco','Décoration'),
  ('mobilier','Mobilier'),
  ('jardin','Jardin'),
  ('bebe','Bébé & puériculture'),
  ('divers','Divers')
on conflict (id) do nothing;

-- ---------- Budgets de démarrage (optionnel) ----------
insert into budgets (nom, type, periodicite, alloue, couleur, description) values
  ('Maison (général)','recurrent','mensuel',0,'#2dd4bf','Achats polyvalents pour la maison'),
  ('Courses','recurrent','mensuel',600,'#f5a623','Courses alimentaires mensuelles')
on conflict do nothing;

-- ============================================================
--  ROW LEVEL SECURITY — modèle foyer partagé
--  Toute personne connectée (authenticated) peut tout lire/écrire.
--  La clé "anon" publique du front ne donne accès qu'après login.
-- ============================================================
alter table categories          enable row level security;
alter table budgets             enable row level security;
alter table tickets             enable row level security;
alter table articles            enable row level security;
alter table memoire_affectation enable row level security;

create policy "foyer_categories" on categories
  for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "foyer_budgets" on budgets
  for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "foyer_tickets" on tickets
  for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "foyer_articles" on articles
  for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "foyer_memoire" on memoire_affectation
  for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

-- ============================================================
--  NOTE — Pour ISOLER les données par utilisateur (chacun les siennes) :
--   1) Ajouter sur budgets/tickets/articles :  owner uuid default auth.uid()
--   2) Remplacer les policies par :  using (owner = auth.uid())
--   3) Côté app, renseigner owner à l'insertion (ou laisser le default).
-- ============================================================

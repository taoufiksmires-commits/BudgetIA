# BudgetIA

Application de suivi des achats et budgets, avec affectation automatique (sans IA) et scan de tickets (IA facultative). PWA mono-fichier, données dans **Supabase**, hébergée sur **GitHub Pages**.

---

## 1. Créer la base Supabase

1. Créez un projet sur [supabase.com](https://supabase.com).
2. Ouvrez **SQL Editor**, collez le contenu de `schema.sql`, cliquez **Run**.
3. Récupérez vos identifiants dans **Settings → API** :
   - **Project URL** (ex : `https://abcd1234.supabase.co`)
   - **Clé `anon` `public`** (longue chaîne `eyJ…`)
4. Dans **Authentication → Providers → Email** : pour un accès immédiat, désactivez *Confirm email* (sinon il faudra valider chaque compte par email).

> La clé `anon` est publique par nature : la sécurité repose sur le RLS + l'authentification. Ne mettez **jamais** la clé `service_role` dans le front.

---

## 2. Configurer l'application

Ouvrez `index.html` et renseignez en haut du script :

```js
const SUPABASE_URL = "https://VOTRE-PROJET.supabase.co";
const SUPABASE_ANON_KEY = "VOTRE_CLE_ANON_PUBLIC";
```

C'est la seule modification nécessaire.

---

## 3. Publier sur GitHub Pages

```bash
git init
git add index.html README.md schema.sql
git commit -m "BudgetIA — version Supabase"
git branch -M main
git remote add origin https://github.com/VOTRE-COMPTE/budgetia.git
git push -u origin main
```

Puis sur GitHub : **Settings → Pages → Build and deployment → Source : Deploy from a branch → `main` / `/ (root)`**.
L'appli sera disponible sous `https://VOTRE-COMPTE.github.io/budgetia/`.

---

## 4. Première utilisation

1. Ouvrez l'URL Pages → **Créer un compte** (vous, puis Zineb avec son propre compte).
2. Les deux comptes partagent le **même budget foyer** (modèle par défaut).
3. Pour activer le **scan IA** : onglet **Réglages → Activer le scan IA**, collez votre clé API Anthropic. La clé reste **locale à l'appareil**, elle n'est pas envoyée dans la base.

---

## 5. Migrer les données de l'ancienne version (localStorage)

Si vous aviez saisi des achats dans la version locale :
1. Ouvrez l'ancienne `budgetia.html` → **Réglages → Exporter (JSON)**.
2. Dans la nouvelle appli → **Réglages → Importer en base** → sélectionnez le fichier.

---

## Architecture

| Couche | Choix |
|---|---|
| Front | PWA mono-fichier (HTML/CSS/JS), thème sombre |
| Données | Supabase (PostgreSQL) — tables `budgets`, `tickets`, `articles`, `memoire_affectation`, `categories` |
| Auth | Supabase Auth (email + mot de passe) |
| Sécurité | Row Level Security — accès après connexion |
| IA | Facultative, isolée : photo de ticket → articles (API Anthropic, clé locale) |
| Réglages | Locaux par appareil (clé API, modèle) |

Le moteur de suggestion (mémoire des corrections → projet unique → enseigne → polyvalent → mot-clé) reste **100 % déterministe**, exécuté côté client.

---

## Données partagées vs isolées

Par défaut, tout compte connecté voit les mêmes données (budget commun du foyer).
Pour que chaque utilisateur ait **ses propres** données, suivez la note en bas de `schema.sql` (colonne `owner` + policies `owner = auth.uid()`).

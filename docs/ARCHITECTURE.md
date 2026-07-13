# Data Warehouse - Supermarché Madagascar

## 📊 Structure de l'Entrepôt de Données

Une implémentation complète du modèle en étoile (Star Schema) de Kimball pour l'analyse des ventes.

```
database/
├── migrations/                 # Scripts d'initialisation (ordre numérique)
│   ├── 001_init_database_and_schemas.sql
│   ├── 002_create_staging_tables.sql
│   ├── 003_create_dimensions.sql
│   └── 004_create_fact_table.sql
├── procedures/                 # Procédures stockées (ETL)
│   └── sp_alimenter_etoile.sql
├── views/                      # Vues Analytics (organisées par niveau)
│   ├── v1_ventes_par_periode.sql
│   ├── v2_analyse_dimensions.sql
│   └── v3_analyses_avancees.sql
└── init_all.sql               # Script maître d'initialisation
```

## 🏗️ Architecture

### Couches de l'Entrepôt

```
STAGING (Couche brute)
        ↓
    ETL (sp_alimenter_etoile)
        ↓
CORE (Modèle en étoile)
  ├── Dimensions (9)
  └── Fait Ventes
        ↓
ANALYTICS (Vues de reporting)
```

### Schemas

| Schema | Rôle | Contenu |
|--------|------|---------|
| `staging` | Données brutes | Table `stg_ventes` (import CSV) |
| `core` | Modèle analytique | 9 dimensions + 1 table de faits |
| `analytics` | Reporting | Vues prêtes pour BI/Dashboard |

## 📐 Modèle en Étoile (Core)

### Dimensions (9)

1. **dim_temps** - Calendrier avec conventions temporelles
2. **dim_client** - Profils clients et géolocalisation
3. **dim_produit** - Catalogue avec catégories
4. **dim_magasin** - Points de vente
5. **dim_vendeur** - Personnel de vente
6. **dim_promotion** - Campagnes promotionnelles
7. **dim_canal** - Canaux de distribution (En ligne, Magasin, etc.)
8. **dim_paiement** - Modes de paiement
9. **dim_statut** - Statuts de paiement

### Table de Faits

**fait_ventes** - Mesures principales:
- `quantite_vendue` - Quantité vendue
- `prix_unitaire` - Prix unitaire
- `montant_brut` - Montant avant remise
- `taux_remise` - Pourcentage de remise
- `montant_remise` - Montant en euros
- `montant_net` - Montant après remise
- `cout_unitaire` - Coût d'achat
- `cout_total` - Coût total
- `benefice` - Profit (montant_net - cout_total)
- `marge_pourcentage` - Taux de marge

## 📈 Vues Analytics

### Niveau 1: Agrégations Temporelles

```sql
vw_ventes_par_jour      -- Analyse quotidienne
vw_ventes_par_mois      -- Analyse mensuelle
vw_ventes_par_trimestre -- Analyse trimestrielle
```

### Niveau 2: Analyse par Dimension

```sql
vw_performance_magasins    -- Classement des magasins
vw_top_produits            -- Produits vedettes
vw_vendeurs_performance    -- Performance vendeurs
vw_analyse_categories      -- Ventes par catégorie
```

### Niveau 3: Analyses Avancées

```sql
vw_impact_promotions              -- ROI des promotions
vw_analyse_clients                -- Segmentation client (RFM)
vw_canaux_distribution            -- Performance canaux
vw_retours_qualite                -- Analyse des retours
vw_moyens_paiement_distribution   -- Distribution paiements
```

## 🔄 Processus ETL

### 1. Import des données

```bash
# Import du CSV dans le staging
COPY staging.stg_ventes FROM '/chemin/vers/data_ventes_brute.csv' 
WITH (FORMAT CSV, HEADER);
```

### 2. Alimentation du modèle

```sql
-- Transformer staging → core
CALL core.sp_alimenter_etoile();
```

### 3. Nettoyage du staging (optionnel)

```sql
-- Vider la table de staging après succès
CALL core.sp_nettoyer_staging();
```

## 🚀 Usage

### Initialisation complète

```bash
psql -U user -d entrepot_supermarche -f database/init_all.sql
```

### Importer les données

```sql
-- 1. Charger les données dans staging
COPY staging.stg_ventes FROM '/data/ventes.csv' WITH (FORMAT CSV, HEADER);

-- 2. Alimenter le modèle en étoile
CALL core.sp_alimenter_etoile();

-- 3. Vérifier les résultats
SELECT * FROM analytics.vw_ventes_par_jour ORDER BY date_vente DESC LIMIT 10;
```

### Interroger les vues

```sql
-- Chiffre d'affaires par magasin
SELECT * FROM analytics.vw_performance_magasins;

-- Top 10 produits
SELECT * FROM analytics.vw_top_produits LIMIT 10;

-- Ventes par jour
SELECT * FROM analytics.vw_ventes_par_jour;
```

## 📊 Intégration Dashboard

Les vues sont conçues pour être directement consommées par:
- **Power BI** - Connexion directe au schema `analytics`
- **Grafana** - Requêtes SQL natives
- **Tableau** - Via connecteur PostgreSQL
- **Metabase** - Interface intuitive

### Exemple de connexion

```
Host: [votre-host]
Port: 5432
Database: entrepot_supermarche
Schema: analytics
User: [votre-user]
Password: [votre-password]
```

## 🔒 Sécurité & Performance

### Indices

- Index sur les clés étrangères (JOIN performances)
- Index composite sur dates + montants (agrégations rapides)
- Partitionnement possible par année/mois en cas de volumétrie importante

### Contraintes d'intégrité

- Clés primaires et étrangères pour la cohérence
- Contraintes CHECK sur les valeurs (ex: note_client 1-5)
- ON CONFLICT pour les upserts idempotents

## 📋 Checklist de mise en œuvre

- [ ] Créer la base de données
- [ ] Exécuter les migrations (001-004)
- [ ] Charger les données dans staging
- [ ] Exécuter `sp_alimenter_etoile`
- [ ] Valider les vues analytics
- [ ] Configurer la connexion BI
- [ ] Créer les dashboards dans la repo de dashboard
- [ ] Documenter les KPIs métier

## 🔗 Lien avec l'autre repo

Pour la partie dashboard/BI, créez une repo séparée:

```
repo-dashboard/
├── dashboards/
├── reports/
├── queries/          # Requêtes SQL réutilisables
├── docs/
└── connection.yaml   # Config de connexion au DW
```

Les vues du schema `analytics` seront le point d'entrée unique pour tous les dashboards.

## 📞 Support & Maintenance

### Logs de chargement

```sql
-- Voir l'historique d'alimentation
SELECT * FROM core.fait_ventes 
ORDER BY date_creation DESC LIMIT 100;
```

### Monitoring

```sql
-- Nombre de lignes par table
SELECT 'dim_temps' as table_name, COUNT(*) as count FROM core.dim_temps
UNION ALL
SELECT 'fait_ventes', COUNT(*) FROM core.fait_ventes;
```

---

**Version**: 1.0  
**Modèle**: Star Schema (Kimball)  
**Dernière mise à jour**: 2026-07-13

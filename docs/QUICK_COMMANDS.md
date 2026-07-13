# Commandes et Scripts Utiles

## 🚀 Démarrage Rapide

### 1. Initialiser l'entrepôt

```bash
psql -U postgres -f database/init_all.sql
```

### 2. Importer les données

```bash
# Option A: Directement depuis le CSV
psql -U postgres -d entrepot_supermarche -c \
  "COPY staging.stg_ventes FROM 'data_ventes_brute.csv' WITH (FORMAT CSV, HEADER);"

# Option B: Via script Python
python scripts/import_csv.py --file data_ventes_brute.csv
```

### 3. Alimenter le modèle

```bash
psql -U postgres -d entrepot_supermarche -c "CALL core.sp_alimenter_etoile();"
```

### 4. Valider les données

```bash
psql -U postgres -d entrepot_supermarche -c "SELECT * FROM analytics.vw_ventes_par_jour LIMIT 5;"
```

## 📊 Requêtes Diagnostic

### Vérifier la structure

```sql
-- Tables créées
SELECT schema_name, table_name FROM information_schema.tables 
WHERE schema_name IN ('staging', 'core', 'analytics')
ORDER BY schema_name, table_name;

-- Vues créées
SELECT table_schema, table_name FROM information_schema.views
WHERE table_schema = 'analytics'
ORDER BY table_name;

-- Procédures créées
SELECT routine_schema, routine_name FROM information_schema.routines
WHERE routine_schema = 'core' AND routine_type = 'PROCEDURE';
```

### Compter les lignes

```sql
SELECT
    'staging.stg_ventes' as table_name,
    COUNT(*) as count
FROM staging.stg_ventes

UNION ALL

SELECT 'core.dim_temps', COUNT(*) FROM core.dim_temps
UNION ALL
SELECT 'core.dim_client', COUNT(*) FROM core.dim_client
UNION ALL
SELECT 'core.dim_produit', COUNT(*) FROM core.dim_produit
UNION ALL
SELECT 'core.dim_magasin', COUNT(*) FROM core.dim_magasin
UNION ALL
SELECT 'core.dim_vendeur', COUNT(*) FROM core.dim_vendeur
UNION ALL
SELECT 'core.dim_promotion', COUNT(*) FROM core.dim_promotion
UNION ALL
SELECT 'core.fact_ventes', COUNT(*) FROM core.fait_ventes
ORDER BY table_name;
```

### Vérifier l'intégrité des relations

```sql
-- Ventes sans client associé
SELECT COUNT(*) as orphan_count
FROM core.fait_ventes f
LEFT JOIN core.dim_client c ON f.id_client = c.id_client
WHERE c.id_client IS NULL;

-- Produits manquants
SELECT COUNT(*) as orphan_count
FROM core.fait_ventes f
LEFT JOIN core.dim_produit p ON f.id_produit = p.id_produit
WHERE p.id_produit IS NULL;
```

## 🧹 Maintenance

### Nettoyer le staging

```sql
TRUNCATE TABLE staging.stg_ventes;
```

### Réinitialiser l'entrepôt complet

```bash
# Supprimer et recréer la base
psql -U postgres -c "DROP DATABASE IF EXISTS entrepot_supermarche CASCADE;"
psql -U postgres -f database/init_all.sql
```

### Réanalyser les performances

```sql
ANALYZE core.fait_ventes;
ANALYZE core.dim_temps;
ANALYZE core.dim_client;
```

## 📈 Performances

### Voir les indexes

```sql
SELECT indexname, tablename, indexdef
FROM pg_indexes
WHERE schemaname = 'core'
ORDER BY tablename, indexname;
```

### Plan d'exécution (utilité pour debug)

```sql
EXPLAIN ANALYZE
SELECT * FROM analytics.vw_performance_magasins;

EXPLAIN ANALYZE
SELECT * FROM analytics.vw_ventes_par_jour 
WHERE date_vente >= '2024-01-01';
```

### Requête la plus coûteuse

```sql
SELECT query, calls, mean_time, total_time
FROM pg_stat_statements
ORDER BY total_time DESC
LIMIT 10;
```

## 🔍 Exploration des Données

### Top 10 ventes par jour

```sql
SELECT * FROM analytics.vw_ventes_par_jour 
ORDER BY chiffre_affaires DESC 
LIMIT 10;
```

### Tendance de CA sur 90 jours

```sql
SELECT 
    date_vente,
    chiffre_affaires,
    SUM(chiffre_affaires) OVER (
        ORDER BY date_vente 
        ROWS BETWEEN 7 PRECEDING AND CURRENT ROW
    ) as ca_7jours
FROM analytics.vw_ventes_par_jour
WHERE date_vente >= NOW() - INTERVAL '90 days'
ORDER BY date_vente DESC;
```

### Clients VIP (CA > 10x moyenne)

```sql
WITH client_stats AS (
    SELECT 
        ca_client,
        AVG(ca_client) OVER () as ca_moyen
    FROM analytics.vw_analyse_clients
)
SELECT * FROM analytics.vw_analyse_clients c
WHERE ca_client > (SELECT ca_moyen * 10 FROM client_stats)
ORDER BY ca_client DESC;
```

### Produits en baisse

```sql
SELECT 
    nom_produit,
    categorie,
    chiffre_affaires,
    marge_moyenne,
    nombre_ventes
FROM analytics.vw_top_produits
WHERE nombre_ventes < (SELECT AVG(nombre_ventes) FROM analytics.vw_top_produits)
ORDER BY chiffre_affaires ASC
LIMIT 20;
```

## 🔐 Gestion des Accès

### Créer un utilisateur read-only pour le dashboard

```sql
CREATE ROLE readonly_user WITH LOGIN PASSWORD 'secure_password';

-- Permissions base de données
GRANT CONNECT ON DATABASE entrepot_supermarche TO readonly_user;

-- Permissions schemas
GRANT USAGE ON SCHEMA analytics TO readonly_user;
GRANT USAGE ON SCHEMA core TO readonly_user;

-- Permissions tables
GRANT SELECT ON ALL TABLES IN SCHEMA analytics TO readonly_user;
GRANT SELECT ON ALL TABLES IN SCHEMA core TO readonly_user;

-- Permissions par défaut (nouvelles tables futures)
ALTER DEFAULT PRIVILEGES IN SCHEMA analytics 
GRANT SELECT ON TABLES TO readonly_user;
```

### Révoquer les accès

```sql
REVOKE ALL PRIVILEGES ON DATABASE entrepot_supermarche FROM readonly_user;
DROP ROLE readonly_user;
```

## 📅 Planification (Cron)

### Alimenter l'entrepôt tous les jours à 2h du matin

```bash
0 2 * * * psql -U postgres -d entrepot_supermarche \
    -c "CALL core.sp_alimenter_etoile();" \
    -c "CALL core.sp_nettoyer_staging();"
```

### Sauvegarder la base tous les jours

```bash
0 3 * * * pg_dump -U postgres entrepot_supermarche \
    > /backups/dw_$(date +\%Y\%m\%d).sql
```

## 📦 Export des Données

### Exporter les vues en CSV

```bash
# Ventes par jour
psql -U postgres -d entrepot_supermarche -c \
    "COPY (SELECT * FROM analytics.vw_ventes_par_jour) \
    TO STDOUT WITH CSV HEADER" \
    > ventes_par_jour.csv

# Performance magasins
psql -U postgres -d entrepot_supermarche -c \
    "COPY (SELECT * FROM analytics.vw_performance_magasins) \
    TO STDOUT WITH CSV HEADER" \
    > performance_magasins.csv
```

### Exporter en JSON

```bash
psql -U postgres -d entrepot_supermarche -c \
    "SELECT row_to_json(t) FROM analytics.vw_ventes_par_jour t LIMIT 100" \
    > ventes_sample.json
```

## 🚨 Troubleshooting

### Les vues retournent des données vides

```sql
-- Vérifier que les données sont chargées
SELECT COUNT(*) FROM staging.stg_ventes;
SELECT COUNT(*) FROM core.fait_ventes;

-- Relancer l'alimentation si nécessaire
CALL core.sp_alimenter_etoile();
```

### Les joins ne trouvent pas les clés

```sql
-- Exemple: Clients manquants
SELECT DISTINCT id_client FROM core.fait_ventes
EXCEPT
SELECT id_client FROM core.dim_client;
```

### Performance lente des requêtes

```sql
-- Vérifier les indexes
SELECT * FROM pg_stat_user_indexes 
WHERE schemaname = 'core' 
ORDER BY idx_scan ASC;

-- Réanalyser si nécessaire
ANALYZE;
```

---

**Dernière mise à jour**: 2026-07-13

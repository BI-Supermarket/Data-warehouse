-- ============================================================
-- INITIALISATION COMPLÈTE DE L'ENTREPÔT DE DONNÉES
-- ============================================================
-- Script maître pour initialiser toute la structure
-- Exécuter les migrations dans l'ordre: 001 → 004
-- ============================================================

-- Étape 1: Créer la base et les schemas
\i database/migrations/001_init_database_and_schemas.sql

-- Étape 2: Créer les tables de staging
\i database/migrations/002_create_staging_tables.sql

-- Étape 3: Créer les dimensions
\i database/migrations/003_create_dimensions.sql

-- Étape 4: Créer la table de faits
\i database/migrations/004_create_fact_table.sql

-- Étape 5: Créer les procédures
\i database/procedures/sp_alimenter_etoile.sql

-- Étape 6: Créer les vues analytics
\i database/views/v1_ventes_par_periode.sql
\i database/views/v2_analyse_dimensions.sql
\i database/views/v3_analyses_avancees.sql

RAISE NOTICE '✅ Structure complète de l''entrepôt créée avec succès!';

-- ============================================================
-- MIGRATION 001: Initialisation de la base de données
-- ============================================================
-- Crée la base de données et les schemas principaux
-- ============================================================

-- Création de la base de données
CREATE DATABASE IF NOT EXISTS entrepot_supermarche;

-- Création des schemas
CREATE SCHEMA IF NOT EXISTS staging;    -- Données brutes importées
CREATE SCHEMA IF NOT EXISTS core;       -- Modèle en étoile (dimensions + faits)
CREATE SCHEMA IF NOT EXISTS analytics;  -- Vues prêtes pour le reporting

-- Commentaires pour la documentation
COMMENT ON SCHEMA staging IS 'Données brutes importées du CSV - tables de transit temporaires';
COMMENT ON SCHEMA core IS 'Modèle en étoile (Star Schema Kimball) - dimensions et table de faits';
COMMENT ON SCHEMA analytics IS 'Vues et rapports pour les dashboards et outils BI';

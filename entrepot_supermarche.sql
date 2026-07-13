-- 1. Création de la base de données dédiée
CREATE DATABASE entrepot_supermarche;

-- CRUCIAL : Ouvrez une nouvelle fenêtre de requête connectée à la base 'entrepot_supermarche' avant de continuer.

-- 2. Création des trois couches d'isolation logiques
CREATE SCHEMA staging;
CREATE SCHEMA core;
CREATE SCHEMA analytics;

CREATE TABLE staging.stg_ventes (
    id_vente VARCHAR(100),
    date_vente DATE,
    heure_vente TIME,
    id_ticket VARCHAR(100),
    id_client VARCHAR(100),
    nom_client VARCHAR(255),
    genre_client VARCHAR(10),
    age_client INT,
    ville_client VARCHAR(100),
    id_produit VARCHAR(100),
    nom_produit VARCHAR(255),
    categorie_produit VARCHAR(100),
    sous_categorie VARCHAR(100),
    marque VARCHAR(100),
    id_magasin VARCHAR(100),
    nom_magasin VARCHAR(255),
    ville_magasin VARCHAR(100),
    id_vendeur VARCHAR(100),
    nom_vendeur VARCHAR(255),
    quantite_vendue INT,
    prix_unitaire NUMERIC(12, 2),
    montant_brut NUMERIC(12, 2),
    remise VARCHAR(10),
    taux_remise NUMERIC(5, 2),
    montant_remise NUMERIC(12, 2),
    montant_net NUMERIC(12, 2),
    cout_unitaire NUMERIC(12, 2),
    cout_total NUMERIC(12, 2),
    benefice NUMERIC(12, 2),
    marge NUMERIC(12, 4), -- Permet de stocker précisément les ratios complexes
    mode_paiement VARCHAR(50),
    statut_paiement VARCHAR(50),
    id_promotion VARCHAR(100),
    nom_promotion VARCHAR(255),
    stock_avant_vente INT,
    stock_apres_vente INT,
    fournisseur VARCHAR(255),
    jour INT,
    semaine INT,
    mois INT,
    trimestre INT,
    annee INT,
    jour_semaine VARCHAR(20),
    periode_journee VARCHAR(20),
    canal_vente VARCHAR(50),
    region VARCHAR(100),
    district VARCHAR(100),
    code_postal VARCHAR(50),
    note_client INT,
    retour_produit VARCHAR(10),
    raison_retour VARCHAR(255),
    anomalie VARCHAR(255)
);

-- 1. Dimension Client
CREATE TABLE core.dim_client (
    id_client VARCHAR(100) PRIMARY KEY,
    nom_client VARCHAR(255),
    genre_client VARCHAR(10),
    age_client INT,
    ville_client VARCHAR(100)
);

-- 2. Dimension Produit
CREATE TABLE core.dim_produit (
    id_produit VARCHAR(100) PRIMARY KEY,
    nom_produit VARCHAR(255),
    categorie_produit VARCHAR(100),
    sous_categorie VARCHAR(100),
    marque VARCHAR(100),
    fournisseur VARCHAR(255)
);

-- 3. Dimension Magasin
CREATE TABLE core.dim_magasin (
    id_magasin VARCHAR(100) PRIMARY KEY,
    nom_magasin VARCHAR(255),
    ville_magasin VARCHAR(100),
    region VARCHAR(100),
    district VARCHAR(100),
    code_postal VARCHAR(50)
);

-- 4. Dimension Vendeur
CREATE TABLE core.dim_vendeur (
    id_vendeur VARCHAR(100) PRIMARY KEY,
    nom_vendeur VARCHAR(255)
);

-- 5. Dimension Promotion
CREATE TABLE core.dim_promotion (
    id_promotion VARCHAR(100) PRIMARY KEY,
    nom_promotion VARCHAR(255)
);

-- 6. Dimension Temps
CREATE TABLE core.dim_temps (
    id_temps INT PRIMARY KEY, -- Clé intelligente format YYYYMMDD
    date_vente DATE UNIQUE NOT NULL,
    jour INT,
    semaine INT,
    mois INT,
    trimestre INT,
    annee INT,
    jour_semaine VARCHAR(20)
);

-- 7. Table de Faits Centrale
CREATE TABLE core.fait_ventes (
    id_vente VARCHAR(100) PRIMARY KEY,
    id_ticket VARCHAR(100),
    heure_vente TIME,
    id_client VARCHAR(100) REFERENCES core.dim_client(id_client),
    id_produit VARCHAR(100) REFERENCES core.dim_produit(id_produit),
    id_magasin VARCHAR(100) REFERENCES core.dim_magasin(id_magasin),
    id_vendeur VARCHAR(100) REFERENCES core.dim_vendeur(id_vendeur),
    id_promotion VARCHAR(100) REFERENCES core.dim_promotion(id_promotion),
    id_temps INT REFERENCES core.dim_temps(id_temps),
    quantite_vendue INT,
    prix_unitaire NUMERIC(12, 2),
    montant_brut NUMERIC(12, 2),
    remise VARCHAR(10),
    taux_remise NUMERIC(5, 2),
    montant_remise NUMERIC(12, 2),
    montant_net NUMERIC(12, 2),
    cout_unitaire NUMERIC(12, 2),
    cout_total NUMERIC(12, 2),
    benefice NUMERIC(12, 2),
    marge NUMERIC(12, 4),
    mode_paiement VARCHAR(50),
    statut_paiement VARCHAR(50),
    stock_avant_vente INT,
    stock_apres_vente INT,
    periode_journee VARCHAR(20),
    canal_vente VARCHAR(50),
    note_client INT,
    retour_produit VARCHAR(10),
    raison_retour VARCHAR(255),
    anomalie VARCHAR(255)
);

CREATE OR REPLACE PROCEDURE core.sp_automatiser_pipeline_etoile()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Message de suivi dans les journaux de PostgreSQL
    RAISE NOTICE 'Début de la ventilation automatique du Staging vers le Core...';

    -- 1. Alimentation de la dimension Temps (Calendrier)
    INSERT INTO core.dim_temps (id_temps, date_vente, jour, semaine, mois, trimestre, annee, jour_semaine)
    SELECT DISTINCT
        CAST(TO_CHAR(date_vente, 'YYYYMMDD') AS INT),
        date_vente, jour, semaine, mois, trimestre, annee, jour_semaine
    FROM staging.stg_ventes
    WHERE date_vente IS NOT NULL
    ON CONFLICT (id_temps) DO NOTHING;

    -- 2. Alimentation des autres dimensions (Clients, Produits, Magasins, Vendeurs, Promotions)
    INSERT INTO core.dim_client (id_client, nom_client, genre_client, age_client, ville_client)
    SELECT DISTINCT id_client, nom_client, genre_client, age_client, ville_client 
    FROM staging.stg_ventes 
    WHERE id_client IS NOT NULL
    ON CONFLICT (id_client) DO NOTHING;

    INSERT INTO core.dim_produit (id_produit, nom_produit, categorie_produit, sous_categorie, marque, fournisseur)
    SELECT DISTINCT id_produit, nom_produit, categorie_produit, sous_categorie, marque, fournisseur 
    FROM staging.stg_ventes 
    WHERE id_produit IS NOT NULL
    ON CONFLICT (id_produit) DO NOTHING;

    INSERT INTO core.dim_magasin (id_magasin, nom_magasin, ville_magasin, region, district, code_postal)
    SELECT DISTINCT id_magasin, nom_magasin, ville_magasin, region, district, code_postal 
    FROM staging.stg_ventes 
    WHERE id_magasin IS NOT NULL
    ON CONFLICT (id_magasin) DO NOTHING;

    INSERT INTO core.dim_vendeur (id_vendeur, nom_vendeur)
    SELECT DISTINCT id_vendeur, nom_vendeur 
    FROM staging.stg_ventes 
    WHERE id_vendeur IS NOT NULL
    ON CONFLICT (id_vendeur) DO NOTHING;

    INSERT INTO core.dim_promotion (id_promotion, nom_promotion)
    SELECT DISTINCT id_promotion, nom_promotion 
    FROM staging.stg_ventes 
    WHERE id_promotion IS NOT NULL
    ON CONFLICT (id_promotion) DO NOTHING;

    -- 3. Alimentation de la table de faits centrale (Liaison générale)
    INSERT INTO core.fait_ventes (
        id_vente, id_ticket, heure_vente, id_client, id_produit, id_magasin, id_vendeur, id_promotion, id_temps,
        quantite_vendue, prix_unitaire, montant_brut, remise, taux_remise, montant_remise, montant_net,
        cout_unitaire, cout_total, benefice, marge, mode_paiement, statut_paiement, stock_avant_vente,
        stock_apres_vente, periode_journee, canal_vente, note_client, retour_produit, raison_retour, anomalie
    )
    SELECT 
        id_vente, id_ticket, heure_vente, id_client, id_produit, id_magasin, id_vendeur, id_promotion,
        CAST(TO_CHAR(date_vente, 'YYYYMMDD') AS INT),
        quantite_vendue, prix_unitaire, montant_brut, remise, taux_remise, montant_remise, montant_net,
        cout_unitaire, cout_total, benefice, marge, mode_paiement, statut_paiement, stock_avant_vente,
        stock_apres_vente, periode_journee, canal_vente, note_client, retour_produit, raison_retour, anomalie
    FROM staging.stg_ventes
    WHERE id_vente IS NOT NULL
    ON CONFLICT (id_vente) DO NOTHING;

    RAISE NOTICE 'Ventilation vers le modèle en étoile terminée avec succès !';

    -- 4. Nettoyage de la zone de transit (Staging) pour le prochain import
    -- Décommenter la ligne ci-dessous si vous souhaitez vider le staging automatiquement à la fin
    -- TRUNCATE TABLE staging.stg_ventes;

END;
$$;
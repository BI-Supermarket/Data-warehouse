-- ============================================================
--  ENTREPOT DE DONNEES - SUPERMARCHE MADAGASCAR
--  Modèle : Star Schema (Kimball)
--  Généré depuis le pipeline ETL Python
-- ============================================================

-- ============================================================
--  1. BASE ET SCHEMAS
-- ============================================================
CREATE DATABASE entrepot_supermarche;

CREATE SCHEMA staging;    -- Données brutes importées
CREATE SCHEMA core;        -- Modèle en étoile (dimensions + faits)
CREATE SCHEMA analytics;   -- Vues prêtes pour le reporting

-- ============================================================
--  2. STAGING (1 table = 1 copie du CSV nettoyé)
-- ============================================================
CREATE TABLE staging.stg_ventes (
    -- Identifiants
    id_vente          VARCHAR(100),
    id_ticket         VARCHAR(100),
    id_client         VARCHAR(100),
    id_produit        VARCHAR(100),
    id_magasin        VARCHAR(100),
    id_vendeur        VARCHAR(100),
    id_promotion      VARCHAR(100),

    -- Temps
    date_vente        DATE,
    heure_vente       TIME,
    jour              INT,
    semaine           INT,
    mois              INT,
    trimestre         INT,
    annee             INT,
    jour_semaine      VARCHAR(20),
    periode_journee   VARCHAR(20),

    -- Client
    nom_client        VARCHAR(255),
    genre_client      VARCHAR(10),
    age_client        INT,
    ville_client      VARCHAR(100),
    region            VARCHAR(100),
    district          VARCHAR(100),
    code_postal       VARCHAR(50),

    -- Produit
    nom_produit       VARCHAR(255),
    categorie_produit VARCHAR(100),
    sous_categorie    VARCHAR(100),
    marque            VARCHAR(100),
    fournisseur       VARCHAR(255),

    -- Magasin
    nom_magasin       VARCHAR(255),
    ville_magasin     VARCHAR(100),

    -- Vendeur
    nom_vendeur       VARCHAR(255),

    -- Vente
    quantite_vendue   INT,
    prix_unitaire     NUMERIC(12, 2),
    montant_brut      NUMERIC(12, 2),
    remise            VARCHAR(10),
    taux_remise       NUMERIC(5, 2),
    montant_remise    NUMERIC(12, 2),
    montant_net       NUMERIC(12, 2),
    cout_unitaire     NUMERIC(12, 2),
    cout_total        NUMERIC(12, 2),
    benefice          NUMERIC(12, 2),
    marge             NUMERIC(12, 4),
    mode_paiement     VARCHAR(50),
    statut_paiement   VARCHAR(50),
    canal_vente       VARCHAR(50),
    note_client       INT,
    stock_avant_vente INT,
    stock_apres_vente INT,

    -- Retours
    retour_produit    VARCHAR(10),
    raison_retour     VARCHAR(255),

    -- Qualité
    anomalie          BOOLEAN
);

-- ============================================================
--  3. CORE - DIMENSIONS
--  Chaque dimension a une clé primaire simple (naturelle)
-- ============================================================

-- 3.1 Client
CREATE TABLE core.dim_client (
    id_client   VARCHAR(100) PRIMARY KEY,
    nom         VARCHAR(255),
    genre       VARCHAR(10),
    age         INT,
    ville       VARCHAR(100),
    region      VARCHAR(100),
    district    VARCHAR(100),
    code_postal VARCHAR(50)
);

-- 3.2 Produit
CREATE TABLE core.dim_produit (
    id_produit      VARCHAR(100) PRIMARY KEY,
    nom             VARCHAR(255),
    categorie       VARCHAR(100),
    sous_categorie  VARCHAR(100),
    marque          VARCHAR(100),
    fournisseur     VARCHAR(255)
);

-- 3.3 Magasin
CREATE TABLE core.dim_magasin (
    id_magasin  VARCHAR(100) PRIMARY KEY,
    nom         VARCHAR(255),
    ville       VARCHAR(100),
    region      VARCHAR(100),
    district    VARCHAR(100)
);

-- 3.4 Vendeur
CREATE TABLE core.dim_vendeur (
    id_vendeur  VARCHAR(100) PRIMARY KEY,
    nom         VARCHAR(255)
);

-- 3.5 Promotion
CREATE TABLE core.dim_promotion (
    id_promotion  VARCHAR(100) PRIMARY KEY,
    nom           VARCHAR(255)
);

-- 3.6 Canal de vente (Ex: En ligne, Magasin, Téléphone, Catalogue)
CREATE TABLE core.dim_canal (
    id_canal  INT PRIMARY KEY,
    canal     VARCHAR(50)
);

-- 3.7 Mode de paiement (Ex: Carte bancaire, Mobile Money, Espèces)
CREATE TABLE core.dim_paiement (
    id_paiement    INT PRIMARY KEY,
    mode_paiement  VARCHAR(50)
);

-- 3.8 Statut de paiement (Ex: Payé, En attente, Annulé)
CREATE TABLE core.dim_statut (
    id_statut       INT PRIMARY KEY,
    statut_paiement VARCHAR(50)
);

-- 3.9 Temps (Calendrier)
CREATE TABLE core.dim_temps (
    id_temps    INT PRIMARY KEY,       -- Format YYYYMMDD
    date_vente  DATE UNIQUE NOT NULL,
    jour        INT,
    semaine     INT,
    mois        INT,
    nom_mois    VARCHAR(20),
    trimestre   INT,
    annee       INT,
    jour_semaine VARCHAR(20)
);

-- ============================================================
--  4. CORE - TABLE DE FAITS
--  Contient les mesures + clés étrangères vers les dimensions
-- ============================================================
CREATE TABLE core.fait_ventes (
    -- Clés étrangères (9 dimensions)
    id_vente      VARCHAR(100) PRIMARY KEY,
    id_date       INT       REFERENCES core.dim_temps(id_temps),
    id_client     VARCHAR(100) REFERENCES core.dim_client(id_client),
    id_produit    VARCHAR(100) REFERENCES core.dim_produit(id_produit),
    id_magasin    VARCHAR(100) REFERENCES core.dim_magasin(id_magasin),
    id_vendeur    VARCHAR(100) REFERENCES core.dim_vendeur(id_vendeur),
    id_promotion  VARCHAR(100) REFERENCES core.dim_promotion(id_promotion),
    id_canal      INT       REFERENCES core.dim_canal(id_canal),
    id_paiement   INT       REFERENCES core.dim_paiement(id_paiement),
    id_statut     INT       REFERENCES core.dim_statut(id_statut),

    -- Mesures (10)
    quantite         INT,
    prix_unitaire    NUMERIC(12, 2),
    montant_brut     NUMERIC(12, 2),
    taux_remise      NUMERIC(5, 2),
    montant_remise   NUMERIC(12, 2),
    montant_net      NUMERIC(12, 2),
    cout_unitaire    NUMERIC(12, 2),
    cout_total       NUMERIC(12, 2),
    benefice         NUMERIC(12, 2),
    marge            NUMERIC(12, 4),

    -- Attributs de la transaction
    stock_avant      INT,
    stock_apres      INT,
    note_client      INT,
    retour_produit   VARCHAR(10),
    raison_retour    VARCHAR(255)
);

-- ============================================================
--  5. INDEX (pour les performances)
-- ============================================================
CREATE INDEX idx_fait_date      ON core.fait_ventes(id_date);
CREATE INDEX idx_fait_client    ON core.fait_ventes(id_client);
CREATE INDEX idx_fait_produit   ON core.fait_ventes(id_produit);
CREATE INDEX idx_fait_magasin   ON core.fait_ventes(id_magasin);
CREATE INDEX idx_fait_promotion ON core.fait_ventes(id_promotion);

-- ============================================================
--  6. VUES ANALYTICS (à créer selon les besoins du dashboard)
-- ============================================================
-- Les vues seront ajoutées ici après le développement du dashboard.
-- Exemples :
--   - v_ca_quotidien     : CA par jour
--   - v_ca_categorie     : CA par catégorie de produit
--   - v_top_produits     : Top 10 produits
--   - v_impact_promos    : Impact des promotions
--   - v_performance_mag  : Performance par magasin

-- ============================================================
--  7. PROCEDURE D'ALIMENTATION (Staging → Core)
-- ============================================================
CREATE OR REPLACE PROCEDURE core.sp_alimenter_etoile()
LANGUAGE plpgsql
AS $$
BEGIN

    -- 1. Alimenter les dimensions
    INSERT INTO core.dim_temps (id_temps, date_vente, jour, semaine, mois, nom_mois, trimestre, annee, jour_semaine)
    SELECT DISTINCT
        CAST(TO_CHAR(date_vente, 'YYYYMMDD') AS INT),
        date_vente, jour, semaine, mois,
        CASE mois
            WHEN 1  THEN 'Janvier'   WHEN 2  THEN 'Février'
            WHEN 3  THEN 'Mars'      WHEN 4  THEN 'Avril'
            WHEN 5  THEN 'Mai'       WHEN 6  THEN 'Juin'
            WHEN 7  THEN 'Juillet'   WHEN 8  THEN 'Août'
            WHEN 9  THEN 'Septembre' WHEN 10 THEN 'Octobre'
            WHEN 11 THEN 'Novembre'  WHEN 12 THEN 'Décembre'
        END,
        trimestre, annee, jour_semaine
    FROM staging.stg_ventes
    WHERE date_vente IS NOT NULL
    ON CONFLICT (id_temps) DO NOTHING;

    INSERT INTO core.dim_client (id_client, nom, genre, age, ville, region, district, code_postal)
    SELECT DISTINCT id_client, nom_client, genre_client, age_client,
                    ville_client, region, district, code_postal
    FROM staging.stg_ventes WHERE id_client IS NOT NULL
    ON CONFLICT (id_client) DO NOTHING;

    INSERT INTO core.dim_produit (id_produit, nom, categorie, sous_categorie, marque, fournisseur)
    SELECT DISTINCT id_produit, nom_produit, categorie_produit,
                    sous_categorie, marque, fournisseur
    FROM staging.stg_ventes WHERE id_produit IS NOT NULL
    ON CONFLICT (id_produit) DO NOTHING;

    INSERT INTO core.dim_magasin (id_magasin, nom, ville, region, district)
    SELECT DISTINCT id_magasin, nom_magasin, ville_magasin, region, district
    FROM staging.stg_ventes WHERE id_magasin IS NOT NULL
    ON CONFLICT (id_magasin) DO NOTHING;

    INSERT INTO core.dim_vendeur (id_vendeur, nom)
    SELECT DISTINCT id_vendeur, nom_vendeur
    FROM staging.stg_ventes WHERE id_vendeur IS NOT NULL
    ON CONFLICT (id_vendeur) DO NOTHING;

    INSERT INTO core.dim_promotion (id_promotion, nom)
    SELECT DISTINCT id_promotion, nom_promotion
    FROM staging.stg_ventes WHERE id_promotion IS NOT NULL
    ON CONFLICT (id_promotion) DO NOTHING;

    INSERT INTO core.dim_canal (id_canal, canal)
    SELECT ROW_NUMBER() OVER (ORDER BY canal_vente), canal_vente
    FROM (SELECT DISTINCT canal_vente FROM staging.stg_ventes) sub
    ON CONFLICT (id_canal) DO NOTHING;

    INSERT INTO core.dim_paiement (id_paiement, mode_paiement)
    SELECT ROW_NUMBER() OVER (ORDER BY mode_paiement), mode_paiement
    FROM (SELECT DISTINCT mode_paiement FROM staging.stg_ventes) sub
    ON CONFLICT (id_paiement) DO NOTHING;

    INSERT INTO core.dim_statut (id_statut, statut_paiement)
    SELECT ROW_NUMBER() OVER (ORDER BY statut_paiement), statut_paiement
    FROM (SELECT DISTINCT statut_paiement FROM staging.stg_ventes) sub
    ON CONFLICT (id_statut) DO NOTHING;

    -- 2. Alimenter la table de faits
    INSERT INTO core.fait_ventes (
        id_vente, id_date, id_client, id_produit, id_magasin,
        id_vendeur, id_promotion, id_canal, id_paiement, id_statut,
        quantite, prix_unitaire, montant_brut, taux_remise, montant_remise,
        montant_net, cout_unitaire, cout_total, benefice, marge,
        stock_avant, stock_apres, note_client, retour_produit, raison_retour
    )
    SELECT
        s.id_vente,
        CAST(TO_CHAR(s.date_vente, 'YYYYMMDD') AS INT),
        s.id_client, s.id_produit, s.id_magasin, s.id_vendeur,
        s.id_promotion, c.id_canal, pv.id_paiement, st.id_statut,
        s.quantite_vendue, s.prix_unitaire, s.montant_brut,
        s.taux_remise, s.montant_remise, s.montant_net,
        s.cout_unitaire, s.cout_total, s.benefice, s.marge,
        s.stock_avant_vente, s.stock_apres_vente,
        s.note_client, s.retour_produit, s.raison_retour
    FROM staging.stg_ventes s
    LEFT JOIN core.dim_canal     c  ON s.canal_vente    = c.canal
    LEFT JOIN core.dim_paiement  pv ON s.mode_paiement  = pv.mode_paiement
    LEFT JOIN core.dim_statut    st ON s.statut_paiement = st.statut_paiement
    WHERE s.id_vente IS NOT NULL
    ON CONFLICT (id_vente) DO NOTHING;

    RAISE NOTICE 'Alimentation du modèle en étoile terminée.';
END;
$$;

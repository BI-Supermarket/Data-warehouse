-- ============================================================
-- MIGRATION 003: Création des dimensions (Star Schema)
-- ============================================================
-- Chaque dimension a une clé primaire simple (naturelle)
-- ============================================================

-- 3.1 Dimension: Temps (Calendrier)
CREATE TABLE IF NOT EXISTS core.dim_temps (
    id_temps        INT PRIMARY KEY,       -- Format YYYYMMDD
    date_vente      DATE UNIQUE NOT NULL,
    jour            INT,
    nom_jour        VARCHAR(20),           -- Lundi, Mardi, etc.
    semaine         INT,
    mois            INT,
    nom_mois        VARCHAR(20),           -- Janvier, Février, etc.
    trimestre       INT,
    annee           INT,
    est_weekend     BOOLEAN,
    est_ferie       BOOLEAN DEFAULT FALSE
);

COMMENT ON TABLE core.dim_temps IS 'Dimension Temps - Calendrier avec conventions temporelles';

-- 3.2 Dimension: Client
CREATE TABLE IF NOT EXISTS core.dim_client (
    id_client       VARCHAR(100) PRIMARY KEY,
    nom             VARCHAR(255) NOT NULL,
    genre           VARCHAR(10),
    age             INT,
    ville           VARCHAR(100),
    region          VARCHAR(100),
    district        VARCHAR(100),
    code_postal     VARCHAR(50),
    date_creation   DATE,
    est_actif       BOOLEAN DEFAULT TRUE
);

COMMENT ON TABLE core.dim_client IS 'Dimension Client - Profils des clients';

-- 3.3 Dimension: Produit
CREATE TABLE IF NOT EXISTS core.dim_produit (
    id_produit      VARCHAR(100) PRIMARY KEY,
    nom             VARCHAR(255) NOT NULL,
    categorie       VARCHAR(100),
    sous_categorie  VARCHAR(100),
    marque          VARCHAR(100),
    fournisseur     VARCHAR(255),
    cout_achat      NUMERIC(12, 2),
    prix_list       NUMERIC(12, 2),
    date_creation   DATE,
    est_actif       BOOLEAN DEFAULT TRUE
);

COMMENT ON TABLE core.dim_produit IS 'Dimension Produit - Catalogue des produits';

-- 3.4 Dimension: Magasin
CREATE TABLE IF NOT EXISTS core.dim_magasin (
    id_magasin      VARCHAR(100) PRIMARY KEY,
    nom             VARCHAR(255) NOT NULL,
    ville           VARCHAR(100),
    region          VARCHAR(100),
    district        VARCHAR(100),
    adresse         VARCHAR(255),
    telephone       VARCHAR(20),
    manager         VARCHAR(100),
    date_ouverture  DATE,
    est_ouvert      BOOLEAN DEFAULT TRUE
);

COMMENT ON TABLE core.dim_magasin IS 'Dimension Magasin - Points de vente';

-- 3.5 Dimension: Vendeur
CREATE TABLE IF NOT EXISTS core.dim_vendeur (
    id_vendeur      VARCHAR(100) PRIMARY KEY,
    nom             VARCHAR(255) NOT NULL,
    id_magasin      VARCHAR(100),
    date_embauche   DATE,
    est_actif       BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (id_magasin) REFERENCES core.dim_magasin(id_magasin)
);

COMMENT ON TABLE core.dim_vendeur IS 'Dimension Vendeur - Personnel de vente';

-- 3.6 Dimension: Promotion
CREATE TABLE IF NOT EXISTS core.dim_promotion (
    id_promotion    VARCHAR(100) PRIMARY KEY,
    nom             VARCHAR(255) NOT NULL,
    type_promotion  VARCHAR(50),           -- Réduction, Bundle, Gratuit, etc.
    date_debut      DATE,
    date_fin        DATE,
    pourcentage     NUMERIC(5, 2),
    montant_fixe    NUMERIC(12, 2),
    description     TEXT,
    est_active      BOOLEAN DEFAULT TRUE
);

COMMENT ON TABLE core.dim_promotion IS 'Dimension Promotion - Campagnes promotionnelles';

-- 3.7 Dimension: Canal de vente
CREATE TABLE IF NOT EXISTS core.dim_canal (
    id_canal        INT PRIMARY KEY,
    nom_canal       VARCHAR(50) NOT NULL,  -- En ligne, Magasin, Téléphone, Catalogue
    description     VARCHAR(255)
);

COMMENT ON TABLE core.dim_canal IS 'Dimension Canal de vente - Points de contact clients';

-- 3.8 Dimension: Mode de paiement
CREATE TABLE IF NOT EXISTS core.dim_paiement (
    id_paiement     INT PRIMARY KEY,
    mode_paiement   VARCHAR(50) NOT NULL   -- Carte bancaire, Mobile Money, Espèces
);

COMMENT ON TABLE core.dim_paiement IS 'Dimension Mode de paiement';

-- 3.9 Dimension: Statut de paiement
CREATE TABLE IF NOT EXISTS core.dim_statut (
    id_statut       INT PRIMARY KEY,
    statut_paiement VARCHAR(50) NOT NULL   -- Payé, En attente, Annulé
);

COMMENT ON TABLE core.dim_statut IS 'Dimension Statut de paiement';

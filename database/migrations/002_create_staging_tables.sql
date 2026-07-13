-- ============================================================
-- MIGRATION 002: Création des tables de staging
-- ============================================================
-- Tables de transit pour les données brutes importées du CSV
-- ============================================================

CREATE TABLE IF NOT EXISTS staging.stg_ventes (
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
    anomalie          BOOLEAN,
    
    -- Métadonnées
    date_import       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    source_fichier    VARCHAR(255)
);

COMMENT ON TABLE staging.stg_ventes IS 'Table de staging temporaire pour les données de ventes brutes importées';

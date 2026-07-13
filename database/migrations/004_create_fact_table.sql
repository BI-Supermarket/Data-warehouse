-- ============================================================
-- MIGRATION 004: Création de la table de faits
-- ============================================================
-- Table centrale du modèle en étoile contenant les mesures
-- ============================================================

CREATE TABLE IF NOT EXISTS core.fait_ventes (
    -- Clés étrangères (9 dimensions)
    id_vente        VARCHAR(100) PRIMARY KEY,
    id_temps        INT NOT NULL,
    id_client       VARCHAR(100) NOT NULL,
    id_produit      VARCHAR(100) NOT NULL,
    id_magasin      VARCHAR(100) NOT NULL,
    id_vendeur      VARCHAR(100) NOT NULL,
    id_promotion    VARCHAR(100),
    id_canal        INT,
    id_paiement     INT,
    id_statut       INT,

    -- Mesures (10 mesures principales)
    quantite_vendue     INT NOT NULL,
    prix_unitaire       NUMERIC(12, 2) NOT NULL,
    montant_brut        NUMERIC(12, 2) NOT NULL,
    taux_remise         NUMERIC(5, 2),
    montant_remise      NUMERIC(12, 2),
    montant_net         NUMERIC(12, 2) NOT NULL,
    cout_unitaire       NUMERIC(12, 2),
    cout_total          NUMERIC(12, 2),
    benefice            NUMERIC(12, 2),           -- montant_net - cout_total
    marge_pourcentage   NUMERIC(12, 4),           -- (benefice / montant_net) * 100

    -- Attributs de la transaction
    stock_avant         INT,
    stock_apres         INT,
    note_client         INT CHECK (note_client >= 1 AND note_client <= 5),
    retour_produit      VARCHAR(10),              -- OUI/NON
    raison_retour       VARCHAR(255),
    
    -- Métadonnées
    date_creation       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    est_anomalie        BOOLEAN DEFAULT FALSE,

    -- Contraintes de clés étrangères
    FOREIGN KEY (id_temps)     REFERENCES core.dim_temps(id_temps),
    FOREIGN KEY (id_client)    REFERENCES core.dim_client(id_client),
    FOREIGN KEY (id_produit)   REFERENCES core.dim_produit(id_produit),
    FOREIGN KEY (id_magasin)   REFERENCES core.dim_magasin(id_magasin),
    FOREIGN KEY (id_vendeur)   REFERENCES core.dim_vendeur(id_vendeur),
    FOREIGN KEY (id_promotion) REFERENCES core.dim_promotion(id_promotion),
    FOREIGN KEY (id_canal)     REFERENCES core.dim_canal(id_canal),
    FOREIGN KEY (id_paiement)  REFERENCES core.dim_paiement(id_paiement),
    FOREIGN KEY (id_statut)    REFERENCES core.dim_statut(id_statut)
);

COMMENT ON TABLE core.fait_ventes IS 'Table de faits centrale - Mesures de ventes avec clés étrangères vers dimensions';

-- Indices de performance
CREATE INDEX idx_fait_temps      ON core.fait_ventes(id_temps);
CREATE INDEX idx_fait_client     ON core.fait_ventes(id_client);
CREATE INDEX idx_fait_produit    ON core.fait_ventes(id_produit);
CREATE INDEX idx_fait_magasin    ON core.fait_ventes(id_magasin);
CREATE INDEX idx_fait_vendeur    ON core.fait_ventes(id_vendeur);
CREATE INDEX idx_fait_promotion  ON core.fait_ventes(id_promotion);
CREATE INDEX idx_fait_date_range ON core.fait_ventes(id_temps, montant_net);  -- Pour agrégations temporelles

-- ============================================================
-- PROCEDURE: Alimentation de l'entrepôt (Staging → Core)
-- ============================================================
-- Extrait et transforme les données du staging vers le modèle en étoile
-- À exécuter après chaque import de données
-- ============================================================

CREATE OR REPLACE PROCEDURE core.sp_alimenter_etoile()
LANGUAGE plpgsql
AS $$
DECLARE
    v_count_temps INT;
    v_count_client INT;
    v_count_produit INT;
    v_count_magasin INT;
    v_count_vendeur INT;
    v_count_ventes INT;
BEGIN

    -- 1. Alimenter la dimension TEMPS
    INSERT INTO core.dim_temps (id_temps, date_vente, jour, nom_jour, semaine, mois, nom_mois, trimestre, annee, est_weekend)
    SELECT DISTINCT
        CAST(TO_CHAR(date_vente, 'YYYYMMDD') AS INT) AS id_temps,
        date_vente,
        EXTRACT(DAY FROM date_vente)::INT,
        TO_CHAR(date_vente, 'Day'),
        EXTRACT(WEEK FROM date_vente)::INT,
        EXTRACT(MONTH FROM date_vente)::INT,
        TO_CHAR(date_vente, 'Month'),
        EXTRACT(QUARTER FROM date_vente)::INT,
        EXTRACT(YEAR FROM date_vente)::INT,
        EXTRACT(DOW FROM date_vente) IN (0, 6)  -- 0=Sunday, 6=Saturday
    FROM staging.stg_ventes
    WHERE date_vente IS NOT NULL
    ON CONFLICT (id_temps) DO NOTHING;

    GET DIAGNOSTICS v_count_temps = ROW_COUNT;
    RAISE NOTICE '✓ Dimension TEMPS: % lignes insérées', v_count_temps;

    -- 2. Alimenter la dimension CLIENT
    INSERT INTO core.dim_client (id_client, nom, genre, age, ville, region, district, code_postal, est_actif)
    SELECT DISTINCT
        id_client, nom_client, genre_client, age_client,
        ville_client, region, district, code_postal, TRUE
    FROM staging.stg_ventes
    WHERE id_client IS NOT NULL
    ON CONFLICT (id_client) DO NOTHING;

    GET DIAGNOSTICS v_count_client = ROW_COUNT;
    RAISE NOTICE '✓ Dimension CLIENT: % lignes insérées', v_count_client;

    -- 3. Alimenter la dimension PRODUIT
    INSERT INTO core.dim_produit (id_produit, nom, categorie, sous_categorie, marque, fournisseur, est_actif)
    SELECT DISTINCT
        id_produit, nom_produit, categorie_produit,
        sous_categorie, marque, fournisseur, TRUE
    FROM staging.stg_ventes
    WHERE id_produit IS NOT NULL
    ON CONFLICT (id_produit) DO NOTHING;

    GET DIAGNOSTICS v_count_produit = ROW_COUNT;
    RAISE NOTICE '✓ Dimension PRODUIT: % lignes insérées', v_count_produit;

    -- 4. Alimenter la dimension MAGASIN
    INSERT INTO core.dim_magasin (id_magasin, nom, ville, region, district, est_ouvert)
    SELECT DISTINCT
        id_magasin, nom_magasin, ville_magasin, region, district, TRUE
    FROM staging.stg_ventes
    WHERE id_magasin IS NOT NULL
    ON CONFLICT (id_magasin) DO NOTHING;

    GET DIAGNOSTICS v_count_magasin = ROW_COUNT;
    RAISE NOTICE '✓ Dimension MAGASIN: % lignes insérées', v_count_magasin;

    -- 5. Alimenter la dimension VENDEUR
    INSERT INTO core.dim_vendeur (id_vendeur, nom, est_actif)
    SELECT DISTINCT id_vendeur, nom_vendeur, TRUE
    FROM staging.stg_ventes
    WHERE id_vendeur IS NOT NULL
    ON CONFLICT (id_vendeur) DO NOTHING;

    GET DIAGNOSTICS v_count_vendeur = ROW_COUNT;
    RAISE NOTICE '✓ Dimension VENDEUR: % lignes insérées', v_count_vendeur;

    -- 6. Alimenter les dimensions de référence (CANAL, PAIEMENT, STATUT)
    INSERT INTO core.dim_canal (id_canal, nom_canal)
    SELECT ROW_NUMBER() OVER (ORDER BY canal_vente), canal_vente
    FROM (SELECT DISTINCT canal_vente FROM staging.stg_ventes WHERE canal_vente IS NOT NULL) sub
    ON CONFLICT (id_canal) DO NOTHING;

    INSERT INTO core.dim_paiement (id_paiement, mode_paiement)
    SELECT ROW_NUMBER() OVER (ORDER BY mode_paiement), mode_paiement
    FROM (SELECT DISTINCT mode_paiement FROM staging.stg_ventes WHERE mode_paiement IS NOT NULL) sub
    ON CONFLICT (id_paiement) DO NOTHING;

    INSERT INTO core.dim_statut (id_statut, statut_paiement)
    SELECT ROW_NUMBER() OVER (ORDER BY statut_paiement), statut_paiement
    FROM (SELECT DISTINCT statut_paiement FROM staging.stg_ventes WHERE statut_paiement IS NOT NULL) sub
    ON CONFLICT (id_statut) DO NOTHING;

    -- 7. Alimenter la table de FAITS
    INSERT INTO core.fait_ventes (
        id_vente, id_temps, id_client, id_produit, id_magasin,
        id_vendeur, id_promotion, id_canal, id_paiement, id_statut,
        quantite_vendue, prix_unitaire, montant_brut, taux_remise,
        montant_remise, montant_net, cout_unitaire, cout_total,
        benefice, marge_pourcentage, stock_avant, stock_apres,
        note_client, retour_produit, raison_retour, est_anomalie
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
        s.note_client, s.retour_produit, s.raison_retour,
        COALESCE(s.anomalie, FALSE)
    FROM staging.stg_ventes s
    LEFT JOIN core.dim_canal     c  ON s.canal_vente     = c.nom_canal
    LEFT JOIN core.dim_paiement  pv ON s.mode_paiement   = pv.mode_paiement
    LEFT JOIN core.dim_statut    st ON s.statut_paiement = st.statut_paiement
    WHERE s.id_vente IS NOT NULL
    ON CONFLICT (id_vente) DO NOTHING;

    GET DIAGNOSTICS v_count_ventes = ROW_COUNT;
    RAISE NOTICE '✓ Table FAITS: % lignes insérées', v_count_ventes;

    RAISE NOTICE '✅ Alimentation du modèle en étoile terminée avec succès!';

EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'Erreur lors de l''alimentation: %', SQLERRM;
END;
$$;

-- Procedure pour nettoyer le staging après alimentation réussie
CREATE OR REPLACE PROCEDURE core.sp_nettoyer_staging()
LANGUAGE plpgsql
AS $$
BEGIN
    TRUNCATE TABLE staging.stg_ventes;
    RAISE NOTICE '✓ Table de staging nettoyée';
EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'Erreur lors du nettoyage du staging: %', SQLERRM;
END;
$$;

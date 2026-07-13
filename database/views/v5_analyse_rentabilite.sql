-- ============================================================
-- VUES ANALYTICS - NIVEAU 5: ANALYSE DE RENTABILITÉ
-- ============================================================
-- Marges, rentabilité, impact des promotions, analyse des remises
-- ============================================================

-- ══════════════════════════════════════════════════════════
-- 5.1 MARGE BRUTE PAR PRODUIT
-- ══════════════════════════════════════════════════════════
-- USE: Identifier les produits rentables vs non-rentables
CREATE OR REPLACE VIEW analytics.vw_marge_produit AS
SELECT
    p.id_produit,
    p.nom AS nom_produit,
    p.categorie,
    p.sous_categorie,
    p.marque,
    COUNT(DISTINCT f.id_vente) AS nombre_ventes,
    SUM(f.quantite_vendue) AS quantite_vendue,
    ROUND(AVG(f.prix_unitaire)::NUMERIC, 2) AS prix_unitaire_moyen,
    ROUND(AVG(f.cout_unitaire)::NUMERIC, 2) AS cout_unitaire_moyen,
    ROUND(SUM(f.montant_net)::NUMERIC, 2) AS ca_net,
    ROUND(SUM(f.cout_total)::NUMERIC, 2) AS cout_total,
    ROUND(SUM(f.benefice)::NUMERIC, 2) AS benefice_total,
    ROUND(AVG(f.marge_pourcentage)::NUMERIC, 2) AS marge_pct_moyen,
    ROUND(((SUM(f.montant_net) - SUM(f.cout_total)) / NULLIF(SUM(f.montant_net), 0) * 100)::NUMERIC, 2) AS marge_brute_globale_pct,
    ROW_NUMBER() OVER (ORDER BY SUM(f.benefice) DESC) AS rang_benefice
FROM core.fait_ventes f
JOIN core.dim_produit p ON f.id_produit = p.id_produit
GROUP BY p.id_produit, p.nom, p.categorie, p.sous_categorie, p.marque
ORDER BY SUM(f.benefice) DESC;

COMMENT ON VIEW analytics.vw_marge_produit IS 
'Marge et bénéfice par produit - Identifier produits rentables/déficitaires';


-- ══════════════════════════════════════════════════════════
-- 5.2 MARGE PAR CATÉGORIE
-- ══════════════════════════════════════════════════════════
-- USE: Performance financière par catégorie de produits
CREATE OR REPLACE VIEW analytics.vw_marge_categorie AS
SELECT
    p.categorie,
    p.sous_categorie,
    COUNT(DISTINCT f.id_vente) AS nombre_ventes,
    COUNT(DISTINCT f.id_produit) AS produits_uniques,
    SUM(f.quantite_vendue) AS quantite_vendue,
    ROUND(SUM(f.montant_net)::NUMERIC, 2) AS ca_net,
    ROUND(SUM(f.cout_total)::NUMERIC, 2) AS cout_total,
    ROUND(SUM(f.benefice)::NUMERIC, 2) AS benefice_total,
    ROUND(AVG(f.marge_pourcentage)::NUMERIC, 2) AS marge_pct_moyen,
    ROUND(((SUM(f.montant_net) - SUM(f.cout_total)) / NULLIF(SUM(f.montant_net), 0) * 100)::NUMERIC, 2) AS marge_brute_pct,
    ROUND((SUM(f.benefice) / NULLIF(SUM(f.montant_net), 0) * 100)::NUMERIC, 2) AS rentabilite_pct,
    CASE 
        WHEN ((SUM(f.montant_net) - SUM(f.cout_total)) / NULLIF(SUM(f.montant_net), 0) * 100) > 30 THEN 'TRÈS RENTABLE'
        WHEN ((SUM(f.montant_net) - SUM(f.cout_total)) / NULLIF(SUM(f.montant_net), 0) * 100) > 15 THEN 'RENTABLE'
        WHEN ((SUM(f.montant_net) - SUM(f.cout_total)) / NULLIF(SUM(f.montant_net), 0) * 100) > 0 THEN 'PEU RENTABLE'
        ELSE 'DÉFICITAIRE'
    END AS niveau_rentabilite
FROM core.fait_ventes f
JOIN core.dim_produit p ON f.id_produit = p.id_produit
GROUP BY p.categorie, p.sous_categorie
ORDER BY SUM(f.benefice) DESC;

COMMENT ON VIEW analytics.vw_marge_categorie IS 
'Analyse rentabilité par catégorie - Classifier catégories par profitabilité';


-- ══════════════════════════════════════════════════════════
-- 5.3 MARGE PAR MAGASIN
-- ══════════════════════════════════════════════════════════
-- USE: Performance financière par point de vente
CREATE OR REPLACE VIEW analytics.vw_marge_magasin AS
SELECT
    m.id_magasin,
    m.nom AS nom_magasin,
    m.ville,
    m.region,
    COUNT(DISTINCT f.id_vente) AS nombre_ventes,
    SUM(f.quantite_vendue) AS quantite_vendue,
    ROUND(SUM(f.montant_net)::NUMERIC, 2) AS ca_net,
    ROUND(SUM(f.cout_total)::NUMERIC, 2) AS cout_total,
    ROUND(SUM(f.benefice)::NUMERIC, 2) AS benefice_total,
    ROUND(AVG(f.marge_pourcentage)::NUMERIC, 2) AS marge_pct_moyen,
    ROUND(((SUM(f.montant_net) - SUM(f.cout_total)) / NULLIF(SUM(f.montant_net), 0) * 100)::NUMERIC, 2) AS marge_brute_pct,
    ROUND((SUM(f.benefice) / NULLIF(SUM(f.ca_net), 0) * 100)::NUMERIC, 2) AS rentabilite_pct,
    ROUND((SUM(f.benefice) / COUNT(DISTINCT f.id_vente))::NUMERIC, 2) AS benefice_par_vente
FROM core.fait_ventes f
JOIN core.dim_magasin m ON f.id_magasin = m.id_magasin
GROUP BY m.id_magasin, m.nom, m.ville, m.region
ORDER BY SUM(f.benefice) DESC;

COMMENT ON VIEW analytics.vw_marge_magasin IS 
'Rentabilité par magasin - Comparer performance financière points de vente';


-- ══════════════════════════════════════════════════════════
-- 5.4 PRODUITS PLUS ET MOINS RENTABLES
-- ══════════════════════════════════════════════════════════
-- USE: Top/Flop des produits par rentabilité
CREATE OR REPLACE VIEW analytics.vw_produits_rentabilite_ranking AS
SELECT
    p.id_produit,
    p.nom AS nom_produit,
    p.categorie,
    COUNT(DISTINCT f.id_vente) AS nombre_ventes,
    SUM(f.quantite_vendue) AS quantite_vendue,
    ROUND(SUM(f.montant_net)::NUMERIC, 2) AS ca_net,
    ROUND(SUM(f.cout_total)::NUMERIC, 2) AS cout_total,
    ROUND(SUM(f.benefice)::NUMERIC, 2) AS benefice,
    ROUND(AVG(f.marge_pourcentage)::NUMERIC, 2) AS marge_pct,
    ROUND((SUM(f.benefice) / NULLIF(COUNT(DISTINCT f.id_vente), 0))::NUMERIC, 2) AS benefice_par_transaction,
    CASE 
        WHEN ROW_NUMBER() OVER (ORDER BY SUM(f.benefice) DESC) <= 10 THEN 'TOP 10'
        WHEN ROW_NUMBER() OVER (ORDER BY SUM(f.benefice) ASC) <= 10 THEN 'BOTTOM 10'
        ELSE 'MOYEN'
    END AS classification,
    ROW_NUMBER() OVER (ORDER BY SUM(f.benefice) DESC) AS rang_benefice_desc,
    ROW_NUMBER() OVER (ORDER BY SUM(f.benefice) ASC) AS rang_benefice_asc
FROM core.fait_ventes f
JOIN core.dim_produit p ON f.id_produit = p.id_produit
GROUP BY p.id_produit, p.nom, p.categorie
ORDER BY SUM(f.benefice) DESC;

COMMENT ON VIEW analytics.vw_produits_rentabilite_ranking IS 
'Top 10 et Flop 10 produits - Identifier étoiles et problèmes';


-- ══════════════════════════════════════════════════════════
-- 5.5 IMPACT DES PROMOTIONS SUR LA RENTABILITÉ
-- ══════════════════════════════════════════════════════════
-- USE: Analyser si les promos sont réellement rentables
CREATE OR REPLACE VIEW analytics.vw_impact_promos_rentabilite AS
SELECT
    pr.id_promotion,
    pr.nom AS nom_promotion,
    pr.type_promotion,
    COUNT(DISTINCT f.id_vente) AS nombre_ventes,
    COUNT(DISTINCT f.id_produit) AS produits_concernes,
    SUM(f.quantite_vendue) AS quantite_vendue,
    ROUND(SUM(f.montant_brut)::NUMERIC, 2) AS ca_sans_promo,
    ROUND(SUM(f.montant_remise)::NUMERIC, 2) AS montant_remise,
    ROUND((SUM(f.montant_remise) / NULLIF(SUM(f.montant_brut), 0) * 100)::NUMERIC, 2) AS taux_remise_moyen_pct,
    ROUND(SUM(f.montant_net)::NUMERIC, 2) AS ca_avec_promo,
    ROUND(SUM(f.cout_total)::NUMERIC, 2) AS cout_total,
    ROUND(SUM(f.benefice)::NUMERIC, 2) AS benefice_avec_promo,
    -- Estimation du bénéfice sans promo (hypothèse: marge identique)
    ROUND((SUM(f.montant_brut) - SUM(f.cout_total))::NUMERIC, 2) AS benefice_estime_sans_promo,
    ROUND((SUM(f.benefice) / NULLIF(SUM(f.montant_net), 0) * 100)::NUMERIC, 2) AS marge_pct_avec_promo,
    ROUND(((SUM(f.montant_brut) - SUM(f.cout_total)) / NULLIF(SUM(f.montant_brut), 0) * 100)::NUMERIC, 2) AS marge_estime_sans_promo_pct,
    CASE 
        WHEN (SUM(f.benefice) / NULLIF(SUM(f.montant_net), 0)) > ((SUM(f.montant_brut) - SUM(f.cout_total)) / NULLIF(SUM(f.montant_brut), 0)) THEN 'AMÉLIORE MARGE'
        WHEN (SUM(f.benefice) / NULLIF(SUM(f.montant_net), 0)) < ((SUM(f.montant_brut) - SUM(f.cout_total)) / NULLIF(SUM(f.montant_brut), 0)) THEN 'DÉTÉRIORE MARGE'
        ELSE 'NEUTRE'
    END AS impact_promo
FROM core.fait_ventes f
LEFT JOIN core.dim_promotion pr ON f.id_promotion = pr.id_promotion
WHERE f.id_promotion IS NOT NULL
GROUP BY pr.id_promotion, pr.nom, pr.type_promotion
ORDER BY SUM(f.benefice) DESC;

COMMENT ON VIEW analytics.vw_impact_promos_rentabilite IS 
'Effet des promotions sur la marge et rentabilité - Évaluer ROI promos';


-- ══════════════════════════════════════════════════════════
-- 5.6 ANALYSE DES REMISES: EFFET SUR LA MARGE
-- ══════════════════════════════════════════════════════════
-- USE: Comprendre comment les remises affectent la rentabilité
CREATE OR REPLACE VIEW analytics.vw_analyse_remises_vs_marge AS
SELECT
    CASE 
        WHEN f.taux_remise IS NULL OR f.taux_remise = 0 THEN 'SANS REMISE'
        WHEN f.taux_remise > 0 AND f.taux_remise <= 5 THEN '0-5%'
        WHEN f.taux_remise > 5 AND f.taux_remise <= 10 THEN '5-10%'
        WHEN f.taux_remise > 10 AND f.taux_remise <= 20 THEN '10-20%'
        ELSE '> 20%'
    END AS tranche_remise,
    COUNT(DISTINCT f.id_vente) AS nombre_ventes,
    SUM(f.quantite_vendue) AS quantite_vendue,
    ROUND(SUM(f.montant_brut)::NUMERIC, 2) AS ca_brut,
    ROUND(SUM(f.montant_remise)::NUMERIC, 2) AS remises_totales,
    ROUND(SUM(f.montant_net)::NUMERIC, 2) AS ca_net,
    ROUND(SUM(f.cout_total)::NUMERIC, 2) AS cout_total,
    ROUND(SUM(f.benefice)::NUMERIC, 2) AS benefice,
    ROUND(AVG(f.marge_pourcentage)::NUMERIC, 2) AS marge_pct_moyen,
    ROUND((SUM(f.benefice) / NULLIF(SUM(f.montant_net), 0) * 100)::NUMERIC, 2) AS rentabilite_pct,
    ROUND((COUNT(DISTINCT f.id_vente)::NUMERIC / (SELECT COUNT(*) FROM core.fait_ventes) * 100), 2) AS pct_transactions
FROM core.fait_ventes f
GROUP BY 
    CASE 
        WHEN f.taux_remise IS NULL OR f.taux_remise = 0 THEN 'SANS REMISE'
        WHEN f.taux_remise > 0 AND f.taux_remise <= 5 THEN '0-5%'
        WHEN f.taux_remise > 5 AND f.taux_remise <= 10 THEN '5-10%'
        WHEN f.taux_remise > 10 AND f.taux_remise <= 20 THEN '10-20%'
        ELSE '> 20%'
    END
ORDER BY 
    CASE 
        WHEN 'SANS REMISE' THEN 0
        WHEN '0-5%' THEN 1
        WHEN '5-10%' THEN 2
        WHEN '10-20%' THEN 3
        ELSE 4
    END;

COMMENT ON VIEW analytics.vw_analyse_remises_vs_marge IS 
'Relation remises vs rentabilité - Montrer l''impact de chaque tranche de remise';

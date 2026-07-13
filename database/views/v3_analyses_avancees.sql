-- ============================================================
-- VUES ANALYTICS - NIVEAU 3: ANALYSES AVANCÉES
-- ============================================================
-- Vues pour les analyses croisées, impact promos, ROI, etc.
-- ============================================================

CREATE OR REPLACE VIEW analytics.vw_impact_promotions AS
SELECT
    pr.id_promotion,
    pr.nom AS promotion,
    pr.type_promotion,
    COUNT(DISTINCT f.id_vente) AS nombre_ventes_promo,
    COUNT(DISTINCT f.id_produit) AS produits_concernes,
    SUM(f.quantite_vendue) AS quantite_avec_promo,
    ROUND(SUM(f.montant_brut)::NUMERIC, 2) AS montant_sans_promo,
    ROUND(SUM(f.montant_remise)::NUMERIC, 2) AS remises_accordees,
    ROUND(SUM(f.montant_net)::NUMERIC, 2) AS montant_avec_promo,
    ROUND(SUM(f.benefice)::NUMERIC, 2) AS benefice_promo,
    ROUND((SUM(f.montant_remise) / SUM(f.montant_brut) * 100)::NUMERIC, 2) AS taux_remise_moyen
FROM core.fait_ventes f
LEFT JOIN core.dim_promotion pr ON f.id_promotion = pr.id_promotion
WHERE f.id_promotion IS NOT NULL
GROUP BY pr.id_promotion, pr.nom, pr.type_promotion
ORDER BY SUM(f.montant_net) DESC;

COMMENT ON VIEW analytics.vw_impact_promotions IS 'Impact financier des promotions';


CREATE OR REPLACE VIEW analytics.vw_analyse_clients AS
SELECT
    c.id_client,
    c.nom,
    c.region,
    COUNT(DISTINCT f.id_vente) AS nombre_achat,
    COUNT(DISTINCT f.id_produit) AS nombre_produits_achetes,
    ROUND(SUM(f.montant_net)::NUMERIC, 2) AS ca_client,
    ROUND(AVG(f.montant_net)::NUMERIC, 2) AS panier_moyen,
    ROUND(MAX(f.montant_net)::NUMERIC, 2) AS panier_max,
    ROUND(AVG(f.note_client)::NUMERIC, 2) AS satisfaction_moyenne,
    MAX(t.date_vente) AS derniere_achat,
    ROUND((SUM(f.montant_net) / COUNT(DISTINCT f.id_vente))::NUMERIC, 2) AS ticket_moyen
FROM core.fait_ventes f
JOIN core.dim_client c ON f.id_client = c.id_client
JOIN core.dim_temps t ON f.id_temps = t.id_temps
GROUP BY c.id_client, c.nom, c.region
ORDER BY SUM(f.montant_net) DESC;

COMMENT ON VIEW analytics.vw_analyse_clients IS 'Segmentation et analyse client (RFM)';


CREATE OR REPLACE VIEW analytics.vw_canaux_distribution AS
SELECT
    ca.id_canal,
    ca.nom_canal,
    COUNT(DISTINCT f.id_vente) AS nombre_ventes,
    SUM(f.quantite_vendue) AS quantite_vendue,
    ROUND(SUM(f.montant_net)::NUMERIC, 2) AS chiffre_affaires,
    ROUND(SUM(f.benefice)::NUMERIC, 2) AS benefice,
    ROUND(AVG(f.marge_pourcentage)::NUMERIC, 2) AS marge_moyenne,
    ROUND((SUM(f.montant_net) / COUNT(DISTINCT f.id_vente))::NUMERIC, 2) AS panier_moyen,
    ROUND((COUNT(DISTINCT f.id_vente) / (SELECT COUNT(*) FROM core.fait_ventes) * 100)::NUMERIC, 2) AS pct_ventes
FROM core.fait_ventes f
JOIN core.dim_canal ca ON f.id_canal = ca.id_canal
GROUP BY ca.id_canal, ca.nom_canal
ORDER BY SUM(f.montant_net) DESC;

COMMENT ON VIEW analytics.vw_canaux_distribution IS 'Performance par canal de distribution';


CREATE OR REPLACE VIEW analytics.vw_retours_qualite AS
SELECT
    CASE
        WHEN f.retour_produit = 'OUI' THEN 'Produits retournés'
        ELSE 'Sans retour'
    END AS statut_retour,
    COUNT(DISTINCT f.id_vente) AS nombre_ventes,
    ROUND((COUNT(DISTINCT f.id_vente)::NUMERIC / 
           (SELECT COUNT(*) FROM core.fait_ventes) * 100), 2) AS pct_ventes,
    SUM(f.quantite_vendue) AS quantite,
    ROUND(SUM(f.montant_net)::NUMERIC, 2) AS montant_net,
    COUNT(DISTINCT CASE WHEN f.raison_retour IS NOT NULL THEN f.id_vente END) AS ventes_avec_raison
FROM core.fait_ventes f
GROUP BY f.retour_produit
ORDER BY nombre_ventes DESC;

COMMENT ON VIEW analytics.vw_retours_qualite IS 'Analyse des retours et anomalies qualité';


CREATE OR REPLACE VIEW analytics.vw_moyens_paiement_distribution AS
SELECT
    pm.id_paiement,
    pm.mode_paiement,
    COUNT(DISTINCT f.id_vente) AS nombre_ventes,
    ROUND((COUNT(DISTINCT f.id_vente)::NUMERIC / 
           (SELECT COUNT(*) FROM core.fait_ventes) * 100), 2) AS pct_ventes,
    ROUND(SUM(f.montant_net)::NUMERIC, 2) AS montant_net,
    ROUND(SUM(f.benefice)::NUMERIC, 2) AS benefice
FROM core.fait_ventes f
LEFT JOIN core.dim_paiement pm ON f.id_paiement = pm.id_paiement
GROUP BY pm.id_paiement, pm.mode_paiement
ORDER BY COUNT(DISTINCT f.id_vente) DESC;

COMMENT ON VIEW analytics.vw_moyens_paiement_distribution IS 'Distribution des modes de paiement';

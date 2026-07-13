-- ============================================================
-- VUES ANALYTICS - NIVEAU 2: ANALYSE PAR DIMENSION
-- ============================================================
-- Vues pour l'analyse des performances par client, produit, magasin
-- ============================================================

CREATE OR REPLACE VIEW analytics.vw_performance_magasins AS
SELECT
    m.id_magasin,
    m.nom AS nom_magasin,
    m.ville,
    m.region,
    COUNT(DISTINCT f.id_vente) AS nombre_ventes,
    COUNT(DISTINCT f.id_client) AS nombre_clients,
    SUM(f.quantite_vendue) AS quantite_vendue,
    ROUND(SUM(f.montant_net)::NUMERIC, 2) AS chiffre_affaires,
    ROUND(SUM(f.benefice)::NUMERIC, 2) AS benefice,
    ROUND(AVG(f.marge_pourcentage)::NUMERIC, 2) AS marge_moyenne,
    ROUND((SUM(f.montant_net) / COUNT(DISTINCT f.id_vente))::NUMERIC, 2) AS panier_moyen,
    ROUND((SUM(f.benefice) / SUM(f.montant_net) * 100)::NUMERIC, 2) AS rentabilite_pct
FROM core.fait_ventes f
JOIN core.dim_magasin m ON f.id_magasin = m.id_magasin
GROUP BY m.id_magasin, m.nom, m.ville, m.region
ORDER BY SUM(f.montant_net) DESC;

COMMENT ON VIEW analytics.vw_performance_magasins IS 'Performance commerciale par magasin';


CREATE OR REPLACE VIEW analytics.vw_top_produits AS
SELECT
    p.id_produit,
    p.nom AS nom_produit,
    p.categorie,
    p.sous_categorie,
    p.marque,
    COUNT(DISTINCT f.id_vente) AS nombre_ventes,
    SUM(f.quantite_vendue) AS quantite_vendue,
    ROUND(SUM(f.montant_net)::NUMERIC, 2) AS chiffre_affaires,
    ROUND(SUM(f.benefice)::NUMERIC, 2) AS benefice,
    ROUND(AVG(f.marge_pourcentage)::NUMERIC, 2) AS marge_moyenne,
    ROW_NUMBER() OVER (ORDER BY SUM(f.montant_net) DESC) AS rang_ca
FROM core.fait_ventes f
JOIN core.dim_produit p ON f.id_produit = p.id_produit
GROUP BY p.id_produit, p.nom, p.categorie, p.sous_categorie, p.marque
ORDER BY SUM(f.montant_net) DESC;

COMMENT ON VIEW analytics.vw_top_produits IS 'Top produits par chiffre d''affaires';


CREATE OR REPLACE VIEW analytics.vw_vendeurs_performance AS
SELECT
    v.id_vendeur,
    v.nom AS nom_vendeur,
    m.nom AS nom_magasin,
    COUNT(DISTINCT f.id_vente) AS nombre_ventes,
    COUNT(DISTINCT f.id_client) AS nombre_clients,
    SUM(f.quantite_vendue) AS quantite_vendue,
    ROUND(SUM(f.montant_net)::NUMERIC, 2) AS chiffre_affaires,
    ROUND(SUM(f.benefice)::NUMERIC, 2) AS benefice,
    ROUND(AVG(f.marge_pourcentage)::NUMERIC, 2) AS marge_moyenne,
    ROUND(AVG(f.note_client)::NUMERIC, 2) AS note_client_moyenne
FROM core.fait_ventes f
JOIN core.dim_vendeur v ON f.id_vendeur = v.id_vendeur
LEFT JOIN core.dim_magasin m ON v.id_magasin = m.id_magasin
GROUP BY v.id_vendeur, v.nom, m.nom
ORDER BY SUM(f.montant_net) DESC;

COMMENT ON VIEW analytics.vw_vendeurs_performance IS 'Performance par vendeur';


CREATE OR REPLACE VIEW analytics.vw_analyse_categories AS
SELECT
    p.categorie,
    p.sous_categorie,
    COUNT(DISTINCT f.id_vente) AS nombre_ventes,
    COUNT(DISTINCT f.id_client) AS nombre_clients_uniques,
    SUM(f.quantite_vendue) AS quantite_vendue,
    ROUND(SUM(f.montant_net)::NUMERIC, 2) AS chiffre_affaires,
    ROUND(SUM(f.benefice)::NUMERIC, 2) AS benefice,
    ROUND(AVG(f.marge_pourcentage)::NUMERIC, 2) AS marge_moyenne,
    ROUND((SUM(f.montant_net) / COUNT(DISTINCT f.id_vente))::NUMERIC, 2) AS panier_moyen
FROM core.fait_ventes f
JOIN core.dim_produit p ON f.id_produit = p.id_produit
GROUP BY p.categorie, p.sous_categorie
ORDER BY SUM(f.montant_net) DESC;

COMMENT ON VIEW analytics.vw_analyse_categories IS 'Analyse des ventes par catégorie de produits';

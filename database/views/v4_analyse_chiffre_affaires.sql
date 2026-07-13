-- ============================================================
-- VUES ANALYTICS - NIVEAU 4: ANALYSE DU CHIFFRE D'AFFAIRES
-- ============================================================
-- CA global, tendances, répartition par canal et géographie
-- ============================================================

-- ══════════════════════════════════════════════════════════
-- 4.1 CA GLOBAL PAR MAGASIN ET PÉRIODE (Mois/Trimestre/Année)
-- ══════════════════════════════════════════════════════════
-- USE: Dashboard KPI, comparaison historique par magasin
CREATE OR REPLACE VIEW analytics.vw_ca_magasin_par_periode AS
SELECT
    t.annee,
    t.trimestre,
    t.mois,
    t.nom_mois,
    m.id_magasin,
    m.nom AS nom_magasin,
    m.ville,
    m.region,
    COUNT(DISTINCT f.id_vente) AS nombre_transactions,
    COUNT(DISTINCT f.id_client) AS clients_uniques,
    SUM(f.quantite_vendue) AS quantite_totale,
    ROUND(SUM(f.montant_brut)::NUMERIC, 2) AS ca_brut,
    ROUND(SUM(f.montant_remise)::NUMERIC, 2) AS total_remises,
    ROUND(SUM(f.montant_net)::NUMERIC, 2) AS ca_net,
    ROUND(AVG(f.montant_net)::NUMERIC, 2) AS panier_moyen,
    ROUND((COUNT(DISTINCT f.id_vente) FILTER (WHERE f.retour_produit = 'OUI') 
           / COUNT(DISTINCT f.id_vente)::NUMERIC * 100), 2) AS taux_retour_pct
FROM core.fait_ventes f
JOIN core.dim_temps t ON f.id_temps = t.id_temps
JOIN core.dim_magasin m ON f.id_magasin = m.id_magasin
GROUP BY t.annee, t.trimestre, t.mois, t.nom_mois, m.id_magasin, m.nom, m.ville, m.region
ORDER BY t.annee DESC, t.mois DESC, m.nom;

COMMENT ON VIEW analytics.vw_ca_magasin_par_periode IS 
'CA par magasin et période (mois/trimestre/année) - Suivi de croissance temporelle';


-- ══════════════════════════════════════════════════════════
-- 4.2 TOP PRODUITS: QUANTITÉ vs CHIFFRE D'AFFAIRES
-- ══════════════════════════════════════════════════════════
-- USE: Analyser le contraste entre volume et valeur (produits à fort volume vs produits premium)
CREATE OR REPLACE VIEW analytics.vw_top_produits_volume_vs_ca AS
SELECT
    p.id_produit,
    p.nom AS nom_produit,
    p.categorie,
    p.sous_categorie,
    p.marque,
    COUNT(DISTINCT f.id_vente) AS nombre_ventes,
    SUM(f.quantite_vendue) AS quantite_totale,
    ROUND(AVG(f.prix_unitaire)::NUMERIC, 2) AS prix_moyen,
    ROUND(SUM(f.montant_net)::NUMERIC, 2) AS ca_total,
    ROUND((SUM(f.montant_net) / NULLIF(SUM(f.quantite_vendue), 0))::NUMERIC, 2) AS ca_par_unite,
    ROUND(SUM(f.benefice)::NUMERIC, 2) AS benefice_total,
    ROUND(AVG(f.marge_pourcentage)::NUMERIC, 2) AS marge_moyenne_pct,
    ROW_NUMBER() OVER (ORDER BY SUM(f.montant_net) DESC) AS rang_ca,
    ROW_NUMBER() OVER (ORDER BY SUM(f.quantite_vendue) DESC) AS rang_volume
FROM core.fait_ventes f
JOIN core.dim_produit p ON f.id_produit = p.id_produit
GROUP BY p.id_produit, p.nom, p.categorie, p.sous_categorie, p.marque
ORDER BY ca_total DESC;

COMMENT ON VIEW analytics.vw_top_produits_volume_vs_ca IS 
'Produits classés par CA et volume - Identifier les produits stars (volume/valeur)';


-- ══════════════════════════════════════════════════════════
-- 4.3 PERFORMANCE PAR CATÉGORIE DE PRODUITS
-- ══════════════════════════════════════════════════════════
-- USE: Dashboard commerce, analyser la contribution de chaque catégorie
CREATE OR REPLACE VIEW analytics.vw_ca_par_categorie AS
SELECT
    p.categorie,
    p.sous_categorie,
    COUNT(DISTINCT f.id_vente) AS nombre_ventes,
    COUNT(DISTINCT f.id_client) AS clients_uniques,
    COUNT(DISTINCT f.id_produit) AS produits_uniques,
    SUM(f.quantite_vendue) AS quantite_vendue,
    ROUND(SUM(f.montant_brut)::NUMERIC, 2) AS ca_brut,
    ROUND(SUM(f.montant_remise)::NUMERIC, 2) AS remises_totales,
    ROUND(SUM(f.montant_net)::NUMERIC, 2) AS ca_net,
    ROUND((SUM(f.montant_net) / COUNT(DISTINCT f.id_vente))::NUMERIC, 2) AS panier_moyen,
    ROUND(SUM(f.benefice)::NUMERIC, 2) AS benefice,
    ROUND(AVG(f.marge_pourcentage)::NUMERIC, 2) AS marge_moyenne_pct,
    ROUND((SUM(f.montant_net) / (SELECT SUM(montant_net) FROM core.fait_ventes) * 100)::NUMERIC, 2) AS pct_ca_total
FROM core.fait_ventes f
JOIN core.dim_produit p ON f.id_produit = p.id_produit
GROUP BY p.categorie, p.sous_categorie
ORDER BY SUM(f.montant_net) DESC;

COMMENT ON VIEW analytics.vw_ca_par_categorie IS 
'CA et performance par catégorie/sous-catégorie - Contribution au chiffre total';


-- ══════════════════════════════════════════════════════════
-- 4.4 TENDANCES SAISONNIÈRES ET PICS DE VENTES
-- ══════════════════════════════════════════════════════════
-- USE: Identifier les mois/périodes forts et creux, prévisions saisonnalité
CREATE OR REPLACE VIEW analytics.vw_tendances_saisonnieres AS
SELECT
    t.mois,
    t.nom_mois,
    t.trimestre,
    COUNT(DISTINCT t.annee) AS annees_observees,
    ROUND(AVG(monthly_ca)::NUMERIC, 2) AS ca_moyen_mois,
    ROUND(MIN(monthly_ca)::NUMERIC, 2) AS ca_min_mois,
    ROUND(MAX(monthly_ca)::NUMERIC, 2) AS ca_max_mois,
    ROUND(STDDEV(monthly_ca)::NUMERIC, 2) AS volatilite_ca,
    ROUND(AVG(monthly_transactions)::NUMERIC, 0) AS transactions_moyennes,
    ROUND(AVG(monthly_clients)::NUMERIC, 0) AS clients_moyens,
    CASE 
        WHEN AVG(monthly_ca) > (SELECT AVG(ca) FROM (
            SELECT SUM(f.montant_net) as ca 
            FROM core.fait_ventes f 
            GROUP BY EXTRACT(MONTH FROM core.dim_temps.date_vente)
        ) sub) THEN 'MOIS FORT'
        ELSE 'MOIS CREUX'
    END AS classification_saisonnalite
FROM core.fait_ventes f
JOIN core.dim_temps t ON f.id_temps = t.id_temps
JOIN (
    SELECT 
        EXTRACT(MONTH FROM dim_temps.date_vente) as mois,
        EXTRACT(YEAR FROM dim_temps.date_vente) as annee,
        SUM(fait_ventes.montant_net) as monthly_ca,
        COUNT(DISTINCT fait_ventes.id_vente) as monthly_transactions,
        COUNT(DISTINCT fait_ventes.id_client) as monthly_clients
    FROM core.fait_ventes
    JOIN core.dim_temps ON core.fait_ventes.id_temps = core.dim_temps.id_temps
    GROUP BY EXTRACT(MONTH FROM dim_temps.date_vente), EXTRACT(YEAR FROM dim_temps.date_vente)
) monthly ON EXTRACT(MONTH FROM t.date_vente) = monthly.mois
GROUP BY t.mois, t.nom_mois, t.trimestre
ORDER BY t.mois;

COMMENT ON VIEW analytics.vw_tendances_saisonnieres IS 
'Analyse des pics et creux saisonniers - Identifier périodes fortes/creuses';


-- ══════════════════════════════════════════════════════════
-- 4.5 RÉPARTITION DES VENTES PAR CANAL DE DISTRIBUTION
-- ══════════════════════════════════════════════════════════
-- USE: Analyser la contribution de chaque canal (En ligne, Magasin, Téléphone, etc.)
CREATE OR REPLACE VIEW analytics.vw_ca_par_canal AS
SELECT
    c.id_canal,
    c.nom_canal,
    COUNT(DISTINCT f.id_vente) AS nombre_ventes,
    COUNT(DISTINCT f.id_client) AS clients_uniques,
    SUM(f.quantite_vendue) AS quantite_vendue,
    ROUND(SUM(f.montant_brut)::NUMERIC, 2) AS ca_brut,
    ROUND(SUM(f.montant_remise)::NUMERIC, 2) AS remises_totales,
    ROUND(SUM(f.montant_net)::NUMERIC, 2) AS ca_net,
    ROUND((SUM(f.montant_net) / COUNT(DISTINCT f.id_vente))::NUMERIC, 2) AS panier_moyen,
    ROUND(SUM(f.benefice)::NUMERIC, 2) AS benefice,
    ROUND(AVG(f.marge_pourcentage)::NUMERIC, 2) AS marge_moyenne_pct,
    ROUND((SUM(f.montant_net) / (SELECT SUM(montant_net) FROM core.fait_ventes) * 100)::NUMERIC, 2) AS pct_ca_total,
    ROUND((COUNT(DISTINCT f.id_vente)::NUMERIC / (SELECT COUNT(*) FROM core.fait_ventes) * 100), 2) AS pct_transactions_total,
    ROUND(AVG(f.note_client)::NUMERIC, 2) AS satisfaction_moyenne
FROM core.fait_ventes f
LEFT JOIN core.dim_canal c ON f.id_canal = c.id_canal
GROUP BY c.id_canal, c.nom_canal
ORDER BY SUM(f.montant_net) DESC;

COMMENT ON VIEW analytics.vw_ca_par_canal IS 
'Ventes par canal (En ligne, Magasin, Téléphone) - Contribution et performance canal';


-- ══════════════════════════════════════════════════════════
-- 4.6 CA GÉOGRAPHIQUE (Région/District/Ville)
-- ══════════════════════════════════════════════════════════
-- USE: Analyser la performance par zone géographique
CREATE OR REPLACE VIEW analytics.vw_ca_par_geographie AS
SELECT
    m.region,
    m.district,
    m.ville,
    COUNT(DISTINCT m.id_magasin) AS nombre_magasins,
    COUNT(DISTINCT f.id_vente) AS nombre_ventes,
    COUNT(DISTINCT f.id_client) AS clients_uniques,
    SUM(f.quantite_vendue) AS quantite_vendue,
    ROUND(SUM(f.montant_net)::NUMERIC, 2) AS ca_net,
    ROUND((SUM(f.montant_net) / COUNT(DISTINCT f.id_vente))::NUMERIC, 2) AS panier_moyen,
    ROUND(SUM(f.benefice)::NUMERIC, 2) AS benefice,
    ROUND(AVG(f.marge_pourcentage)::NUMERIC, 2) AS marge_moyenne_pct,
    ROUND((SUM(f.montant_net) / (SELECT SUM(montant_net) FROM core.fait_ventes) * 100)::NUMERIC, 2) AS pct_ca_total
FROM core.fait_ventes f
JOIN core.dim_magasin m ON f.id_magasin = m.id_magasin
GROUP BY m.region, m.district, m.ville
ORDER BY SUM(f.montant_net) DESC;

COMMENT ON VIEW analytics.vw_ca_par_geographie IS 
'Ventes par région/district/ville - Analyse géographique';

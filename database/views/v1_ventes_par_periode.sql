-- ============================================================
-- VUES ANALYTICS - NIVEAU 1: AGRÉGATIONS TEMPORELLES
-- ============================================================
-- Vues pour les analyses par période (jour, semaine, mois, etc.)
-- ============================================================

CREATE OR REPLACE VIEW analytics.vw_ventes_par_jour AS
SELECT
    t.date_vente,
    t.nom_jour,
    COUNT(DISTINCT f.id_vente) AS nombre_ventes,
    COUNT(DISTINCT f.id_client) AS nombre_clients,
    COUNT(DISTINCT f.id_produit) AS nombre_produits,
    SUM(f.quantite_vendue) AS quantite_totale,
    ROUND(SUM(f.montant_brut)::NUMERIC, 2) AS chiffre_brut,
    ROUND(SUM(f.montant_remise)::NUMERIC, 2) AS remises_totales,
    ROUND(SUM(f.montant_net)::NUMERIC, 2) AS chiffre_affaires,
    ROUND(SUM(f.cout_total)::NUMERIC, 2) AS cout_total,
    ROUND(SUM(f.benefice)::NUMERIC, 2) AS benefice_total,
    ROUND(AVG(f.marge_pourcentage)::NUMERIC, 2) AS marge_moyenne
FROM core.fait_ventes f
JOIN core.dim_temps t ON f.id_temps = t.id_temps
GROUP BY t.date_vente, t.nom_jour, t.id_temps
ORDER BY t.date_vente DESC;

COMMENT ON VIEW analytics.vw_ventes_par_jour IS 'Ventes agrégées par jour - KPIs quotidiens';


CREATE OR REPLACE VIEW analytics.vw_ventes_par_mois AS
SELECT
    t.annee,
    t.mois,
    t.nom_mois,
    COUNT(DISTINCT f.id_vente) AS nombre_ventes,
    COUNT(DISTINCT f.id_client) AS nombre_clients,
    COUNT(DISTINCT f.id_produit) AS nombre_produits,
    SUM(f.quantite_vendue) AS quantite_totale,
    ROUND(SUM(f.montant_net)::NUMERIC, 2) AS chiffre_affaires,
    ROUND(SUM(f.benefice)::NUMERIC, 2) AS benefice_total,
    ROUND(AVG(f.marge_pourcentage)::NUMERIC, 2) AS marge_moyenne,
    ROUND((SUM(f.montant_net) / COUNT(DISTINCT f.id_vente))::NUMERIC, 2) AS panier_moyen
FROM core.fait_ventes f
JOIN core.dim_temps t ON f.id_temps = t.id_temps
GROUP BY t.annee, t.mois, t.nom_mois
ORDER BY t.annee DESC, t.mois DESC;

COMMENT ON VIEW analytics.vw_ventes_par_mois IS 'Ventes agrégées par mois - Analyse mensuelle';


CREATE OR REPLACE VIEW analytics.vw_ventes_par_trimestre AS
SELECT
    t.annee,
    t.trimestre,
    CONCAT('Q', t.trimestre, ' ', t.annee) AS periode,
    COUNT(DISTINCT f.id_vente) AS nombre_ventes,
    SUM(f.quantite_vendue) AS quantite_totale,
    ROUND(SUM(f.montant_net)::NUMERIC, 2) AS chiffre_affaires,
    ROUND(SUM(f.benefice)::NUMERIC, 2) AS benefice_total,
    ROUND(AVG(f.marge_pourcentage)::NUMERIC, 2) AS marge_moyenne
FROM core.fait_ventes f
JOIN core.dim_temps t ON f.id_temps = t.id_temps
GROUP BY t.annee, t.trimestre
ORDER BY t.annee DESC, t.trimestre DESC;

COMMENT ON VIEW analytics.vw_ventes_par_trimestre IS 'Ventes par trimestre - Analyse trimestrielle';


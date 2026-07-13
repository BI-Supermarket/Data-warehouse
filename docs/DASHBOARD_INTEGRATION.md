# Guide d'Intégration Dashboard

## 📊 Exposer les Vues sur un Dashboard

Ce guide explique comment connecter votre repo dashboard à l'entrepôt de données.

## 🎯 Architecture Recommandée

```
Data Warehouse (cette repo)          Dashboard Repo
┌─────────────────────────────┐      ┌──────────────────────────┐
│  PostgreSQL                 │      │  Power BI / Grafana      │
├─────────────────────────────┤      ├──────────────────────────┤
│ schema: analytics           │ <──> │  Dashboards              │
│  ├── vw_ventes_par_jour    │      │  ├── Ventes quotidiennes │
│  ├── vw_top_produits       │      │  ├── Performance Magasins│
│  ├── vw_impact_promotions  │      │  └── Analyse Clients     │
│  └── ... (15 vues)         │      │                          │
└─────────────────────────────┘      └──────────────────────────┘
```

## 🔌 Configuration Connexion

### PostgreSQL Connection String

```
postgresql://user:password@host:5432/entrepot_supermarche?sslmode=require
```

### Variables d'Environnement

Créer un fichier `.env` dans le repo dashboard:

```env
# Connection
DB_HOST=localhost
DB_PORT=5432
DB_NAME=entrepot_supermarche
DB_USER=readonly_user
DB_PASSWORD=secure_password
DB_SCHEMA=analytics

# API
API_PORT=3000
API_LOG_LEVEL=info
```

## 📋 Vues Disponibles

### Ventes par Période (Temps)

```sql
SELECT * FROM analytics.vw_ventes_par_jour
WHERE date_vente >= '2024-01-01'
ORDER BY date_vente DESC;
```

**Colonnes**: date_vente, nom_jour, nombre_ventes, chiffre_affaires, marge_moyenne

---

### Performance Magasins

```sql
SELECT * FROM analytics.vw_performance_magasins
ORDER BY chiffre_affaires DESC;
```

**Colonnes**: nom_magasin, ville, chiffre_affaires, benefice, rentabilite_pct

---

### Top Produits

```sql
SELECT * FROM analytics.vw_top_produits
LIMIT 10;
```

**Colonnes**: nom_produit, categorie, chiffre_affaires, quantite_vendue, marge_moyenne

---

### Vendeurs Performance

```sql
SELECT * FROM analytics.vw_vendeurs_performance
ORDER BY chiffre_affaires DESC;
```

**Colonnes**: nom_vendeur, nom_magasin, nombre_ventes, note_client_moyenne

---

### Impact Promotions

```sql
SELECT * FROM analytics.vw_impact_promotions
ORDER BY montant_avec_promo DESC;
```

**Colonnes**: promotion, remises_accordees, benefice_promo, taux_remise_moyen

---

### Analyse Clients (RFM)

```sql
SELECT * FROM analytics.vw_analyse_clients
WHERE ca_client > 0
ORDER BY ca_client DESC;
```

**Colonnes**: nom, ca_client, nombre_achat, panier_moyen, derniere_achat

---

### Distribution Canaux

```sql
SELECT * FROM analytics.vw_canaux_distribution;
```

**Colonnes**: nom_canal, chiffre_affaires, pct_ventes, panier_moyen

---

## 🛠️ Exemples de Dashboards

### Dashboard 1: Executive Summary

```python
# Vue d'ensemble des KPIs

SELECT 
    SUM(chiffre_affaires) as ca_total,
    SUM(benefice) as benefice_total,
    COUNT(DISTINCT id_client) as clients_actifs,
    COUNT(DISTINCT id_produit) as produits_vendus
FROM analytics.vw_ventes_par_jour
WHERE date_vente >= DATE_TRUNC('month', NOW());
```

### Dashboard 2: Performance Magasins

```python
# Comparer les magasins en temps réel

SELECT 
    nom_magasin,
    chiffre_affaires,
    benefice,
    rentabilite_pct,
    nombre_ventes
FROM analytics.vw_performance_magasins
ORDER BY chiffre_affaires DESC;
```

### Dashboard 3: Analyse Produits

```python
# Catégories et marques à surveiller

SELECT 
    categorie,
    sous_categorie,
    chiffre_affaires,
    quantite_vendue,
    marge_moyenne
FROM analytics.vw_analyse_categories
ORDER BY chiffre_affaires DESC;
```

### Dashboard 4: Retours & Qualité

```python
# Suivi des anomalies

SELECT 
    statut_retour,
    nombre_ventes,
    pct_ventes,
    montant_net
FROM analytics.vw_retours_qualite;
```

## 🐍 Exemple API FastAPI

```python
from fastapi import FastAPI
from sqlalchemy import create_engine
import os

app = FastAPI()
engine = create_engine(
    f"postgresql://{os.getenv('DB_USER')}:{os.getenv('DB_PASSWORD')}"
    f"@{os.getenv('DB_HOST')}:{os.getenv('DB_PORT')}/{os.getenv('DB_NAME')}"
)

@app.get("/api/ventes/par-jour")
async def ventes_par_jour():
    """Ventes quotidiennes"""
    with engine.connect() as conn:
        result = conn.execute(
            "SELECT * FROM analytics.vw_ventes_par_jour ORDER BY date_vente DESC LIMIT 30"
        )
        return {"data": [dict(row) for row in result]}

@app.get("/api/magasins/performance")
async def performance_magasins():
    """Performance par magasin"""
    with engine.connect() as conn:
        result = conn.execute(
            "SELECT * FROM analytics.vw_performance_magasins ORDER BY chiffre_affaires DESC"
        )
        return {"data": [dict(row) for row in result]}
```

## 🔐 Sécurité

### Utilisateur Read-Only

Créer un utilisateur limité pour le dashboard:

```sql
CREATE ROLE readonly_user WITH LOGIN PASSWORD 'secure_password';

GRANT CONNECT ON DATABASE entrepot_supermarche TO readonly_user;
GRANT USAGE ON SCHEMA analytics TO readonly_user;
GRANT SELECT ON ALL TABLES IN SCHEMA analytics TO readonly_user;

ALTER DEFAULT PRIVILEGES IN SCHEMA analytics 
GRANT SELECT ON TABLES TO readonly_user;
```

### Firewall

- Limiter l'accès au port 5432 à l'IP du serveur dashboard
- Utiliser SSL/TLS pour les connexions à distance

## 📈 Performance

### Optimisation

```sql
-- Refresh des statistiques (si volume important)
ANALYZE analytics.vw_ventes_par_jour;

-- Voir les plans de requête
EXPLAIN ANALYZE 
SELECT * FROM analytics.vw_performance_magasins;
```

### Caching

Pour les dashboards haute fréquence, implémenter un cache:

```python
from functools import lru_cache
import time

CACHE_TTL = 300  # 5 minutes

@lru_cache(maxsize=128)
def get_top_products(limit=10):
    # Mis en cache automatiquement
    pass
```

## 🔄 Synchronisation des Données

### Fréquence de Refresh

**Recommandation**: Exécuter `sp_alimenter_etoile()` tous les jours (ou selon votre besoin):

```bash
# Cron job quotidien
0 2 * * * psql -U user -d entrepot_supermarche -c "CALL core.sp_alimenter_etoile();"
```

### Monitoring

Vérifier que les données sont à jour:

```sql
SELECT MAX(date_vente) as derniere_vente
FROM core.fait_ventes;
```

## 🚀 Déploiement

### Docker Compose pour le Dashboard

```yaml
version: '3.8'
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: entrepot_supermarche
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - ./database:/docker-entrypoint-initdb.d
    
  dashboard:
    build: .
    ports:
      - "${API_PORT}:${API_PORT}"
    environment:
      - DB_HOST=postgres
      - DB_NAME=${DB_NAME}
    depends_on:
      - postgres
```

---

**Pour toute question**: Consulter [ARCHITECTURE.md](./ARCHITECTURE.md)

# Data Warehouse - Supermarché Madagascar

Un entrepôt de données complet et scalable utilisant le modèle en étoile (Star Schema) pour l'analyse des ventes de supermarché.

## 🎯 Objectif

Fournir une **source de vérité unique** (Single Source of Truth) pour tous les dashboards et rapports d'analyse avec:
- Architecture modulaire et maintenable
- Performances optimisées pour les requêtes analytiques
- Vues prêtes pour l'export vers BI/Dashboard
- Séparation claire entre données brutes et modèle analytique

## 📊 Structure

```
Data-warehouse/
├── database/
│   ├── migrations/              # Scripts d'initialisation (exécuter dans l'ordre)
│   │   ├── 001_init_database_and_schemas.sql
│   │   ├── 002_create_staging_tables.sql
│   │   ├── 003_create_dimensions.sql
│   │   └── 004_create_fact_table.sql
│   ├── procedures/              # ETL - Transformation des données
│   │   └── sp_alimenter_etoile.sql
│   ├── views/                   # Vues analytics (15+ rapports)
│   │   ├── v1_ventes_par_periode.sql
│   │   ├── v2_analyse_dimensions.sql
│   │   └── v3_analyses_avancees.sql
│   └── init_all.sql            # Script maître
├── docs/
│   ├── ARCHITECTURE.md          # 📘 Modèle en étoile expliqué
│   ├── DASHBOARD_INTEGRATION.md # 🔌 Connexion BI/Dashboard
│   └── QUICK_COMMANDS.md        # 🚀 Commandes utiles
├── data_ventes_brute.csv       # Données source
├── entrepot_supermarche.sql    # (Ancien - voir migrations/)
└── README.md
```

## 🚀 Démarrage Rapide

### 1. Initialiser la base de données

```bash
# PostgreSQL doit être installé et démarré
psql -U postgres -f database/init_all.sql
```

### 2. Importer les données

```bash
psql -U postgres -d entrepot_supermarche -c \
  "COPY staging.stg_ventes FROM 'data_ventes_brute.csv' WITH (FORMAT CSV, HEADER);"
```

### 3. Alimenter le modèle

```bash
psql -U postgres -d entrepot_supermarche -c "CALL core.sp_alimenter_etoile();"
```

### 4. Interroger les vues

```bash
psql -U postgres -d entrepot_supermarche -c \
  "SELECT * FROM analytics.vw_ventes_par_jour LIMIT 5;"
```

## 📐 Architecture

### Star Schema (Kimball)

```
                         TEMPS
                           ▲
                           │
      PRODUIT ◄─┐         │         ┌─► CLIENT
        ▲      │         │         │      ▲
        │    ┌──────────────────┐  │      │
        │    │   FAIT VENTES    │  │      │
        └────┤                  ├──┘      │
             │  10 mesures      │         │
             │  9 clés étrangères         │
             └──────────────────┘         │
        ┌───────────┴────────┬──────────┘
        │                    │
      MAGASIN          PROMOTION
        ▲                    ▲
        │                    │
     VENDEUR ◄────────► CANAL, PAIEMENT, STATUT
```

### Les 3 Couches

| Couche | Role | Tables | Accès |
|--------|------|--------|-------|
| **Staging** | Import brut | `stg_ventes` | ETL uniquement |
| **Core** | Modèle analytique | 9 dimensions + 1 fait | ETL uniquement |
| **Analytics** | Reporting | 15+ vues | **BI/Dashboard** ✓ |

## 📊 Vues Disponibles (15+)

### Agrégations Temporelles
- `vw_ventes_par_jour` - Quotidien
- `vw_ventes_par_mois` - Mensuel
- `vw_ventes_par_trimestre` - Trimestriel

### Analyse par Dimension
- `vw_performance_magasins` - Classement magasins
- `vw_top_produits` - Produits vedettes
- `vw_vendeurs_performance` - Performance vendeurs
- `vw_analyse_categories` - Par catégorie

### Analyses Avancées
- `vw_impact_promotions` - ROI promos
- `vw_analyse_clients` - Segmentation RFM
- `vw_canaux_distribution` - Performance canaux
- `vw_retours_qualite` - Anomalies
- `vw_moyens_paiement_distribution` - Distribution paiements

## 🔌 Connexion Dashboard

### String de Connexion

```
postgresql://user:password@localhost:5432/entrepot_supermarche
```

### Accès depuis votre repo Dashboard

```python
import psycopg2
from psycopg2.extras import RealDictCursor

conn = psycopg2.connect(
    host="localhost",
    database="entrepot_supermarche",
    user="readonly_user",
    password="secure_password"
)

cursor = conn.cursor(cursor_factory=RealDictCursor)
cursor.execute("SELECT * FROM analytics.vw_ventes_par_jour")
rows = cursor.fetchall()
```

### Exemple Power BI / Grafana

1. Créer une nouvelle connexion PostgreSQL
2. Hostname: `localhost`
3. Port: `5432`
4. Database: `entrepot_supermarche`
5. Schema: `analytics`
6. Choisir les vues à importer ✓

## 📈 Mesures (KPIs)

La table de faits contient 10 mesures:

| Mesure | Description | Format |
|--------|-------------|--------|
| `quantite_vendue` | Unités | INT |
| `prix_unitaire` | PU hors remise | NUMERIC(12,2) |
| `montant_brut` | CA avant remise | NUMERIC(12,2) |
| `taux_remise` | % remise | NUMERIC(5,2) |
| `montant_remise` | € remise | NUMERIC(12,2) |
| `montant_net` | CA après remise | NUMERIC(12,2) |
| `cout_unitaire` | Coût d'achat | NUMERIC(12,2) |
| `cout_total` | Coût total | NUMERIC(12,2) |
| `benefice` | Profit (net - coût) | NUMERIC(12,2) |
| `marge_pourcentage` | Taux de marge | NUMERIC(12,4) |

## 🔄 Pipeline ETL

```
CSV (data_ventes_brute.csv)
  ↓
STAGING (stg_ventes)
  ↓
sp_alimenter_etoile()
  ├─ Alimenter dimensions (9)
  └─ Alimenter fait (mesures)
  ↓
CORE (modèle en étoile)
  ↓
ANALYTICS (vues de reporting)
  ↓
📊 DASHBOARDS
```

## 📖 Documentation

- **[ARCHITECTURE.md](./docs/ARCHITECTURE.md)** - Modèle en détail, dimensions, faits
- **[DASHBOARD_INTEGRATION.md](./docs/DASHBOARD_INTEGRATION.md)** - Intégration BI, exemples
- **[QUICK_COMMANDS.md](./docs/QUICK_COMMANDS.md)** - Commandes SQL utiles, troubleshooting

## 🛠️ Migrations

Exécuter dans cet ordre:

```bash
psql -U postgres -f database/migrations/001_init_database_and_schemas.sql
psql -U postgres -f database/migrations/002_create_staging_tables.sql
psql -U postgres -f database/migrations/003_create_dimensions.sql
psql -U postgres -f database/migrations/004_create_fact_table.sql
psql -U postgres -f database/procedures/sp_alimenter_etoile.sql
psql -U postgres -f database/views/*.sql
```

Ou simplement:

```bash
psql -U postgres -f database/init_all.sql
```

## 📋 Checklist de Déploiement

- [ ] PostgreSQL installé et démarré
- [ ] Exécuter `init_all.sql`
- [ ] Vérifier que les 9 dimensions sont peuplées
- [ ] Importer le CSV
- [ ] Exécuter `sp_alimenter_etoile()`
- [ ] Tester les vues: `SELECT * FROM analytics.vw_ventes_par_jour`
- [ ] Créer utilisateur read-only pour dashboard
- [ ] Configurer connexion BI
- [ ] Créer dashboards dans repo séparée

## 🔐 Sécurité

### Utilisateur Read-Only pour Dashboard

```sql
CREATE ROLE readonly_user WITH LOGIN PASSWORD 'secure_password';
GRANT CONNECT ON DATABASE entrepot_supermarche TO readonly_user;
GRANT USAGE ON SCHEMA analytics TO readonly_user;
GRANT SELECT ON ALL TABLES IN SCHEMA analytics TO readonly_user;
```

## 🚀 Optimisations

✅ Indexes sur clés étrangères et dates
✅ Contraintes d'intégrité référentielle
✅ Upserts idempotents (ON CONFLICT)
✅ Star schema optimisé pour agrégations
✅ Vues materialisées possibles pour volumétrie importante

## 📞 Support

### Obtenir de l'aide

```bash
# Voir toutes les vues disponibles
psql -U postgres -d entrepot_supermarche -c \
  "SELECT table_name FROM information_schema.views WHERE table_schema = 'analytics' ORDER BY table_name;"

# Vérifier l'état des données
psql -U postgres -d entrepot_supermarche -c \
  "SELECT * FROM analytics.vw_ventes_par_jour LIMIT 1;"

# Consulter la documentation
cat docs/ARCHITECTURE.md
cat docs/QUICK_COMMANDS.md
```

## 🔄 Maintenance

### Alimenter quotidiennement (Cron)

```bash
# Chaque jour à 2h du matin
0 2 * * * psql -U postgres -d entrepot_supermarche -c "CALL core.sp_alimenter_etoile();"
```

### Sauvegarder la base

```bash
pg_dump -U postgres entrepot_supermarche > backup_$(date +%Y%m%d).sql
```

## 🎓 Concepts Clés

**Star Schema**: Modèle OLAP optimisé pour les requêtes analytiques avec dimensions dénormalisées autour d'une table de faits centralisée.

**Kimball Methodology**: Approche pragmatique du data warehouse orientée métier (bottom-up).

**ETL**: Extract-Transform-Load = Import → Nettoyage → Modèle analytique

**Fact Table**: Table centrale avec mesures quantitatives (montants, quantités, comptages)

**Dimensions**: Contexte des mesures (Qui? Quoi? Quand? Où? Comment?)

## 📂 Prochaines Étapes

1. **Créer une repo dashboard** (séparée) pour Power BI, Grafana, etc.
2. **Configurer Git CI/CD** pour automatiser les migrations
3. **Implémenter un data mart** pour chaque département (ventes, RH, finances)
4. **Archiver les données** après 2-3 ans dans une table historique

## 📅 Historique Versions

| Version | Date | Changements |
|---------|------|------------|
| 1.0 | 2026-07-13 | Structure initiale: 4 migrations, 15 vues, procédures |

---

**Modèle**: Star Schema (Kimball)  
**Base de données**: PostgreSQL 12+  
**Maintenance**: Quotidienne (sp_alimenter_etoile)  
**Utilisateurs**: Analytics Team, BI Team, Dashboards

🚀 **Prêt à commencer?** → Voir [QUICK_COMMANDS.md](./docs/QUICK_COMMANDS.md)

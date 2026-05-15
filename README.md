#  Gold Price Forecasting — SARIMA (Box & Jenkins)

> **Modélisation et prévision du prix mensuel de l'or** via la méthode de Box & Jenkins  
> Série : janvier 2000 – décembre 2011 · 144 observations · USD / once troy

---

##  Contenu du repo

```
├── Code/
│   └── gold_price_sarima.ipynb   # Pipeline complet Python
├── rapport/
│   └── Rapport_Projet_SC.pdf     # Rapport détaillé (10 pages)
├── data/
│   └── GoldPrices.txt          # Série brute (LBMA PM Fix)
└── README.md
```

---

##  Objectif

Appliquer la méthode **Box & Jenkins** de bout en bout sur une série réelle :

1. **Identification** — analyse qualitative, tests de stationnarité, corrélogrammes ACF/PACF
2. **Estimation** — ajustement par maximum de vraisemblance
3. **Validation** — diagnostic des résidus (Ljung-Box, QQ-plot)
4. **Prévision** — 24 mois avec intervalle de confiance à 95 %

---

##  Données

| Paramètre | Valeur |
|---|---|
| Source | USAGOLD / World Gold Council (LBMA PM Fix) |
| Période | Janvier 2000 – Décembre 2011 |
| Fréquence | Mensuelle |
| Observations | 144 |
| Apprentissage | Jan. 2000 – Déc. 2009 (120 obs.) |
| Validation | Jan. 2010 – Déc. 2011 (24 obs.) |

---

##  Méthodologie

### 1. Analyse qualitative
La série présente les trois caractéristiques typiques des **séries airline** :
-  Tendance fortement croissante (×5 en 12 ans)
-  Saisonnalité annuelle (pic automnal : Diwali + Nouvel An chinois)
-  Variance croissante → transformation logarithmique nécessaire

### 2. Stationnarisation

| Transformation | Stat. ADF | p-value | Conclusion |
|---|---|---|---|
| Série originale | 1.157 | 0.996 | Non stationnaire |
| log(série) | 0.264 | 0.976 | Non stationnaire |
| log + d=1 | −2.810 | 0.057 | Non stationnaire |
| **log + d=1 + D=1** | **−5.284** | **0.000** |  **Stationnaire** |

### 3. Identification des ordres

L'analyse ACF/PACF sur 36 lags révèle :
- **ACF** : pic significatif au lag 1 et au lag 12 → composantes MA non saisonnière et saisonnière
- **PACF** : décroissance progressive → structure MA pure

→ **p=0, q=1, P=0, Q=1**

### 4. Comparaison des modèles

| Modèle | AIC | BIC | Log-Vrais. |
|---|---|---|---|
| SARIMA(1,1,1)(1,1,1)₁₂ | −349.87 | −337.21 | 179.94 |
| SARIMA(1,1,0)(0,1,1)₁₂ | −345.12 | −337.49 | 175.56 |
| SARIMA(2,1,2)(1,1,1)₁₂ | −342.14 | −324.48 | 178.07 |
| **SARIMA(0,1,1)(0,1,1)₁₂** | **−341.53** | **−333.93** | **173.76** |

**Modèle retenu : SARIMA(0,1,1)(0,1,1)₁₂** — *modèle airline*

Justification : parcimonie maximale (2 paramètres), cohérence ACF/PACF, BIC compétitif et référence historique de Box & Jenkins.

### 5. Coefficients estimés

| Paramètre | Estimation | Erreur std | p-value |
|---|---|---|---|
| MA(1) — θ₁ | −0.1754 | 0.0677 | 0.010  |
| MA sais. — Θ₁ | −0.9303 | 0.2174 | 0.000  |
| σ² | 0.00126 | 0.0002 | 0.000  |

---

##  Résultats des prévisions

| Métrique | Valeur |
|---|---|
| RMSE | 194.79 |
| MAE | 173.19 |
| **MAPE** | **11.8 %** |
| Biais | +173.19 $ |

>  MAPE de **11,8 %** sur 24 mois — classé **"bon"** selon la grille usuelle (10–20 %)  
>  Biais positif expliqué par l'accélération non linéaire du prix en 2010–2011 (crise dettes souveraines + QE massif), non anticipable par un modèle linéaire.

---

##  Stack technique

![Python](https://img.shields.io/badge/Python-3.10+-3776AB?style=flat&logo=python&logoColor=white)
![R](https://img.shields.io/badge/R-4.x-276DC3?style=flat&logo=r&logoColor=white)
![Jupyter](https://img.shields.io/badge/Jupyter-Notebook-F37626?style=flat&logo=jupyter&logoColor=white)

**Python** : `pandas` · `statsmodels` · `matplotlib` · `scipy`  
**R** : `tseries` · `forecast`

---

##  Lancer le notebook

```bash
git clone https://github.com/Lechguer/time-series-box-jenkins.git
cd time-series-box-jenkins
pip install pandas statsmodels matplotlib scipy
jupyter notebook notebook/gold_price_sarima.ipynb
```

---

##  Rapport

Le rapport complet (10 pages) est disponible dans [`rapport/Rapport_Projet_SC.pdf`](rapport/Rapport_Projet_SC.pdf).

---

##  Auteur

**Zakaria Lechguer** — Data & Software Engineering  
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Zakaria_Lechguer-0A66C2?style=flat&logo=linkedin)](https://www.linkedin.com/in/zakaria-lechguer)
[![GitHub](https://img.shields.io/badge/GitHub-Lechguer-181717?style=flat&logo=github)](https://github.com/Lechguer)

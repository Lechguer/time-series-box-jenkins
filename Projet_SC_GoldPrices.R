# ============================================================================
#  Projet de Séries Chronologiques — Méthode de Box & Jenkins
#  Application à la série Prix mensuel de l'or (USD / once troy), 2000-2011
#
#  Fichier  : Projet_SC_GoldPrices.R
#  Données  : GoldPrices.txt   (colonnes : Month, Price)
#  Modèle   : SARIMA(0,1,1)(0,1,1)[12]
#
#  Packages requis : tseries, forecast, lmtest, ggplot2, scales
#  Installation (une seule fois) :
#    install.packages(c("tseries", "forecast", "lmtest", "ggplot2", "scales"))
# ============================================================================

# ---- 1. Importation des bibliothèques ----
suppressPackageStartupMessages({
  library(tseries)    # adf.test()
  library(forecast)   # Arima(), ggtsdisplay(), accuracy(), checkresiduals()
  library(lmtest)     # coeftest() — significativité des coefficients
  library(ggplot2)
  library(scales)
})

# Style sobre, en accord avec le rapport LaTeX
theme_set(theme_minimal(base_size = 12) +
            theme(panel.grid.minor = element_blank(),
                  plot.title = element_text(face = "bold")))

COLOR_PRIMARY <- "#2C3E50"   # apprentissage
COLOR_ACCENT  <- "#C0392B"   # validation / réel
COLOR_VALID   <- "#27AE60"   # prévision

# ---- 2. Chargement des données ----
df <- read.csv("GoldPrices.txt", stringsAsFactors = FALSE)
df$Month <- as.Date(paste0(df$Month, "-01"))      # YYYY-MM-DD
serie    <- ts(df$Price, start = c(2000, 1), frequency = 12)

cat("Nombre d'observations :", length(serie), "\n")
cat("Période :", format(min(df$Month), "%B %Y"), "—",
    format(max(df$Month), "%B %Y"), "\n")
cat(sprintf("Min : %.2f USD/once  |  Max : %.2f USD/once\n",
            min(serie), max(serie)))

# ---- 3. Découpage apprentissage / validation ----
train <- window(serie, end   = c(2009, 12))   # 120 obs.
test  <- window(serie, start = c(2010,  1))   #  24 obs.
n_test <- length(test)
cat(sprintf("Apprentissage : %d obs.   Validation : %d obs.\n",
            length(train), n_test))

# ---- 4. Représentation graphique ----
df_train <- data.frame(date  = as.Date(time(train)), prix = as.numeric(train),
                       bloc  = "Apprentissage")
df_test  <- data.frame(date  = as.Date(time(test)),  prix = as.numeric(test),
                       bloc  = "Validation")
df_full  <- rbind(df_train, df_test)

p1 <- ggplot(df_full, aes(date, prix, color = bloc)) +
  geom_line(linewidth = 0.7) +
  scale_color_manual(values = c("Apprentissage" = COLOR_PRIMARY,
                                "Validation"    = COLOR_ACCENT)) +
  labs(title = "Prix mensuel de l'or (2000 - 2011)",
       x = "Année", y = "Prix (USD / once)", color = NULL) +
  theme(legend.position = "top")
print(p1)
ggsave("figures/fig1_serie_complete_R.png", p1, width = 10, height = 5, dpi = 150)

# ---- 5. Décomposition multiplicative ----
decomp <- decompose(train, type = "multiplicative")
plot(decomp, col = COLOR_PRIMARY)

# Boxplot mensuel
df_box <- data.frame(mois = factor(cycle(train), levels = 1:12),
                     prix = as.numeric(train))
p_box <- ggplot(df_box, aes(mois, prix)) +
  geom_boxplot(fill = "grey85", color = COLOR_PRIMARY,
               outlier.color = COLOR_ACCENT) +
  labs(title = "Distribution mensuelle des prix de l'or (apprentissage)",
       x = "Mois", y = "Prix (USD / once)")
print(p_box)

# ---- 6. Test de stationnarité (ADF) ----
test_adf_resume <- function(s, nom) {
  r <- suppressWarnings(adf.test(s))
  data.frame(Serie       = nom,
             Stat_ADF    = round(unname(r$statistic), 4),
             p_value     = round(r$p.value, 4),
             Conclusion  = ifelse(r$p.value < 0.05, "Stationnaire", "Non stationnaire"))
}

train_log         <- log(train)
train_log_diff    <- diff(train_log,   lag = 1)
train_log_diff_s  <- diff(train_log_diff, lag = 12)

tab_adf <- rbind(
  test_adf_resume(train,            "Serie originale"),
  test_adf_resume(train_log,        "log(serie)"),
  test_adf_resume(train_log_diff,   "log + diff. d=1"),
  test_adf_resume(train_log_diff_s, "log + diff. d=1 + D=1")
)
print(tab_adf, row.names = FALSE)

# ---- 7. Corrélogrammes ACF / PACF ----
ggtsdisplay(train_log_diff_s, lag.max = 36,
            main = "Série stationnarisée  (log + d=1 + D=1)",
            theme = theme_minimal())

# ---- 8. Sélection et estimation du modèle SARIMA ----
candidats <- list(
  list(order = c(0, 1, 1), seasonal = c(0, 1, 1)),
  list(order = c(1, 1, 0), seasonal = c(0, 1, 1)),
  list(order = c(0, 1, 1), seasonal = c(1, 1, 0)),
  list(order = c(1, 1, 0), seasonal = c(1, 1, 0)),
  list(order = c(1, 1, 1), seasonal = c(1, 1, 1)),
  list(order = c(2, 1, 2), seasonal = c(1, 1, 1))
)

ajuster_un <- function(ord, sais) {
  m <- Arima(train_log, order = ord,
             seasonal = list(order = sais, period = 12),
             method = "ML")
  data.frame(Modele  = sprintf("SARIMA(%d,%d,%d)(%d,%d,%d)[12]",
                               ord[1], ord[2], ord[3],
                               sais[1], sais[2], sais[3]),
             AIC     = round(m$aic, 3),
             BIC     = round(BIC(m), 3),
             logLik  = round(as.numeric(logLik(m)), 3))
}

tab_modeles <- do.call(rbind,
                       lapply(candidats,
                              function(c) ajuster_un(c$order, c$seasonal)))
tab_modeles <- tab_modeles[order(tab_modeles$AIC), ]
print(tab_modeles, row.names = FALSE)

# Modèle final retenu : SARIMA(0,1,1)(0,1,1)[12]
modele_final <- Arima(train_log,
                      order    = c(0, 1, 1),
                      seasonal = list(order = c(0, 1, 1), period = 12),
                      method   = "ML")

cat("\n=== Coefficients estimés ===\n")
print(coeftest(modele_final))

cat(sprintf("\nAIC = %.3f   BIC = %.3f   logLik = %.3f   sigma² = %.6f\n",
            modele_final$aic, BIC(modele_final),
            as.numeric(logLik(modele_final)), modele_final$sigma2))

# ---- 9. Diagnostic des résidus ----
cat("\n=== Test de Ljung-Box ===\n")
lb_12 <- Box.test(residuals(modele_final), lag = 12,
                  type = "Ljung-Box", fitdf = 2)
lb_24 <- Box.test(residuals(modele_final), lag = 24,
                  type = "Ljung-Box", fitdf = 2)
print(lb_12); print(lb_24)

checkresiduals(modele_final)

# ---- 10. Prévision (avec correction de biais log-normale) ----
prev <- forecast(modele_final, h = n_test, level = 95)

# Prévision ponctuelle = exp(mu + sigma²/2)
sigma2_h <- (prev$upper - prev$mean) / qnorm(0.975)   # écart-type prévisionnel
sigma2_h <- sigma2_h^2
prev_moyenne <- exp(prev$mean + 0.5 * sigma2_h)
ic_lo  <- exp(prev$lower)
ic_hi  <- exp(prev$upper)

# Tableau des prévisions
tableau_prev <- data.frame(
  Date       = as.Date(time(test)),
  Reel       = round(as.numeric(test), 2),
  Prevision  = round(as.numeric(prev_moyenne), 2),
  IC95_bas   = round(as.numeric(ic_lo), 2),
  IC95_haut  = round(as.numeric(ic_hi), 2)
)
print(head(tableau_prev, 12), row.names = FALSE)

# Graphique des prévisions
df_prev <- data.frame(
  date     = as.Date(time(test)),
  reel     = as.numeric(test),
  pred     = as.numeric(prev_moyenne),
  ic_lo    = as.numeric(ic_lo),
  ic_hi    = as.numeric(ic_hi)
)

p2 <- ggplot() +
  geom_line(data = df_train, aes(date, prix),
            color = COLOR_PRIMARY, linewidth = 0.6) +
  geom_ribbon(data = df_prev,
              aes(x = date, ymin = ic_lo, ymax = ic_hi),
              fill = COLOR_VALID, alpha = 0.18) +
  geom_line(data = df_prev, aes(date, reel),
            color = COLOR_ACCENT, linewidth = 0.8) +
  geom_line(data = df_prev, aes(date, pred),
            color = COLOR_VALID, linewidth = 0.8, linetype = "dashed") +
  labs(title = "Prévisions du modèle SARIMA(0,1,1)(0,1,1)[12]",
       x = "Année", y = "Prix (USD / once)")
print(p2)
ggsave("figures/fig7_previsions_R.png", p2, width = 10, height = 5, dpi = 150)

# Zoom sur la période de validation
p3 <- ggplot(df_prev, aes(date)) +
  geom_ribbon(aes(ymin = ic_lo, ymax = ic_hi),
              fill = COLOR_VALID, alpha = 0.18) +
  geom_line (aes(y = reel), color = COLOR_ACCENT, linewidth = 0.9) +
  geom_point(aes(y = reel), color = COLOR_ACCENT, size = 1.6) +
  geom_line (aes(y = pred), color = COLOR_VALID, linewidth = 0.9,
             linetype = "dashed") +
  geom_point(aes(y = pred), color = COLOR_VALID, size = 1.6, shape = 15) +
  labs(title = "Zoom : prévisions vs réalité (2010 - 2011)",
       x = "Mois", y = "Prix (USD / once)")
print(p3)

# ---- 11. Évaluation ----
y  <- as.numeric(test)
yh <- as.numeric(prev_moyenne)
err <- y - yh

metriques <- data.frame(
  RMSE                   = round(sqrt(mean(err^2)), 3),
  MAE                    = round(mean(abs(err)),    3),
  `MAPE (%)`             = round(mean(abs(err / y)) * 100, 3),
  `Biais (erreur moy.)`  = round(mean(err), 3),
  check.names = FALSE
)
cat("\n=== Métriques d'évaluation ===\n")
print(metriques, row.names = FALSE)

# ---- Fin du script ----
cat("\nAnalyse terminée. Modèle SARIMA(0,1,1)(0,1,1)[12] validé.\n")

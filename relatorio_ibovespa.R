library(tidyverse)
library(readr)
library(vars)
library(urca)
library(dynlm)
library(aod)

ibovespa_data <- readRDS('ibovespa_data.rds')
taxa_selic <- readRDS('taxa_selic.rds')

#_____________________ibovespa vs selic_________________
dados_combinados <- ibovespa_data %>%
  inner_join(taxa_selic, by = "date") %>%
  arrange(date)

# Calcular retornos logarítmicos do Ibovespa
dados_combinados <- dados_combinados %>%
  mutate(
    retorno_ibov = c(NA, diff(log(preco_ibovespa)) * 100)
  ) %>%
  na.omit()

# 2. Análise Descritiva
sumario_estatistico <- list(
  correlacao = cor.test(dados_combinados$taxa_selic, dados_combinados$retorno_ibov),
  estat_selic = summary(dados_combinados$taxa_selic),
  estat_ibov = summary(dados_combinados$retorno_ibov)
)

# 3. Modelo VAR
dados_ts <- ts(dados_combinados[, c("retorno_ibov", "taxa_selic")], frequency = 12)
modelo_var <- VAR(dados_ts, p = 2)

# Teste de Causalidade de Granger
causalidade <- causality(modelo_var, cause = "taxa_selic")

# Teste de Cointegração de Johansen
johansen_test <- ca.jo(dados_ts, type = "trace", K = 2, ecdet = "const")

# Modelo ARDL
modelo_ardl <- dynlm(retorno_ibov ~ L(retorno_ibov, 1) + L(taxa_selic, 1), data = dados_combinados)

# 4. Resultados e Análises
cat("Teste de Causalidade de Granger:\n")
print(causalidade)
cat("\nTeste de Cointegração de Johansen:\n")
summary(johansen_test)
cat("\nModelo ARDL:\n")
summary(modelo_ardl)

# Gráfico 1: Evolução temporal
g1 <- ggplot(dados_combinados, aes(x = date)) +
  geom_line(aes(y = preco_ibovespa, color = "Ibovespa")) +
  geom_line(aes(y = taxa_selic * mean(preco_ibovespa)/mean(taxa_selic), 
                color = "Selic (Escala Ajustada)")) +
  scale_y_continuous(
    name = "Ibovespa",
    sec.axis = sec_axis(~. * mean(dados_combinados$taxa_selic)/
                          mean(dados_combinados$preco_ibovespa), 
                        name = "Taxa Selic (%)")) +
  theme_minimal() +
  labs(title = "Evolução: Ibovespa vs Taxa Selic",
       color = "Série") +
  theme(legend.position = "bottom")

# Estatísticas Móveis
dados_combinados <- dados_combinados %>%
  arrange(date) %>%
  mutate(
    corr_movel = rollapply(
      data = cbind(retorno_ibov, taxa_selic),
      width = 12,
      FUN = function(x) cor(x[,1], x[,2]),
      by.column = FALSE,
      fill = NA
    )
  )

# Gráfico 4: Correlação Móvel
g4 <- ggplot(dados_combinados, aes(x = date, y = corr_movel)) +
  geom_line(color = "darkgreen") +
  theme_minimal() +
  labs(title = "Correlação Móvel entre Selic e Retornos",
       y = "Correlação")




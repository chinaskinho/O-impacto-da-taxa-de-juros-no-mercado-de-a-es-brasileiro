library(readr)

analisar_selic_acoes <- function(df_selic, df_acoes) {
  library(tidyverse)
  library(lubridate)
  library(stats)
  library(ggplot2)
  
  # 1. Preparação dos dados
  # Combinar os dataframes
  dados_combinados <- df_acoes %>%
    pivot_wider(names_from = ticker, values_from = preco_ajustado) %>%
    inner_join(df_selic, by = "date") %>%
    arrange(date)
  
  # Calcular retornos logarítmicos das ações
  dados_combinados <- dados_combinados %>%
    mutate(
      retorno_acao1 = c(NA, diff(log(`MGLU3.SA`))),
      retorno_acao2 = c(NA, diff(log(`ABEV3.SA`))), 
      retorno_acao3 = c(NA, diff(log(`BHIA3.SA`))),
      retorno_selic = c(NA, diff(log(taxa_selic)))
    ) %>%
    na.omit()
  
  # 2. Análises Simples
  
  # Correlação de Pearson
  corr_acao1 <- cor.test(dados_combinados$retorno_acao1, dados_combinados$retorno_selic)
  corr_acao2 <- cor.test(dados_combinados$retorno_acao2, dados_combinados$retorno_selic)
  corr_acao3 <- cor.test(dados_combinados$retorno_acao3, dados_combinados$retorno_selic)
  
  # Coeficiente de Determinação
  r2_acao1 <- summary(lm(retorno_acao1 ~ retorno_selic, data = dados_combinados))$r.squared
  r2_acao2 <- summary(lm(retorno_acao2 ~ retorno_selic, data = dados_combinados))$r.squared
  r2_acao3 <- summary(lm(retorno_acao3 ~ retorno_selic, data = dados_combinados))$r.squared
  
  # Teste de Hipótese
  hipotese_acao1 <- summary(lm(retorno_acao1 ~ retorno_selic, data = dados_combinados))
  hipotese_acao2 <- summary(lm(retorno_acao2 ~ retorno_selic, data = dados_combinados))
  hipotese_acao3 <- summary(lm(retorno_acao3 ~ retorno_selic, data = dados_combinados))
  
  # 3. Visualização
  g1 <- ggplot(dados_combinados, aes(x = retorno_selic)) +
    geom_point(aes(y = retorno_acao1, color = "MGLU3"), alpha = 0.5) +
    geom_point(aes(y = retorno_acao2, color = "ABEV3"), alpha = 0.5) +
    geom_point(aes(y = retorno_acao3, color = "BHIA3"), alpha = 0.5) +
    geom_smooth(aes(y = retorno_acao1, color = "MGLU3"), method = "lm") +
    geom_smooth(aes(y = retorno_acao2, color = "ABEV3"), method = "lm") +
    geom_smooth(aes(y = retorno_acao3, color = "BHIA3"), method = "lm") +
    theme_minimal() +
    labs(title = "Relação entre Taxa Selic e Retornos das Ações",
         x = "Retorno da Taxa Selic (%)",
         y = "Retorno da Ação (%)", 
         color = "Série")
  
  # 4. Resultados
  return(list(
    dados = dados_combinados,
    correlacao = list(
      acao1 = corr_acao1,
      acao2 = corr_acao2, 
      acao3 = corr_acao3
    ),
    r2 = list(
      acao1 = r2_acao1,
      acao2 = r2_acao2,
      acao3 = r2_acao3
    ),
    hipotese = list(
      acao1 = hipotese_acao1,
      acao2 = hipotese_acao2,
      acao3 = hipotese_acao3
    ),
    grafico = g1
  ))
}


dados_acoes_bancos <- readRDS('dados_acoes_bancos.rds')
dados_acoes_consumo <- readRDS('dados_acoes_consumo.rds')
taxa_selic <- readRDS('taxa_selic.rds')
analise_consumo <- analisar_selic_acoes(taxa_selic, dados_acoes_consumo)
saveRDS(analise_consumo, file = 'analise_consumo.rds')

print(analise_consumo$grafico)


dados <- readRDS('analise_consumo.rds')

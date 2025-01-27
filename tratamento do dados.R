library(yfR)
library(quantmod)
library(rbcb)
library(dplyr)
library(readr)
library(tidyverse)
library(zoo)

#taxa selic
taxa_selic <- get_series(432, start_date = '2010-01-01' , end_date = Sys.Date())
colnames(taxa_selic) <- c("date", "taxa_selic")
#convertendo a selic para mensal
taxa_selic <- taxa_selic %>%
  mutate(year_month = floor_date(date, "month")) %>%
  group_by(year_month) %>%
  summarize(taxa_selic = mean(taxa_selic, na.rm = TRUE)) %>%
  rename(date = year_month)

#----------------------------ações brasileiras----------------------------------------------------------

            
# Defindo os tickers e o período de análise
tickers_bancos <- c("ITUB3.SA", "BBDC3.SA", "BBAS3.SA")
tickers_var_cons <- c( "MGLU3.SA", "ABEV3.SA", "BHIA3.SA")
start_date <- "2010-01-01"
end_date <- Sys.Date()

# Função para coletar dados de um ticker, com tratamento de erros e dados insuficientes
coletar_dados_acao <- function(ticker) {
  # Tenta coletar os dados e captura possíveis erros
  dados <- tryCatch({
    yf_get(
      tickers = ticker,
      first_date = start_date,
      last_date = end_date,
      freq_data = "monthly",
      how_to_aggregate = "last",
      thresh_bad_data = 0.5
    )
  }, error = function(e) {
    message("Erro ao coletar dados para o ticker:", ticker)
    return(NULL)
  })
  
  # Verifica se os dados foram coletados com sucesso e formata
  if (!is.null(dados) && nrow(dados) > 0) {
    dados <- dados %>%
      select(date = ref_date, preco_ajustado = price_adjusted) %>%
      mutate(ticker = ticker)
  } else {
    message("Dados insuficientes para o ticker:", ticker)
    dados <- data.frame(ticker = ticker, stringsAsFactors = FALSE)  # Data frame vazio
  }
  return(dados)
}

# Coleta os dados para todos os tickers e armazena em uma lista
dados_acoesbanc <- lapply(tickers_bancos, coletar_dados_acao)
dados_acoescons <- lapply(tickers_var_cons, coletar_dados_acao)

# Combina os data frames em um único objeto
dados_acoesbanc <- do.call(rbind, dados_acoesbanc)
dados_acoescons <- do.call(rbind, dados_acoescons)







#ibovespa
ticker_bvsp <- "^BVSP"
ibovespa_data <- yf_get(
  tickers = ticker_bvsp,
  first_date = start_date,
  last_date = end_date,
  freq_data = "monthly",
  how_to_aggregate = "last",
  thresh_bad_data = 0.5
) %>%
  select(date = ref_date, preco_ibovespa = price_adjusted)

#juntando tudo
dados_completos <- dados_combinados %>%
  left_join(taxa_selic, by = "date") %>%
  left_join(ibovespa_data, by = "date")

#salvando .rds
saveRDS(ibovespa_data, file = "ibovespa_data.rds")


library(arrow)
library(duckdb)
library(dplyr)
library(odbc)

# Ejemplo función deduplicar ----------------------------------------------

# Leer los datos
data <- read_parquet("ejemplo_rc.parquet")

# Convertirlos a formato Arrow
data <- as_arrow_table(data)

# Crear conexión DB
con <- dbConnect(duckdb::duckdb(), dbdir = "rep.db", read_only = FALSE)

# Registrar el objeto Arrow como una tabla virtual 
arrow::to_duckdb(data, table_name = "rc_deduplicated_by_run", con = con)

# Crear la tabla DuckDb de la tabla virtual anterior
dbSendQuery(con, "CREATE TABLE rc_deduplicated_by_run AS SELECT * FROM rc_deduplicated_by_run")

# Elimnar data en formato Arrow
rm(data)

# Traer los datos en formato DuckDB
data <- tbl(con, "rc_deduplicated_by_run")

print("Deduplicar...")

data <- data %>% 
  group_by(nombre_paste_rc, fecha_nac_rc) %>% 
  slice_max(run_dv) %>% 
  ungroup() %>% 
  compute()

# Re-convertir a Arrow
data <- data %>% to_arrow()
data <- data %>% as_arrow_table()

# Descontectar
dbDisconnect(con, shutdown = TRUE)

file.remove("rep.db")

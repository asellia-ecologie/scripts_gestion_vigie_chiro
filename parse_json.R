library(jsonlite)
library(RPostgreSQL)

# Renseigner l’emplacement du json à ouvrir :
tvb <- read_json("/home/bbk9/Documents/asellia/donnees_carafe/TVB_CCSP_deltas_d335d013-ac3a-41e9-97c5-7303351a5003.json")

# Si cred.R se trouve à côté du script, il n’y a normalement rien à modifier :
cred_bdd <- "cred.R"

source(file.path(cred))
tryCatch(
  {
    drv <- dbDriver("PostgreSQL")
    print("Connecting to Database…")
    connec <- dbConnect(drv,
      dbname = dbname,
      host = host,
      port = port,
      user = user,
      password = password
    )
    print("Database Connected!")
  },
  error = function(cond) {
    print("Unable to connect to Database.")
  }
)


# json is the file as opened with jsonlite
# schema and table are the schema and table you want to update in your pg
# database
update_pg_from_json <- function(json, schema, table) {
  sql_pk <- paste0(
    "SELECT c.column_name
     FROM information_schema.key_column_usage AS c
     LEFT JOIN information_schema.table_constraints AS t
     ON t.constraint_name = c.constraint_name
     WHERE t.table_name = '",
    table,
    "' AND t.constraint_type = 'PRIMARY KEY';"
  )
  colonne_pk <- dbGetQuery(
    connec, sql_pk
  )

  for (i in 1:length(json$deltas)) {
    # print(tvb$deltas[[i]]$sourceLayerId)
    # stations <- append(stations, json$deltas[[i]]$Pk)
    split <- strsplit(json$deltas[[i]]$sourceLayerId, "_")
    longueur <- length(unlist(split))
    longueur <- longueur - 5
    # my database table names are writen with "_" separated words
    # so I need to glue the name back together
    table_in <- paste(unlist(split)[1:longueur], collapse = "_")
    if (table_in == table) {
      id <- json$deltas[[i]]$sourcePk
      variables <- names(json$deltas[[i]]$new$attributes)
      dictionnaire <- list()
      for (ii in 1:length(variables)) {
        dictionnaire <- append(
          dictionnaire,
          paste0(
            variables[ii],
            " = '",
            json$deltas[[i]]$new$attributes[variables[ii]], "'"
          )
        )
      }
      if (exists("json$deltas[[i]]$new$geometry")) {
        dictionnaire <- append(
          dictionnaire,
          paste0("geom = st_force2d('", json$deltas[[i]]$new$geometry, "')")
        )
      }

      sql_update <- paste0(
        "update ", schema, ".", table, " set ",
        print(paste(unlist(dictionnaire), collapse = ", ")), " where ", colonne_pk,
        " = '", id, "';"
      )
      print(paste("update : ", i))
      dbGetQuery(connec, sql_update)
    }
  }
}


update_from_json(tvb, "bd_biodiv", "stations_ccsp")

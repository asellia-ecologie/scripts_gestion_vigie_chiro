library(jsonlite)
library(RPostgreSQL)

# Location of your delta.json :
tvb <- read_json("/home/bbk9/Documents/asellia/donnees_carafe/TVB_CCSP_deltas_d335d013-ac3a-41e9-97c5-7303351a5003.json")

# We put our connection variables (dbname, host, port, user, password) in a
# cred.R file next to our script, adapt to your liking

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

# Function update_pg_from_json
# --------
# parses qfield cloud delta json and updates postgresql related table
# multiple table data are stored in the json file, the parameters permits
#  to choose which one we want to update
#  no information is present in the qfield record as to the time the data was
# produced, if multiple modifications occur on the same table, only the last
# will be visible. It is up to you to clean the json file before using the
# function
#  
# Parameters
# --------
# json :
#  jsonlite open object
# schema :
#  name of postgresql schema you want to update to
# table :
#   name of postgresql table you want to update to

# Returns
#  --------
#  nothing :
#  updates PG database
#
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
          # our geom column is point, not pointz, remove st_force2d() if you
          # want to record pointz geometries
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

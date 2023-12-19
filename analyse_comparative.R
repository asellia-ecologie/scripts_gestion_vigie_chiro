library("tidyverse")
library("RPostgreSQL")
library("sf")
library("writexl")
library("readxl")
library("xlsx")
library(data.table)
library(sjmisc)
# rm(list=ls())
# tadten / toutes années / au contact

# Dans le terminal (terminal anaconda sur windows)
# À exécuter à la racine du dossier où se trouvent FAIT et csv :
# xlsx2csv -d ";" -s 1 2023/FAIT ANALYSES/csv
# On situe l’espace de travail où se trouvent les dossiers
# (à modifier selon son ordi)
dossier <- "/home/bbk9/kDrive/Shared/BDD/SONS"
setwd(dossier)


# indication du dossier où trouver les sons a traiter
d <- "ANALYSES/csv"
chemin_csv <- file.path(dossier, d)
# et les scripts (pour faire appel à d’autres)
dos_scripts <- "00_SCRIPTS"
# Création d’une liste des fichiers csv
fichiers_csv <- list.files(chemin_csv,
  pattern = "*.csv", full.names = TRUE
)

fichiers_a_faire_csv <- list.files(paste0(chemin_csv, "/a_faire"),
  pattern = "*.csv", full.names = TRUE
)

# Choix des colonnes que l’on veut garder des compils tadarida :
colonnes <- c(
  "Nom", "nom_du_fichier", "Type", "temps_debut", "temps_fin",
  "frequence_mediane", "tadarida_taxon", "tadarida_probabilite",
  "observateur_taxon",
  "observateur_probabilite", "validateur_taxon",
  "validateur_probabilite"
)

add_filename <- function(x) {
  df <- fread(x, sep = ";", select = colonnes)
  transform(df, tag = tools::file_path_sans_ext(x))
}

# ouverture des csv et chargement dans la liste 'tables' :
tables_compils <- lapply(fichiers_csv, add_filename)
tables_compils_a_faire <- lapply(fichiers_a_faire_csv, add_filename)

for (i in seq_along(tables_compils)) {
  if (nrow(tables_compils[[i]]) <= 1) {
    print(fichiers_csv[i])
  }
}

for (i in seq_along(tables_compils_a_faire)) {
  if (nrow(tables_compils_a_faire[[i]]) == 0) {
    print(fichiers_a_faire_csv[i])
  }
}

col <- colonnes[-2]
tables_compils <- lapply(tables_compils, setNames, col)
tables_compils_a_faire <- lapply(tables_compils, setNames, col)
# mise bout à bout de toutes les tables
sons <- do.call(rbind, tables_compils)
sons_a_faire <- do.call(rbind, tables_compils_a_faire)
sons <- rbind(sons, sons_a_faire)

rm(tables_compils, tables_compils_a_faire, sons_a_faire)
# Si on veut enregistrer la compil dans un gros csv :
write.csv2(sons, "tadarida_2014_2023.csv")
write.csv2(sons_asellia, "tadarida_tadten_2014_2022.csv")
# Si on a enregistré la compil et qu’on veut l’ouvrir :
sons <- read.csv2("tadarida_2014_2023.csv")

# Ne garder que les lignes analysées :
sons_asellia <- sons %>% filter(!is.na(observateur_taxon))

# Virer les cellules observateur_taxon vide :
sons_asellia <- sons_asellia %>% filter(observateur_taxon != "")
# sons_asellia <- sons %>% filter(tadarida_taxon == "Tadten")
# unique(sons_asellia$observateur_taxon)

sons_asellia <- sons_asellia %>% select(-compil_orig)
sons_asellia <- unique(sons_asellia)

# Chercher où se trouvent les valeurs chelous
sons_asellia[sons_asellia$observateur_taxon == "Lusmeg"]

rm(sons)
# Ne prendre que les sons supérieurs à 0.5 de proba :
sons_asellia$tadarida_probabilite <- str_replace(
  sons_asellia$tadarida_probabilite, ",", "."
)
sons_asellia$tadarida_probabilite <- as.numeric(
  sons_asellia$tadarida_probabilite
)
sons_asellia$simi <- ifelse(
  sons_asellia$observateur_taxon ==
    sons_asellia$tadarida_taxon,
  TRUE, FALSE
)
# sons_asellia$Nom
# unique(str_split_i(sons_asellia$Nom, "_", 1))
# unique(str_split_i(sons_asellia$Nom, "_", 2))

# unique(str_split_i(sons_asellia$Nom, "_", 3))
# On liste les valeurs uniques de obs_tax pour voir si tout est ok :
unique(sons_asellia$observateur_taxon)

# Et si on trouve une valeur étrange on va la chercher :
sons_asellia %>% filter(observateur_taxon == "Possible")
# Certaines lignes sont à 0 pour le taxon (+ faible proba tadarida)
sons_0 <- sons_asellia %>% filter(observateur_taxon == "0")
unique(sons_0$compil_orig)

sons_asellia <- sons_asellia %>% filter(observateur_taxon != "0")
# Correction de observateur_taxon sous la forme
# Majmin
sons_asellia$observateur_taxon <- str_to_title( # met en Maj
  tolower( # ce qui a été mis en min
    sons_asellia$observateur_taxon
  )
)


# Régler pb de certains sons SW5
sons_asellia$Nom <- str_replace(sons_asellia$Nom, "_00000_", "_")

# Création des colonnes issues du nom de fichier :
sons_asellia$nom_point <- str_split_i(sons_asellia$Nom, "_", 2)

unique(sons_asellia$nom_point)
sons_asellia <- sons_asellia %>% filter(nom_point != "du")
sons_asellia <- sons_asellia %>% filter(nom_point != "20230331")
sons_asellia <- sons_asellia %>% filter(nom_point != "20230401")

# Vérifier qu’une placette se trouve dans la compil
# sons_asellia %>% filter(nom_point %like% 'Mong%')

sons_asellia$lieu_dit <- str_split_i(sons_asellia$Nom, "_", 3)
unique(sons_asellia$lieu_dit)

# Enlever les sons SW5 sans préfixe
sons_asellia <- sons_asellia %>% filter(!str_like(Nom, "SW5%"))

sons_asellia$boitier <- str_split_i(
  str_split_i(
    sons_asellia$Nom, "_", 1
  ), "-", -1
)

# test :

sons_asellia$boitier <- str_split_i(
  sons_asellia$Nom, "_", -4
)

sons_asellia %>% filter(boitier == "PlanMilieu")
unique(sons_asellia$boitier)

sons_asellia %>% filter(boitier == "Car040863")
sons_asellia %>% filter(boitier == "StJou01")

sons_asellia$date_heure <- ymd_hms(
  paste(
    str_split_i(sons_asellia$Nom, "_", -3),
    str_split_i(sons_asellia$Nom, "_", -2)
  )
)
# unique(sons_asellia$nom_point)
unique(sons_asellia$lieu_dit)
unique(sons_asellia$date_heure)

sons_asellia %>% filter(is.na(date_heure))
sons_asellia <- sons_asellia %>% filter(!is.na(date_heure))
# Ajout du champ heure_stats pour représenter les activités horaires :
# Attention ! Tout est à la même date ne pas utiliser ailleurs.
sons_asellia$heure_stats <- ymd_hms(
  paste(
    "20000101",
    str_split_i(sons_asellia$Nom, "_", -2)
  )
)


# Remplissage conditionnel du champ date_nuit :
sons_asellia$date_nuit <- dplyr::if_else(
  between(hour(sons_asellia$date_heure), 12, 23), # si entre midi-minuit
  format(date(sons_asellia$date_heure), # on garde la date
    format = "%Y-%m-%d"
  ),
  format(date(sons_asellia$date_heure - days(1)), # sinon on prend
    format = "%Y-%m-%d"
  )
) # la veille

# Deux manières de calculer les fréquences de similitudes
# (tadarda/observateur) par taxon :
sons_asellia %>%
  group_by(observateur_taxon) %>%
  frq(simi)
flat_table(sons_asellia, observateur_taxon, simi)

# La ligne suivante va chercher les identifiants
# pour se connecter à la bdd_placettes_2023 :
source(file.path(dossier, dos_scripts, "cred.R"))

# Puis on établit la connexion :
tryCatch(
  {
    drv <- dbDriver("PostgreSQL")
    print("Connecting to Database...")
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

# Requete pour récupérer la bdd_placettes_2023 en entier :
query_totale <- paste(
  "select geom, nombre_de_nuits,date, nom_point, obs1,
                      \"lieu-dit\", type_habitat",
  "from bd_sons.bdd_placettes_2023"
)

# Exécution de la requete et stockage dans un tableau géolocalisé :
placettes <- st_read(connec,
  query = query_totale, quiet = TRUE
)

# Pour gérer l’intervale dans la jointure :
sons_asellia$date_nuit <- as.Date(sons_asellia$date_nuit)
placettes$nombre_de_nuits <- as.integer(placettes$nombre_de_nuits)

# Mise à 1 si le nombre de nuits n’a pas été renseigné :
placettes$nombre_de_nuits[is.na(placettes$nombre_de_nuits)] <- 1

# calcul de la dernière nuit de pose du boitier si plusieurs nuits :
placettes$date_max <- placettes$date + days(placettes$nombre_de_nuits - 1)

# création de la jointure entre le nom_point et l’intervale de date :
by <- join_by(
  nom_point,
  between(x$date_nuit, y$date, y$date_max)
)
by2 <- join_by(nom_point, x$lieu_dit == y$"lieu-dit")

# Nettoyage (à éviter) si des date_nuit manquent la jointure sera impossible :
sons_asellia <- sons_asellia %>% filter(!is.na(date_nuit))

sons_asellia <- unique(sons_asellia)
# jointure entre les sons et la bdd placettes
data_loc <- left_join(sons_asellia, placettes,
  by2,
  multiple = "first"
)

perdus <- data_loc %>% filter(is.na(id))
unique(perdus$nom_point)
perdus %>% group_by(nom_point, date_nuit)
unique(paste(perdus$nom_point, perdus$date_nuit))
class(data_loc)
data_loc <- st_as_sf(data_loc)
data_inpn <- data_loc %>%
  group_by(
    nom_point, date_nuit, observateur_taxon,
    obs1, type_habitat
  ) %>%
  summarise(nombre = n())

data_inpn <- st_as_sf(data_inpn)
data_inpn <- data_inpn %>% st_cast("POINT")
data_inpn$x_wgs84 <- st_coordinates(test)[, 1]
data_inpn$y_wgs84 <- st_coordinates(test)[, 2]
write.csv2(data_inpn, "export_inpn.csv")
plot(data_loc)
class(data_inpn)
# placettes %>% filter(nom_point == "Maza36")
placettes %>% filter(is.na(nom_point))
class(placettes)
placettessansna <- placettes %>% filter(!is.na(nom_point))
data_tadten <- data_inpn %>% filter(observateur_taxon == "Tadten")
data_barbar <- data_inpn %>% filter(observateur_taxon == "Barbar")
data_nyclas <- data_inpn %>% filter(observateur_taxon == "Nyclas")
data_loc_no_autre <- data_loc[, -"tadarida_taxon_autre"]
unique(data_loc$observateur_probabilite)
st_write(data_barbar, "barbar_20230625.shp",
  driver = "ESRI Shapefile", append = FALSE
)
st_write(data_tadten, "tadten_20230625.shp",
  driver = "ESRI Shapefile", append = FALSE
)
st_write(data_loc, "bdd_sons_nyclas_2014_2023.gpkg",
  driver = "GPKG", append = FALSE
)
st_write(data_loc, "bdd_sons_tadten_2014_2023_tadarida_taxon.gpkg",
  driver = "GPKG", append = FALSE
)

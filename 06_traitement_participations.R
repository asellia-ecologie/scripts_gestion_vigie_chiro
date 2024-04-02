library("tidyverse")
library("RPostgreSQL")
library("sf")
library("writexl")
library("readxl")
# On situe l’espace de travail où se trouve le script

dossier <- "/home/asellia_pc_chiro/Bureau/GESTION_SONS/03_TRAITEMENT_PARTICIPATIONS"
setwd(dossier)
# Il faut qu’il soit dans SCRIPTS à-côté de PARTICIPATIONS, A_FAIRE, FAIT
dos_parti <- "PARTICIPATIONS"
dos_scripts <- "/home/asellia_pc_chiro/Bureau/GESTION_SONS/00_SCRIPTS/scripts_gestion_vigie_chiro"
dos_compils <- "COMPILS"

# Création du chemin vers les participations :
chemin_parti <- file.path(dossier, dos_parti)

# Liste des participations csv :
participations <- list.files(chemin_parti, pattern = "*.csv", full.names = TRUE)

# On va chercher les identifiants de la bdd dans cred.R :
source(file.path(dos_scripts, "cred.R"))
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


for (parti in participations) { # Pour chaque participation :
  print(parti)
  fichier <- parti

  participation <-
    read.csv(fichier, sep = ";") # on ouvre le fichier
  especes <- read.csv("ref_vigie.csv", sep = ";") # et la liste des esp.
  # especes_ortho <- read.csv("ref_vigie_ortho.csv", sep = ";") # liste des esp. à
  # intégrer

  format(date(participation$Date_Heure), format = "%d/%m/%Y")
  # Création de la colonne date_heure à partir du nom du fichier
  participation$Date_Heure <- ymd_hms(
    paste(
      str_split_i(
        participation$nom.du.fichier,
        "_", -3
      ),
      str_split_i(
        participation$nom.du.fichier,
        "_", -2
      )
    )
  )
  # Calcul de la nuit concernée :
  participation$Date_Nuit <-
    dplyr::if_else(
      between(hour(participation$Date_Heure), 12, 23),
      format(date(participation$Date_Heure),
        format = "%d/%m/%Y"
      ),
      format(date(participation$Date_Heure - days(1)),
        format = "%d/%m/%Y"
      )
    )

  # Distinction des chiros/autres dans type
  participation$Type <- dplyr::if_else(participation$tadarida_taxon %in%
    especes$espece, "Chiro", NA)
  participation$Type <- dplyr::if_else(participation$tadarida_taxon ==
    "noise" & is.na(participation$Type), "Noise", "Autre")
  # Création de la colonne 'Point'
  participation$Point <- str_split_i(participation$nom.du.fichier, "_", 2)

  # Création de la colonne 'Site'
  participation$Site <- str_split_i(participation$nom.du.fichier, "_", 3)
  # detecteur
  participation$Detecteur <- str_split_i(participation$nom.du.fichier, "_", -4)
  # Récupération des valeurs uniques de boitier, point et date_nuit
  boitier <- unique(participation$Boitier)
  point <- unique(participation$Point)
  date_nuit <- fast_strptime(unique(participation$Date_Nuit), "%d/%m/%Y")
  date_nuit <- as.Date(date_nuit)
  print(boitier)
  print(date_nuit)
  # on va récupérer l’étude de la participation dans la bdd

  etude <- dbGetQuery(
    connec,
    paste0(
      "select etude from bd_sons.bdd_placettes
                              where nom_point = \'", point, "'
                              and \"date\" =\'",
      date_nuit, "\'"
    )
  )
  etude
  # on en fait un tableau
  participation <- as_tibble(participation)
  # renommage de colonne
  participation$nom_du_fichier <- participation$nom.du.fichier
  participation$identificateur <- NA
  # ordre des colonnes qui nous convient
  ordre_colonnes <- c(
    "nom_du_fichier", "Date_Nuit", "Type", "temps_debut",
    "temps_fin", "frequence_mediane", "tadarida_taxon",
    "tadarida_probabilite", "tadarida_taxon_autre",
    "observateur_taxon", "observateur_probabilite", "identificateur",
    "validateur_taxon", "validateur_probabilite", "Point",
    "Site", "Detecteur", "Date_Heure"
  )
  participation <- participation[, ordre_colonnes]
  class(participation)
  # Note pour lire les xlsx c’est pas le numero de feuille qui compte mais son
  # ordre dans les onglets
  # NB : penser à vérifier dans le script que "Feuil1" contient les données brutes

  # on écrut le fichier dans un xlsx par étude (ouverture et ajout s’il existe, création sinon)
  if (file.exists(paste0(
    dos_compils, "/compilation_", unique(year(date_nuit)),
    "_", etude, ".xlsx"
  ))) {
    a <- read_excel(paste0(
      dos_compils, "/compilation_", unique(year(date_nuit)),
      "_", etude, ".xlsx"
    ))
    p <- rbind(a, participation)
    write_xlsx(p, paste0(
      dos_compils, "/compilation_",
      unique(year(date_nuit)), "_", etude, ".xlsx"
    ))
  } else {
    write_xlsx(participation, paste0(
      dos_compils, "/compilation_",
      unique(year(date_nuit)),
      "_", etude, ".xlsx"
    ))
  }
}

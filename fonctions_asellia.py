"""
Ensemble de fonctions nécessaires  à l’utilisation de 01_gestion_sons.Rmd
"""
import os
import subprocess
from psycopg2 import sql


def updateStatus(cursor, colonne, site, date):
    """
    Updates column ("colonne") in PostgreSQL to "ok"

    Parameters
    --------
    cursor : contextlib connection.cursor
    colonne : str
        Column name in table must be in : renomme, extrait, vigie, analyse
    site : str
        Name of site from Asellia’s bdd_placettes
    date : str
        Text formated date like : "19/02/2023"

    Returns
    --------
    None
    """
    date_split = date.split('/')
    date = date_split[2] + '-' + date_split[1] + '-' + date_split[0]
    sqlUpdateStatus = sql.SQL(''' update bd_sons.bdd_placettes
    set {} = 'ok'
    where nom_point = %s
    and "date" = %s;
    ''').format(sql.Identifier(colonne))
    cursor.execute(sqlUpdateStatus, [site, date])


def get_placette_count(cursor, boitier, date):
    """
    Fonction pour faire la correspondance entre les boitiers et les nuits
    dans la bdd placettes :

    Parameters
    --------
    cursor : contextlib connection.cursor
    boitier : str
        Code boitier enregistreur Asellia : SM1, SM2, SW5...
    date : str
        Date au format "annee-mois-jour" ex : 2023-10-02

    Returns
    --------
    results : int
        nombre de placettes correspondantes dans la bdd_placettes asellia
    """
    query = '''SELECT count(distinct(id)) FROM bd_sons.bdd_placettes
    WHERE num_sm2 = %s
    and %s::date - "date" between 0 and (nombre_de_nuits - 1);'''
    cursor.execute(query, [boitier, date])
    results = cursor.fetchone()
    return results[0] if results else ''


def get_nuit_count(cursor, placette, date):
    """
    Fonction pour faire la correspondance entre les boitiers et les nuits
    dans la bdd placettes :

    Parameters
    --------
    cursor : contextlib connection.cursor
    placette : str
        numéro placette Asellia
    date : str
        Date au format "annee-mois-jour" ex : 2023-10-02

    Returns
    --------
    results : int
        nombre de placettes correspondantes dans la bdd_placettes asellia
    """
    query = '''SELECT count(distinct(id)) FROM bd_sons.bdd_placettes
    WHERE nom_point = %s
    and %s::date - "date" between 0 and (nombre_de_nuits - 1);'''
    cursor.execute(query, [placette, date])
    results = cursor.fetchone()
    return results[0] if results else ''


def nettoyageDossier(dossier):
    """
    Supprime les dossiers vides dans l’arborescence descendante de "dossier"

    Parameters
    --------
    dossier : str
        Nom du dossier dont on veut nettoyer l’arborescence

    Returns
    --------
    None
    """
    for subdir, dirs, files in os.walk(dossier):
        if len(dirs) == 0 and len(files) == 0 and subdir != dossier:
            os.rmdir(subdir)
            print(subdir)


def get_ligne(cursor, boitier, date):
    """
    Récupère les informations de la bdd_placettes pour le boitier à la date
    voulue afin de remplir un fichier csv à alimenter dans le script
    find_points.R (Y Bas, MNHN;fj eq)

    Parameters
    --------
    cursor : contextlib connection.cursor
    boitier : str
    date : str

    Returns
    --------
    results : list
    """
    query = """
        select split_part(obs1, ' ',2) as FirstName,
        split_part(obs1, ' ',1) as FamilyName,
        'asellia.ecologie@gmail.com' as Email,
        'Asellia Écologie' as Affiliation, 'France' as Country,
        nom_point as Site, st_x(geom) as X, st_y(geom) as Y,
        'Pass'||passage as Participation,
        to_char("date",'DD/MM/YYYY') as StartDate,
        to_char("date" + interval '1 day' * nombre_de_nuits, 'DD/MM/YYYY') as
        EndDate, 1 as TypeStudy, hauteur_micro as MicHeight,
        case
        when num_sm2 in ('SM1', 'SM2', 'SM3', 'SM4') then 18
        when num_sm2 like 'SM%%' then 20
        when num_sm2 in ('SW5', '622741', '622782', '622801', '622816', '633084', '633090', '636629', '657392', '657396', '657404', '660610', '657418', '668998') then 2
        else 14
        end as Recorder,
        'NA' as Mic, 999 as GainRecorder, 0 as HPF, 2 as FreqMin,
        999 as FreqMax, 12 as TriggerLevel, 999 as MinDur, 999 as MaxDur,
        2 as TrigWin, 0 as Pause, 600 as TrigWinMax, 5 as FileSplittingLength,
        'no' as NoiseFilter, '' as Comment
    from bd_sons.bdd_placettes t1
    where num_sm2 = %s
    and %s::date - "date" between 0 and (nombre_de_nuits - 1);"""
    cursor.execute(query, [boitier, date])
    results = cursor.fetchone()
    print(results)
    return results if results else ''


def get_ligne_placette(cursor, placette, date):
    """
    Récupère les informations de la bdd_placette pour le boitier à la date
    voulue afin de remplir un fichier csv à alimenter dans le script
    find_points.R (Y Bas, MNHN)

    Parameters
    --------
    cursor : contextlib connection.cursor
    placette : str
    date : str

    Returns
    --------
    results : list
    """
    query = """
        select split_part(obs1, ' ',2) as FirstName,
        split_part(obs1, ' ',1) as FamilyName,
        'asellia.ecologie@gmail.com' as Email,
        'Asellia Écologie' as Affiliation, 'France' as Country,
        nom_point as Site, st_x(geom) as X, st_y(geom) as Y,
        'Pass'||passage as Participation,
        to_char("date",'DD/MM/YYYY') as StartDate,
        to_char("date" + interval '1 day' * nombre_de_nuits, 'DD/MM/YYYY') as
        EndDate, 1 as TypeStudy, hauteur_micro as MicHeight,
        case
        when num_sm2 in ('SM1', 'SM2', 'SM3', 'SM4') then 18
        when num_sm2 like 'SM%%' then 20
        when num_sm2 in ('SW5', '622741', '622782', '622801', '622816', '633084', '633090', '636629', '657392', '657396', '657404', '660610', '657418', '668998') then 2
        else 14
        end as Recorder,
        'NA' as Mic, 999 as GainRecorder, 0 as HPF, 2 as FreqMin,
        999 as FreqMax, 12 as TriggerLevel, 999 as MinDur, 999 as MaxDur,
        2 as TrigWin, 0 as Pause, 600 as TrigWinMax, 5 as FileSplittingLength,
        'no' as NoiseFilter, '' as Comment
    from bd_sons.bdd_placettes t1
    where nom_point = %s
    and %s::date - "date" between 0 and (nombre_de_nuits - 1);"""
    cursor.execute(query, [placette, date])
    results = cursor.fetchone()
    print(results)
    return results if results else ''


def updateVigie(cursor, site, carre):
    """
    Parameters
    --------
    cursor : contextlib connection.cursor
    site : str
        nom_point in our database, unique site name
    carre : str
        Vigie Chiro Carré 6 digit code as given when the site is created
    """
    sqlUpdateCarre = ''' update bd_sons.bdd_placettes
    set vigie_chiro = %s
    where nom_point = %s
    and vigie_chiro is null;
    '''

    cursor.execute(sqlUpdateCarre, [carre, site])


def updatePoint(cursor, site, point):
    """ 

    Parameters
    --------
    cursor : contextlib connection.cursor
    """
    sqlUpdatePoint = ''' update bd_sons.bdd_placettes
    set code_point = %s
    where nom_point = %s;
    '''
    cursor.execute(sqlUpdatePoint, [point, site])


def updateVigieId(cursor, id_site, site, date):
    """
    Met à jour le code unique du carré vigie Chiro dans la base de données
    placettes de Asellia Ecologie.

    Parameters
    --------
    cursor : contextlib connection.cursor
    id_site : str
        identifiant site vigie chiro
    site : str
        nom_point base de données placettes
    date : str
        date au format "13/01/2023"

    Returns
    --------
    None
    """
    date_split = date.split('/')
    date = date_split[2] + '-' + date_split[1] + '-' + date_split[0]
    print(date)
    print(id_site)
    print(site)
    sqlUpdateVigieId = ''' update bd_sons.bdd_placettes
    set site_vigie = %s
    where nom_point = %s
    and "date" = %s;
    '''
    cursor.execute(sqlUpdateVigieId, [id_site, site, date])


def updateParticipationId(cursor, participation, site, date):
    """
    Parameters
    --------
    cursor : contextlib connection.cursor
    """
    date_split = date.split('/')
    date = date_split[2] + '-' + date_split[1] + '-' + date_split[0]
    sqlUpdateParticipation = ''' update bd_sons.bdd_placettes
    set participation_vigie = %s
    where nom_point = %s
    and "date" = %s and participation_vigie is null;
    '''
    cursor.execute(sqlUpdateParticipation, [participation, site, date])


def get_prefix(cursor, boitier, date):
    """ 
    Récupère le préfixe à utiliser pour renommer les sons avant envoi vigie
    chiro depuis la base de données placettes

    Parameters
    --------
    cursor : contextlib connection.cursor
    boitier : str
    date : str

    Returns
    --------
    results[0] : str
    """
    query = """select code_total
        from bd_sons.bdd_placettes t1
        where num_sm2 = %s
        and %s::date - "date" between 0 and (nombre_de_nuits - 1);"""
    cursor.execute(query, [boitier, date])
    results = cursor.fetchone()
    return results[0] if results else ''


def get_prefix_placette(cursor, placette, date):
    """ 
    Récupère le préfixe à utiliser pour renommer les sons avant envoi vigie
    chiro depuis la base de données placettes

    Parameters
    --------
    cursor : contextlib connection.cursor
    placette : str
    date : str

    Returns
    --------
    results[0] : str
    """
    query = """select code_total
        from bd_sons.bdd_placettes t1
        where nom_point = %s
        and %s::date - "date" between 0 and (nombre_de_nuits - 1);"""
    cursor.execute(query, [placette, date])
    results = cursor.fetchone()
    return results[0] if results else ''


def get_placette(cursor, boitier, date):
    """
    Parameters
    --------
    cursor : contextlib connection.cursor
    boitier : str
    date : str

    Returns
    --------
    result : list
    """

    query = """select etude, "lieu-dit", nom_point, passage
        from bd_sons.bdd_placettes t1
        where num_sm2 = %s
        and %s - to_char("date", \'YYYYMMdd\')::integer between 0 and (nombre_de_nuits - 1);"""
    cursor.execute(query, [boitier, date])
    results = cursor.fetchone()
    return results if results else ''


def get_placette_old(cursor, placette, date):
    """
    Parameters
    --------
    cursor : contextlib connection.cursor
    placette : str
    date : str

    Returns
    --------
    result : list
    """

    query = """select etude, "lieu-dit", nom_point, passage
        from bd_sons.bdd_placettes t1
        where nom_point = %s
        and %s - to_char("date", \'YYYYMMdd\')::integer between 0 and (nombre_de_nuits - 1);"""
    cursor.execute(query, [placette, date])
    results = cursor.fetchone()
    return results if results else ''


def getSiteParti(cursor, boitier, date):
    """
    Parameters
    --------
    cursor : contextlib connection.cursor
    boitier : str
    date : str

    Returns
    --------
    result : str
    """

    query = """select site_vigie, participation_vigie
        from bd_sons.bdd_placettes t1
        where nom_point = %s
        and %s::date - "date" between 0 and (nombre_de_nuits);"""
    cursor.execute(query, [boitier, date])
    results = cursor.fetchone()
    return results if results else ''


def sevenzip(filename, zipname):
    """
    Compresse un dossier avec 7zip par paquets de 700Mo

    Parameters
    --------
    filename : str
        nom du dossier que l’on veut zipper
    zipname : str
        nom des fichiers zip
    """
    system = subprocess.Popen(["7z", "-v700m", "a", zipname, filename])
    return system.communicate()

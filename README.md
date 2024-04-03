# Asellia’s chiro sound workflow 

## Gestion_sons.Rmd (and its derivatives)

Workflow to manage bat recordings from SM, Active/Passive recorders and Anabat Swift
Relies on a PostgreSQL database containing location information (geom, date, recorder prefix...)

Depends on : 
- Samuel Ortion’s tadam.py : <https://forge.chapril.org/Chiro-Canto/TadaridaTools/>
- Some scripts from cesco-lab’s [Vigie-Chiro_scripts](https://github.com/cesco-lab/Vigie-Chiro_scripts)
    - find_points.r
    - create_participations.R
    - CreateTar_ErrorProof_parallel_sitesaisi.R

parse_json.R is usefull for QField Cloud users who might want to update their 
Postgres database with unapplied data recovered from the Qfield Cloud team

This work is licensed under a
[Creative Commons Attribution 4.0 International License][cc-by-sa].

[![CC BY SA 4.0][cc-by-sa-image]][cc-by-sa]

[cc-by-sa]: http://creativecommons.org/licenses/by-sa/4.0/
[cc-by-sa-image]: https://i.creativecommons.org/l/by-sa/4.0/88x31.png
[cc-by-sa-shield]: https://img.shields.io/badge/License-CC%20BY%20SA%204.0-lightgrey.svg

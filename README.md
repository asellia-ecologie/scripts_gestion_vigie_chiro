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

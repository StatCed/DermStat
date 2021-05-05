import os, csv, datetime

print('############################################################')
print('#                                                          #')
print('# Création du fichier .SAS pour importation du ficher .CSV #')
print('# contenant les données brutes                             #')  
print('#                                                          #')
print('############################################################\n\n')


#Date de création du fichier
date=str(datetime.datetime.now())


#Adresse repertoire courant
adresse=os.getcwd();
#print("Adresse du répertoire pour windows :\n",adresse,"\n")


#Modification de la lettre du disque réseau pour correspondre au  disque local
#du serveur en focntion du site (Tunis ou Lyon) -> test sur l utilisateur
# Q: -> D:
if os.getlogin() == 'CJU':
	adresseSAS = adresse.replace('Q:' , 'D:')
else:
	adresseSAS = adresse.replace('Q:' , 'W:')
    
#print("Le repertoire contenant les données brutes :\n",adresseSAS,"\n")


#Chemin du driver SAS
driver=adresseSAS.replace("\\0.Data\\0.DataCSV", "\\0.Driver.sas")
#print("Le chemin du Driver :\n",driver,"\n")


#Information relative à l étude à renseigner  
donnees = input('\nNom du fichier de donnéees brute en .csv: ')

plan = input("\nPlan expérimental (Intra/Para/BIE) : ")

infos_etude = input("\nSouhaitez-vous rentrer les informations relatives à l'étude (O/N):")
if infos_etude.upper()=='O':
    titre = input("\nIntitulé de l'étude :")
    revendication = input("\nRevendication du produit de l'étude :")
    zone = input("\nZone :")
    nombre_de_sujets = input("\nNombre de sujets :")
    site = input("\nSite (France/Pologne/Tunisie/Ile Mauride/EVIC/ATS) :")
    CP = input("\nChef de projet :")


#Chemin du fichier brut   
adresse_donnees = adresseSAS + "\\" + donnees + ".csv"
#print("\n\nLe chemin des données brutes :\n",adresse_donnees,"\n")


#Nom du fichier SAS d importation   
import_sas = "I" + donnees + ".sas"


#Ecriture du code SAS 
file=donnees+".csv"
with open(file) as csv_file:
    with open(import_sas, "w+", encoding="ANSI") as imp_new:
        if infos_etude.upper()=='O':
            imp_new.write(f"/*\nIntitulé de l'étude :\n\
{20*'-'}\n{titre}; \n\n Revendication : \n\
{20*'-'}\n{revendication} \n*/\n\n")      
            imp_new.write(f'%global titre revendication date zone plan nombre_de_sujets site CP; \n\
%let titre = {titre};\n\
%let revendication = {revendication};\n\
%let plan = {plan};\n\
%let zone = {zone};\n\
%let site = {site};\n\
%let CP = {CP};\n\
%let date = {date};\n\n'                 
        )
        imp_new.write(f'%include "{driver}"; \n\n\
DATA lib.R{donnees}; \n\
	infile "{adresse_donnees}" \n\
	LRECL=32767 \n\
	ENCODING=wlatin1 \n\
	firstobs=2 \n\
	TERMSTR=CRLF \n\
	DLM=";" \n\
	MISSOVER \n\
	DSD ; \n\
INPUT \n')
        csv_reader= csv.reader(csv_file, delimiter=';')
        line_count = 1
        for row in csv_reader:
            if line_count == 1:
                for variable in row:
                    if line_count == 1:
                        imp_new.write(f'{variable} : $char100. \n')
                        line_count += 1
                    else:
                        imp_new.write(f'{variable} : numx32. \n')
                        line_count += 1      
                imp_new.write(f';\nrun;\n\n\n')

                imp_new.write(f'data lib.R{donnees};\n\
	retain product subject;\n\
	set lib.R{donnees};\n\
run;\n\n')
                
                imp_new.write(f'\noptions fmtsearch=(env.F{donnees});\n\
%table2(\n\
	tableEntree = lib.R{donnees}, 	\n\
	tableSortie = lib.D{donnees},   \n\
	autresVariables = ,  			\n\
	listeParametres = , 			\n\
	listeFormatsParametre = , 		\n\
	listeProduits = ,				\n\
	listeFormatsProduit = ,			\n\
	listeTemps = ,	         		\n\
	listeTempsNum = ,	 			\n\
	TypeEtude =  {plan}, 			\n\
	delta = oui,       				\n\
	libFormat = env.F{donnees},     \n\
	tableVar =  env.E{donnees});\n\n\n')
                
                                         				           
Stop = input("\n\nCréation du fichier d'import terminé !")

import os

print('##########################################################')
print('#                                                        #')
print('# Création du fichier analyse.sas qui contient les       #')
print('# les appels de macro SAS dédiées à l analyse des        #')  
print('# données                                                #')
print('#                                                        #')
print('##########################################################\n\n\n')

#Adresse repertoir courant
adresse_locale=os.getcwd();
print("L'adresse du répertoire de l'étude pour Windows est :\n",adresse_locale,"\n")

#Modification de la lettre du disque réseau pour correspondre au  disque local
#du serveur
# Q: -> D:

adresse_sas = adresse_locale.replace("Q:", "D:")
print("L'adresse du répertoire de l'étude pour le serveur SAS est :\n",adresse_sas,"\n")


#Chemin du dossier analyse
adresse_dossier_analyse = adresse_sas.replace("\\2.Program","\\")
print("Le chemin du dossier SAS est :\n",adresse_dossier_analyse)


#Ecriture de la table de données brutes .csv     
TABLE_SAS = input('Nom de la table de données brutes .CSV :')


#Chemin du driver SAS
driver=adresse_dossier_analyse + "0.Driver.sas"
print("Le chemin du driver SAS est :\n",driver)



#########################################
#
#Ecriture d'un progmramme d'aalyse SAS	
#					
#########################################

prog_temp=adresse_locale + "\\Analyse.txt"
prog1=adresse_locale + "\\A" + TABLE_SAS + ".sas"

with open(prog_temp, "r",encoding="ANSI") as f:
        with open(prog1, "w+", encoding="ANSI") as f_new:
            lines=f.readlines()
            for l in lines:
                if l.find("CHEMIN_DRIVER") == -1 and l.find("TABLE_SAS") == -1:
                    f_new.write(l)
                elif l.find("CHEMIN_DRIVER") > -1:
                    f_new.write(l.replace("CHEMIN_DRIVER", driver))
                elif l.find("TABLE_SAS") > -1:
                    f_new.write(l.replace("TABLE_SAS", TABLE_SAS))    
                else:
                    f_new.write("ERREUR 99999")
					
attente=input('Création du fichier "Analyse" pour le table TABLE_SAS effectué!')
				


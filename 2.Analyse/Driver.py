import os

print('##########################################################')
print('#                                                        #')
print('# Création du fichier driver .sas qui contient les liens #')
print('# vers les bibliothèques                                 #')  
print('#         - des données                                  #')
print('#         - des macro                                    #')
print('#         - des sorties RTF                              #')
print('#                                                        #')
print('##########################################################\n\n\n')

#Adresse repertoir courant
adresse_locale=os.getcwd();
print("L'adresse du répertoire de l'étude pour Windows est :\n",adresse_locale,"\n")

#Modification de la lettre du disque réseau pour correspondre au  disque local
#du serveur en fonction de l'utilisateur
if os.getlogin() == 'CJU':
	adresse_sas = adresse_locale.replace("Q:", "D:")+"\\"
else:
	adresse_sas = adresse_locale.replace("Q:", "W:")+"\\"	 	

#adresse_sas = adresse_locale.replace("\\\Treville\sas", "D:")
print("L'adresse du répertoire de l'étude pour le serveur SAS est :\n",adresse_sas,"\n")





#########################################################
#														#		
#Ecriture du Driver.SAS à partir du fichier Driver.txt	#
#														#		
#########################################################

driver_txt=adresse_locale + "\\0.Driver.txt"
driver_sas=adresse_locale + "\\0.Driver.sas"

with open(driver_txt, "r",encoding="ANSI") as f:
        with open(driver_sas, "w+", encoding="ANSI") as f_new:
            lines=f.readlines()
            for l in lines:
                if l.find("CHEMIN_DU_DOSSIER_ANALYSE_SAS") == -1:
                    f_new.write(l)
                else:
                    f_new.write(l.replace("CHEMIN_DU_DOSSIER_ANALYSE_SAS", adresse_sas))


attente=input('\nCréation du fichier driver.sas effectué !')








options mstored sasmstore=macro;

%macro environnement
(
f=lib.formats /*Fichier des format*/, 
table=lib.environnement /*table contenant les variables globales*/
)/STORE SOURCE;

*------------------------
Bibliothèque des formats;
options fmtsearch = (&f);

*------------
ENVIRONNEMENT
;

proc sql;
	select name
	into : liste_var_glob separated by ' '
	from &table
	where (scope='GLOBAL') and
	(index(name, 'SYS') =  0 
		and index(name, 'SAS') =  0
		and index(name, 'SQL') =  0
		and index(name, '_')	= 0)
;
quit;

%global &liste_var_glob;

data _null_;    

	set &table(where=(scope='GLOBAL'));

	if  (index(name, 'SYS') =  0 
		and index(name, 'SAS') =  0
		and index(name, 'SQL') =  0
		and index(name, '_')	= 0); 

	call symput(name,strip(value));                                                                                      

run; 

%mend;
 

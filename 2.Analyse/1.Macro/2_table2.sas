

options mstored sasmstore=macro;

%global typeEtude;

%macro table2 (
	tableEntree=  , 
	tableSortie=, 
	autresVariables=,                 /*optionnel*/
	listeParametres= ,				  /*optionnel - Définit l ordre des variables de la table de sortie*/	
	listeFormatsParametre = ,    	  /*optionnel*/			
	listeProduits = ,	              /*optionnel*/						
	listeFormatsProduit = ,	          /*optionnel*/				
	listeTemps = ,	                  /*optionnel*/							
	listeTempsNum = ,	              /*optionnel*/					
	TypeEtude	=  Intra,              /*Intra ou Para*/
	delta= Oui 	,                     /*Oui/Non*/
	libFormat = ,
	tableVar =  ,
	debug= N,						  /*Oui/Non*/
) / STORE SOURCE;
; 


%global PlanExperimental;
%let PlanExperimental=&typeEtude;

%let table=&tableEntree.;
%let product_pos=1;
%let subject_pos=2;
%let var_pivot_fin=2;
%let var_transpose_deb=%eval(3+%sysfunc(countw(&autresVariables)));

*#######################################################

OBJECTIF: 	récupérer les paramètres de la table brute
			nécessaire à la macro table()

SORTIE:

Table SAS avec les variables de la table/
- _POSITION

Macro variables:
- __product
- __subject
- __varClassement (variables pivots)
- __varTransposees (variables classement) 
- __listeParaC
- __listeParaN
- __listeFormatPara
- __listeTimeC	
- __listeTimeN
- __listeProdC
- __listeFormatProd
;

*#######################################################;


%global 
 __product
 __subject
 __varClassement 
 __varTransposees  
 __listeParaC
 __listeParaN
 __listeFormatPara
 __listeTimeC	
 __listeTimeN
 __listeProdC
 __listeFormatProd
;

ods output position=_POSITION;
proc contents data=&table order=varnum;
run;

proc sql;
	select variable
	into : __product
	from _POSITION
	where num = &product_pos
;
	select variable
	into : __subject
	from _POSITION
	where num = &subject_pos
;
	select variable
	into : __varClassement separated by ' '
	from _POSITION
	where num <= &var_pivot_fin
;
	select variable
	into : __varTransposees separated by ' '
	from _POSITION
	where num >= &var_transpose_deb
;	
quit;

data _PARA_ET_TPS;
	set _POSITION;
	paraC=scan(variable, 1, '_');
	timeC=scan(variable, 2,'_');
	if num >= &var_transpose_deb ;
run;


proc sort data= _PARA_ET_TPS out=_PARA nodupkey;
	by paraC;
run; 

proc sort data= _PARA out=_PARA nodupkey;
	by num;
run; 

data _PARA;
	set _PARA;
	paraN = _n_;
run;

proc sort data= _PARA_ET_TPS out=_TIME nodupkey;
	by timeC;

proc sort data= _TIME out=_TIME nodupkey;
	by num;

data _TIME;
	set _TIME;
	timeN = _n_;
run;

proc sql;
	select paraC, paraN
	into : __listeParaC separated by ' ', : __listeParaN separated by ' '
	from _PARA
	order by paraN
;
	select paraC
	into : __listeFormatPara separated by '!' 
	from _PARA
	order by paraN
;
	select timeC, timeN
	into : __listeTimeC separated by ' ', : __listeTimeN separated by ' '
	from _TIME
;	
quit; 

data _PROD;
	set &table;
	prodC = compress(&__product);
	obs=_n_;

proc sort data=_PROD out=_PROD nodupkey;
	by prodC;

proc sort data=_PROD out=_PROD;
	by obs;
run;

proc sql;
	select prodC
	into : __listeProdC separated by ' '
	from _PROD
	order by obs
;
	select prodC
	into : __listeFormatProd separated by '!'
	from _PROD
	order by obs
;
quit;
/*******************************Fin extraction************************************/	
/********************************************************
Objectif du macro assign:
   -Pour affecter toutes les variables de macro extraites aux variables de macro appropriées.
   -Pour définir des variables avec remplissage optionnel. 
    Ce sont les macro variables des formats de temps,  produit et  paramètres.
*********************************************************/
%let variablesDeClassement= &__varClassement;
%put variablesDeClassement= &variablesDeClassement.;
%let variablesTransposees= &__varTransposees;
%put variablesTransposees= &variablesTransposees.;

%if %length(&listeParametres)=0 %then %do;
	%let listeParametres = &__listeParaC;
%end;

%put listeParametres=&listeParametres.;

%macro assign();
%if  %length(&listeProduits.) = 0 %then %do;
											%let listeProduits = &__listeProdC ;
										%end;
%put listeProduits=&listeProduits.;

%if %length(&listeFormatsParametre.) = 0 %then %do;
                                               %let	listeFormatsParametre = &__listeFormatPara ; 
                                               %end;
%put listeFormatsParametre= &listeFormatsParametre;

%if %length(&listeFormatsProduit.) = 0 %then   %do;
                                               %let	listeFormatsProduit = &__listeFormatProd;
                                               %end;
%put listeFormatsProduit= &listeFormatsProduit;

%if %length(&listeTemps.) = 0 %then %do;
                                    %let	listeTemps = &__listeTimeC;
                                    %end;
%put listeTemps= &listeTemps;

%if %length(&listeTempsNum.) = 0 %then %do;
                                       %let	listeTempsNum = &__listeTimeN;
                                       %end;
%put listeTempsNum= &listeTempsNum;

%mend assign;

%assign();


/*Amélioration possible:
	- insensibilite à la casse
	- nombre de variables de classement variable
	- français/anglais
	- possibilité de ne plus avoir les varaition Di-D0
*/


*-----------------------------------------------------------------------
1. Macro-variable avec le nombre de parametres, de produits et de temps
------------------------------------------------------------------------; 

%global NombreParametres NombreProduits NombreTemps;

%let NombreParametres 	= %sysfunc(countw(&listeParametres,%str( )));
%let NombreProduits 	= %sysfunc(countw(&listeProduits,%str( )));
%let NombreTemps 		= %sysfunc(countw(&listeTemps,%str( )));



*-------------------------------------------------------------------------
2. Stockage dans des macro-variables :
	- chaque parametre (para1, para2...) et numérique (ParaN1, ParaN2)
	- chaque produit en charactère (p1, p2...) et (pn1, pn2)   
	- chaque temps en charactère (t1, t2...) et (tn1, tn2)
--------------------------------------------------------------------------; 

%macro StockageVariables ();  

	%do i = 1 %to &NombreParametres;			
		%global para&i paraN&i; 									
		%let Para&i 	= %scan (&listeParametres, &i, ' ' ) ;
		%let paraN&i 	= &i;
	%end;

	%do i = 1 %to &NombreProduits;				
		%global p&i pN&i; 								
		%let p&i 	= %scan (&listeProduits, &i, ' ' ) ;
		%let pN&i 	= &i;
	%end;

	%do i = 1 %to &NombreTemps;							
		%global t&i tN&i; 
		%let t&i = %scan (&listeTemps, &i, ' ' ) ;
		%let tN&i = %scan (&listeTempsNum, &i, ' ' ) ;
	%end;

%mend StockageVariables;


%StockageVariables();

*--------------------------------------------------------------------------------------
3. Création des formats paramétre (parameterf.), product (productf.) et temps (tempsf.)
---------------------------------------------------------------------------------------; 

%macro format();

*==================
Format parametre
===================;

%global paraf1;
%let paraf1 = %scan(&listeFormatsParametre, 1, !|);
%let listeFormatsParametre2 = %str( 1 = "&paraf1" ) ;

%do i = 2 %to &NombreParametres;
	%global paraf&i;
	%let paraf&i = %scan(&listeFormatsParametre, &i,!); 
	%let listeFormatsParametre2 = &listeFormatsParametre2 %str( &i = "&&Paraf&i" ) ;
%end;


*==================
Format produit
===================;

%global pf1 listeInformatsProduit;
%let pf1 = %scan(&listeFormatsProduit, 1,!);
%let listeFormatsProduit2 = %str( 1 = "&pf1" ) ;
%let listeInformatsProduit 	= %str ( "&pf1" = 1 ) ; 

%do i = 2 %to &NombreProduits;
	%global pf&i;
	%let pf&i = %scan(&listeFormatsProduit, &i, !); 
	%let listeFormatsProduit2 = &listeFormatsProduit2 %str( &i = "&&pf&i" ) ;
	%let listeInFormatsProduit = &listeInFormatsProduit %str( "&&pf&i" = &i ) ;
%end;

*Format pour la comparaison des produits 2 à 2;
%do i=1 %to %eval(&NombreProduits-1);

	%do j=%eval(&i+1) %to &NombreProduits;

		*-Création de la variable numérique comparaison des produits
		1000 = comparaison des produits
		100 * i + j = produit i comparé au produit j
		;
		%let numTimeN = %eval(1000+100*&i+&j);
		%let numDuformat= %eval(&NombreProduits+&i);
		%let pf&numDuFormat= &&pf&i vs &&pf&j;
		%let listeFormatsProduit2 = &listeFormatsProduit2  %str( &numTimeN = "&&pf&numDuFormat" );
		%let listeInFormatsProduit = &listeInFormatsProduit %str("&&pf&i vs &&pf&j" = &numTimeN);
	%end;

%end;

*=====================================
			Format temps
=====================================;


*Initialisation liste des formats pour le temps;
%let listeFormatsTemps 		=	 %str( &tN1 = "&t1" ) ;

*Initialisation liste des informats pour le temps;
%global listeInformatsTemps;
%let listeInformatsTemps 	= %str ( "&t1" = &tN1 ) ; 

%do i=2 %to &NombreTemps;

	%let listeFormatsTemps = &listeFormatsTemps %str( &&tN&i = "&&t&i" ) ;
	%let listeInformatsTemps = &listeInformatsTemps %str( "&&t&i" = &&tN&i ) ;

	%do j=1 %to %eval(&i-1);
		
		%let code_Numerique_ti_t1 = %sysevalf(&j*1000+&&tN&i);
		%let code_Numerique_ti_t1_rel = %sysevalf(&j*1000+&&tN&i+100);
		%let listeFormatsTemps = &listeFormatsTemps %str( &code_Numerique_ti_t1 = "&&t&i.-&&t&j" ) %str( &code_Numerique_ti_t1_rel = "(&&t&i.-&&t&j)/&&t&j" );
		%let code_Charactere_ti_t1 = &&t&i-&&t&j;
		%let code_Charactere_ti_t1_rel = (&&t&i.-&&t&j)/&&t&j;
		%let listeInformatsTemps = &listeInformatsTemps %str( "&code_Charactere_ti_t1" = &code_Numerique_ti_t1 ) %str( "&code_Charactere_ti_t1_rel" = &code_Numerique_ti_t1_rel );

	%end;

%end;



%if %length(&libFormat) ne 0 %then %do;
	%let catalogue_format = &libFormat;
%end;
%else %do;
	%let catalogue_format = work;
%end;

proc format library = &catalogue_format;

		value parameterf
			&listeFormatsParametre2;

		value productf
			&listeFormatsProduit2;

		invalue productf
			&listeInformatsProduit;

		invalue timef
			&listeInformatsTemps;

		value timef
			&listeFormatsTemps;
run;

%mend format; 

%format();



*-------------------------------------------------------------------------
4. Transposition de la table entrée en long
--------------------------------------------------------------------------; 

proc sort data=&tableEntree 
	out=&tableSortie; 
	by &autresVariables. &variablesDeClassement.;
run;
proc transpose data=&tableSortie 
	out=&tableSortie (rename=(col1=value)) name=variable; 
	var &variablesTransposees.;
	by &autresVariables. &variablesDeClassement.;
	informat col1 best32.;
	format col1 best32.;
run;



*-------------------------------------------------------------------------
5. Création des variables numériques :
	- paramètres caractère et numérique 
	- produit numérique 
	- temps caractére
--------------------------------------------------------------------------; 

data &tableSortie;

	informat 	parameter $char100.
				product $char100. 
				time $char100.
				productN 8. 
				parameterN 8. 
				timeN 8.
	; 

	format		parameter $100.
				product $char100.
				time $100.
				parameterN parameterf.
				productN productf.
				timen timef.
	;

	label 		subject='Subject'	
				parameter='Parameter'	
				parameterN='Parameter'
				product='Product'
 				productN='Product'
				value='Value'
				variable='Variable entrée'
	;

	set &tableSortie;

		%do i = 1 %to &NombreTemps;
			if upcase(scan(variable,2,"_"))= upcase("&&t&i") then do;
            *if index(upcase(variable), upcase("&&t&i")) ne 0 then do;
				time = "&&t&i";  
				timeN= "&&tN&i";
			end;	
		%end;

		%do i = 1 %to &NombreParametres;
			if upcase(scan(variable,1,"_"))= upcase("&&Para&i") then do;
            *if index(upcase(variable), upcase("&&Para&i")) ne 0 then do;
				parameter = "&&Para&i"; 
				parametern=	&i; 
			end;	
		%end;

		%do i = 1 %to &NombreProduits;
			if upcase(product) = upcase("&&p&i")  then do;
            *if index(upcase(product), upcase("&&p&i")) ne 0 then do; 
				productn = &i; 
			end;
		%end;

run;


*========================================================================
Vérification de la bonne correspondance des nouvelles variables
=========================================================================;

proc sql;
	create table CQ_formats_parametres as
	select distinct put(parametern,8.0) as num, parametern, parameter,variable
	from &tableSortie;

	select distinct put(parametern,8.0) as num, parametern, parameter,variable
	from &tableSortie;

	select distinct productn,product
	from &tableSortie;

	select distinct time,variable
	from &tableSortie;
quit;




*============================================================================
Calcul des variations par rapport à la valeur basale Ti-T0 pour chaque sujet
=============================================================================;

*Modif CJU le 01/09/2020 - gestion cas ou une seule cinétqiue;
/*%if &delta = abs or &delta = rel %then %do;*/

%if  %index(%upcase(&delta),N) = 0 %then %do;

		proc sort data=&tableSortie out=&tableSortie; 
			by &autresVariables subject parametern parameter productn product timen time; 

		proc transpose data=&tableSortie out=&tableSortie;
			var value;
			id time;
			by &autresVariables subject parametern parameter productn product ;

		data &tableSortie;
			set &tableSortie;
			%do i = 2 %to &NombreTemps;

				%do j=1 %to %eval(&i-1);

					&&t&i.._&&t&j = &&t&i-&&t&j; 
					&&t&i.._&&t&j.._rel = (&&t&i-&&t&j)/&&t&j; 
				
				%end;
			
			%end;
		run;

		/*Définition de la dernière variation calculée pour la PROC TRANSPOSE*/
		%let avant_dernier_temps_de_mesure=%eval(&NombreTemps-1);

		proc transpose data=&tableSortie out=&tableSortie name=time;
			var &t1--&&t&NombreTemps.._&&t&avant_dernier_temps_de_mesure.._rel;
			by &autresVariables subject parametern parameter productn product;
		run;

%end;



*========================================================================
	Calcul des différences entre les produits pour chaque sujet 
=========================================================================;


*Si le nombre de produit est supérieur à 1;
%if (%index(%upcase(&TypeEtude),I) and %eval(&NombreProduits > 1)) %then %do;

		proc sort data=&tableSortie out=&tableSortie; 
			by &autresVariables subject parametern parametern time productN ;
		run;

		proc transpose data=&tableSortie out=&tableSortie name=time;
			var value;
			id productN;
			by &autresVariables subject parametern parameter time;
		run;

		data &tableSortie;
			set &tableSortie;
			%do i=1 %to %eval(&NombreProduits-1);
				%do j=%eval(&i+1) %to &NombreProduits;
					"&&pf&i.._&&pf&j"n = "&&pf&i"n - "&&pf&j"n;
				%end;
			%end;
		run; 
		
		data CJU_test2;
			set  &tableSortie;
		run;

		%let nombreProduits_1 = %eval(&NombreProduits-1);

		proc transpose data=&tableSortie out=&tableSortie (rename=(col1=value)) name=time name=product;
			var "&pf1"n--"&&pf&nombreProduits_1.._&&pf&NombreProduits"n;
			by &autresVariables subject parametern parameter time;
		run;

		data CJU_test3;
			set  &tableSortie;
		run;


%end;




data &tableSortie;

	retain &autresVariables Subject Parameter ParameterN ProductN Product TimeN Time value;
	
	rename 	Parameter=parameterC 
			parameterN=parameter 

			product=productC
			productN=product

			Time=timeC 
			TimeN=time 
	;

	label	
			timeN='Time'  
			productN ='Product'
			parameterN ='Parameter'	
	;

	informat 	time $char100. 
				timen 8. 
				value best32.
	;

	format 	time $char100. 
			timen timef.
			productN productf.
			value best32.
	;

	length product $ 100
	;

	set &tableSortie;
	type = 'raw';	

		%do i = 1 %to &NombreTemps;
			if index(upcase(time), upcase("&&t&i")) ne 0 then timeN = &&tN&i;			
		%end;
		

		%do i = 2 %to &NombreTemps;

			%do j=1 %to %eval(&i-1);
		
			if index(upcase(time), upcase("&&t&i.._&&t&j")) ne 0 then do; timeN = %sysevalf(&j*1000+&&tN&i); type='abs'; end;
		*!!! if (  index(upcase(time), upcase("&&t&i.._&t1")) ne 0  and  index(upcase(product), upcase("&p1._&p2")) ne 0 ) then timeN = %sysevalf(&&tN&i+2000);
			if index(upcase(time), upcase("&&t&i.._&&t&j.._rel")) ne 0 then do; timeN = %sysevalf(&j*1000+&&tN&i+100); type='rel'; end;

			%end;

		%end;


		%if %index(%upcase(&TypeEtude,I)) %then %do; 
			 
			%do i = 1 %to &NombreProduits;
				if index(upcase(product), upcase("&&pf&i")) ne 0 then productN = &&pN&i;
			%end;

			%do i=1 %to %eval(&NombreProduits-1);
				%do j=%eval(&i+1) %to &NombreProduits;
					if index(upcase(product), upcase("&&pf&i.._&&pf&j")) ne 0 then productN=%sysevalf(1000+100*&i+&j);
				%end;
			%end;

		%end;

run;

%put _global_;

*================================================================
Vérification de la bonne correspondance des nouvelles variables
+ effectif à chaque temps par produit et paramètre
=================================================================;

proc sql;
	select distinct time, timeC
	from &tableSortie;

	select distinct put(parameter,8.0) as num, parameter, product, time, count(subject) as Effectif
	from &tableSortie
	group by parameter, product, time;
quit;


*================================================================
Suppression des variable de type caractère
=================================================================;

data &tableSortie;
	drop parameterC productC timeC;	
	set  &tableSortie;
	NO=_n_;  /*Numero de l'observation*/ 
run;


*================================================================
Propriété des varaibles
=================================================================;

proc contents data=&tableSortie;
ods select variables;
run;


*-----------------------------------------
Controle correspondance entre les formats 
des parametres et les variables
------------------------------------------;

title 'Controle correspondance entre les formats des parametres et les variables';
proc sql;
	select distinct parameterN format 8.0, parameterN, parameter
	from work.cq_formats_parametres;
quit;
title;


proc format library = &libFormat fmtlib;
select parameterf productf @productf timef @timef prodf;
run;


*COMMANDES POUR GERER LES MACRO ET LES FORMAT STOCKES;
/*
proc catalog catalog = std.sasmacr;
contents;
run;
/*
proc catalog catalog = work.formats ;
contents;
run;

/*
%copy  table/source out="d:\statistiques\output\divers\test.rtf";
*/

%put _global_;

%if %length (&tableVar) ne 0 %then %do;
	data &tableVar;  	
   		set sashelp.vmacro(where=(scope='GLOBAL'));    
		if substr(name,1,3) ne 'SYS';      
	run;
%end;


/*######################################################

MISE A JOUR DE LISTE DES ANALYSES STATISTIQUES REALISEES 

########################################################*/

proc sort data=&tableVar out=tp;
	by name;
run;

data tp;
	set tp;
	by name;
	first_name=first.name;
run;

proc transpose data=tp out=T_tp;
	var value;
	id name;
	where first_name=1;
run;

data dermscan.Listes_des_etudes;
	set dermscan.Listes_des_etudes T_tp;
run;



*Mode DEBUG;
%if %index(%upcase(&debug),N) %then %do;
*Nettoyage de la bibliothèque WORK;
	proc datasets lib=work nolist; 
	  delete 
	CQ_FORMATS_PARAMETRES	
	_PARA	
	_PARA_ET_TPS	
	_POSITION	
	_PROD	
	_PRODSAVAIL	
	_TIME
	tp
	T_tp	
	; 
	quit; 
%end;


%mend table;  

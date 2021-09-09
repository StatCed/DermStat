
*****************************************************************************************

NOM : %evic_analyse()

OBJET : réalise l analyse statistique des données issue de EVIC
		fournit une table SAS en sortie avec l emsenbles des statistiques 
		nécessaires aux différents rapport pour EVIC -> SNIFF TEST, SCORAGE, METROLOGIE 

REQUIERE : 	prend en entrée une table excel de données avec les variables suivantes	->
			PARAMETER/PRODUCT/TIME/SUBJECT/VALUE (issue de la macro %table()) 

MACRO DEPENDANCE : %stat_evic()

ENTREE : table SAS 

SORTIE : table SAS

DATE : 	13/11/2020

DERNIERE MODIFICATION : 13/11/2020

AUTEUR : Cédric Jung - cju@dermscan.com

****************************************************************************************;


*libname macro "D:\StructureEtude\0.XXEXXXX_Draft\2.Analyse\1.Macro";

options mstored sasmstore=macro;

%macro evic_analyse(table=DATASET2, dec=,f=0, out=, lang=ang, non_parametric=/*oui/non*/) / STORE SOURCE ;

*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
1.
	-	STATISTIQUES DESCRIPTIVES
	-	VARIATION PAR RAPPORT A LA VALEUR BASALE -> STUDENT / WILCOXON

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~;
%evic_Stat(
	table=&table,
	numParametre= ,
	format=8.&dec , 
	sortieBrute= n,
	TableauRapport= o,
	Plan = &planExperimental,
	wilcoxon=&non_parametric,
	stat =  1 2 3 4 6 7,
	lang = fr,
	tempsAvecComparaison=%str(time>=0 ),
	leg=N
); 

*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
2. Format Français/Anglais
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~;
proc format;
	invalue statf
		'N_VM' 		= 1
		'M_EC' 		= 2
		'M_ESM'		= 2.5
		'ESM'  		= 3
		'Med'  		= 4
		'CV' 		= 4.5
		'Q1_Q3'   	= 5
		'Qrange'	= 5.5
		'Range'		= 6
		'IC'		= 6.5 
		'pvalueC'	= 7
		;
%if %upcase(&lang) = ANG %then %do;
	value statf
		-10		= 'Time'
		-9		= 'Parameter'
		-8		= 'Number of subject'
		-7		= 'Product'

        1     	= 'N (miss)'
        2     	= 'mean (SD)'
        2.5 	= 'Mean ± SEM'    
        3     	= 'SEM'
        4     	= 'median'
        4.5 	= 'CV'
        5     	= 'Q1 ; Q3'
        5.5 	= 'IQR'
        6     	= 'min ; max'
        6.5 	= '95% CI'
		6.75	= 'Statistical test'
        7     	= 'p-value'
		8		= 'Statistical interpretation     (Significant if p<0,050)'
		9     	= 'Effect in %'

		11 		= 'Number of subject'
		12		= 'Mean'
		13 		= 'Standard deviation'
		13.5	= 'Median'
		14		= 'Maximum'
		15		= 'Minimum'

		21  	= 'Statistical test'
        22    	= 'p-value'
		23    	= 'Interpretation'
   
        31  	= 'Number and %'
        32  	= 'Improvement score'
;
 	value responderf
		1	=	'Volunteer responders'
		2	=	'Panel total'
;
	value significativityf
		1	=	'Yes'
		0	=	'No'
;
	value conclusionf
		0 = 'NA'
		1 = 'Significant difference'
		2 = 'No difference'
;
%end;

%else %if %upcase(&lang) = FR %then %do;
	value statf
		-10		= 'Temps'
		-9		= 'Paramètre'
		-8		= 'Nombre de sujets'
		-7		= 'Produit'

        1     	= 'N(VM)'
        2     	= 'Moyenne(ET)'
        2.5 	= 'Moyenne ± ESM'    
        3     	= 'ESM'
        4     	= 'Médiane'
        4.5 	= 'CV'
        5     	= 'Q1 ; Q3'
        5.5 	= 'IQR'
        6     	= 'min ; max'
        6.5 	= '95% CI'
		6.75	= 'Test Statistique'
        7     	= 'p-value'
		8		= 'Interprétation statistique (Significatif si p<0,050)'
		9     	= 'Effet en %'

		11 		= 'Nombre de sujets'
		12		= 'Moyenne'
		13 		= 'Ecart type'
		13.5	= 'Médiane'
		14		= 'Maximum'
		15		= 'Minimum'

		21  	= 'Statistical test'
        22    	= 'p-value'
		23    	= 'Interpretation'
   
        31  	= 'Nombre et %'
        32  	= 'Score d''amélioration'
;
 value responderf
		1	=	'Volontaires répondeurs'
		2	=	'Panel total'
;
;
value significativityf
		1	=	'Oui'
		0	=	'Non'
;
	value conclusionf
		0 = 'NA'
		1 = 'Différence significative'
		2 = 'Pas de différence'
;
%end;

value $testf
		'Signed Rank'	=	'Wilcoxon'
		"Student's t"	=	'Student'
;

%let GlobalTime = ;
%do tps=1 %to &NombreTemps;
	%let GlobalTime =&GlobalTime &&t&tps.,;
%end;
value GlobalTimef
	1 = "&GlobalTime"
;
run;


*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
2.
	-	CHANGE FROM BASELINE TEST T/WILCOXON

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~;

proc sort data=STAT_NUM out=STAT_NUM_RAW;
	by parameter product time;
run;

proc transpose data=STAT_NUM_RAW out=STAT_NUM_RAW (rename=(col1=value));
	var value_N value_Mean value_Std value_Median value_Min value_Max;
	by parameter product time;
run; 

data STAT_NUM_RAW;
	set STAT_NUM_RAW;
	length col1 $ 50;
	*Variables STATn et PANEL pour sniff test;
	if _name_='value_N' 		then do; statN=11; /*statN2 = 1; panel=2;*/ end;
	if _name_='value_Mean' 		then do; statN=12; /*statN2 = 2; panel=2;*/ end;	
	if _name_='value_Std' 		then statN=13;
	if _name_='value_Median' 	then statN=13.5;
	if _name_='value_Max' 		then statN=14;
	if _name_='value_Min' 		then statN=15;
	if statN=11 		then col1=strip(put(value,8.0));
	else if statN>11 	then col1=strip(put(value,8.2));
run;

/*
data __pvalue_1;
	length conclusion $ 50 test2 $ 50;
	set __pvalue;
*	if time > 1000;
	if missing(pvalue)				then conclusion = put(0,conclusionf.);
	else if pvalue < 0.05 			then conclusion = put(1,conclusionf.);
	else if pvalue > 0.05 			then conclusion = put(2,conclusionf.);
	if index(test,'Signed')			then test2='Wilcoxon';
	else if index(test,'Student') 	then test2='Student';
	else test2='NA';
	normality_test = 0;
run;
*/

data __pvalue_2;
	length conclusion $ 50 test2 $ 50;
	set __pvalue;
*	if time > 1000;
	if missing(pvalue)				then conclusion = put(0,conclusionf.);
	else if pvalue < 0.05 			then conclusion = put(1,conclusionf.);
	else if pvalue > 0.05 			then conclusion = put(2,conclusionf.);
	if index(test,'Signed')			then test2='Wilcoxon';
	else if index(test,'Student') 	then test2='Student';
	else test2='NA';
	normality_test = 1;
run;

proc transpose data=__pvalue_2 out=__pvalue_3;
	by parameter product time;
	var conclusion test2;
run;

data __pvalue_4;
	drop _name_;
	set __pvalue_3;
	if index(_name_,'test') then statN = 6.75;
	if index(_name_,'conc') then statN = 8;
run;


*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
2.
	-	EFFET TEMPS GLOBAL (ANOVA)

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~;

*
Initialisation table de
Stockage des effets temps
;  
data Overall_Time_Effect;
run;

%do i=1 %to &NOMBREPARAMETRES;
	%do pdt=1 %to &NOMBREPRODUITS;
		%ANOVA(table= &table,
			class = %str(parameter product subject time),
			model = %str(value= time / ddfm=KR outp=resid_&&para&i ;),
			random =%str(repeated  time / sub=subject type=CS),	
			where = %str(where time<1000 and product=&pdt and parameter=&i),
			table_cont= comparison,
			log = log(value),
			sqrt = sqrt(value), 
			numParametre=&i, 
			format=8.&dec, 
			SortiesBrutes=non,
			pol=calibri	,
			tail=8	,
			larg=1,
			lang=ANG,
			cont= 
		%str(
		estimate 'time'	time -1 1 /cl;
		)
		);

		*Stockage test de Shapiro-Wilk dans macro variable;
		data Normality_Residuals;
			set Normality_Residuals;
			if testLab='W' then call symput ('Shapiro_Wilk',pvalue);
		run;

		*Stockage des resultats dans la table Overall_Time_Effect;
		data Fixed_effect_&&para&i;
			keep parameter product probF Shapiro_Wilk; 
			set Fixed_effect_&&para&i;
			parameter=&i;
			product=&pdt;
			rename probf=ANOVA;
			Shapiro_Wilk=input(symget('Shapiro_Wilk'),best32.);
			format Shapiro_Wilk pvalue8.4;
		run;

		data Overall_Time_Effect;
			set Overall_Time_Effect fixed_effect_&&para&i;
			if not missing(product);
		run;
	%end;

*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
3.
	-	EFFET TEMPS GLOBAL (FRIEDMAN)

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~;
*Test de Friedman;
proc sort data=&table out=&table; by parameter product subject time ; run;

ods output CMH=CMH;
PROC FREQ DATA=&table;
	where product < 1000 and time <1000;
	TABLES subject*time*value / CMH2 SCORES=RANK NOPRINT;
	by parameter product;
RUN;

data CMH;
	keep parameter product prob;
	set CMH;
	if AltHypothesis='Row Mean Scores Differ';
	rename prob=Friedman;
run;


*Stockage des resultats du test ANOVA et Friedman dans la table Overall_Time_Effect2;
proc sql;
	create table Overall_Time_Effect2 as
	select a.parameter, a.product, a.Shapiro_Wilk, a.ANOVA, b.Friedman 
	from Overall_Time_Effect as a left join CMH as b
	on a.parameter=b.parameter and a.product=b.product;
quit;

data Overall_Time_Effect3;
	length conclusion $ 50;
	set Overall_Time_Effect2;

	/*Sélection du test en fonction de la normalité*/
	/*if Shapiro_Wilk < 0.01 then do;
		test='Friedman';
		pvalueC=strip(put(Friedman,pvalue8.4));
		pvalue = Friedman;
	end;
	if Shapiro_Wilk > 0.01 then do;
		test='ANOVA';
		pvalueC=strip(put(ANOVA,pvalue8.4));
		pvalue = ANOVA;
	end;*/

	test='Friedman';
	pvalueC=strip(put(Friedman,pvalue8.4));
	pvalue = Friedman;
	if missing(pvalue) 		then conclusion=put(0,conclusionf.);
	else if pvalue < 0.05	then conclusion=put(1,conclusionf.);
	else if pvalue > 0.05 	then conclusion=put(2,conclusionf.);
	output;

	test='ANOVA';
	pvalueC=strip(put(ANOVA,pvalue8.4));
	pvalue = ANOVA;
	if missing(pvalue) 		then conclusion=put(0,conclusionf.);
	else if pvalue < 0.05	then conclusion=put(1,conclusionf.);
	else if pvalue > 0.05 	then conclusion=put(2,conclusionf.);
	output;

run;

proc sort data=Overall_Time_Effect3 
	out=Overall_Time_Effect3;
	by parameter product test pvalue ;
run;

proc transpose data=Overall_Time_Effect3 
	out=Overall_Time_Effect4 name=stat;
	by parameter product test pvalue ;
	var test pvalueC conclusion;
run;

data Overall_Time_Effect5;
	set Overall_Time_Effect4;
	if stat = 'test' 			then statN = 21;
	else if stat = 'pvalueC' 	then statN = 22;
	else if index(stat,'conc')	then statN = 23;
	time=1;
run;


*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
4.
	-	POURCENTAGE D AMELIORATION SUR LES MOYENNES

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

*
Pourcentage d amelioration calculés à partir des valeurs moyennes
de chaque temps (et non pas à partir des données individuels)
;

proc sort data=STAT_NUM out=STAT_NUM2;
	by parameter product time;
run;
proc transpose data=STAT_NUM2 out=STAT_NUM2 (drop=_name_);
	var value_Mean;
	by parameter product;
	id time;
	where time < 1000 and product < 1000;
run;

data STAT_NUM2;
	set STAT_NUM2;
	%do j=2 %to &NOMBRETEMPS;
		"&&t&j..-&t1"n =(&&t&j - &t1)/&t1;
	%end;
run;

proc transpose data=STAT_NUM2 out=STAT_NUM3 
	(rename=(col1=value)) name=timeC;
	by parameter product;
run;

proc sort data=STAT_NUM3 out=STAT_NUM4;
	by parameter timeC product;
run;
proc transpose data=STAT_NUM4 out=STAT_NUM4 (drop=_name_);
	by parameter timeC;
	id product;
	var value;
run;

%put _global_;

data STAT_NUM5;
	set STAT_NUM4;
	%if %eval(&NOMBREPRODUITS > 1) %then %do;
		"&pf1 vs &pf2"n=&pf1-&pf2;
	%end;
run;
	
proc transpose data=STAT_NUM5 
	out=STAT_NUM6 
	(rename=(col1=value)) 
	name=productC;
	by parameter timeC;
run;	

data STAT_NUM7 ;
*	drop timeC productC value ;
	set STAT_NUM6;
	length col1 $ 50;
	statN=9;
	product=input(productC,productf.);
	time=input(timeC,timef.);
	if time > 1000;
	%if %eval (&nombreproduits>1) %then %do;
		if product > 1000;
	%end;
	if not missing(value) then col1=strip(put(value,percentN8.1));
	else col1='NA'; 
run;

data STAT_NUM8 ;
	set STAT_NUM6;
	statN=9;
	length Percentage $ 50;
	product=input(productC,productf.);
	time=input(timeC,timef.);
	if time > 1000;
	%if %eval (&nombreproduits>1) %then %do;
		if product > 1000;
	%end;
	if missing(value) then Percentage='NA'; 
	else Percentage=strip(put(value,percentN8.1));
run;

%end;


*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
5.
		PROPORTION DE REPONDEURS AVEC :
			UNE AUGMENTATION 
			UNE STAGNATION
			UNE DIMINUTION

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~;


data CFB;
	set &table;
	if time > 1000;
	if value = . then CFB = .;
	else if value < 0 then CFB = -1;
	else if value = 0 then CFB = 0;
	else if value > 0 then CFB = 1;
	else CFB = 9999;
run;

proc sort data=CFB out=CFB; 
	by parameter product time;
run;

data classData;
	format parameter parameterf. product productf. time timef.;
	do parameter=1 to &NOMBREPARAMETRES;
		do product=1 to &NOMBREPRODUITS;
			do time=1002 to %eval(1000+&NOMBRETEMPS);
				do CFB=-1,0,1;
					output;
				end;
			end;
		end;
	end;
run;		

ods output table=Responders_proportion (drop=_type_ _table_ _page_) ;
proc tabulate data=CFB classData=classData missing ;
	where CFB ne .;
	class parameter product time CFB;
	table parameter * product * time*(CFB=' ') , (n pctn<CFB>*f=8.2)/ misstext='0';
run;

*Calcul de l effet moyen chez les répondeurs;
ods output summary=Responders_mean_effect;
proc means data=CFB n mean nonobs;
	var value;
	class parameter product time CFB;
run;

proc sql;
	create table Responders_proportion_2 as
	select *
	from Responders_proportion as a left join Responders_mean_effect as b
	on a.parameter=b.parameter and a.product=b.product and a.time=b.time and a.cfb=b.cfb
	order by parameter, product, time, CFB;
quit;

data Responders_proportion_3;
	length 'Nombre et %'n $ 50 "Score d'amélioration"n $ 50;
	drop N pctN_1110 value_N value_mean;
	set Responders_proportion_2;
	if missing(N) then N=0;
	'Nombre et %'n = strip(put(N,best32.0)||' ('||strip(put(PctN_1110,best32.0))||'%)');
	if missing(value_mean) then "Score d'amélioration"n='/';
	else "Score d'amélioration"n=strip(put(value_mean,8.2));
run; 


/*
proc transpose data=Responders_proportion_2 out=Responders_proportion_3;
	by parameter product time CFB;
	var N PctN_1110 value_N value_Mean;
run;
*/

*Récupération de l effet moyen chez les tous les sujets;
data STAT_NUM_RAW2;
	set STAT_NUM_RAW;
	if statN in (11 12);
*	if statN = 11 then statN = 31;
*	if statN = 12 then statN = 32;
*	panel = 2;
run;

proc sql;
	create table Responders_proportion_4 as
	select a.*, strip(put(b.value_N,8.0)) as N, strip(put(b.value_Mean,8.2)) as Mean_effect
	from Responders_proportion_3 as a left join STAT_NUM as b
	on a.parameter=b.parameter and a.product=b.product and a.time=b.time 
	order by parameter, product, time, CFB;
quit;


proc transpose data=Responders_proportion_4 out=Responders_proportion_5;
	by parameter product time CFB;
	var 'Nombre et %'n "Score d'amélioration"n N Mean_effect;
run;

data Responders_proportion_5;
	set Responders_proportion_5;
	if _name_ in ('Nombre et %' 'N') then statN=31;
	else statN=32;
	if _name_ in ('Nombre et %' "Score d'amélioration") then Responder=1;
	else  Responder=2;
run;



*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
6.
	-	NOMBRE TOTAL DE SUJETS PAR PRODUIT

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~;

%do p=1 %to 1 /*&NOMBREPRODUITS*/;

	%global Nb_subjects_prod&p;

	proc sql;
		select distinct subject
		into : Nb_subject_prod&p
		from &table
		where product=&p
		group by parameter, product, time;
	quit;

%end;

	proc sql;
		create table sample_size as
		select distinct 
			parameter, 
			product,
			time, 
			strip(put(count(distinct subject),8.0)) as col1, 
			'Sample size' as stat,
			-8 as statN 
		from &table
		where product < 1000;
		;
	quit;

/*
	proc sql;
		create table time as
		select distinct parameter, product, time
		from dataset2;
	quit;

	proc sql;
		create table sample_size as 
		select *
		from time as a, sample_size as b 
		where a.parameter=b.parameter and a.product=b.product;
	quit;
*/


*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
7.
	-	RECUPERATION DES INFOS :
			PARAMETRE
			PRODUCT
			TIME

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~;

proc sql;
	create table PARA_PROD_TPS as 
	select distinct parameter, product, time,
		put(parameter,parameterf.) as parameterC,
		put(product,productf.) as productC,
		put(time, timef.) as timeC
	from &table;
quit;

proc transpose data=PARA_PROD_TPS out=PARA_PROD_TPS2;
	by parameter product time;
	var parameterC productC timeC;
run;

data PARA_PROD_TPS2;
	set PARA_PROD_TPS2;
	if index(_name_,'para') then statN=-9;
	if index(_name_,'prod') then statN=-7;
	if index(_name_,'time') then statN=-10;
 run;


*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
8.
	-	STOCKAGE DE TOUS LES RESULTATS DANS UNE TABLE

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~;

data &out.1;
	length stat $ 100 col1 $ 50;
	format statN statf. responder responderf.;
	drop stat test _label_ _name_ value;
	set __result  
		STAT_NUM7 
		__pvalue_4
		sample_size 
		Responders_proportion_5 
		/*Responders_mean_effect_3*/
		STAT_NUM_RAW
		PARA_PROD_TPS2;
run;


*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
9.
	-	AJOUT DES COMPARAISONS ENTRE PRODUIT EN COLONNE

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~;

data pvalue_comp_prod;
	drop product;
	set __pvalue_2;
	%if %eval(&nombreproduits>1) %then %do;
		if product > 1000;
	%end;
run;

proc sql;
	create table &out.2 as
	select a.*, b.test, b.pvalue as pvalue2, b.conclusion
	from &out.1 as a left join pvalue_comp_prod as b
	on a.parameter=b.parameter and a.time = b.time;
quit;
	 
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
11.
	-	AJOUT DES EFFET EN POURCENATGE EN COLONNE

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~;

proc sql;
	create table &out.3 as
	select *
	from &out.2 as a left join stat_num8 as b
	on a.parameter=b.parameter and a.time = b.time 
;
quit;

*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
10.
	-	AJOUT DES COMPARAISONS ENTRE PRODUIT EN COLONNE

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~;

data &out.4;
	set &out.3 Overall_Time_Effect5;
	*Variable charactère -> prob des formats audn n mélange les langue fr/ang;
	statC=put(statN,statf.);
run;

proc sort data=&out.4 out=&out;
	by parameter product time statN;
run;


*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
11. Affichage des différentes catégories pour la variable
	filtre STATN 
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~;

proc sql;	
	select distinct statN format 8.2, statN
	from &out;
quit; 


%mend;


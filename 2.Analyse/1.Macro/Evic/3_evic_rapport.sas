 
/*****************************************************************************************

NOM : %evic_rapport()

OBJET : analyse statistique des données issue de EVIC
		fournit une table SAS en sortie avec l emsenbles des statistiques 
		nécessaires aux différents rapport pour EVIC -> SNIFF TEST, SCORAGE, METROLOGIE 

REQUIERE : 	prend en entrée une table excel de données avec les variables suivantes	->
			PARAMETER/PRODUCT/TIME/SUBJECT/VALUE (issue de la macro %table()) 

MACRO DEPENDANCE : 	%evic_stat()
					%evic_analyse() -> à éxécuter avant
						
EXEMPLE D APPEL :	%evic_analyse(table=DATASET, dec=2,f=0, out=ANALYSE, non_parametric=oui, lang=ang);
					%evic_rapport(raw_data=DATASET, table_entree=ANALYSE);

ENTREE : table SAS 

SORTIE : rapport RTF

DATE : 	13/11/2020

DERNIERE MODIFICATION : 07/09/2021

AUTEUR : Cédric Jung - cju@dermscan.com

****************************************************************************************/;

*libname macro "D:\StructureEtude\0.XXEXXXX_Draft\2.Analyse\1.Macro";
options mstored sasmstore=macro;

%macro evic_rapport(raw_data=,table_entree=,rtf_sortie=&rtf_sortie) /store source;

title 'Analyse descripitive';
proc report data=&table_entree
	style(column)= [just=center cellwidth=0.6in  fontsize=8 pt font_face=tahoma];	
	where product < 1000 and statN in (11 12 13 13.5 14 15);
	column ("Parameter" parameter) ("Product" product) ("Time" time) statC, (col1 n);
	define parameter 	/ ' '	group order=internal style(column)=[just=left cellwidth=1in];
	define product 		/ ' '	group order=internal style(column)=[just=left cellwidth=1in];
	define time 		/ ' '	group order=internal style(column)=[just=left cellwidth=1in];
	define statC		/ ' '	across order=data;
	define col1 		/ ' ' 	display;
	define n 			/ 		noprint;
run;

title 'Effet temps global';
proc report data=&table_entree
	style(column)= [just=center cellwidth=1in  fontsize=8 pt font_face=tahoma];	
	where product < 1000 and (time=1 and statN=1)=1 or (test='Friedman');
	column statC (Parameter), (Product), (time), (col1 n);
	define statC		/ ' '	order group order=data;
	define parameter 	/ ' '	across style(column)=[just=left cellwidth=1in];
	define product 		/ ' '	across order=internal style(column)=[just=left cellwidth=1in];
	define time 		/ ' '	across order=internal style(column)=[just=left cellwidth=1in] f=GlobalTimef.;
	define col1 		/ ' ' 	display;
	define n 			/ 		noprint;
run;

%do par=1 %to &nombreParametres;
title "Variation par rapport à la valeur basale pour chaque produit - &&paraf&i";
proc report data=&table_entree
	style(column)= [just=center cellwidth=1in  fontsize=8 pt font_face=tahoma];		
	where product<1000 and time >1000 and statN in (-8 6.75 7 8) and parameter=&par;
	column  statC parameter, product, time, (col1 n);
	define statC 		/ ' ' 	group order=data;
	define parameter 	/' ' 	group across order=internal;
	define time 		/ ' '	group across order=internal;
	define product 		/ ' ' 	group across order=internal;
	define col1  		/ ' ' 	display ;
	define n			/ noprint;
run;
%end;

title 'Analyse comparative entre les produits';
proc report data=&table_entree
	style(column)= [just=center cellwidth=1in  fontsize=8 pt font_face=tahoma];		
	where product>1000 and (time=1 or time >1000) and statN in (-10 -9 -8 6.75 7 8);
	column statC product, parameter, time, (col1 n);
	define statC 	/ ' ' group order=data;
	define parameter /' ' group across order=internal;
	define time 	/ ' ' group across order=internal;
	define product 	/ ' ' group across order=internal;
	define col1  	/ ' ' display center ;
	define n		/ noprint;
run;

ods startpage=now;
title 'ANNEXE';
title2 'Global time effect - Friedman test';

proc freq data=&raw_data;
	where product < 1000 and time <1000;
	tables subject*time*value / CMH2 SCORES=RANK NOPRINT;
	by parameter product;
	format time GlobalTimef.;
	label value ='Score';
run;

ods startpage=now;
title1 'Pairwise comparison - Wilcoxon signed rank test';
proc univariate data=&raw_data normal;
	where time > 1;
	ods select testsforlocation /*testsfornormality*/;
	var value;
	class parameter time;
	label value ='Score';
run;
title;

/*
title 'Analyse comparative';

data test;
	set &table_entree;	
	if (statN in (2)) and (time > 1000);
*	if missing(pvalue2) then pvalue2=0;
*	if missing(pvalue) then pvalue=0;
run;

proc report data=test missing;	
	where (statN in (2)) and (time > 1000);
	column ("Parameter" parameter) ("time" time)  ("Variation moyenne" product), (col1 n) ("Test" test n)  ("p-value" pvalue2 n) ("Interprétation" conclusion n) ("Effect in %" percentage n);
	
	define parameter 	/ ' '	group order=internal ;	
	define time 		/ ' '	group order=internal ;

	define product 		/ ' '	across order=internal ;

	define col1 		/ ' '  display center;
	define n / noprint;
	define test 		/ ' '	group ;
	define n / noprint;
	define pvalue2 		/ ' '	group ;
	define n / noprint;
	define conclusion 	/ ' ' group ;
	define n / noprint;
	define percentage 	/ ' ' group ;
	define n / noprint;
run;


title 'Analyse sur les répondeurs';
proc report data=&table_entree;	

	where CFB=-1 and product >1000;

*	where statN in (11 21 22 23) and parameter =1 and product > 1000 and time >1000;
	
	column parameter product statn responder, time, (col1 n);
	
	define parameter 	/ ' '	group order=internal ;
	define product 		/ ' '	group order=internal ;
	define statN 		/ ' '	group order=internal left;
	define responder 	/ ' '	across order=internal ;
	define time 		/ ' '	across order=internal ;
	define col1 		/ ' ' 	display center;
	define n 			/ 		noprint;

run;


title 'Variation par rapport à la valeur basale pour chaque produit';
proc report data=&table_entree;	
	where product<1000 and time >1000 and statN in (-10 -9 -7 -8 6.75 7 8);
	column  statN parameter, product, time, (col1 n);
	define statN 	/ ' ' group order=internal;
	define parameter /' ' group across order=internal;
	define time 	/ ' '	group across order=internal;
	define product 	/ ' ' group across order=internal;
	define col1  	/ ' ' display ;
	define n		/ noprint;
run;

data tab;
	set &table_entree;
	if product>1000 and (time=1 or time >1000) and statN in (-10 -9 -8 6.75 7 8);
run;


ods  escapechar='^';

*footnote1 'Pour le parametre XXXX: ^2n on observe une diminution';*/
title;
%mend;



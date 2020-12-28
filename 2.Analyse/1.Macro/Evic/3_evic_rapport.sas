 
*****************************************************************************************

NOM : %evic_rapport()

OBJET : analyse statistique des données issue de EVIC
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



%macro evic_rapport(table_entree=,rtf_sortie=&rtf_sortie) /store source;

ods rtf file="&rtf_sortie" notoc_data nogtitle contents=yes bodytitle startpage=no style=sty.s4;

proc sql;	
	select distinct statN format 8.2, statN
	from &table_entree;
quit; 

ods rtf style=sty.s4;

title 'Analyse descripitive';
proc report data=&table_entree;	
	where statN in (11 12 13 14 15);
	column parameter product time statN, (col1 n);
	
	define parameter 	/	group order=internal ;
	define product 	/	group order=internal ;
	define time 	/	group order=internal ;
	define statN	/	across order=internal ;
	define col1 / ' ' display;
	define n / noprint;
run;

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
	define col1 		/ ' ' display center;
	define n 			/ noprint;

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

ods rtf style=sty.s4;
title 'Analyse comparative entre les produits';
proc report data=tab
	style(column)= [cellwidth=1.2in /*fontsize=10pt font_face=arial*/];

*	where product>1000 and (time=1 or time >1000) and statN in (-10 -9 -8 6.75 7 8);

	column  statN product, parameter, time, (col1 n);
	define statN 	/ ' ' group order=internal;
	define parameter /' ' group across order=internal;
	define time 	/ ' '	group across order=internal;
	define product 	/ ' ' group across order=internal;
	define col1  	/ ' ' display center ;
	define n		/ noprint;
run;
footnote1 'Pour le parametre XXXX: ^2n on observe une diminution';
ods rtf close;


%no_section(&rtf_sortie);


%mend;



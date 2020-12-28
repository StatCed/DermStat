

 
*#############################################################

PROGRAMME : A1_20E3034.sas

OBJET: Analyse statistique de la table de données D1_20E3034

DATE :

AUTEUR :

#############################################################;



**************************************************************
Chargement du pilote
;

%macro chargement_pilote();

%if %symexist(chargement) = 0 %then %do; 
	*Driver;
	%include "D:\Statistiques\Data_SAS\2020\Givaudan\20E3034\2.Analyse\0.Driver.sas";
		%global chargement;
		%let chargement	= OK;
%end;

%mend;

%chargement_pilote();

**************************************************************
Chargement des macro-variables crées par la macro TABLE()
;

%environnement(f=env.F1_20E3034, table=env.E1_20E3034);


**************************************************************
Declaration des macro-variables
;

%let DATASET=lib.D1_20E3034;
%let RTF=A1_P2362vsRef1012;


**************************************************************
Nettoyage de la table de données
;

*
Suppression des variations relatives 
Suppression des comparaisons entre produits
Suppression des compraison entre les temps post basales
;

data G1;
	drop type;
	set &DATASET;
	if type ne 'rel'; 
*	if product < 1000; 
	if time < 2000;
run;





/*1. Normalité*/
proc sort data=G1 
	out=tab; 
	by parameter product time;

proc univariate data=tab normal;
ods output testsfornormality=testsfornormality;
ods select testsfornormality;
where time < 1000 and product < 1000;
	var value;
	class  product time;
	by parameter;
run;

proc sort data=testsfornormality 
	out=testsfornormality_2; 
	by parameter product time;
	where test='Shapiro-Wilk';
run;

data testsfornormality_3;
	length Normality $ 50;
	set testsfornormality_2;
	if pValue=. then Normality='NA';
	else if pValue < 0.05 then Normality='No';
	if pValue > 0.05 then Normality='Yes';
	label normality='Normality assumption';
run;

proc sql;
	select count(Normality) as Nb_of_deviation
	into : Nb_of_deviation
	from testsfornormality_3
	where Normality='No';
quit;





/*2. Comparaisons*/
proc univariate data=tab normal;
ods select testsforLocation basicmeasures;
ods output testsforLocation=testsforlocation basicmeasures=basicmeasures;
where time > 1000 /*and product < 1000*/;
	var value;
	class  product time;
	by parameter;
run;

data basicmeasures;
	keep parameter time product Mean_SD locValue;
	set basicmeasures;
	Mean_SD = strip(put(locValue,8.1)) ||' (' ||  strip(put(varValue,8.1)) ||')';
	if LocMeasure = 'Mean';
run;

data testsforlocation;
	set testsforlocation;
	keep parameter product time Test pValue;
run;

proc sort data=testsforlocation 
	out=testsforlocation;
	by parameter product time test;
proc transpose data=testsforlocation 
	out=testsforlocation;
	id test;
	by parameter product time;
	var pvalue;
	where test ne 'Sign';
run;

data testsforlocation;
	set testsforlocation;
	drop _name_ _label_;
run;

/*Jointure des tables de tests de Shapiro-Wilk avec testt/Wilcoxon*/
proc sql;
	create table comparison as
	select *
	from basicmeasures as a, testsforlocation as b
	where a.parameter=b.parameter  and a.product=b.product and a.time=b.time ;
	;
quit;


/*Choix du test entre Student et Wilcoxon en fonction du Shapiro-Wilk à 0.05*/
data comparison_2;
	set comparison;
	drop time product;
	rename timeN=time productN=product;

	Nb_of_deviation=input(symget('Nb_of_deviation'),8.0);
	if Nb_of_deviation > 0 then  normalite='non';
	else if Nb_of_deviation = 0 then  normalite='oui';

	if 	normalite='oui' then do;
		test = "Student's t";
		pvalue="Student's t"n;
	end;
	else if normalite='non' then do;
		test = "Wilcoxon";
		pvalue="Signed Rank"n;
	end;

	else 	pvalue=9999;

	format pvalue pvalue8.4 'One tailed test'n pvalue8.4;
	timeN=input(time,timef.);
	productN=input(product,productf.);
	format timeN timef. productN productf.;

	if productN < 1000 then 'One tailed test'n = pvalue / 2;
	else if productN > 1000 then do;
		if locValue > 0 then do;
			 'One tailed test'n = pvalue / 2;
		end;
		if locValue < 0 then do;
			 'One tailed test'n = 1 - (pvalue / 2);
		end;
	end;
run;






%macro boucle(table=G1, deb=, fin=, dec=,f=0);

	%do i=&deb %to &fin;

%title(title=&i. &pf1 vs &pf2 ,level=1);

%title(title=&i..1 Descriptive statistics, level=2);

			%Stat(table=&table,
				numParametre=&i 	,
				format=8.&dec, 
				sortieBrute= n		,
				TableauRapport= o	,
				Plan = &planExperimental,
				stat =  1 2 3 4 6 7,
				lang = fr,
				tempsAvecComparaison=%str(time<1000 and product<1000 and statN ne 7),
				leg=N
			); 


%let f=%eval(&f+1);
%figure(title=Figure &f.. Box-plot of raw &&paraf&i value, level=1);

title1 f=calibri h=10 pt j=left "The figure below shows the distribution of %lowcase(&&paraf&i) for each time point by zone.";  

			data box_plot;
				set &table;
				if time < 1000 and product < 1000 and parameter=&i;
			run; 

			%distribution2(table=box_plot,para=&i);
title;

%title(title=&i..2 Normality test for raw data distribution, level=2);

proc print data=testsfornormality_3 noobs;
	var product time Test pValue Normality;
run;
	

%let f=%eval(&f+1);
%figure(title=Figure &f.. Change over time in &&paraf&i value, level=1);

			%evolution(
				table=&table,
				para=&i,
				echX=/*%str(values=(1 to 12 by 1) fitpolicy=rotate)*/,
				echY=/*%str(values=(0 to 10 by 1))*/,
				labX=Time,
				labY=%str(&&paraf&i (*ESC*){unicode '000a'x}(mean ± 2*SEM)),
				labGp=Product,
				title=	%str(The figure below shows the evolution of the average value for the %lowcase(&&paraf&i) (± 2*SEM) over time, by zone.),
				ft=timef.
			);

%title(title=&i..3 Change from baseline, level=2);	

proc print data=comparison_2 noobs;
var product time Mean_SD test  'One tailed test'n;
where product <1000;
run;

%title(title=&i..4 Test of superiority, level=2);	

proc print data=comparison_2 noobs;
var product time Mean_SD test  'One tailed test'n;
where product >1000;
run;


ods rtf startpage=now;

	%end;

%mend;



ods rtf file="&output.&rtf..rtf" notoc_data nogtitle contents=yes bodytitle startpage=no style=sty.s4;

%boucle(deb=1, fin=1, dec=2);

ods rtf close;

%no_section(&output.&rtf..rtf);



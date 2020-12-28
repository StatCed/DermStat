%macro chargement_pilote();

%if %symexist(chargement) = 0 %then %do; 
	*Driver;
	%include "d:\Statistiques\Data_SAS\2019\GIVAUDAN\19E2758\2.Analyse\0.Driver.sas";
		%global chargement;
		%let chargement	= OK;
%end;

%mend;

%chargement_pilote();

%environnement(f=env.F_19E2758, table=env.E_19E2758);

%let rtf=1.Analyse test unilateral;
%let data=tab;

*
Suppression des variations relatives 
Suppression des comparaisons entre produits
Suppression des compraison entre les temps post basales
;

data &data;
	drop type;
	set lib.D_19E2758;
	if type ne 'rel'; 
	if product < 1000; 
	if time < 2000;
run;

ods rtf file="&output.0.Exploration.rtf" notoc_data nogtitle bodytitle startpage=no;
options mprint symbolgen mlogic; 
%extremeV0_2 (table=tab,para=);
ods rtf close;
/****************************
*****************************
*****************************
****************************/

proc sort data=tab out=t_tab;
	by parameter time product;
run;


/*Normalité*/
ods output testsfornormality=testsfornormality;

proc sort data=tab 
	out=tab; 
	by parameter product time;

proc univariate data=tab normal;
ods select testsfornormality;
where time < 1000 and product < 1000;
	var value;
	class  product time;
	by parameter;
run;

proc sort data=testsfornormality 
	out=testsfornormality; 
	by parameter product time;
proc transpose data=testsfornormality 
	out=testsfornormality;
	where test='Shapiro-Wilk';
	var pvalue;
	id time;
	by parameter product;
run;
	
data testsfornormality;
	set testsfornormality;
	drop _name_ _label_;
	if (t0 < 0.05 or t1 < 0.05 or t2 < 0.05) 			then normalite='non';
	else if (t0 > 0.05 and t1 > 0.05 and t2 > 0.05) 	then normalite='oui';
run;


/*Comparaison par rapport à la valeur basale*/
proc univariate data=tab normal;
ods select testsforLocation basicmeasures;
ods output testsforLocation=testsforlocation basicmeasures=basicmeasures;
where time > 1000 and product < 1000;
	var value;
	class  product time;
	by parameter;
run;

data basicmeasures;
	keep parameter time product Mean_SD;
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
	create table CFB as
	select *
	from testsfornormality as a, testsforlocation as b
	where a.parameter=b.parameter and a.product=b.product ;
	;
	create table CFB as
	select *
	from basicmeasures as a, CFB as b
	where a.parameter=b.parameter and a.product=b.product and a.time=b.time ;
quit;


/*Choix du test entre Student et Wilcoxon en fonction du Shapiro-Wilk à 0.05*/
data CFB;
	set CFB;
	drop time product;
	rename timeN=time productN=product;
	if 		normalite='oui' then do;
		test = "Student's t";
		pvalue="Student's t"n;
	end;
	else if normalite='non' then do;
		test = "Wilcoxon";
		pvalue="Signed Rank"n;
	end;

	else 	pvalue=9999;

	format pvalue pvalue8.4;
	timeN=input(time,timef.);
	productN=input(product,productf.);
	format timeN timef. productN productf.;
run;

title "Shapiro-Wilk tests sur les données brutes";
proc print data=CFB;
run;
title;


ods rtf file="&output.2.Change from baseline mesures.rtf" style=sty.s4;
proc print data=CFB;
var parameter product time mean_sd test pvalue;
format pvalue pvalue8.4;
run;
ods rtf close;


*################################################################
# 
# Comparaison des produits entre eux sur les variations (Di-t0)
#
#################################################################;
ods trace on;


*Test unilatéral 1;

/*
%let comp=lower_1;
%let hypothese_H1=l;
%let produitsCompares = 
*/

%macro testt(table=tab, comp= ,hypothese_H1= , produitsCompares=, comparaison= );

proc sort data=&table 
	out=t_&table;
	by parameter time;

ods output statistics=__stat_&comp 
		   ttests=__test_&comp 
		   equality=__equa_&comp;
proc ttest data=t_&table sides=&hypothese_H1;
	var value;
	class product;
	where product in (&produitsCompares) and time > 1000;
	by parameter time;
run; 

*Nettoyage et combinaison des tables;
data __stat_&comp;
	keep parameter time product mean stderr ;
	set __stat_&comp;
	product = &comparaison ;
	format product productf.;
	if index(class,'Diff');
run;

proc transpose data=__test_&comp 
out=__test_&comp (drop=_name_ _label_) 
prefix=TestT_&comp._;
	id variances;
	var probt;
	by parameter time;
run;

data __equa_&comp;
	set __equa_&comp;
	keep parameter time ProbF;
	rename probF=EgaliteVar_&comp;
run;

data testT_&comp;
	set __stat_&comp;
	set __equa_&comp;
	set __test_&comp;
	by parameter time;
	if EgaliteVar_&comp > 0.05 then testT_&comp = testT_&comp._Equal;
	else if EgaliteVar_&comp < 0.05 then testT_&comp = testT_&comp._Unequal;
run;

%mend;

options mprint mlogic symbolgen;


%testt(table= tab, comp = lower,hypothese_H1 = l, 	produitsCompares = 1 2, comparaison = 1102);
%testt(table= tab, comp = upper,hypothese_H1 = u, 	produitsCompares = 1 2, comparaison = 1102);
%testt(table= tab, comp = twoSide,hypothese_H1 = 2, produitsCompares = 1 2, comparaison = 1102);

data testT;
drop
EgaliteVar_lower
TestT_lower_Equal
TestT_lower_Unequal
EgaliteVar_upper
TestT_upper_Equal
TestT_upper_Unequal
EgaliteVar_twoSide
TestT_twoSide_Equal
TestT_twoSide_Unequal
;
	merge testT_lower 
	testT_upper 
	testT_twoside;
	by parameter product time  mean StdErr ;
run;


ods rtf style=sty.s4;
proc print data=CFB;
	var parameter product time Mean_SD test pvalue;
run;

proc print data=testT;
run;

proc sort data=testT out=testT; by parameter time product;
proc sort data=CFB out=CFB; by parameter time product;
data testT2;
	merge testT CFB;
	by parameter time;
run;


%macro MannWhitney(table=t_tab,sortie=,hypothese_H1= , produitsCompares= );

%let Pnum1 = %scan(&produitsCompares,1); 
%let Pnum2 = %scan(&produitsCompares,2);
%let comp = %eval(1000 + &Pnum1 * 100 + &Pnum2);

proc sql;
	select distinct product 
	into : Produit1-:Produit2
	from &table
	where product in (&produitsCompares)
;
quit;

proc npar1way data=&table wilcoxon;
ods output 	WilcoxonScores=WilcoxonScores WilcoxonTest=WilcoxonTest;
	where product in (&produitsCompares) and time > 1000;
	by parameter time;
	var value;
	class product;
run;

proc sort data=WilcoxonScores out=WilcoxonScores;
	by parameter time 'Class'n;
proc transpose data=WilcoxonScores out=WilcoxonScores;
	var n--MeanScore ;
	by parameter time 'Class'n;
run;

proc transpose data=WilcoxonScores out=WilcoxonScores delim=_;
	id class _name_ ;
	var col1;
	by parameter time;
run;

proc sort data=WilcoxonTest out=WilcoxonTest;
	by parameter time name1;
proc transpose data=WilcoxonTest out=WilcoxonTest (drop=_name_);
	var nValue1 ;
	by parameter time ;
	id name1;
	where name1 in('_WIL_' 'Z_WIL' 'PR_WIL' 'PL_WIL' 'P2_WIL');
run;

options mlogic mprint;
data MannWhitney&comp;
	drop _name_;
	set WilcoxonScores;
	set WilcoxonTest;
	by parameter time;
	product=&comp;
	Hypothese_H1="&Hypothese_H1";

	/*Calcul de la statistique U*/
	&Produit1._U = &Produit1._SumOfScores - (&Produit1._N * (&Produit1._N + 1) / 2 ); 
	&Produit2._U = &Produit2._SumOfScores - (&Produit2._N * (&Produit2._N + 1) / 2 ); 

	&Produit1._Den_z = &Produit1._U - (&Produit1._N * &Produit2._N / 2 ); 
	&Produit2._Den_z = &Produit2._U - (&Produit1._N * &Produit2._N / 2 ); 

	&Produit1._Diff = &Produit1._SumOfScores - &Produit1._expectedsum;
	&Produit2._Diff = &Produit2._SumOfScores - &Produit2._expectedsum;

	choice=_wil_;

run;

data MannWhitney_&sortie._&comp;

	set MannWhitney&comp;
	
	*On teste quel produit est utilisé pour le calcul de la statistique U
	et l effet attendu; 

	MannWhitney_TwoSide=P2_WIL;

	if z_wil = 0 then do;
			MannWhitney_lower=0.5;
			MannWhitney_upper=0.5;	
	end;

	if (&Produit1._SumOfScores = _wil_) then do;
		if Hypothese_H1='P1<P2' then do;
			if Z_wil < 0 then do; 
				MannWhitney_lower = pl_wil;
				MannWhitney_upper = 1-pl_wil;
			end;
			if Z_wil > 0 then do;
				MannWhitney_lower = 1-pr_wil;
				MannWhitney_upper = pr_wil;
			end;
		end;
		if Hypothese_H1='P1>P2' then do;
			if Z_wil < 0 then do; 
				MannWhitney_upper = 1-pl_wil;
				MannWhitney_lower = pl_wil;
			end;
			if Z_wil > 0 then do;
				MannWhitney_upper = pr_wil;
				MannWhitney_lower = 1-pr_wil;
			end;
		end;
	end;

	if (&Produit2._SumOfScores = _wil_) then do;
		if Hypothese_H1='P1<P2' then do;
			if Z_wil < 0 then do; 
				MannWhitney_upper= pl_wil;
				MannWhitney_lower = 1-pl_wil;
			end;
			if Z_wil > 0 then do;
				MannWhitney_upper = 1-pr_wil;
				MannWhitney_lower = pr_wil;
			end;
		end;
		if Hypothese_H1='P1>P2' then do;
			if Z_wil < 0 then do; 
				MannWhitney_lower = 1-pl_wil;
				MannWhitney_upper = pl_wil;
			end;
			if Z_wil > 0 then do;
				MannWhitney_lower = pr_wil;
				MannWhitney_upper = 1-pr_wil;
			end;
		end;
	end;

run;

%mend;


options mprint symbolgen mlogic;
%MannWhitney(table=t_tab,
sortie=P1supP2	,
hypothese_H1=P1>P2, 
produitsCompares=1 2 );

%MannWhitney(table=t_tab,
sortie=P1infP2	,
hypothese_H1=P1<P2, 
produitsCompares=1 2 );

proc contents data=MannWhitney_P1supP2_1102 order=varnum;
proc contents data=MannWhitney_P1infP2_1102 order=varnum;


data MannWhitney;
	keep 
parameter product time 
Hypothese_H1
MannWhitney_TwoSide
MannWhitney_lower
MannWhitney_Upper
;
set MannWhitney_P1supP2_1102 MannWhitney_P1infP2_1102;
run;

/*
data MannWhitney2;
	set MannWhitney;
	keep parameter product time MannWhitney_lower;
run; 
*/

proc sort data=testt out=testt; by parameter product time;
proc sort data=MannWhitney out=MannWhitney; by parameter product time;
	

proc sort data=testsFornormality out=testsFornormality2;
	by parameter product;
proc transpose data=testsFornormality2 out=testsFornormality2;
	id product;
	var normalite;
	by parameter;
run;

data testsFornormality2;
	drop _name_;
	set testsFornormality2;
	if ( &p1 = "non" or &p2 = "non")  then Normalite = 'non';
	else Normalite = 'oui'; 
run;


data FINAL;
	*merge testsFornormality2;
	merge testt mannWhitney;
	by parameter product time;
run;

proc sql;
	create table final as
	select *
	from testsFornormality2 as a, FINAL as b
	where a.parameter = b.parameter
	;
quit;

proc contents data=final;
run;

data final;
keep
parameter
Hypothese_H1
objective
Normalite
time
product
Mean


StdErr
testT_lower
testT_upper
testT_twoSide
MannWhitney_TwoSide
MannWhitney_lower
MannWhitney_Upper
test2
p_value
;
	retain
parameter
Hypothese_H1
objective
Normalite
time
product
Mean
StdErr
testT_lower
testT_upper
testT_twoSide
MannWhitney_TwoSide
MannWhitney_lower
MannWhitney_Upper
/*test2
p_value*/
;
set final;
/**Création de la variable objective de l'étude. Mis à jour pour chaque étude**/
select;
when(parameter in (3,4,5)) do; objective="Increase"; end;
when(parameter in (1,2)) do; objective="Decrease"; end;
otherwise objective= " ";
end;

run;

/****/
/*Sélection des tests appropriés en fonction de l'hypothèse, de l'objectif et de la normalité*/

data final1 (keep=parameter time product  Normalite objective Hypothese_H1 Mean StdErr teststat Side pvalue);
length teststat $ 30;
set final;
select;									
when( Normalite="oui" and	objective="Increase" and	Hypothese_H1="P1>P2")	do;	teststat="testT";	Side="Upper";	pvalue=testT_upper;	output;	end;
when( Normalite="oui" and	objective="Decrease" and	Hypothese_H1="P1<P2")	do;	teststat="testT";	Side="Lower";	pvalue=testT_lower;	output;	end;
when( Normalite="non" and	objective="Increase" and	Hypothese_H1="P1>P2")	do;	teststat="MannWhitney";	Side="Upper";	pvalue=MannWhitney_upper;	output;	end;
when( Normalite="non" and	objective="Decrease" and	Hypothese_H1="P1<P2")	do;	teststat="MannWhitney";	Side="Lower";	pvalue=MannWhitney_lower;	output;	end;
otherwise 	do;	teststat=" " ;	Side=" " ;	pvalue=. ; delete;	end;			
end;	
run;

data final2;
set final1;
teststat2=cats(teststat,"_",Side);
statn=cats(round(Mean,0.01)," ( ",round(StdErr,0.01),")");
select;
when(teststat2="testT_Upper") do; pvalue2=cats(round(pvalue,0.0001),'µu'); end;
when(teststat2="testT_Lower") do; pvalue2=cats(round(pvalue,0.0001),'µl'); end;
when(teststat2="MannWhitney_Upper") do; pvalue2=cats(round(pvalue,0.0001),'§u'); end;
when(teststat2="MannWhitney_Lower") do; pvalue2=cats(round(pvalue,0.0001),'§l'); end;
otherwise pvalue2=" "; end;
	            /*line 'µu unpaired t-test upper';
				line 'µl unpaired t-test lower';
				line "§u Mann-Whitney test upper";
				line "§l Mann-Whitney test lower";*/
run;

/*--------------------------Reporting-------------------------------------*/

 
ods rtf file="&output.&rtf..rtf" notoc_data nogtitle bodytitle startpage=no style=sty.s4;

proc format;
	value color
		1="#3F9EA9"
		2="#C2C2FE"
	;
run;

    %Let pol = calibri;
	%let tail = 8;
	%let larg = 0.8;

proc report data= final2 out= report_final1

		style(report)= [frame=box rules=cols cellspacing=0 font_face=&pol fontsize=&tail pt]
		style(header)= [ BACKGROUND=/*#D9D9D9*/ #BBE1E6 font_weight=bold fontsize=&tail pt font_face=&pol cellspacing=0]
		style(column)= [cellwidth=&larg.in  fontsize=&tail pt font_face=&pol]
;

		column ("Unilateral tests" parameter product time  statn pvalue2);
		
		define parameter 	/ "Parameter" order=internal group left style=[backgroundcolor=#BBE1E6 /*#3F9EA9*/];
        define product 		/ "Comparison " order=internal left f=productf. GROUP;
		define time 		/ "Time " order=internal left ;
		define statN 		/ "Mean(SEM)" order=internal  left ;
		define pvalue2		/ "P-value" order=internal  Right;

/*----------------------*/
		compute after _page_ /left style={font_face=arial fontsize=6pt color=blue /*bordertopcolor=#3F9EA9*/ bordertopwidth=1};
				line 'µu unpaired t-test upper';
				line 'µl unpaired t-test lower';
				line "§u Mann-Whitney test upper";
				line "§l Mann-Whitney test lower";
		endcomp;

run;


proc print data=final;run;

ods rtf close;
%no_section(&output.&rtf..rtf);
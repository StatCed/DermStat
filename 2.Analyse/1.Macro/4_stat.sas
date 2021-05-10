

options mstored sasmstore=macro;

%macro stat
(
	table=,
	numParametre=,
	format=8.2,
	sortieBrute=n,
	tableauRapport=o,
	Plan=,
	test=,
	tempsAvecComparaison=,
	stat=,
	pol=calibri,
	tail=8,
	larg=0.8,
	lang=ang,
	leg=Y,
	out=__result,
	debug=Y,
	libFormat=work
	rtf=N
) 
/ STORE SOURCE DES="v21.05.10";



*--------------------------------------------------
Avertissement la normalité n est plus vérifiée,
le paramètre test est fixé sur STUDENT ou WILCOXON;
%if %length(&test) ne 0 %then %do;
	%put ERROR: Attention paramètre test fixé sur &test;
%end;


proc format library = &libFormat;
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
		'IC'	= 6.5 
		'pvalueC'	= 7
;

%if %upcase(&lang) = ANG %then %do;
	value statf
		1 	= 'N (miss)'
		2 	= 'mean (SD)'
		2.5 = 'Mean ± SEM'	
		3 	= 'SEM'
		4 	= 'median'
		4.5 = 'CV'
		5 	= 'Q1 ; Q3'
		5.5 = 'IQR'
		6 	= 'min ; max'
		6.5 = '95% CI'
		7 	= 'p-value'
	;
%end;
%else %do;
	value statf
		1 	= 'N (VM)'
		2 	= 'moy (ET)'
		2.5 = 'Moy ± ESM'	
		3 	= 'ESM'
		4 	= 'médiane'
		4.5 = 'CV'
		5 	= 'Q1 ; Q3'
		5.5 = 'EI'
		6 	= 'min ; max'
		6.5 = 'IC 95%'
		7 	= 'p-value'
	;
%end;
	value significativityf
		1	=	'Yes'
		0	=	'No'
;
	value $testf
		'Signed Rank'	=	'Wilcoxon'
		"Student's t"	=	'Student'
;
run;





*-----------------------------------------------------------------
On supprime les sorties des
procédures 
;
%if %index(%upcase(&rtf),N) ne 0 %then %do;
	ods rtf exclude all;
%end;












*----------------------------------------------------------------
Analyse du paramètre sélectionné si numParametre a une valeur 
		sinon analyse de tous les paramètres
;

%if %length(&numParametre) ^= 0 %then %do;
	%let __selection_parametres =%str(if parameter in (&numParametre));
%end;
%else %do;
	%let __selection_parametres =%str() ;
%end;





************************************************************

2. CREATION D UNE TABLE AVEC LES STATISTIQUES DESCRIPTIVES

************************************************************;

data __&table;
	set &table;
	&__selection_parametres;
run;

ods output table=__DESC;

proc tabulate data=__&table order=unformatted;

*	where ( time < 1000 and product < 1000 ) = 1 or (time > 1000);

	class parameter time  product;
	var value;
	table parameter=' '*time=' '*value=' '*(n nmiss mean median stderr std q1 q3 Qrange min max LCLM UCLM CV), product ;

run; 

*
Table avec les valeurs au format numériques;

data Stat_num;
	set __DESC;
run;


%macro Pourcentage_Amelioration();
		*
		Calcul des pourcentages moyen d amélioration sur les moyennes observées;
		proc sort data=Stat_num out=pourcentage_amelioration;
			by parameter product time;
			where time < 1000 and product <1000;
		proc transpose data=pourcentage_amelioration out=pourcentage_amelioration prefix=P delim=_t;
			var value_Mean;
			by parameter;
			id product time;
			format product 8.0 format time 8.0;
		run;

		data pourcentage_amelioration;
			set pourcentage_amelioration;
			%do produit=1 %to &NOMBREPRODUITS;
			%do temps=2 %to &NOMBRETEMPS;
			"Pourcentage_&&P&Produit.._&&t&temps.._&t1"n	= ("p&produit._t&temps"n - "p&produit._t1"n) / "p&produit._t1"n;
			%end;
			%end;
		run;

		data pourcentage_amelioration;
			set pourcentage_amelioration;
			%do produit1=1 %to %eval(&NOMBREPRODUITS-1);
				%do produit2=%eval(&produit1+1) %to &NOMBREPRODUITS;
					%do n=2 %to &NOMBRETEMPS;
					"Pourcentage_&p1._&p2._&&t&n.._&t1"n	= 	"Pourcentage_&&P&Produit1.._&&t&n.._&t1"n - "Pourcentage_&&P&produit2.._&&t&n.._&t1"n;
					*	"&&Pf&produit1 - &&Pf&produit2 pour (&&t&n - &t1)"n	= 	Pourcentage_P&Produit1._t&n._t1 - Pourcentage_P&produit2._t&n._t1;
					%end;
				%end;
			%end;
		run;
%mend;
*
%Pourcentage_Amelioration();



*--------Mise en forme de la table------------------------------------------------;

data __DESC;

	set __DESC;

	N_VM = strip(put(value_N,8.0))||' ('||strip(put(value_nmiss,8.0))||')';
	M_EC = strip(put(value_mean,&format))||' ('||strip(put(value_std,&format))||')';
	ESM  = strip(put(value_stderr,&format));
	Med  = strip(put(value_median,&format));
	Q1_Q3  	= strip(put(value_q1,&format))|| ' ; '||strip(put(value_q3,&format));
	Range = strip(put(value_min,&format)) || ' ; '||strip(put(value_max,&format));
	IC = '('||strip(put(value_LCLM,&format)) || ' ; '||strip(put(value_UCLM,&format))||')';
	CV = strip(put(value_CV,8.1));
	Qrange = strip(put(value_qrange,&format));
	/*Format Moy ± SEM*/ 
	M_ESM = strip(put(value_mean,&format))||' ± '||strip(put(value_stderr,&format));

run;




*-------Transposition en long pour impression (PROC REPORT)---------------;

proc sort data=__DESC out=__DESC; 
	by parameter product  time ;
run;


proc transpose data=__DESC out=__DESC name=stat; 
	by parameter product  time ;
	var N_VM--M_ESM;
run;





***************************************************************************
	2. TEST T DONNES APPARIES / WILXOXON / SHAPIRO-WILK
;

proc sort data=__&table out=__&table; by parameter product time; run;

%if ( %index(%upcase(&sortieBrute),N) and %index(%upcase(&rtf),N) ne 0 ) %then %do;
	ods rtf exclude all; %end;
%else %if %index(%upcase(&rtf),N) ne 0 %then %do; 
	ods rtf select all; %end;


ods output testsfornormality=__NORM testsforlocation=__LOC;

proc univariate data=__&table normal;
/*&tempsAvecComparaison*/ ; 
ods exclude Moments /*BasicMeasures  TestsForLocation*/ Quantiles ExtremeObs MissingValues ParameterEstimates GoodnessOfFit FitQuantiles;
  var value;
  by parameter product time;
run;



*----Table avec choix du test statistique en fonction du Shapiro-Wilk-----;

proc sql noprint;
	create table __COMP as
	select  a.parameter, 
			a.product, 
			a.time, 
			a.product, 
			a.testlab, 
			b.testlab, 
			a.pvalue as shapiro, 
			b.pvalue as pvalue,
			b.test,
			/*calculated pvalueC as stat,*/

			%if %length(&test)=0 %then %do;
				case 
					when a.pvalue > 0.01 and b.testlab='t' then 1 
					when a.pvalue <= 0.01 and b.testlab='t' then 0 
					when a.pvalue > 0.01 and b.testlab='S' then 0 
					when a.pvalue <= 0.01 and b.testlab='S' then 1 
					else 0
				end as bool,
			%end;

			%if %index(%upcase(&test),W) %then %do;
				case 
					when a.pvalue > 0.01 and b.testlab='t' then 0 
					when a.pvalue <= 0.01 and b.testlab='t' then 0 
					when a.pvalue > 0.01 and b.testlab='S' then 1 
					when a.pvalue <= 0.01 and b.testlab='S' then 1 
					else 0
				end as bool,
			%end;

			%if %index(%upcase(&test),T) %then %do;
				case 
					when a.pvalue > 0.01 and b.testlab='t' then 1 
					when a.pvalue <= 0.01 and b.testlab='t' then 1 
					when a.pvalue > 0.01 and b.testlab='S' then 0 
					when a.pvalue <= 0.01 and b.testlab='S' then 0 
					else 0
				end as bool,
			%end;
				case 
					when b.testlab='t' and b.pvalue ne . then strip(put(b.pvalue,pvalue8.4)||'°')
					when b.testlab='S' and b.pvalue ne . then strip(put(b.pvalue,pvalue8.4)||'*')
					else 'na'
				end as pvalueC

	from __NORM as a, __LOC as b

	where (a.parameter = b.parameter) 
			and (a.product=b.product) 
			and (a.time=b.time) 
			and calculated bool=1
;
quit; 

proc sort data=__COMP out=__COMP; 
		where testlab='W'; by parameter product time ;

proc transpose data=__COMP out=__PVALUE 
	(rename=(col1=pvalue )) name=stat;
	var pvalue;
	by parameter product time test;
run;

proc transpose data=__COMP out=__COMP  name=stat;
	var pvalueC;
	by parameter product time ;
run;

proc print data=__comp;
run;
proc print data=__pvalue;
run;


*--------Création de la variable numérique produit-------------------------------------;

data __RESULT;

	set __DESC __COMP;

	statN = input(stat,statf.);
	format statN statf. time timef.;

		%do a = 1 %to &NombreProduits;
				if index(upcase(product), upcase("&&p&a")) ne 0 then do; 
					product = &a; 
				end;
		%end;

		%do a=1 %to %eval(&NombreProduits-1);
			%do b=%eval(&a+1) %to &NombreProduits;
				if index(upcase(product), upcase("&&p&a.._&&p&b")) ne 0 then product=%sysevalf(1000+100*&a+&b);
			%end;
		%end;

run;


*-----------Ajout de la variable pvalue numérique------------------------;

*Liaison avec la table contenant les pvalue numérique;
proc sql;
	create table &out as 
	select *
	from __RESULT as a left join __PVALUE as b
	on a.parameter=b.parameter and a.product=b.product and a.time=b.time
	;
quit;








**************************************************************************
	3. CAS OU LE PLAN EXPERIMENTAL = GROUPE PARALLELE
;

%if  %index(%upcase(&plan,P)) %then %do;

	%let comp=0;

	%do produit1=1 %to %eval(&nombreproduits-1);

		%do produit2=%eval(&produit1+1) %to &nombreproduits; 	
	
		%let comp=%eval(&comp+1);

*------------------------------------------------------------------------
			test t pour échantillons indépendant
;

	proc sort data=__&table out=__&table; by parameter time product; 

	ods output statistics=__stat_para&comp 
				ttests=__test_para&comp 
				equality=__equa_para&comp;

	proc ttest data=__&table;
		where product in (&produit1 &produit2);
		var value;
		class product ;
		by parameter time;
	run;


	proc sql;

		create table __Unpairedttest&comp as
		select a.parameter, a.time, a.class, a.mean, a.stddev, a.stderr, b.variances, b.probt
		from __stat_para&comp as a, __test_para&comp as b
		where (a.parameter = b.parameter) and (a.time=b.time)and class='Diff (1-2)'
	;

		create table __UnpairedTtest&comp as
		select a.parameter, a.time, a.class, a.mean, a.stddev, a.stderr, a.variances, a.probt, b.probf,
		case	
			when b.probf < 0.05 and a.variances='Equal' 	then 0
			when b.probf >= 0.05 and a.variances='Equal' 	then 1  
			when b.probf < 0.05 and a.variances='Unequal' 	then 1
			when b.probf >= 0.05 and a.variances='Unequal' 	then 0
		end as bool
		from __UnpairedTtest&comp as a, __equa_para&comp as b
		where (a.parameter = b.parameter) and (a.time=b.time) and calculated bool=1
	;

	quit;


*------------------------------------------------------------------------
			test de Mann-Whitnney
;

	ods output wilcoxontest=__MannWhitney&comp;
	proc npar1way data=__&table wilcoxon;
		where product in (&produit1 &produit2) ;
		var value;
		class product ;
		by parameter time;
	run;

	data __MannWhitney&comp;
		rename nvalue1=MannWhitney;
		keep parameter time label1 nValue1;
		set __MannWhitney&comp;
		if name1 ='P2_WIL';
	run;

	proc sql;
		create table __comp_para&comp as
		select *
		from __UnpairedTtest&comp as a, __MannWhitney&comp as b
		where (a.parameter = b.parameter) and (a.time=b.time) ;
	quit;

	proc sql /*noprint*/;
		select distinct product
		into: prod1-:prod2
		from __norm
		where product in (&produit1 &produit2) 
		order by product
	;
	quit; 
	
*CJU:where product in ("&&pf&produit1" "&&pf&produit2") ;

	proc sort data=__norm out=__norm; by parameter time product; 

	proc transpose data=__norm out=__norm_&comp;
	where testlab='W';
		by  parameter time;
		var pvalue;
		id product;
	run;

	data __norm_&comp;
		set __norm_&comp;
		if "&prod1"n > 0.01  and "&prod2"n > 0.01 then normalite=1;
		if "&prod1"n <= 0.01  or "&prod2"n <= 0.01 then normalite=0;

	run;

	proc sql;
		create table __comp_para&comp as
		select a.*, put(stderr,&format) as stderrC, b.normalite, strip(put(probt,pvalue8.4)||'µ') as ttest, strip(put(MannWhitney,pvalue8.4)||'§') as MW, 
		case
			when b.normalite=1 then calculated ttest
			when b.normalite=0 then calculated MW
		end as pvalueC,
		strip(put(Mean, &format))||' ('||strip(put(stdDev, &format))||')' as meanSD,
		strip(put(Mean, &format))||' ± '||strip(put(stderr, &format)) as meanSEM
		from __comp_para&comp as a, __norm_&comp as b
		where (a.parameter = b.parameter) and (a.time=b.time);
	quit;
		
	proc transpose data=__comp_para&comp out=__comp_para&comp;
		by parameter time;
		var meanSD meanSEM pvalueC;
	run;

	data __comp_para&comp;
		set __comp_para&comp;
		if _name_ ='meanSD' 	then statN = 2;
		if _name_ ='meanSEM' 	then statN = 2.5;
		if _name_ = 'pvalueC' 	then statN = 7;
		product = %eval(1000 + 100*&produit1 + &produit2);
	run;

	data &out;
		set &out __comp_Para&comp;
	run;


****************************************
	Nettoyage des tables générées 
par les procédures TTEST ET NPAR1WAY
 	  dans la bilbiothèque *WORK*
****************************************;

%if %index(%upcase(&debug),N) %then %do;
proc datasets library=work;
delete
__COMP_PARA&comp
__EQUA_PARA&comp
__MANNWHITNEY&comp
__NORM_&comp
__STAT_PARA&comp
__TEST_PARA&comp
__UNPAIREDTTEST&comp
;
run;
%end;

	%end;
%end;


%end;



******************************************
	Nettoyage final des tables générées 
 	  dans la bilbiothèque *WORK*
******************************************;

%if %index(%upcase(&debug),N) %then %do;
proc datasets library=work;
delete
__&table 
__COMP
__DESC
__LOC
__NORM
__PVALUE
__RESULT
;
run;
%end;


***************************************
	Impression des résultats 
****************************************;

proc sort data=&out out=&out; by parameter  product time statN; run;

%if ( %index(%upcase(&TableauRapport),N) and %index(%upcase(&rtf),N) ne 0 ) %then %do;
	ods rtf exclude all; %end;
%else %if %index(%upcase(&rtf),N) ne 0 %then %do; 
	ods rtf select all; %end;


proc format;
	value color
		1="#3F9EA9"
		2="#C2C2FE"
	;
run;

proc report data=&out /*out=__REPORT_1*/

		style(report)= [frame=box rules=cols cellspacing=0 font_face=&pol fontsize=&tail pt]
		style(header)= [ BACKGROUND=/*#D9D9D9*/ #BBE1E6 font_weight=bold fontsize=&tail pt font_face=&pol cellspacing=0]
		style(column)= [cellwidth=&larg.in  fontsize=&tail pt font_face=&pol]
;
		where (&tempsAvecComparaison) and statN in (&stat);

		column ("&&paraf&numParametre" parameter time  statN product, col1 n );
		
		define parameter 	/ " " order=internal group left style=[BACKGROUND=#BBE1E6 font_weight=bold] noprint;

		define time 		/ " " order=internal group left style=[BACKGROUND=#BBE1E6 font_weight=bold cellwidth=&larg.in];
		define statN 		/ " " order=internal group left style=[BACKGROUND=#BBE1E6 fontstyle=italic cellwidth=&larg.in];
		define product 		/ " " across order=internal center f=productf. style=[backgroundcolor=#BBE1E6 /*#3F9EA9*/];
		define col1			/ " " center;
		define n 			/  center noprint ;

		%if %length(&numParametre) = 0 %then %do;
			compute before parameter / style=[BACKGROUND=#BBE1E6 font_face=&pol fontsize=&tail pt fontweight=bold];
				line @1 parameter parameterf.;
			endcomp;
		%end;

		/*
		compute after parameter;
			line ' ';
		endcomp;
		*/		

		compute time;
     	 	if time ^= ''  then call define(_row_,'style','style=[bordertopcolor=#3F9EA9 bordertopwidth=1]');
   		endcomp;

		compute product;
			if statn=2 then call define (_col_, "style", "style=[fontweight=bold]");
			if statn=7 then call define (_row_, "style", "style=[backgroundcolor=#DAEFF2 fontstyle=italic]");
		endcomp;

	%if &leg = Y %then %do;

		compute after _page_ /left style={font_face=arial fontsize=6pt color=blue /*bordertopcolor=#3F9EA9*/ bordertopwidth=1};

			%if ( %index(%upcase(&plan),I) ) %then %do;
				line '°paired t-test';
				line "*Wilcoxon signed rank test";
			%end;

			%else %if ( %index(%upcase(&plan),P) ) %then %do;
				line '°paired t-test';
				line "*Wilcoxon signed rank test";
				line 'µ unpaired t-test';
				line "§ Mann-Whitney test";
			%end;

		endcomp;
	
	%end;

run;

%if %index(%upcase(&rtf),N) ne 0 %then %do;
	ods rtf select all;
%end;


title;
%mend;


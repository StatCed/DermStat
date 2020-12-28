
options mstored sasmstore=macro;

%macro catego(data= , 
			para= /*Analyse tous les paramètre si vide (nombre/vide)*/, 
			value=value,
			dec=, 
			row=parameter*time, 
			col=product*side,
			out=catego,
			f= , 
			classData= 	/*Nom de la table CLASSDATA - Optionel*/,
			bin= 		/*Affiche les IC (Y/N)*/,
			mv=N		/*Inclus les valeurs manquantes dans le calcul des frequences (Y/N)*/
			)   /STORE SOURCE ;


%let time = %sysfunc(datetime());

ods rtf select none;

*Activation instruction CLASSDATA;
%if %length(&classData) ne 0 %then %do;
	%let instruction_classData=%str(classData=&classData);
%end;
%else %let instruction_classData=;


/****************************************************/
/*Manipulation des macros-variables CLASS			*/
/*pour obtenir la liste des variables et renseigner */	
/*l instruction CLASS;								*/
/****************************************************/

%let row2=%sysfunc(tranwrd(&row,*,));
%let col2=%sysfunc(tranwrd(&col,*,));

ods rtf select none;

****************************************
Nombre de valeurs valides et manquantes;

ods trace on;
ods output Summary=_SUMMARY;
proc means data=&data n nmiss nonobs ;
	%if %length(&para) ne 0 %then %do;
		where parameter=&para ;
	%end;
var &value;
class &row2 &col2;
run;

data _SUMMARY;
	length 'N (%)'n $ 100 category $ 100;
	set _SUMMARY;
	'N (%)'n=catx(' ',put(&value._N,8.0), cats('(',put(&value._NMiss,8.0),')'));
	&value=-9999;
	category='N (MV)';
run;


****************************************
Distribution des catégories;

ods output table=_TABLE;
proc tabulate data=&data &instruction_classData missing ;
	%if %length(&para) ne 0 %then %do;
		where parameter=&para and &value ne .;
	%end;
	%else %do;
		where &value ne .;
	%end;
	class &row2 &col2 &value;
	table &row * &col* (&value=' ') , (n pctn<&value>*f=8.2)/ misstext='0';
	format &value. &f. ;/*mgu 19/10/2020*/
run;




*-----------------------------------------------
Récupération du nom de la variable PCTN_1110,
le nombre de 1 varie en fontion du nombre 
de variable de classement dans le proc TABULATE
;
ods trace on;
ods output Variables=_VARIABLES;
proc contents data=_TABLE ;
run;

proc sql ;
	select variable
	into : pctn 
	from _VARIABLES
	where index(upcase(variable), 'PCTN') > 0;
quit;



*-----------------------------------------------
Création du DATASET final avec les résultats
;
data _TABLE;
	length 'N (%)'n $ 100 category $ 100;
	set _TABLE;
	'N (%)'n = strip(put(N,8.0))||' ('||strip(put(&pctn,8.&dec))||'%)';
	if missing(N) then 'N (%)'n= '0 ('||strip(put(&pctn,8.&dec))||'%)';
	*Création de la variable statC qui contient les catégories;
	%if %length(&f) ne 0 %then %do;
		category=put(&value, &f);
	%end;

	%if %length(&f) = 0 %then %do;  
		category=&value;
	%end;
	
	%if &value=-9999 %then category='N (MV)';

run;

data &out;
	drop _type_ _page_ _table_ &value._N &value._NMiss;
	set _table _summary;
run;

*Nettoyage;
/*
proc datasets nolist nowarn;
    delete _table _summary _variables; 
run;quit;
*/
*Durée éxécution;

%if ( %index(%upcase(&bin),Y) or  %index(%upcase(&bin),O) )= 0 %then %do;
%report(table=&out, row= &row * &value._n * category, col=&col, disp='N (%)'n);
%end;

%else %if ( %index(%upcase(&bin),Y) or  %index(%upcase(&bin),O) ) %then %do;

	%binomial(data=&data,class=&row2 &col2,value=&value,out=binomial);

	proc sql;
		create table &out.2 as
		select 	a.parameter, 
				a.product, 
				a.time, 
				a.&value, 
				a.category, 
				a.'N (%)'n, 
				'95% CI'n, 		
				'Binomial test'n
		from &out as a inner join binomial as b
		on 	a.parameter	=b.parameter 	and 
				a.product	=b.product 		and 
				a.time		=b.time			and
				a.&value	=b.&value	
		;
	quit;

	%report(table=&out.2, row= &row * &value._n * category, col=&col, disp='N (%)'n * '95% CI'n * 'Binomial test'n);

%end;

 %let time = %sysfunc(round(%sysevalf(%sysfunc(datetime()) - &time), 0.01));
 %put NOTE: The &sysmacroname macro used &time seconds.;
	
%mend ;

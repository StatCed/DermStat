
%include "D:\StructureEtude\1.XXEXXXX_Draft\2.Analyse\0.Driver.sas";

options mstored sasmstore=macro;

%macro catego(data= , 
			para=, 
			value=value,
			dec=, 
			class=parameter*product*time, 
			out=catego,
			f= , 
			classData=
			)  / STORE SOURCE;


%let time = %sysfunc(datetime());


ods output table=&out;

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

data _null_;
	class=symget('class');
    class2=tranwrd(class,"*"," ");
    call symput('class2',class2);
run;


****************************************
Nombre de valeurs valides et manquantes;

ods trace on;
ods output Summary=_SUMMARY;
proc means data=&data n nmiss nonobs;
	%if %length(&para) ne 0 %then %do;
		where parameter=&para ;
	%end;
var &value;
class &class2;
run;

data _SUMMARY;
	length statC $ 100;
	set _SUMMARY;
	col1=catx(' ',put(&value._N,8.0),	cats('(',put(&value._NMiss,8.0),')'));
	&value=-9999;
	statC='N (MV)';
run;


****************************************
Distribution des catégories;
ods output table=_TABLE;
proc tabulate data=&data &instruction_classData missing;
	%if %length(&para) ne 0 %then %do;
		where parameter=&para and &value ne .;
	%end;
	%else %do;
		where &value ne .;
	%end;
	class &class2 &value;
	table &class * (&value=' ') , (n pctn<&value all>*f=8.2)/ misstext='0';
run;



*-----------------------------------------------
Récupération du nom de la variable PCTN_1110,
le nombre de 1 varie en fontion du nombre 
de variable de classement dans le proc TABULATE
;
ods trace on;
ods output Variables=_VARIABLES;
proc contents data=_TABLE;
run;

proc sql;
	select variable
	into : pctn 
	from _VARIABLES
	where index(upcase(variable), 'PCTN') > 0;
quit;



*-----------------------------------------------
Création du DATASET final avec les résultats
;
data _TABLE;
	length statC $ 100;
	set _TABLE;
	col1 = strip(put(N,8.0))||' ('||strip(put(&pctn,8.&dec))||'%)';
	*Création de la variable statC qui contient les catégories;
	%if %length(&f) ne 0 %then %do;
		statC=put(&value, &f);
	%end;

	%if %length(&f) = 0 %then %do;  
		statC=&value;
	%end;
run;

data &out;
	drop _type_ _page_ _table_ &value._N &value._NMiss;
	set _table _summary;
run;

*Nettoyage;

proc datasets nolist nowarn;
    delete _table _summary _variables; 
run;quit;

*Durée éxécution;

proc report data=&out;

	column (/*"&para"*/ parameter time &value statC  product, col1 n) ;

	define parameter / ' ' 		left order=internal group ;
	define time 	 / ' ' 		order=internal group ;
	define &value 	 / ' ' 		order=internal group noprint;
	define statC 	 / ' ' 		order=internal group ;
	define product 	 / ' ' 		order=internal group across center ;
	define col1 	 / 'N (%)' 	display left ;
	define n 		 / ' ' 		noprint;
run;

 %let time = %sysfunc(round(%sysevalf(%sysfunc(datetime()) - &time), 0.01));
 %put NOTE: The &sysmacroname macro used &time seconds.;

%mend;




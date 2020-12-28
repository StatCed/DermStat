
*
%include "D:\StructureEtude\1.XXEXXXX_Draft\2.Analyse\0.Driver.sas";
*
options mstored sasmstore=macro;

%macro creation_formats(tab=, Modified_format=, position=)
 / /*STORE SOURCE*/;


*2. Comptage du nombre de variables catégorielles; 

proc sql;
	select  count(distinct variable) as nb
	into : Nombre_variables_categorielles
	from &position
	where type = 'Char';
quit;


*3. Stockage des variables catégorielles dans des macro-varaibles; 

proc sql;
	select  distinct variable as nb
	into : var1 -: %sysfunc(compress(var&Nombre_variables_categorielles))
	from &position
	where type = 'Char'
	order by num;
quit;


*4. Stockage de la liste des variables catégorielles dans une macro-variable; 

proc sql;
	select  distinct variable 
	into : Liste_Variables_Categorielles separated by ' '
	from &position
	where type = 'Char'
	order by num;
quit;


ods trace on;
ods output OneWayFreqs=OneWayfreqs;
proc freq data=&tab;
table &Liste_Variables_Categorielles /list missing;
run;

%macro loop();
data OneWayfreqs_2;

	retain para paraN ;

	length para $ 100 category $ 100 paraN 8.0 ;
	
	set OneWayfreqs;

	%do i = 1 %to &Nombre_variables_categorielles;
		if index(table,"&&var&i") then do; 
			para = "&&var&i";
			paraN=&i;
			category="&&var&i"n;
		end;
	%end;
run;
%mend;

%loop();


data OneWayfreqs_3;
	retain para paraN category category_num;
	length informat $ 100 format $ 100;
	set OneWayfreqs_2;
	by paraN;
	category_num+1;

	if first.paraN then category_num=1;

	informat=cats(category_num,'=',category);
	
	format=cats(category,'=',category_num);
run;


data OneWayfreqs_4;
	retain para paraN category category_num;
	length informat $ 100 format $ 100;
	set OneWayfreqs_3;
	by paraN category_num;

	category=cats("'",category,"'");

	bool=first.paraN;

		if (first.paraN=1 and last.paraN=1)=1 then do;
			format=catx(' ','value',compress(para),category_num,'=',category,';');
			informat = catx(' ','invalue',compress(para),category,'=',category_num,';');
			end;

		else if first.paraN = 1 then do;
			format=catx(' ','value',compress(para),category_num,'=',category);
			informat = catx(' ','invalue',compress(para),category,'=',category_num);
			end;

		else if last.paraN then do;
			format=catx(' ',category_num,'=',category,';');
			informat=catx(' ',category,'=',category_num,';');
			end;

		else do;
			format=catx(' ',category_num,'=',category); 
			informat=catx(' ',category,'=',category_num); 
			end;
run; 


proc sql;
	select informat, format
	into : informat separated by ' ', : format separated by ' '
	from OneWayfreqs_4;
quit;



*Stockage du format parameterF;


*Compte du nombre de paramètres;
proc sql;
	select  count(distinct variable) as nb
	into : Nombre_Parametres
	from &position
;
quit;


*Création des instructions FORMAT et INFORMAT;
data format_parameter;
	set &position end=eof;
	obs=_n_;

	variable2=cats("'",variable,"'");
	
	if obs=1 then do;
		format_parameter =catx(' ','value parameterf',OBS,'=',variable2);
		informat_parameter   = catx(' ','invalue parameterf',variable2,'=',OBS);
		end;
	else if eof=1 then do;
		format_parameter	 = catx(' ',OBS,'=',variable2,';');
		informat_parameter	 = catx(' ',variable2,'=',OBS,';');
		end;
	else do;
		format_parameter 	 = catx(' ',OBS,'=',variable2);
		informat_parameter	 = catx(' ',variable2,'=',OBS);
		end;
run;

proc sql;
	select distinct informat_parameter, format_parameter
	into : informat_parameter separated by ' ', : format_parameter separated by ' '
	from format_parameter
	order by Num
;
quit;



*instructions FORMAT et INFORMAT;

proc format;
		&informat;
		&format;
		&informat_parameter;
		&format_parameter;
run;

proc format;
&Modified_format;
run;

proc format library = work fmtlib;
run;

%mend;




*CREATION DES VARIABLES NUMERIQUES;
%macro creation_variables_numeriques(in=DATA_2, out=DATA_3, table_formats=format_parameter)
 / /*STORE SOURCE*/;

data &table_formats._2;

	set &table_formats;

	if type = 'Char';

		variable_num=cats(variable,'_num');

		convertion_en_var_num = cats(variable_num,'=input(', variable,',',variable,'.',');');

		CQ_convertion = cats(variable_num,'*',variable);

		CQ_formats = catx(' ',variable_num, cats(variable,'.'));

		rename_var_num = cats(variable_num,'=',variable); 

run; 


proc sql;
	select convertion_en_var_num, CQ_convertion, rename_var_num, CQ_formats, variable, CQ_formats

	into 	: 	convertion_en_var_num separated by ' ',
		 	:	CQ_convertion separated by ' ',
			:	rename_var_num separated by ' ',
			:	CQ_formats separated by ' ',
			:	drop_para separated by ' ',
			:	CQ_formats separated by ' '

	from &table_formats._2
;
quit;

data &out;
	set &in;
	&convertion_en_var_num
;
run;

proc freq data=&out;
	table &CQ_convertion / list missing;
	format &CQ_formats;
run;

data &out;
	set &out;
	rename &rename_var_num;
	drop &drop_para;
	format &CQ_formats;
run;

%mend;




%macro freq(table= , para=, num= , f= , class=)  /*STORE SOURCE*/;


proc format;
	picture p8r (round) 0-100 = '0009.9%)'			
						(prefix='(')
;
run;

ods output table=desc&NUM;

*Activation instruction CLASSDATA;
%if %length(&class) ne 0 %then %do;
	%let instruction_classData=%str(classData=&class);
%end;
%else %let instruction_classData=;

proc tabulate data=&table &instruction_classData;

	where not missing(&para);

	class product &para;
	table &para=' ' all,product*(n pctn<&para all>*f=p8r.)/ misstext='0';
run;

data desc&NUM;

	drop _page_ _table_;

	length statC $ 100;

	set desc&NUM;

	*Création de la variable col1 qui contient les stat : N(%);
	if N = . then N = 0;
	if _type_ = '11' then col1 = strip(put(N,8.0))||' ('||strip(put(pctn_10,8.1))||'%)';
	if _type_ = '10' then col1 = strip(put(N,8.0));

	*Création de la variable statC qui contient les catégories;
	%if %length(&f) ne 0 %then %do;
		statC=put(&para, &f);
	%end;

	%if %length(&f) = 0 %then %do;  
		statC=&para;
	%end;

	if _type_ = '10' then statC="N=";

	*Création de la variable tri pour ordonner les valeurs dans la PROC REPORT;
	tri=&para;

	vtype=vtype(&para);

	if (vtype='C' and _type_= '10') =1 then tri='0' ;
	else if (vtype='N' and _type_= '10')=1 then tri=-9999 ;

	para="&para";

	parameter=&NUM;

run;

proc report data=desc&NUM;
	column ("&para" tri statC product, col1 n) ;
	define tri 		/		order order=internal noprint;
	define statC 	/ ' ' 	group ;
	define product 	/ ' ' 	order=internal group across center ;
	define col1 	/ ' ' 	display left ;
	define n 		/ ' ' 	display noprint;
run;

%mend;


%macro mean (table=, para=,ordre=,format=,format2=)  /*STORE SOURCE*/;

proc format;
		invalue statf
		'N_VM' 		= 1
		'M_EC' 		= 2
		'ESM'  		= 3
		'Med'  		= 4
		'Range'		= 5
;
		value statf
		1 = 'N'
		2 = 'mean (SD)'
		3 = 'SEM'
		4 = 'median'
		5 = 'min ; max'
;
run;

ods output table=desc&ordre;
proc tabulate data=&table order=internal ;
	class  product;
	var &para;
	table &para=' '*(n nmiss mean median stderr std min max), product;
run;

data desc&ordre;
	set desc&ordre;
	N_VM 	= strip(put(&para._N,8.0))/*||' ('||strip(put(&para._nmiss,8.0))||')'*/;
	M_EC 	= strip(put(&para._mean,&format))||' ('||strip(put(&para._std,&format))||')';
	ESM  	= strip(put(&para._stderr,&format));
	Med  	= strip(put(&para._median,&format));
	Range	= strip(put(&para._min,&format2)) || ' ; '||strip(put(&para._max,&format2));
run;

proc sort data=desc&ordre out=desc&ordre; 
	by product; 
run;

proc transpose data=desc&ordre out=desc&ordre name=stat; 
	by product;
	var N_VM--range;
run;

data desc&ordre;
	length statC $ 100;
	set desc&ordre;
	statN = input(stat,statf.);
	format statN statf.;
	statC = put(statN,statf.);
	parameter=&ordre;
	para="&para";
	tri=statN;
run;


proc report data=desc&ordre;

	column ("&para" statN statC product, col1 n) ;

	define statn 	/ order group order=internal noprint ;
	define statC 	/ order ' ' group  ;
	define product 	/ ' ' order group across center ;
	define col1 	/ ' ' display center ;
	define n 		/ noprint;

run;

title;

%mend;



%macro analyse_descriptive(tab=DATA_3, class_data=class, position=position,out=) /*STORE SOURCE*/;

proc sql;
	select  count(distinct variable) as nb
	into : Nombre_Parametres
	from &position
quit;

data cju;
	set &position;
run;

%macro loop();
*Gestion du choix avec ou sans table CLASS_DATA;
	%if %length(&class_data) ne 0 %then %do;

		proc contents data=&CLASS_DATA order=varnum;		
		ods output position=CLASS_DATA_POSITION;
		run;

		%global var_in_class;
		proc sql;
		select variable 
		into : var_in_class separated by ' '
		from CLASS_DATA_POSITION
		quit;

	%end;
	%else %do;
		%let var_in_class = ;
	%end;
%mend;
options mprint symbolgen mlogic;
%loop();

options mprint mlogic;
data Appel_Macro_DESC;

	set &position;

	obs=_n_;

	var_in_classdata ="&var_in_class";

	if (type = 'Char' and index(upcase(var_in_classdata),trim(upcase(variable)))) then do;
		Appel_Macro_DESC=catx(' ','%freq(table=&tab, para=',VARIABLE,', num=',obs, ', f=',cats(VARIABLE,'., class=&class_data);')); 
	end;

	else if (type = 'Char' and index(upcase(var_in_classdata),trim(upcase(variable)))=0) then do;
		Appel_Macro_DESC=catx(' ','%freq(table=&tab, para=',VARIABLE,', num=',obs, ', f=',cats(VARIABLE,'., class=);'));  
	end;

	if type = 'Num' then do;
		Appel_Macro_DESC=catx(' ','%mean(table=&tab, para=',VARIABLE,', ordre=',obs, ', format=8.2, format2=8.1);');  
	end;
run;


%global Appel_Macro_DESC;

proc sql;
	select Appel_Macro_DESC
	into : Appel_Macro_DESC separated by ' '
	from Appel_Macro_DESC
	;
quit;

&Appel_Macro_DESC;


%put &Appel_Macro_DESC;
 
%let DescFin=%sysfunc(cats(desc,&Nombre_Parametres));

%put &DescFin;

data &out;
	set desc1 - &DescFin ;
run;

%mend;



%include "D:\StructureEtude\1.XXEXXXX_Draft\2.Analyse\0.Driver.sas";





	



options mstored sasmstore=macro;

%macro catego_new(table= , 
			para=, 
			value=value,
			dec=, 
			class=parameter*product*time, 
			out=catego,
			f= , 
			classData=
)  
/ STORE SOURCE;


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
ods output Summary=Summary;
proc means data=&table n nmiss nonobs;
	%if %length(&para) ne 0 %then %do;
		where parameter=&para ;
	%end;
var &value;
class &class2;
run;

data summary;
	length statC $ 100;
	set summary;
	col1=catx(' ',put(value_N,8.0),	cats('(',put(value_NMiss,8.0),')'));
	value=-9999;
	statC='N (MV)';
run;


****************************************
Nombre de valeurs valides et manquantes;
ods output table=table;
proc tabulate data=&table &instruction_classData missing;
	%if %length(&para) ne 0 %then %do;
		where parameter=&para and &value ne .;
	%end;
	%else %do;
		where &value ne .;
	%end;
	class &class2 &value;
	table &class * (&value=' ') , (n pctn<&value all>*f=8.2)/ misstext='0';
run;

ods trace on;
ods output Variables=Variables;
proc contents data=table;
run;

proc sql;
	select variable
	into : pctn 
	from Variables
	where index(upcase(variable), 'PCTN') > 0;
quit;


data table;
	length statC $ 100;
	set table;
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
	set table summary;
run;

proc report data=&out;
	column ("&para"  parameter time &value statC  product, col1 n) ;
	define parameter / ' ' 		left order=internal group ;
	define time 	 / ' ' 		order=internal group ;
	define &value 	 / ' ' 		order=internal group noprint;
	define statC 	 / ' ' 		order group ;
	define product 	 / ' ' 		order=internal group across center ;
	define col1 	 / 'N (%)' 	display left ;
	define n 		 / ' ' 		noprint;
run;

%mend;


data t1;
	do parameter=1 to 3;
		do product=1 to 4;
		 	do time=1 to 3;
				do subject = 1 to 20;					value = int(rand('UNIFORM',1,4));
					if subject = 2 then value = .;
					if value in (1 2) then Responder = 1;
					else if value = 3 then Responder = 0;
					else  Responder = .;
					output;
				end;
			end;
		end;
	end;
	format value 8.0;
run; 

data classdata;
	do parameter=1 to 3;
		do product=1 to 4;
		 	do time=1 to 3;
				do value=1 to 3;

					if value in (1 2) then Responder = 1;
					else if value = 3 then Responder = 0;
					else  Responder = .;
					
					output;
				end;
			end;
		end;
	end;
	format value 8.0;
run;

%catego_new(table=t1 , 
			para=, 
			value=value,
			dec=, 
			class=parameter*product*time, 
			out=catego,
			f= , 
			classData=classdata
);

%catego_new(table=t1 , 
			para=, 
			value=responder,
			dec=, 
			class=parameter*product*time, 
			out=catego,
			f= , 
			classData=classdata
);

/*
proc report data=desc&NUM;
	column ("&para" tri statC product, col1 n) ;
	define tri 		/		order order=internal noprint;
	define statC 	/ ' ' 	group ;
	define product 	/ ' ' 	order=internal group across center ;
	define col1 	/ ' ' 	display left ;
	define n 		/ ' ' 	display noprint;
run;
*/
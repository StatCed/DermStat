


options mstored sasmstore=macro;

%macro exploration(table=,para=)/STORE SOURCE;


ods graphics on / 
      width=4in
      imagefmt=jpeg
      imagemap=on
      imagename="MyBoxplot"
      border=off
;


proc format; 
	invalue quantilef
		'100% Max'=1
		'99%'=2
		'95%'=3
		'90%'=4
		'75% Q3'=5
		'50% Median'=6
		'25% Q1'=7
		'10%'=8
		'5%'=9
		'1%'=10
		'0% Min'=11
	;
	value quantilef
		1='100% Max'
		2='99%'
		3='95%'
		4='90%'
		5='75% Q3'
		6='50% Median'
		7='25% Q1'
		8='10%'
		9='5%'
		10='1%'
		11='0% Min'
	;
run;




ods select none;


*-------------Création d une table temporaire pour travailler-------------;
proc sort data=&table out=_temp_; 

	by parameter product time; 

	*-----On teste l analyse porte sur un parametre en particulier--;
	%if %length(&para) > 0 %then %do; 
		where parameter=&para and value ne . and product < 1000 ;
	%end;
	*-----On teste l analyse porte sur utous les parametres--;
	%if %length(&para) = 0 %then %do; 
		where value ne . and product < 1000 ;
	%end;

run;



*-------------Création d une table avec les quantiles-------------;
ods output 
testsfornormality	= norm 
basicmeasures 		= basicmeasures 
quantiles  			= quantiles 
extremeobs 			= extremeobs;


proc univariate data=_temp_  nextrobs=5 normal;
	var value;
	class product time;
	by parameter;
run;


data quantiles;
	rename quantileN=quantile;
	drop quantile; 
	set quantiles;
	quantileN=input(quantile,quantilef.);
	format quantileN quantilef.;
run;


proc sort data=quantiles out=quantiles; by parameter product time;


proc transpose data=quantiles out=quantiles;
	var estimate;
	id quantile;
	by parameter product time;
	where quantile in (5 7);
run;


data quantiles;
	rename timeN=time productN=product;
	format timeN timef. productN productf.;
	drop time;
	set quantiles;
	IQR = 	'75% Q3'n -'25% Q1'n;
	L_Q1=	'25% Q1'n-1.5*IQR;
	H_Q3=	'75% Q3'n+1.5*IQR;
	timeN=input(time,timef.);
	productN=input(product,productf.);
run;


*----Création d une table avec les valeurs brutes et les valeurs Q1 et Q3-----------;
proc sql;
	create table _temp_ as
	select *
	from _temp_ as a, quantiles as b
	where a.product=b.product and a.time=b.time and a.parameter=b.parameter
	order by value;
;
quit;


ods select all;


*-------------------------------------------------
Si le nombre de valeurs distinctes prise par 
la variable est onférieur à 15, 
La varaible est considéré comme qualitative (score)
;

%global Nombre_de_valeurs_distinctes;


		proc sql noprint ;

			select distinct(value)
			into : Nombre_de_valeurs_distinctes 
			from _temp_
			where time < 1000;
;

		quit;


*----On teste pour chaque valeur si elle se trouve hors "limites"---------
L1 = 1.5*IQR-Q1 / 1.5*IQR+Q3
L1 = 3*IQR-Q1 / 3*IQR+Q3
;

data _temp_;
	set _temp_;

	%if &Nombre_de_valeurs_distinctes >= 15 %then %do;
		if value > H_Q3 then position = 1;
		if value >'75% Q3'n+3*IQR then position =3; 

		if value < L_Q1 then position = 1;
		if value < '25% Q1'n-3*IQR then position =3; 
	 %end;

	%else %if &Nombre_de_valeurs_distinctes < 15 %then %do;
		if value > H_Q3 then position = 1;
		if value < L_Q1 then position = 1;
	%end;
run;

proc format; 
  	value positionf     
		3="salmon"       
		1="orange"
	;
run; 


*----On compte le nombre de parametre dans la table pour un traitement itératif---------;

proc sql noprint;
	select count(distinct parameter) as nb
	into : nb_parameter
	from _temp_
quit
;


proc sort data=_temp_ out=_temp_; by parameter value; run;


*-----On teste si l analyse porte sur un paramètre spécifié--------;

%if %length(&para)=0 %then %do;
	%let para=1;
%end;
%else %if %length(&para) ne 0 %then %do;
	%let nb_parameter=&para;
%end;

%do parameter=&para %to &nb_parameter;

		title1 bold f=calibri h=12pt "Analyse de la distribution des valeurs de la variable &&paraf&parameter";

		/*
		proc sgplot data=_temp_;
		where time < 1000 and parameter = &parameter;
		 	histogram value;
			inset "Raw data : &&paraf&parameter";
		run; 
		*/
		proc sgplot data=_temp_;
		where time < 1000 and parameter = &parameter;
		   vbox value / category=time group=product;
		  	*xaxis  display=none   ;
		   keylegend / title="Zone";
		   inset "Raw data : &&paraf&parameter";
		run; 
		title;
		/*
		proc sgplot data=_temp_;
		where time > 1000 and parameter = &parameter;
		 	histogram value;
			inset "CFB : &&paraf&parameter";
		run; 
		*/
		proc sgplot data=_temp_;
		where time > 1000 and parameter = &parameter;
		   vbox value / category=time group=product;
		   xaxis label="Treatment";
		   keylegend / title="Zone";
		   inset "CFB : &&paraf&parameter";
		run; 


		proc format;
			value ShapiroWilk
				low-0.01="salmon" 
			   0.01<-high="Aquamarine"
		;
		run;

		proc report data=norm 
			style(report)= [frame=box rules=cols cellspacing=0 font_face=calibri fontsize=10 pt]
			style(header)= [ BACKGROUND= #BBE1E6 font_weight=bold fontsize=10pt font_face=calibri cellspacing=0]
			style(column)= [cellwidth=0.9in  fontsize=10pt font_face=calibri];

			where (testlab='W' and parameter=&parameter);

			columns ("Test de normalité &&paraf&parameter" product time pValue); 

			define product 			/ "product"  group  left style=[font_weight=bold];
			define time 			/ "time"   order=data	 group left style=[just=right font_face=arial font_size=10pt ];
			define pValue			/ "Shapiro-Wilk test" display ;

		run;


		*-----Creation macro variables avec la liste des observations extrêmes----;
		%global liste_observations_extremes;
		%let liste_observations_extremes=;

		proc sql noprint;
			select no
			into : liste_observations_extremes separated by ' '
			from _temp_
			where (value < l_q1 or value > H_Q3) and value ne . and parameter=&parameter;
		quit;

		*-----Creation macro variables avec la liste des sujets extremes----;
		%global List_subject_raw_data List_time list_value;
		%let List_subject_raw_data=;
		%let List_time=;
		%let List_value=;

		proc sql noprint;
			select subject, time, value format 8.1
			into : List_subject_raw_data separated by ' ',: List_time separated by ' ', :List_value separated by ','
			from _temp_
			where (value < l_q1 or value > H_Q3) and value ne . /*and time < 1000*/ and parameter=&parameter;
		quit;

		*-----Création macro-variables avec la liste des valeurs < 3*IQR-Q1
															  et > 3*IQR+Q3	----;
		%let List_value_sup3=;
		%let List_value_sup1=;
		%global Nombre_de_valeurs_distinctes;

		proc sql noprint ;

			select distinct(value)
			into : Nombre_de_valeurs_distinctes 
			from _temp_
			where time < 1000;

			select distinct(value)
			into : List_value_sup3 separated by ','
			from _temp_
			where position = 3 and parameter = &parameter and value ne . /*and time < 1000*/
			;
			select distinct(value)
			into : List_value_sup1 separated by ','
			from _temp_
			where position = 1 and parameter = &parameter and value ne . /*and time < 1000*/;

		quit;

		%if %length(&List_subject_raw_data) ne 0 %then %do;

		/*
		proc report data=_temp_ ;

			where (value < l_q1 or value > H_Q3) and value ne . and time < 1000 and parameter=&parameter;

			columns ("&&paraf&parameter" product time no subject value L_Q1 '25% Q1'n '75% Q3'n H_Q3 position n); 

			define product 			/ "product"  group  left style=[font_weight=bold];
			define time 			/ "time"  	 group left style=[just=right font_face=arial font_size=10pt ];
			define no 				/ "num. obs." order	display;
			define subject 			/ "subject" order	display;
			define value 			/ "value" 	order	order=data f=8.2 display;
			define L_Q1				/  	display f=8.2;
			define '25% Q1'n		/  	display f=8.2;
			define '75% Q3'n		/  	display f=8.2;
			define H_Q3				/ 	display f=8.2;
			define position			/ "Outlier" 	display ;
			define n 				/ "n" 		noprint;

			compute position;
				call define (_col_, "style", "style=[backgroundcolor=positionf. fontstyle=italic]");
		    endcomp; 

		run;
		*/
		%end;


*-----------------------------------------------------------------------------------
#
# Création d un format permettant de répérer les valeurs extrêmes
# et les valeurs aberrantes dan la PROC REPORT
# Si la variables est un score (arbitrairement nombre de valeurs distinctes < 15 ) 
# le format est créé à partir des valeurs stcokées dans &List_value_sup1
# puisque les valeurs peuvent se retrouver dans les deux macro variables
# &List_value_sup3 et &List_value_sup1 (nombre de valeurs possible faible
#
;
	
		%if &Nombre_de_valeurs_distinctes > 15 %then %do;
		%if %length(&List_value_sup3) ne 0 and %length(&List_value_sup1) ne 0 %then %do;

		proc format;
			value valuef
				&List_value_sup3="salmon"
				&List_value_sup1="orange"
		;
		run;

		%end;

		%if %length(&List_value_sup3) = 0 and %length(&List_value_sup1) ne 0 %then %do;

		proc format;
			value valuef
			&List_value_sup1="orange"
		;
		run;

		%end;

		%if %length(&List_value_sup3) ne 0 and %length(&List_value_sup1) = 0 %then %do;

		proc format;
			value valuef
			&List_value_sup3="salmon"
		;
		run;

		%end;
		%end;

		%else %if &Nombre_de_valeurs_distinctes < 15 and %length(&List_value_sup1) ne 0 %then %do;
			proc format;
			value valuef
			&List_value_sup1="orange"
			;
		run;
		%end;

		%if %length(&List_subject_raw_data) ne 0 %then %do; 
		proc report data=_temp_ 
		style(report)= [frame=box rules=cols cellspacing=0 font_face=calibri fontsize=10 pt]
		style(header)= [ BACKGROUND= #BBE1E6 font_weight=bold fontsize=10pt font_face=calibri cellspacing=0]
		style(column)= [cellwidth=0.9in  fontsize=10pt font_face=calibri];
			where subject in (&List_subject_raw_data) and value ne . and parameter=&parameter;
		
			columns ("&&paraf&parameter" product  subject time,   value  no n); 
			define product 			/ " "  	 		group order=internal left style=[font_weight=bold];
			define subject 			/ " " 	 		group order=internal;
			define time 			/ " "  			group across order=internal ;
			define value 			/ " " 			f=8.2 display style=[backgroundcolor=valuef.];
			define no 				/ "num. obs." 	noprint;
			define n 				/ "n" 			noprint;

		run;
		title;
		
		/*
		proc report data=_temp_ ;

			where (value < l_q1 or value > H_Q3) and value ne . and time > 1000 and parameter=&parameter;

			columns ("&&paraf&parameter" product time no subject value L_Q1 '25% Q1'n '75% Q3'n H_Q3 position n); 

			define product 			/ "product" 	group  left style=[font_weight=bold];
			define time 			/ "time"  		group left style=[just=right font_face=arial font_size=10pt ];
			define no 				/ "num. obs." 	display;
			define subject 			/ "subject" 	display;
			define value 			/ "value" order=data f=8.2 display;
			define L_Q1				/  	display f=8.2;
			define '25% Q1'n		/  	display f=8.2;
			define '75% Q3'n		/  	display f=8.2;
			define H_Q3				/ 	display f=8.2;
			define position			/ "Outlier" 	display ;
			define n 				/ "n" 		noprint;

			compute position;
				call define (_col_, "style", "style=[backgroundcolor=positionf. fontstyle=italic]");
		    endcomp; 

		run;
		*/
		title;


		%end; 

title;
%end;

%mend;




%macro binomial(tab=, value=, out=binomial);

%global 
list_of_categoriesN
list_of_categoriesC 
number_of_categories 
number_of_values;

proc sql;
	select distinct &value format 8.0, &value, count(distinct &value) 
	into	: 	list_of_categoriesN separated by '!', 
		 	:	list_of_categoriesC separated by '!' ,
			: 	number_of_categories
	from &tab
	where not missing(value);
quit;

%let number_of_categories=%sysfunc(strip(&number_of_categories));

data &out;
run;

%do parameter=1 %to 3;
	%do product=1 %to 4;
		%do time=1 %to 3; 

			%do level= 1 %to &number_of_categories;
				%let categoryC=%scan(&list_of_categoriesC,&level,'!');
				%let categoryN=%scan(&list_of_categoriesN,&level,'!');

			proc sql;
				select count(&value) 
				into : Number_of_values
				from &tab
				where parameter=&parameter
				and product=&product
				and time=&time
				and &value=&categoryN;
			quit;
			
	%if %eval(&Number_of_values)>0 %then %do;

	ods output 
	BinomialCLs=BinomialCLs
	BinomialTest=BinomialTest;

	proc freq data=&tab;

		table &value / binomial (exact wilson level="&categoryC")  chisq;
		where parameter=&parameter
			and product=&product
			and time=&time
		;
	run;

	data temporary;
		*keep parameter time value freq ic binomial_test;
		set BinomialCLs BinomialTest;
		if Type='Wilson' /*or Name1='P2_BIN'*/;
		parameter=&parameter;
		product=&product;
		time=&time;
		value=&categoryN;	
	run;

	data temporary;
		retain parameter product time value freq ic /*binomial_test*/;
		format freq 8.0;
		set temporary;
		freq=proportion*100;
		binomial_test=nvalue1;
		ic=cats('[',put(lowerCl*100,8.0) , '% , ' , put(upperCl*100,8.0),'%]');
	run;

	data &out;
		set &out temporary;
		if not missing(parameter);
	run;
	%end;

%end;
%end;
%end;
%end;

%mend;

options mprint symbolgen mlogic;
*%binomial(tab=DATASET6, value=change);



%let number_of_categories_in_col = 10;
%put &number_of_categories_in_col;
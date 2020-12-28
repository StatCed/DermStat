
*--------------------------------------------------------------
1. Mise à jour en focntion du nombre de varaibles de classement

2. Liaison avec la macro CATEGO
;

options mstored sasmstore=macro;


%macro binomial(data=t1,class=parameter product time,value=value,dec=1,out=_binomial) /store;

*Récupération du nombre et de la liste des niveaux pour chaque variable; 
%let _list_variables	= &class &value;
%let _count_variables 	= %sysfunc(countw(&_list_variables));

%global _variables_liaison;
%let _variables_liaison = a.&_class1=b.&_class1;

%do i=1 %to &_count_variables;

	%let _class&i = %scan(&_list_variables,&i,' '); 

	*Création instruction WHERE pour liaison dans PROC SQL;
	%if &i>1 %then %do;
		%let _variables_liaison = &_variables_liaison and a.&&_class&i=b.&&_class&i ;
	%end;

	%global _list_class&i _count_class&i;

	proc sql;
		select distinct &&_class&i format 8.0, count(distinct &&_class&i) as count
		into : _list_class&i separated by ' ', : _count_class&i
		from &data
		where not missing(&value);
	quit;

%end;



*Création des instructions DO-TO-END pour parcourir les niveaux de chaque variable;
data &out;
run;

%if %eval(&_count_variables = 2) %then %do;
	%do i=1 %to &_count_class1;
		%do j=1 %to &_count_class2;
	



		%end;
	%end;
%end;

%if %eval(&_count_variables = 3) %then %do;
	%do i=1 %to &_count_class1;
		%do j=1 %to &_count_class2;
			%do k=1 %to &_count_class3;


			%end;
		%end;
	%end;
%end;


%if %eval(&_count_variables = 4) %then %do;
	%do i=1 %to &_count_class1;
		%do j=1 %to &_count_class2;
			%do k=1 %to &_count_class3;
				%do l=1 %to &_count_class4;

				ods output 
				BinomialCLs=BinomialCLs
				BinomialTest=BinomialTest;
			
				proc freq data=&data;
					table &value / binomial (exact wilson level=&l)  chisq;
					where 	%scan(&_list_variables,1,' ')=%scan(&_list_class1,&i,' ') and 
							%scan(&_list_variables,2,' ')=%scan(&_list_class2,&j,' ') and
							%scan(&_list_variables,3,' ')=%scan(&_list_class3,&k,' ') ;
					run;

				data BinomialTest;
					set BinomialTest;
					if Name1='P2_BIN' then call symput ('pvalue',nvalue1);
				run;

				data BinomialCLs;

					keep &class &value  /*lowerCl uppercl*/ '95% CI'n 'Binomial test'n;
					set BinomialCLs ;

					if Type='Wilson' /*or Name1='P2_BIN'*/;

					%scan(&_list_variables,1,' ')=	%scan(&_list_class1,&i,' ');
					%scan(&_list_variables,2,' ')=	%scan(&_list_class2,&j,' ');
					%scan(&_list_variables,3,' ')=	%scan(&_list_class3,&k,' ');
					/*Les catégories ne commencent pas forcément à 1*/
					%scan(&_list_variables,4,' ')=	%scan(&_list_class4,&l,' '); 
				
					'95% CI'n=cats('[',put(lowerCl*100,8.&dec) , '% , ' , put(upperCl*100,8.&dec),'%]');
					'Binomial test'n=input(symget('pvalue'),best32.);
					format 'Binomial test'n pvalue8.4;

				run;
		
				data &out;
					set &out BinomialCLs;
					if not missing(parameter);
				run;

				%end;
			%end;
		%end;
	%end;
%end;	



%if %eval(&_count_variables = 5) %then %do;
	%do i=1 %to &_count_class1;
		%do j=1 %to &_count_class2;
			%do k=1 %to &_count_class3;
				%do l=1 %to &_count_class4;
					%do m=1 %to &_count_class5;



					%end;
				%end;
			%end;
		%end;
	%end;
%end;	



%if %eval(&_count_variables = 6) %then %do;
	%do i=1 %to &_count_class1;
		%do j=1 %to &_count_class2;
			%do k=1 %to &_count_class3;
				%do l=1 %to &_count_class4;
					%do m=1 %to &_count_class5;
						%do n=1 %to &_count_class5;



						%end;
					%end;
				%end;
			%end;
		%end;
	%end;
%end;	
%mend;


*--------------------------------------------------------------
1. Mise à jour en focntion du nombre de varaibles de classement

2. Liaison avec la macro CATEGO
;
*
%include "D:\StructureEtude\1.XXEXXXX_Draft\2.Analyse\0.Driver.sas";

options mstored sasmstore=macro;


%macro binomial(data=t1,class=parameter product time,value=value,dec=1,out=_binomial) /store;

*Récupération du nombre et de la liste des categories pour chaque variable; 
%let _list_variables	= &class &value;
%let _count_variables 	= %sysfunc(countw(&_list_variables));

%do i=1 %to &_count_variables;

	%let _class&i = %scan(&_list_variables,&i,' '); 
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


*On parcourt tous les niveaux des variables pour calculer l IC;
%if %eval(&_count_variables = 4) %then %do;
	%do i=1 %to &_count_class1;
		%do j=1 %to &_count_class2;
			%do k=1 %to &_count_class3;
				%do l=1 %to &_count_class4;

				*On vérifie si le nombre de valeur du nivuea est supérieure à 0
				pour éviter de lever une erreur avec la proc freq;
				proc sql;
					select count(&value) as Number_of_values
					into : Number_of_values 
					from &data
					where 	%scan(&_list_variables,1,' ')=%scan(&_list_class1,&i,' ') and 
							%scan(&_list_variables,2,' ')=%scan(&_list_class2,&j,' ') and
							%scan(&_list_variables,3,' ')=%scan(&_list_class3,&k,' ') and 
							&value=%scan(&_list_class4,&l,' ');
				quit;
	
				*On stocke la valeur de la categorie avec son format dans une macro
				variable. Elle sera utilisée comme référence dans la proc freq;
				proc sql;
					select distinct &value 
					into : value_with_format
					from &data
					where 	%scan(&_list_variables,1,' ')=%scan(&_list_class1,&i,' ') and 
							%scan(&_list_variables,2,' ')=%scan(&_list_class2,&j,' ') and
							%scan(&_list_variables,3,' ')=%scan(&_list_class3,&k,' ') and 
							&value=%scan(&_list_class4,&l,' ');
				quit;

	
				%if %eval(&Number_of_values>0) %then %do;
				*Si la categorie à un nombre supérieure à 0, on lance la proc freq;
				ods output 
				BinomialCLs=BinomialCLs
				BinomialTest=BinomialTest;
	
				proc freq data=&data;
					table &value / binomial (exact wilson level="&value_with_format")  chisq;
					where 	%scan(&_list_variables,1,' ')=%scan(&_list_class1,&i,' ') and 
							%scan(&_list_variables,2,' ')=%scan(&_list_class2,&j,' ') and
							%scan(&_list_variables,3,' ')=%scan(&_list_class3,&k,' ') ;
					run;

				data BinomialTest;
					set BinomialTest;
					if Name1='P2_BIN' then call symput ('pvalue',nvalue1);
				run;

				data BinomialCLs;

					*keep &class &value  /*lowerCl uppercl*/ '95% CI'n 'Binomial test'n;
					set BinomialCLs ;

					if Type='Wilson' /*or Name1='P2_BIN'*/;

					%scan(&_list_variables,1,' ')=	%scan(&_list_class1,&i,' ');
					%scan(&_list_variables,2,' ')=	%scan(&_list_class2,&j,' ');
					%scan(&_list_variables,3,' ')=	%scan(&_list_class3,&k,' ');
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

				%if %eval(&Number_of_values=0) %then %do;
					*Si la categorie n est pas présente dans la table, on alimente quand même
					la table de sortie;
					data BinomialCLs;
							%scan(&_list_variables,1,' ')=	%scan(&_list_class1,&i,' ');
							%scan(&_list_variables,2,' ')=	%scan(&_list_class2,&j,' ');
							%scan(&_list_variables,3,' ')=	%scan(&_list_class3,&k,' ');
							/*Les catégories ne commencent pas forcément à 1*/
							%scan(&_list_variables,4,' ')=	%scan(&_list_class4,&l,' '); 
						
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

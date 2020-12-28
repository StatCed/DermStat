
/****************************************
******Mcnemar***********
mgu 11/11/2020
v1
****************************************/

%macro McNemar (tabIn=,ID=subject,comparaison=&col,value=&value.,byvar=&row2)/store source; 

ods rtf exclude all;

data Final_McNemarsTest;
retain &comparaison. &byvar. cValue1 nValue1 test;
stop;
run;
			proc sql;
				select count (distinct &comparaison.)  into: NB&comparaison.
				from &tabIn.;
				quit;

            proc sort data=&tabIn.; by &ID. &byvar.; run;

			proc transpose data=&tabin. out=&tabin._2;
            by &ID. &byvar.;
			id &comparaison.;
			var &value.;
			run;

				%do w=1 %to %eval (&&NB&comparaison. -1) ;
				  %do y=%eval(&w+1) %to  &&NB&comparaison. ;

                       %let comp=%eval(1000+100*&w.+&y.);

                        ods trace on;
						ods output McNemarsTest=McNemarsTest_&comp.;

						proc sort data=&tabIn._2; by  &byvar.; run;

						proc freq data=&tabIn._2;
						title "McNemar's test for Paired Samples";
						  table "&&pf&w."n * "&&pf&y."n/ agree expected;
						  by  &byvar.;
						run;

                        data McNemarsTest2_&comp.;
                        set McNemarsTest_&comp.;
						where name1="P_MCNEM";
						keep &comparaison. &byvar. cValue1 nValue1 test;
                        test="McNemar";
                        &comparaison.=&comp.;
						run;

						 data Final_McNemarsTest;
						 set Final_McNemarsTest McNemarsTest2_&comp.;
						 run;
				  %end;
				%end;

ods rtf select all;

data Final_McNemarsTest;
retain &comparaison. &byvar. cValue1 nValue1 test;
set Final_McNemarsTest;
run;

proc sort data=Final_McNemarsTest;by &comparaison. &byvar. ;run;

proc print data=Final_McNemarsTest noobs;run;

%mend McNemar;

/**test*/

*%McNemar (tabIn=data,ID=subject,comparaison=&col,value=&value.,byvar=&row2); 



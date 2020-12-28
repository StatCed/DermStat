/****************************************
******Test chi2 et Test fisher***********
mgu 05/11/2020
v9
****************************************/
*test;

/**Was updated***
*******************
1.rename ts by Joinclass
2.simplefy the macro Joinclass
3.remove paraint leave only byvar (create a merge list in join class)
4.replace the selection paramerer label1 by name in the fisher table
5.remove duplicate program with the if condition (to be done)
*******************/

%macro chi2fisher (tabIn=, condition=/*Pairewise or All*/,comparaison=&col,value=&value.,byvar=&row2)/store source; 

%global paraint;
%let paraint= &byvar. &comparaison.;

%macro Joinclass();
%global listmerg;
%let nbvarclass= %sysfunc(countw(&paraint));
%let class1=%scan(&paraint.,1," ");
%let listmerg= %str(a. &class1. =b. &class1.);

%do z=2 %to %eval(&nbvarclass.-1);
%let class&z.=%scan(&paraint.,&z.," ");
%let listmerg = &listmerg %str( and a. &&class&z. =b. &&class&z.); 
%end;

%Mend Joinclass;

%Joinclass();


data Final_chi2;
retain &comparaison. &byvar.  test P_&value._N P_&value._C;
stop;
run;

%if (%length(&condition.) =0 or %index(%upcase(&condition.),P)) %then 
%do;
				proc sql;
				select count (distinct &comparaison.)  into: NB&comparaison.
				from &tabIn.;
				quit;

				%do w=1 %to %eval (&&NB&comparaison. -1) ;
				  %do y=%eval(&w+1) %to  &&NB&comparaison. ;

				       %Let condition=%str(&comparaison. in (&w.,&y.));

                       %let comp=%eval(1000+100*&w.+&y.);

                         ods trace on;
						ods output  FishersExact=FishersExact1_&comp.;

						proc sort data=&tabIn.; by  &paraint.; run;

						proc freq data=&tabIn.;
						 where &condition. ;
						  table &comparaison. * &value./ chisq WARN=OUTPUT fisher;
						  by  &byvar.;
						  OUTPUT OUT =CHISQ2_&comp. N PCHI;
						run;

						 data CHISQ3_&comp.;
						 set CHISQ2_&comp.;
							keep &byvar. p_pchi warn_pchi test;
							rename p_pchi=CP_&value.;
						    test="Chi2"; 
						 run;

						 /******GET THE P-&value.S FOR THE FISHER TEST**************/

						 data FishersExact2_&comp.;
						 set FishersExact1_&comp.;
						 if index (label1,"Pr <= P") ne 0 then output;
						 run;
						 
						 data FishersExact3_&comp.;
						 set FishersExact2_&comp.;
						 keep &byvar. nvalue1 warn_pchi test;
						 rename nvalue1=FP_&value.;
						 test="Fisher";
						 run;/*The fisher test P_&value.*/

						 /*****************Create the table with all the p-&value.**********/

						 data P_&value._&comp.;
						 set FishersExact3_&comp. CHISQ3_&comp.;
						 run;

                         proc sql;
						 create table P_&value._&comp. as
						 select a.*,b.CP_&value.,b.warn_pchi
						 from FishersExact3_&comp. as a left join CHISQ3_&comp. as b
                         on &listmerg ; /*mgu:to be updated by listmerge*/
						 quit;

						 data P_&value.2_&comp.;
						 set P_&value._&comp.;
						 if (warn_pchi=1) then do;  P_&value._N=FP_&value.;  test="Fisher";end;
                         if (warn_pchi=0) then do;  P_&value._N=CP_&value.;  test="Chi2"; end;
						 run;

						 data P_&value.3_&comp.;
						 retain &comparaison. &byvar.  test P_&value._N P_&value._C;
						 keep &byvar.  test P_&value._N P_&value._C &comparaison.;
						 set P_&value.2_&comp.;
						 if test="Fisher" then sign="*"; else sign="°";
						 P_&value._C=cat(put(P_&value._N,pvalue8.4),sign);
						 &comparaison.=&comp.;
						 run;

						 proc print data=P_&value.3_&comp.;run;
                        
						 data P_&value.3_&comp.;
                         set P_&value.3_&comp.;
						 run;

						 data Final_chi2;
						 set Final_chi2 P_&value.3_&comp.;
						 run;
				  %end;
				%end;
%end;

%if ( %index(%upcase(&condition.),ALL) ) %then
%do;
						%let comp= 1234;
						ods trace on;
						ods output  FishersExact=FishersExact1;

						proc sort data=&tabIn.; by  &paraint.; run;

						proc freq data=&tabIn.;
						  table &comparaison. * &value./ chisq WARN=OUTPUT fisher;
						  by  &byvar.;
						  OUTPUT OUT =CHISQ2 N PCHI;
						run;

						 data CHISQ3;
						 set CHISQ2;
							keep &byvar. p_pchi warn_pchi test;
							rename p_pchi=CP_&value.;
						    test="Chi2"; 
						 run;

						 /******GET THE P-&value.S FOR THE FISHER TEST**************/

						 data FishersExact2;
						 set FishersExact1;
						 if index (label1,"Pr <= P") ne 0 then output;
						 run;
						 
						 data FishersExact3;
						 set FishersExact2;
						 keep &byvar. nvalue1 warn_pchi test;
						 rename nvalue1=FP_&value.;
						 test="Fisher";
						 run;/*The fisher test P_&value.*/

						 /*****************Create the table with all the p-&value.**********/

						 data P_&value.;
						 set FishersExact3 CHISQ3;
						 run;

                         proc sql;
						 create table P_&value. as
						 select a.*,b.CP_&value.,b.warn_pchi
						 from FishersExact3 as a left join CHISQ3 as b
                         on &listmerg ; /*mgu:to be updated by listmerge*/
						 quit;

						 data P_&value.2;
						 set P_&value.;
						 if (warn_pchi=1) then do;  P_&value._N=FP_&value.;  test="Fisher";end;
                         if (warn_pchi=0) then do;  P_&value._N=CP_&value.;  test="Chi2"; end;
						 run;

						 data P_&value.3_&comp.;
						 retain &comparaison. &byvar.  test P_&value._N P_&value._C;
						 keep &byvar.  test P_&value._N P_&value._C &comparaison.;
						 set P_&value.2;
						 if test="Fisher" then sign="*"; else sign="°";
						 P_&value._C=cat(put(P_&value._N,pvalue8.4),sign);
						 &comparaison.="&comp.";
						 run;

						 proc print data=P_&value.3_&comp.;run;

						 DATA Final_chi2;
						 set P_&value.3_&comp.;
						 run;

%end;
proc sort data=Final_chi2;by &byvar. &comparaison. ;run;

proc print data=Final_chi2;run;

%mend chi2fisher;

/**test*/

*%chi2fisher (tabIn=, condition= /*Pairewise or All*/,comparaison=&col,value=&value.,byvar=&row2); 

/*all product*/
*%chi2fisher (tabIn=data, condition= ALL ,comparaison=product,value=value,byvar=parameter time); 

/*product 2*2*/
*%chi2fisher (tabIn=data, condition= Pairewise,comparaison=product,value=value,byvar=parameter time);


options mstored sasmstore=macro;

%macro anova(table= ,
	class =,
	model =,
	random =,	
	where =,
	table_cont= ,
	log = log(value+1),
	sqrt = sqrt(value), 
	numParametre=1, 
	format=8.2, 
	SortiesBrutes=oui,
	pol=calibri	,
	tail=8	,
	larg=1,
	lang=ANG,
	cont= /*Contrast*/
) /store source ;



%if %upcase(&sortiesBrutes)=NON %then %do; ods rtf exclude all; %end;

*-----------------------------------------
1.TRI DES DONNEES EN FONCTION DES FACTEURS
;

proc sort data=&table out=&&para&NumParametre; 
	&where; 
	by &class ; 
run;


*-------------------------
2.TRANSFORMATION DES DONNEES
- RANG
- logarithme base 10
;

proc rank data=&&para&NumParametre out=&&para&NumParametre ties=mean;
	var value;
	ranks rank; 
run;

data &&para&NumParametre;
	set &&para&NumParametre;
	log = &log;
	sqrt = &sqrt;
run;


*-------------------------
3.Modèle linéaire mixte
;

ods trace on;
ods output 
estimates=estimates_&&para&NumParametre
tests3=fixed_effect_&&para&NumParametre
diffs=diffs_&&para&NumParametre
lsmeans=lsmeans_&&para&NumParametre
lsmestimates=lsmestimates_&&para&NumParametre
diffs=diffs_&&para&NumParametre
;

proc mixed data=&&para&NumParametre order=internal;

	class &class;
	model &model;
	&random;

*---------------------------------------------------------------------------
4.CONSTRUCTION DES CONTRASTES POUR LES COMPARAISON VS BASELINE PAR PRODUITS
;

%if %length(&cont)=0 %then %do;

		*-------Création de la liste de 0 en fonction du nbre de temps----; 
		%let liste0_0 = 0;
		%do N=2 %to &NOMBRETEMPS;
			%let liste0_0 =&liste0_0 0; 
		%end; 

		%let estimate=;
	
		%let decalage_produit_1 = ;

		%do a=1 %to &NOMBREPRODUITS;

				%if &a=1 %then %do; %let decalage_produit_1 = ;  %end;

				%else %if &a ne 1 %then %do; %let decalage_produit_1 = &decalage_produit_1 &liste0_0;  %end;

			
				%do b=2 %to %eval(&NOMBRETEMPS);
					%if &b=2 %then %do; %let decalage_temps = ; %end;
					%else %if &b ne 2 %then %do; %let decalage_temps = &decalage_temps 0; %end;	

					%let estimate = &estimate  
						%str(estimate "&&Pf&a.: &&T&b vs &T1" time -1 &decalage_temps 1 product*time &decalage_produit_1 -1 &decalage_temps 1  / cl;);
				%end;

		%end;

		*COMPARAISON DES PRODUITS;

		*Macro variable pour parcourir les produits dans le contraste;
		%let decalage_produit_1 	= 	;
		%let decalage_produit_2 	= 	;
		*Macro variable pour parcourir les niveaux de temps dans le contraste;
		%let decalage_temps			=	;	

		%do b=2 %to &NOMBRETEMPS;
		
			%if &b=2 %then %do; %let decalage_temps = ; %end;
			%else %if &b ne 2 %then %do; %let decalage_temps = &decalage_temps 0; %end;	

			%let nombre_zero_droit		=	;	
			%do h=%eval(&b+1) %to %eval(&nombretemps);
				%let nombre_zero_droit = &nombre_zero_droit 0;
			%end;

				%do a = 1 %to %eval(&NOMBREPRODUITS-1);
			
					%if &a=1 %then %do; %let decalage_produit_1 = ; %end;
					%else %if &a ne 1 %then %do; %let decalage_produit_1 = &decalage_produit_1 &liste0_0; %end;	

					%do k=%eval(&a+1) %to &NOMBREPRODUITS;
				
						%let difference_position_produit=%eval(&k-&a);

						%if &difference_position_produit = 1 %then %do; %let decalage_produit_2 = ; %end;			
						%else %if &difference_position_produit > 1 %then %do; %let decalage_produit_2 = &decalage_produit_2 &liste0_0; %end;	

						%let estimate = &estimate 	%str(estimate "&&T&b - &T1: &&Pf&a vs &&Pf&k"  product*time 	&decalage_produit_1 	-1 &decalage_temps 1 &nombre_zero_droit		&decalage_produit_2 		1  &decalage_temps -1 &nombre_zero_droit  	 / cl;); 
				
					%end;

				%end;
	
		%end;

&estimate;

%end;

*CONSTRUCTION DES CONTRASTES POUR LES COMPARAISON VS BASELINE PAR PRODUITS - END;

%if  %length(&cont) ne 0 %then %do;

	&cont;

%end;



*-------------------------
6. Test normalité des résidus
;

proc sort data=Resid_&&para&NumParametre out=Resid_&&para&NumParametre; by resid;

goption reset=all dev=actximg;

ods graphics on / 
      width=4in
      imagefmt=gif
      imagemap=on
      imagename="MyBoxplot"
      border=off
;

ods trace on;
ods select testsfornormality histogram qqplot;

proc univariate data=resid_&&para&NumParametre normal;

		var resid;
		histogram resid / normal NORMAL	( 	W=1 	L=1 	COLOR=YELLOW  MU=EST SIGMA=EST)
		CFRAME=GRAY CAXES=BLACK WAXIS=1  CBARLINE=BLACK CFILL=BLUE PFILL=SOLID ;
			qqplot   resid / NORMAL
			(	 	W=1 	L=1 	COLOR=YELLOW   MU=EST  SIGMA=EST       )
			CFRAME=GRAY CAXES=BLACK WAXIS=1;
run;


*---------------------------------------------
Graphique des résidus en fonction des facteurs
;

proc gplot data=resid_&&para&NumParametre;
	plot resid*pred;
run;

%do l=1 %to %sysfunc(countw(&class,%str( )));

	%let facteur = %scan(&class,&l);

	%if (%upcase(&facteur) ne PARAMETER or %upcase(&facteur) ne SUBJECT) %then %do; 
		proc gplot data=resid_&&para&NumParametre;
			plot resid*&facteur;
		run;
	%end;

%end;



%if %sysfunc(exist(lsmeans_&&para&NumParametre)) %then %do;
	data lsmeans_&&para&NumParametre;
		length label $ 100;
		set lsmeans_&&para&NumParametre;
		label = strip(put(product,productf.)) /*|| ' vs ' || strip(put(_product,productf.))*/; 
	run;
%end;
%if %sysfunc(exist(diffs_&&para&NumParametre)) %then %do;
	data contrast_&&para&NumParametre;
		length label $ 100;
		set diffs_&&para&NumParametre;
		label = strip(put(product,productf.)) || ' vs ' || strip(put(_product,productf.)); 
	run;
%end;
%if %sysfunc(exist(estimates_&&para&NumParametre)) %then %do;
	data contrast_&&para&NumParametre;
		length label $ 100;
		set estimates_&&para&NumParametre;
		"label"n=compbl(label);
	run;
%end;
%if %sysfunc(exist(lsmestimates_&&para&NumParametre)) %then %do;
	data contrast_&&para&NumParametre;
		length label $ 100;
		set lsmestimates_&&para&NumParametre;
		"label"n=compbl(label);
	run;
%end;

/*
%if %sysfunc(exist(fixed_effect_&&para&NumParametre)) %then %do;
	data fixed_effect_&&para&NumParametre;
		length label $ 100;
		set fixed_effect_&&para&NumParametre;
		"label"n=compbl(effect);
		pvalue=probf;
	run;

	%if %sysfunc(exist(contrast_&&para&NumParametre)) %then %do;
		data contrast_&&para&NumParametre;
			set fixed_effect_&&para&NumParametre contrast_&&para&NumParametre;
		run;
	%end;
%end;
*/

*--------------------------------------------
Table avec les contrastes
;

data contrast2_&&para&NumParametre (drop=DF tValue Alpha /*Lower Upper*/);

	rename 	stderr=SEM 
			probt=pvalue;

	format estimate &format 
		 	stderr &format;

	length group $ 100;

	set contrast_&&para&NumParametre;
	*"label"n=compbl(label);
	*label = strip(put(product,productf.)) || ' vs ' || strip(put(_product,productf.)); 
	%do a = 1 %to &NombreProduits;
			if  index(label,"&&pf&a") ne 0 then do; 
				Group="&&pf&a"; 
			end;
	%end;

	%do a=1 %to %eval(&NombreProduits-1);
			%do j=%eval(&a+1) %to &NombreProduits;
				if (index(label,"&&pf&a") and index(label,"&&pf&j")) then Group="&&pf&a vs &&pf&j";
			%end;
	%end;

	"95% CI"n = compress("["||put(lower,&format)||";"!!put(upper,&format)||"]");
	Parameter = "&&Para&NumParametre";
	conclusion = compbl(
				label
				!!' ('
				!!strip(put(estimate,&format))
				!!' ± '!!put(stderr,&format)
				!!', p='
				!!strip(put(probt,pvalue8.4)
				!!')'))
				;
	tri=_n_;

	if probt <0.05 then significativity='Yes';
	else if probt >= 0.05 then significativity='No'; 

run;







ods rtf exclude none;

proc report data=fixed_Effect_&&para&NumParametre 
		style(header)= [BACKGROUND=#BBE1E6 fontsize=8pt font_face=calibri fontweight=bold]
		style(column)= [fontsize=8pt font_face=calibri];

		column ("&&paraf&NumParametre" Effect 'probf'n) ;

		define Effect 		/ 'Fixed effects' order=data left group style=[cellwidth=1in] ;
		define 'probf'n 	/ 'p-value' center ;
run;




%if %upcase(&lang) = ANG %then %do;
	%let tr1 = Comparison;
	%let tr2 = Adj. mean;
	%let tr3 = SE;
	%let tr4 = 95% CI ;
	%let tr5 = p-value;
%end;
%else %do;
	%let tr1 = Comparaison;
	%let tr2 = Moy ajustée;
	%let tr3 = ES;
	%let tr4 = IC 95%;
	%let tr5 = p-value;
%end;	


proc report data=contrast2_&&para&NumParametre out=report_contrast

		style(report)= [frame=box rules=cols cellspacing=0 font_face=&pol fontsize=&tail pt]
		style(header)= [ BACKGROUND=#BBE1E6 font_weight=bold fontsize=&tail pt font_face=&pol cellspacing=0]
		style(column)= [cellwidth=1.0in  fontsize=&tail pt font_face=&pol]
;
	/*	style(header)= [BACKGROUND=#BBE1E6 fontsize=&tail.pt font_face=&pol fontweight=bold]
		style(column)= [fontsize=&tail pt font_face=&pol cellwidth=1.2in]; */

		column ("&&paraf&NumParametre" Label estimate SEM pvalue '95% CI'n) ;

		define Label 		/ "&tr1" order=data left group style=[cellwidth=&larg in font_weight=bold] ;
		define estimate 	/ "&tr2" center style=[cellwidth=&larg in];
		define SEM 			/ "&tr3" center style=[cellwidth=&larg in ];
		define '95% CI'n 	/ "&tr4" center style=[cellwidth=&larg in ] ;
		define pvalue 		/ "&tr5" center style=[cellwidth=&larg in ];

		compute after _page_ /left style={font_face=&pol fontsize=6pt color=blue};
			line %nrstr("Values obtained from mixed ANOVA model");
		endcomp;

run;


proc sort data=contrast2_&&para&i out=contrast2_&&para&i; 
	by descending tri; 

proc sgplot data=contrast2_&&para&i noautolegend; 
title1 "&&paraf&i";
title2 "Adjusted mean differences";
   	scatter x=estimate y=label / xerrorlower=lower                                                                                            
                           xerrorupper=upper                                                                                            
                           markerattrs=(symbol=CircleFilled) group=group  ;
	yaxis display=(nolabel) valueattrs=(size=6); 
	xaxis label= "Adjusted means (with 95% CI)" ;
  	refline 0 /axis=x lineattrs=(color=crimson pattern=2); 
run;

title;



%mend ANOVA;



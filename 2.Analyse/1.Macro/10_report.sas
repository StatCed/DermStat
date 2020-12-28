


options mstored sasmstore=macro;


%macro report(table=catego,row=parameter*time*value,col=product,disp=col1)
	/ STORE SOURCE ;

*--------------------
PARAMETRES
;
/*
%let table=catego;
*Variable de classement en ligne;
%let row=parameter*time*value_n*statC; 
*Variable de classement en colonne ACROSS;	
%let col=product;
*Variable en mode affichage DISPLAY;	
%let disp=col1;						
*/

ods rtf select none;

*Nettoyage macro variable row;
%let row=%sysfunc(tranwrd(&row,*,));

*Création de l instruction COLUMN;
%let column= column (	%sysfunc(tranwrd(&row,_N,)) 
						%sysfunc(tranwrd(&col,*,%str(,))), 
						(%sysfunc(tranwrd(&disp,*,))) 
						n ) %str(;)	;

%let column= column (	%sysfunc(tranwrd(&row,_n,)) 
						%sysfunc(tranwrd(&col,*,%str(,))), 
						(%sysfunc(tranwrd(&disp,*,))) 
						n ) %str(;)	;

%let col=%sysfunc(tranwrd(&col,*,));


*Compte du nombre d élément dans chaque liste;
%let list_of_categpries_in_row 		= %sysfunc(countw(&row));
%let list_of_categpries_in_col 		= %sysfunc(countw(&col));
%let list_of_categories_in_disp 	= %sysfunc(countw(&disp,*));


*Création des instructions 	DEFINE;
%let DEFINE_ROW=;
%do i=1 %to &list_of_categpries_in_row;

	%let r&i= %scan(&row,&i,' ');
	%if %index(%upcase(&&r&i,_N)) %then %do;
		%let r&i= %scan(&&r&i,1,_);
		%let r&i= define &&r&i %str(/ " ") order=internal  group noprint %str(;);
	%end;
	%else %do;
		%let r&i= define &&r&i %str(/ " ") order=internal group left %str(;);
	%end;

	%let DEFINE_ROW=&DEFINE_ROW &&r&i;

%end;


%let DEFINE_ACROSS=;
%do i=1 %to &list_of_categpries_in_col;
	%let c&i= %scan(&col,&i,' ');
		%if %index(%upcase(&&c&i),'_N') %then %do;
			%let c&i= %scan(&&c&i,1,'_');
			%let c&i= define &&c&i %str(/ " ") order=internal noprint /*group*/ across %str(;);
		%end;
		%else %do;
			%let c&i= define &&c&i %str(/ " ") order=internal right /*group*/ across %str(;);
		%end;
		%let DEFINE_ACROSS=&DEFINE_ACROSS &&c&i;
%end;


%let DEFINE_DISPLAY=;
%do i=1 %to &list_of_categories_in_disp;
	%let d&i= %scan(&disp,&i,*);
	%let d&i= define &&d&i %str(/" " ) display right %str(;);
	%let DEFINE_DISPLAY=&DEFINE_DISPLAY &&d&i;
%end;

ods rtf select all;

proc report data=&table;

&column;

	&DEFINE_ROW 
	&DEFINE_ACROSS
	&DEFINE_DISPLAY;
	define n / noprint;
run;

%mend;

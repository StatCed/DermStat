


options mstored sasmstore=macro;


%macro report(table=catego,row=parameter*time*value,col=product,disp=col1,where=,width=1)
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
%do inc=1 %to &list_of_categpries_in_row;

	%let r&inc= %scan(&row,&inc,' ');
	%if %index(%upcase(&&r&inc,_N)) %then %do;
		%let r&inc= %scan(&&r&inc,1,_);
		%let r&inc= define &&r&inc %str(/ " ") order=internal  group noprint %str(;);
	%end;
	%else %do;
		%let r&inc= define &&r&inc %str(/ " ") order=internal group left %str(;);
	%end;

	%let DEFINE_ROW=&DEFINE_ROW &&r&inc;

%end;


%let DEFINE_ACROSS=;
%do inc=1 %to &list_of_categpries_in_col;
	%let c&inc= %scan(&col,&inc,' ');
		%if %index(%upcase(&&c&inc),'_N') %then %do;
			%let c&inc= %scan(&&c&inc,1,'_');
			%let c&inc= define &&c&inc %str(/ " ") order=internal noprint /*group*/ across %str(;);
		%end;
		%else %do;
			%let c&inc= define &&c&inc %str(/ " ") order=internal right /*group*/ across %str(;);
		%end;
		%let DEFINE_ACROSS=&DEFINE_ACROSS &&c&inc;
%end;


%let DEFINE_DISPLAY=;
%do inc=1 %to &list_of_categories_in_disp;
	%let d&inc= %scan(&disp,&inc,*);
	%let d&inc= define &&d&inc %str(/" " ) display right %str(;);
	%let DEFINE_DISPLAY=&DEFINE_DISPLAY &&d&inc;
%end;

ods rtf select all;

proc report data=&table

	style(column)= [cellwidth=&width in /*fontsize=&tail pt font_face=&pol*/];

&where;
&column;

	&DEFINE_ROW 
	&DEFINE_ACROSS
	&DEFINE_DISPLAY;
	define n / noprint;
run;

%mend;

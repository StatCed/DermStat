

options mstored sasmstore=macro;

%macro evolution(
	table=,
	echX= /*Optionnel*/,
	echY= /*Optionnel*/,
	labX=Time in (day),
	labY=/*%str(&&paraf&i (*ESC*){unicode '000a'x}(mean ± 2*SEM))*/,
	labGp=Product,
	ft=timef.,
	ref=,
	err= stderr/*STDERR ou STDDEV*/,
	where= 
) /STORE SOURCE;


proc sort data=&table out=mean; 
	&where; 
   	by product time; 
run;

proc means data=mean noprint ; 
   	by product time;                                                                                                                             
   	var value;                                                                                                                            
   	output out=meansout mean=mean stderr=stderr stddev=stddev lclm=lclm uclm=uclm;                                                                                         
run;                                                                                                                                    
                                                                                                                                        
/* Calculate the upper and lower error bar values. */                                                                                       
data reshape(drop=stderr);  
 
   set meansout; 

	%if &err = stderr %then %do;
		lower=mean - 2*stderr;                                                                                                                 
		upper=mean + 2*stderr;
	%end;

	%else %if &err = stddev %then %do;
		lower=mean - stddev;                                                                                                                 
		upper=mean + stddev;
	%end;

	%else %if &err = CI %then %do;
		lower=lclm;                                                                                                                 
		upper=uclm;
	%end;
 
run;          
 
 /* The SCATTER statement generates the scatter plot with error bars. */                                                                 
/* The SERIES statement draws the line to connect the means.         */                                                                 
proc sgplot data=reshape noautolegend; 
   	scatter x=time y=mean / yerrorlower=lower                                                                                            
                           yerrorupper=upper                                                                                            
                           markerattrs=(symbol=CircleFilled) group=product name="scat";                                                                
   	series x=time y=mean / lineattrs=(pattern=1 thickness=1) group=product;
   	xaxis integer &echX label="&labX"
/*fitpolicy=rotate*/
;

&ref
/*refline 28 /axis=x 
label="Treatment end" 
lineattrs=(color=brown) 
labelattrs=(color=brown);)*/
;
   	yaxis &echY label="&labY" ;
	%if %length(&labGp) ne 0 %then %do;
		keylegend "scat" / title="&labGp" noborder;
	%end;
	format time &ft; 

run;

%mend;


%macro distribution(
	table=,
	echY=,
	labY=%str(&&paraf&i (*ESC*){unicode '000a'x}(raw data)), 
	labX=, 
	leg=Product,
	where=
) /STORE SOURCE 
;
proc sgplot data=&table;
   vbox value / category=time group=product grouporder=ascending;
   xaxis label="&labX";
   yaxis label="&labY" &echY;
   keylegend / title="&leg" noborder;
   &where;
run; 
%mend;



/*
%include "D:\Statistiques\Data_SAS\2017\SINCLAIR\17E0646\2.Analyse\0.Driver.sas";

*-----------------------------------
Ajout du bruit
;

proc sql;
	create table exploration as 
	select *, mean(value) as moy,  
	time+(rand('UNIFORM')-0.5)*0.6 as time_bruit
	from lib._17e0646_b1
	where time > 1000
	group by parameter, product, time
;
quit;


%macro l();

ods graphics on / 
      width=4in
      imagefmt=jpeg
      imagemap=on
      imagename="MyBoxplot"
      border=off
;

%do i = 1 %to 18;
title "&&paraf&i";
proc sgplot data=exploration ;
	where parameter=&i;

	scatter y=value x=time_bruit / group=product  dataskin=gloss  name="scat"  
			markerattrs=(  symbol=circlefilled size=10);
	scatter y=moy x=time / group=product dataskin=pressed markerattrs=( symbol=diamond size=12) name='moy';
/*	yaxis values=(0.80 to 1.1 by 0.1)  */;
/*	xaxis  OFFSETMIN=0.1 OFFSETMAX=0.1
	values=(1000 1003 1006) valuesdisplay=('D0' 'M3' 'M6') /*label='Score clinique de varice'*/;
/*	keylegend "scat" / title="Product" noborder;
run; 

proc sgplot data=exploration ;
	where parameter=&i;
	vbox value/category=time group=product;
	scatter y=moy x=time / group=product dataskin=pressed markerattrs=(color=yellow symbol=diamond size=12) name='moy';
run; 
ods startpage=now;
title;
%end;

%mend;

&rtf_deb;
%l();
&rtf_fin;

%&ns;


*libname dermscan "d:\Statistiques\Data_SAS\Dermscan" ;	/***attribution de la bibliothèque dermscan***/ 
*libname d "d:\Statistiques\Data_SAS\Dermscan" ;	
libname	ods "d:\Statistiques\code_sas\ods" ; 		/***attribution de la bibliothèque rtfstyle pour stocker les nouvelles templates***/

options nodate nonumber;   			/***supprime la date et le numéro de page du document rtf***/    

ods noproctitle;

ODS escapechar='^';

%macro title(title=,level=);
ods rtf text="^S={indent=3.5 fontsize=10 pt font_face=calibri font_weight=bold} {\tc\f3\fs0\cf8 &title}"; 
title&level f=calibri h=10 pt bold j=left "&title ^2n";
%mend;

%macro table(title=,level=);

%let tab_num=%eval(&tab_num+1);

ods rtf text="^S={indent=3.5 fontsize=8 pt font_face=calibri} {\tc\f3\fs0\cf8 Table &tab_num.. &title}"; 
title&level f=calibri h=10 pt bold j=center underlin=1 "Table &tab_num.. &title";

%mend;

%macro figure(title=,level=);

%let fig_num=%eval(&fig_num+1);

ods rtf text="^S={indent=3.5 fontsize=8 pt font_face=calibri} {\tc\f3\fs0\cf8 Figure &fig_num.. &title}"; 
title&level f=calibri h=10 pt bold j=center underlin=1 "Figure &fig_num.. &title";

%mend;


ods graphics on / 
      width=4in
      imagefmt=jpeg
      imagemap=on
      imagename="MyBoxplot"
      border=off
;


%let ods= notoc_data bodytitle startpage=no style=sty.s1; /***Attribue à la macro variable les trois options régulièrement utilisée 
											dans les documents rtf***/

%let RTF_Deb 	= ods rtf file="d:\statistiques\output\divers\sortie.rtf" startpage=no bodytitle nogtitle style=sty.s1;
%let RTF_Fin 	= ods rtf close;
%let ns 	= no_section (d:\statistiques\output\divers\sortie.rtf);


%macro chargement();

%if %symexist(chargement) = 0 %then %do; 
	ods path 	work.sty (write) /***indique un chemin accessible en écriture pour les nouvelles templates***/
				sashelp.tmplmst(read);


/***Création d'un nouveau style "template"***/
proc template;
	define style sty.s1;   /***nom du nouveau style***/
	parent=styles.rtf;     /***style parent***/

/**************************************
	test pour modifier les marges
**************************************/

replace Body from Document /
leftmargin = 1.5 cm
rightmargin = 1.5 cm
topmargin = 1.5 cm
bottommargin = 1.5 cm;


/***modification des attributs des titres***/
	style systemtitle /    
	font_face = "arial, helvetica, sans-sherif"
	font_size = 4
	font_weight = bold
	font_style= italic
	background=cxe0e0e0
;

/***modification des attributs de la première ligne des tableaux***/
	style header /
	background=#BBE1E6
	font_weight = bold
	font_size = 8pt
	font_face = "arial"
; 

/***modification des attributs de la première colonne des tableaux***/
	style rowheader /
	font_weight = bold
	font_size = 8pt
	font_face = "arial";

/***modification des attributs de la dernière ligne des tableaux***/	
	style footer /
	font_weight=bold
	background=#BBE1E6
	font_size = 8pt
	font_face="arial";


/***modification des attributs des tableaux***/		
	style table /
	cellpadding=5
	cellspacing=0
	/*bordercolor=green*/
	foreground=green
	just=center
	rules = ROWS  	/* internal borders: none, all, cols, rows, groups */
	frame = box; 	/* outside borders: void, box, above/below, vsides/hsides, lhs/rhs */

	style column  /
	just=c;

/***modification des attributs des titres de procédure***/
	style proctitle / /*color=white*/
	foreground=black /*#BBE1E6 #6633cc*/
	font_weight = bold
	font_size = 8pt
	font_face = "arial";

	style data /
	font_size = 8pt
	font_face = "arial";
end;
run;

/***Création d'un nouveau style "template"***/
proc template;
	define style sty.s2;
	parent=styles.rtf;

/**************************************
	test pour modifier les marges
**************************************/

replace Body from Document /
leftmargin = 3 cm
rightmargin = 3 cm
topmargin = 1.2 cm
bottommargin = 1.2 cm;

	style systemtitle /
	font_face = "arial, helvetica, sans-sherif"
	font_size = 8pt
	font_weight = bold
	font_style= italic
	background=white;

	style header /
	background=#BBE1E6
	font_weight = bold
	font_size =8pt
	font_face = "arial"
	; 

	style rowheader /
	font_weight = bold
	font_size =8pt
	font_face = "arial";

	style footer /
	background=#EFF0FF
	font_weight = bold
	font_size =8pt
	font_face = "arial"
	;

	style table /
	cellpadding=3
	cellspacing=0
	bordercolor=black
	foreground=black
	just=center
	rules = groups
	frame = hsides; 

	style column  /
	just=c;

	style proctitle /
	/*foreground=#6633cc*/
	font_weight = bold
	font_size =8pt
	font_face = "arial";

	style data /
	font_size =8pt
	font_face = "ARIAL";
end;
run;	

/***Création d'un nouveau style "template"***/
proc template;
	define style sty.s3;
	parent=styles.rtf;

/**************************************
	test pour modifier les marges
**************************************/

replace Body from Document /
leftmargin = 3 cm
rightmargin = 3 cm
topmargin = 2.5 cm
bottommargin = 2.5 cm;


	style systemtitle /
	font_face = "times"
	font_size = 7pt
	font_weight = bold
	font_style= italic
	background=cxe0e0e0;

	style header /
	background=#EFF0FF
	font_weight = bold
	font_size = 7pt
	font_face = "times"
	; 

	style rowheader /
	font_weight = bold
	font_size = 7pt
	font_face = "times";

	style footer /
	background=#EFF0FF
	font_weight = bold
	font_size = 7pt
	font_face = "times"
	;

	style table /
	cellpadding=3
	cellspacing=0
	bordercolor=green
	foreground=green
	just=center
	rules = all
	frame = box; 

	style column  /
	just=c;

	style proctitle /
	foreground=#6633cc
	font_weight = bold
	font_size = 7pt
	font_face = "times";

	style data /
	font_size = 7pt
	font_face = "times";
end;
run;	



proc template;
	define style sty.s4;   /***nom du nouveau style***/
	parent=styles.rtf;     /***style parent***/

/**************************************
	test pour modifier les marges
**************************************/

replace Body from Document /
leftmargin = 1.5 cm
rightmargin = 1.5 cm
topmargin = 1.5 cm
bottommargin = 1.5 cm;


/***modification des attributs des titres***/
	style systemtitle /    
	font_face = "arial, helvetica, sans-sherif"
	font_size = 4
	font_weight = bold
	font_style= italic
	background=cxe0e0e0
;

/***modification des attributs de la première ligne des tableaux***/
	style header /
	background=#BBE1E6
	font_weight = bold
	font_size = 8pt
	font_face = "arial"
; 

/***modification des attributs de la première colonne des tableaux***/
	style rowheader /
	font_weight = bold
	font_size = 8pt
	font_face = "arial";

/***modification des attributs de la dernière ligne des tableaux***/	
	style footer /
	font_weight=bold
	background=#BBE1E6
	font_size = 8pt
	font_face="arial";


/***modification des attributs des tableaux***/		
	style table /
	cellpadding=5
	cellspacing=0
	bordercolor=#3F9EA9
	foreground=green
	just=center
	rules = all  	/* internal borders: none, all, cols, rows, groups */
	frame = box; 	/* outside borders: void, box, above/below, vsides/hsides, lhs/rhs */

	style column  /
	just=c;

/***modification des attributs des titres de procédure***/
	style proctitle / /*color=white*/
	foreground=black /*#BBE1E6 #6633cc*/
	font_weight = bold
	font_size = 8pt
	font_face = "arial";

	style data /
	font_size = 8pt
	font_face = "arial";
end;
run;

		%global chargement;
		%let chargement	= OK;
%end;

%mend;

%chargement();





%macro no_section(doc);
/*      Reading and writing to the same file at the same time can be trouble depending on where you are.  */ 
   data temp ;    
     length line $10000;
     infile "&doc" length=lg lrecl=1000000 end=eof;
     input @1 line $varying10000. lg;
run;

  data _null_;
      set temp ; retain flag  0 ; 
      file  "&doc";
/*  KEEP FIRST SECTION BREAK AND ELIMINATE THE REST */
      if (index(line,"\sect") > 0) then do ;
         if ( flag ) then  
            line = "{\pard\par}" ;
         else do ;
            flag = 1 ;
         end ; 
      end ;
    put line ;  
    run;
%mend no_section;
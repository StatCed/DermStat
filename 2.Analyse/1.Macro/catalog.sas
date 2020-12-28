*%include "D:\StructureEtude\1.XXEXXXX_Draft\2.Analyse\0.Driver.sas";

*%include "D:\StructureEtude\1.XXEXXXX_Draft\2.Analyse\1.Macro\10_report.sas" ;                                                        
*%include "D:\StructureEtude\1.XXEXXXX_Draft\2.Analyse\1.Macro\1_environnement.sas";                                                  
%include "D:\StructureEtude\1.XXEXXXX_Draft\2.Analyse\1.Macro\2_table.sas";                                                           
*%include "D:\StructureEtude\1.XXEXXXX_Draft\2.Analyse\1.Macro\3_exploration.sas";                                                   
*%include "D:\StructureEtude\1.XXEXXXX_Draft\2.Analyse\1.Macro\4_stat.sas";                                                            
*%include "D:\StructureEtude\1.XXEXXXX_Draft\2.Analyse\1.Macro\5_graphs.sas";                                                          
*%include "D:\StructureEtude\1.XXEXXXX_Draft\2.Analyse\1.Macro\6_anova.sas";                                                           
*%include "D:\StructureEtude\1.XXEXXXX_Draft\2.Analyse\1.Macro\7_demo.sas" ;                                                           
*%include "D:\StructureEtude\1.XXEXXXX_Draft\2.Analyse\1.Macro\8_catego.sas";                                                          
*%include "D:\StructureEtude\1.XXEXXXX_Draft\2.Analyse\1.Macro\9_binomial.sas";  
*%include "D:\StructureEtude\1.XXEXXXX_Draft\2.Analyse\1.Macro\11_chi2.sas";   
*%include "D:\StructureEtude\1.XXEXXXX_Draft\2.Analyse\1.Macro\12_mcnemar.sas";   

*macro-programmes spécifiques aux etudes EVIC;
*%include "D:\StructureEtude\1.XXEXXXX_Draft\2.Analyse\1.Macro\Evic\1_evic_stat.sas";  
*%include "D:\StructureEtude\1.XXEXXXX_Draft\2.Analyse\1.Macro\Evic\2_evic_analyse.sas";  
*%include "D:\StructureEtude\1.XXEXXXX_Draft\2.Analyse\1.Macro\Evic\3_evic_rapport.sas"; 
*
libname macro "d:\StructureEtude\1.XXEXXXX_Draft\2.Analyse\1.Macro"
*;

proc catalog catalog = macro.sasmacr;
contents;
run;






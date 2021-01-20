#library(Rcmdr)

P1 <- DATASET[which(DATASET$product=="1_CPHX2092"),]
P2 <- DATASET[which(DATASET$product=="2_CPHX2012"),]

para <- c()
pvalue <- c()

side = "less"

col1 <- P1$ptose_t1
col2 <- P1$ptose_t0

col3 <- P1$ptose_t2
col4 <- P1$ptose_t0

col5 <- P2$ptose_t1
col6 <- P2$ptose_t0

col7 <- P2$ptose_t2
col8 <- P2$ptose_t0

col9 <- DATASET$ptose_t1_t0
col10 <- DATASET$ptose_t2_t0

WP1_1=wilcox.test(col1,col2, paired=TRUE,alternative=side,exact = FALSE, correct = FALSE)
WP1_2=wilcox.test(col3,col4, paired=TRUE,alternative=side,exact = FALSE, correct = FALSE)
WP2_1=wilcox.test(col5,col6, paired=TRUE,alternative=side,correct=FALSE, exact=FALSE)
WP2_2=wilcox.test(col7,col8, paired=TRUE,alternative=side,exact = FALSE, correct = FALSE)

para <- append(para,"P1 t1-t0 Wilcoxon :")
para <- append(para,"P1 t2-t0 Wilcoxon :")
para <- append(para,"P2 t1-t0 Wilcoxon :")
para <- append(para,"P2 t2-t0 Wilcoxon :")

pvalue <- append(pvalue,WP1_1$p.value)
pvalue <- append(pvalue,WP1_2$p.value)
pvalue <- append(pvalue,WP2_1$p.value)
pvalue <- append(pvalue,WP2_2$p.value)

MW_1=wilcox.test(col9~product, data=DATASET,exact = FALSE, correct = FALSE,alternative=side)
MW_2=wilcox.test(col10~product, data=DATASET,exact = FALSE, correct = FALSE,alternative=side)

para <- append(para,"P1 vs P2 t1-t0 MW :")
para <- append(para,"P1 vs P2 t2-t0 MW :")

pvalue <- append(pvalue,MW_1$p.value)
pvalue <- append(pvalue,MW_2$p.value)


TP1_1=t.test(col1,col2, paired=TRUE,alternative=side)
TP1_2=t.test(col3,col4, paired=TRUE,alternative=side)
TP2_1=t.test(col5,col6, paired=TRUE,alternative=side)
TP2_2=t.test(col7,col8, paired=TRUE,alternative=side)

para <- append(para,"P1 t1-t0 Student :")
para <- append(para,"P1 t2-t0 Student :")
para <- append(para,"P2 t1-t0 Student :")
para <- append(para,"P2 t2-t0 Student :")

pvalue <- append(pvalue,TP1_1$p.value)
pvalue <- append(pvalue,TP1_2$p.value)
pvalue <- append(pvalue,TP2_1$p.value)
pvalue <- append(pvalue,TP2_2$p.value)

T_1=t.test(col9~product, alternative=side, data=DATASET)
T_2=t.test(col10~product, alternative=side, data=DATASET)

para <- append(para,"P1 vs P2 t1-t0 Student :")
para <- append(para,"P1 vs P2 t2-t0 Student :")

pvalue <- append(pvalue,T_1$p.value)
pvalue <- append(pvalue,T_2$p.value)


RESULT <- data.frame(para,pvalue)

RESULT






# Project: BGI db-db RNA-seq project
# Author: David Cheng & Davit Sargsyan
# Created: 7/5/2017       Last Update: 7/20/2017
#**************************************************
# # Install DESeq from Bioconductor
# source("https://bioconductor.org/biocLite.R")
# biocLite("DESeq2")

# Load packages
require(DESeq2)

# Set working directory to where count files stored----
setwd("C:/Users/davichen/Desktop/DN_Data/db_db mouse data/de_analysis")
or
setwd("C:/git_local/DESeq2/")  #(for Acer PC)
getwd() # to confirm wd

# Import featureCounts output count, tab-delimited text file into R (use Ron's script)
# d=read.table("filename",sep="\t",header=TRUE,stringsAsFactors=FALSE)

# // Meaning, read data from the filename (in quotes), using tab ("\t") as separator, into an object named "d".  
# The file has a first line containing the column headers (header=TRUE) and we want to read in any text (strings) 
# without turning them into statistical factors

# Load counts data from a tab separated values file----
dt1 <- read.table("combraw.count",
                  sep = "\t",
                  header = TRUE,
                  stringsAsFactors = FALSE)

# Rename the samples DR1 to DR8
colnames(dt1)[7:14] <- paste("DR", 
                             1:8, 
                             sep = "")

# Rename the samples 16wC_1, etc with week, genotype, and number (use this for heatmaps)
colnames(dt1)[7:14] <- paste(c("16wC_1","16wC_2","16wDB_1","16wDB_2",
                               "21wC_1","21wC_2","21wDB_1","21wDB_2"))

# Part I: Run a single model----
# Specify treatment groups
mat <- data.frame(condition = rep(c("16wC",
                                    "16wDB",
                                    "21wC",
                                    "21wDB"),
                                  each = 2),
                  batch = rep(1, 8))

# Ignore: trying to give unique id's to heatmap (you have to do it at "Rename the samples" step)
                    #mat <- data.frame(condition = c("16wC_1","16wC_2","16wDB_1","16wDB_2",
                                "21wC_1","21wC_2","21wDB_1","21wDB_2"),batch = rep(1, 8)
                

# Specify treatment groups 2 - all controls vs all diabetics (testing)
mat <- data.frame(condition = rep(c("Control",
                                    "Diabetes",
                                    "Control",
                                    "Diabetes"),
                                  each = 2),
                  batch = rep(1, 8))
# Prepare the data set
dds <- DESeq2::DESeqDataSetFromMatrix(countData = dt1[, 7:14],
                                      colData = mat,
                                      design = ~ condition)


# Differential expression analysis based on the Negative Binomial
dds <- DESeq2::DESeq(dds)
DESeq2::resultsNames(dds)

# Pause, plot PCA on raw/log transformed counts here. Check if variability among replicates greater than variability among conditions----

rld <- rlog(dds, blind = FALSE)
plotPCA(rld)
# Plot dispersion estimates single model - doesn't work on 2 groups at a time out.16w for example
plotDispEsts(dds)

# Compare Diabetes vs Control (Use if doing all controls vs all diabetes, otherwise ignore)
out.DvsC <- DESeq2::results(dds,
                            contrast = c("condition",
                                         "Diabetes",
                                         "Control"))
out.DvsC <- data.frame(dt1[, 1:6], 
                      out.DvsC)
write.csv(out.DvsC, 
          file = "out.DvsC_all.csv")

# Heatmap of count matrix on Extracting transformed values for single model----
library("pheatmap")
select <- order(rowMeans(counts(dds,normalized=TRUE)),
                decreasing = TRUE)[1:3000] # Can change sequence from 1:20 
                                          # to 1:1000 or however many you want,
                                          # but too much (24000) and it's a blur
select

df <- as.data.frame(colData(dds)[,"condition"])
df

# Rename rows in vector as.data.frame to match identically with names in column 7:14 
## If renamed columns DR1:8
rownames(df) <- paste(c("DR1",
                        "DR2",
                        "DR3",
                        "DR4",
                        "DR5","DR6","DR7","DR8"))

## If renamed columns 16wC_1...etc
rownames(df) <- paste(c("16wC_1","16wC_2","16wDB_1","16wDB_2",
                        "21wC_1","21wC_2","21wDB_1","21wDB_2"))


                  
## Optional part of Heatmap taken from (https://www.biostars.org/p/175858/)
nt <- normTransform(dds)
nt
log2.norm.counts <- assay(nt)[select,]

#Continue heatmap here

pheatmap(assay(rld)[select,], cluster_rows = FALSE, show_rownames = TRUE,
         cluster_cols = FALSE, annotation_col = df)

# Gives first 6 rows of sample columns (optional)
head(assay(rld),6)


# Compare 2 groups at a time----
## a. 16-week DB vs. Control
out.16w <- DESeq2::results(dds, 
                           contrast = c("condition",
                                        "16wDB",
                                        "16wC"))


# Plot MA 16 weeks - single model
plotMA(out.16w, ylim=c(-2,2))

# Plot Frequencies of p-values for 16 weeks run as single model
hist(out.16w$pvalue,
     col = "grey", border = "white", 
     xlab = "", ylab = "",
     main = "16 week Frequencies of p-values")

out.16w <- data.frame(dt1[, 1:6],
                      out.16w)
write.csv(out.16w, 
          file = "out.16w_all.csv")

## b. 21-week DB vs. Control
out.21w <- DESeq2::results(dds, 
                           contrast = c("condition",
                                        "21wDB",
                                        "21wC"))


# Plot MA 21 weeks - single model
plotMA(out.21w, ylim=c(-2,2))

# Plot Frequencies of p-values for 21 weeks run as single model
hist(out.21w$pvalue,
     col = "grey", border = "white", 
     xlab = "", ylab = "",
     main = "21 week Frequencies of p-values")


out.21w <- data.frame(dt1[, 1:6], 
                      out.21w)
write.csv(out.21w, 
          file = "out.21w_all.csv")
****************************************************************************************
# Part II: Alternatively, run the analysis 2 treatment groups at a time (Alternate)----
## A. Subset 16-week data
dt.16w <- dt1[, c(1:10)]

mat.16w <- data.frame(condition = rep(c("16wC",
                                        "16wDB"),
                                      each = 2),
                      batch = rep(1, 4))

# Prepare the data set
dds.16w <- DESeq2::DESeqDataSetFromMatrix(countData = dt.16w[, 7:10],
                                          colData = mat.16w,
                                          design = ~ condition)

# Differential expression analysis based on the Negative Binomial
dds.16w <- DESeq2::DESeq(dds.16w)

# Plot dispersion estimates
plotDispEsts(dds.16w)

# Pause, plot MA & PCA on 16wk raw counts here. Check if variability among replicates greater than variability among conditions----

plotMA(dds.16w, ylim=c(-2,2))
rld <- rlog(dds.16w, blind = F)
plotPCA(rld)

# Continue with DESeq2
DESeq2::resultsNames(dds.16w)

# Compare 16-week DB vs. Control
out.16w.2 <- DESeq2::results(dds.16w, 
                             contrast = c("condition",
                                          "16wDB",
                                          "16wC"))
# Plot Frequencies of p-values for 16 weeks
hist(out.16w.2$pvalue,
     col = "grey", border = "white", 
     xlab = "", ylab = "",
     main = "16 week Frequencies of p-values")

#optional analysis, do before running data.frame
summary(out.16w.2)

out.16w.2 <- data.frame(dt1[, 1:6],
                        out.16w.2)
write.csv(out.16w.2, 
          file = "out.16w.csv")

## B. Subset 21-week data
dt.21w <- dt1[, c(1:6, 11:14)]

mat.21w <- data.frame(condition = rep(c("21wC",
                                        "21wDB"),
                                      each = 2),
                      batch = rep(1, 4))

# Prepare the data set
dds.21w <- DESeq2::DESeqDataSetFromMatrix(countData = dt.21w[, 7:10],
                                          colData = mat.21w,
                                          design = ~ condition)

# Differential expression analysis based on the Negative Binomial
dds.21w <- DESeq2::DESeq(dds.21w)

# Plot dispersion estimates
plotDispEsts(dds.21w)

# Pause, plot MA & PCA on 21wk raw/log transformed counts here. Check if variability among replicates greater than variability among conditions----

rld <- rlog(dds.21w, blind = F)
plotPCA(rld)
plotMA(dds.21w, ylim=c(-2,2))

# Optional, shrink log2 fold changes
dds.21wLFC <- lfcShrink(dds.21w, coef = 2, out.21w.2=out.21w.2)
dds.21wLFC

# Continue with DESeq2
DESeq2::resultsNames(dds.21w)

# Compare 21-week DB vs. Control
out.21w.2 <- DESeq2::results(dds.21w, 
                             contrast = c("condition",
                                          "21wDB",
                                          "21wC"))

# Plot Frequencies of p-values for 21 weeks
hist(out.21w.2$pvalue,
     col = "grey", border = "white", 
     xlab = "", ylab = "",
     main = "21 week Frequencies of p-values")

# Optional analysis, do before running data.frame
summary(out.21w.2)


out.21w.2 <- data.frame(dt1[, 1:6],
                        out.21w.2)
write.csv(out.21w.2, 
          file = "out.21w2.csv")

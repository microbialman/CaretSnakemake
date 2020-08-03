#load packages
library(caret, quietly=TRUE)
library(doParallel)
library(tidyverse)
library(argparser, quietly=TRUE)

#setup parser
p <- arg_parser("Run a Caret model on pre-structured data.")
# Add command line arguments
p <- add_argument(p, "--structureddata", help="RData object with pre-structured data objects")
p <- add_argument(p, "--model", help="Model to run, using Caret nomenclature")
p <- add_argument(p, "--seed", help="Seed for randomisation", default = "808") 
p <- add_argument(p, "--metric", help="Summary metric to use for selecting best model (see caret documentation)", default = "Kappa")
p <- add_argument(p, "--metricmax", help="Should the summary metric be maximised for the optimal model", default = TRUE)
p <- add_argument(p, "--prepro", help="Comma seperated list of pre-processing steps to carry out")
p <- add_argument(p, "--threads", help="Threads for parallel processing")
p <- add_argument(p, "--outdir", help="Output directory")

# Parse the command line arguments
argv <- parse_args(p)
outdir <- argv$outdir

#setup parallel
if(!is.na(argv$threads)){
cl <- makePSOCKcluster(as.numeric(argv$threads))
registerDoParallel(cl)}

# load in the data
load(argv$structureddata)
classcol <- colnames(train)[colindex]

#check the packages are installed for the model to be run
modname <- argv$model
caretInfo <- getModelInfo(modname,regex = F)
packages <- caretInfo[[modname]]$library
available <- sapply(packages,require,character.only=T)
#try and install missing packages once
if(any(available==FALSE)){
  for(i in packages[available==FALSE]){
    try(install.packages(i,verbose=T))
  }
}
#if not skip this model and not missing packages
available <- sapply(packages,require,character.only=T)
if(any(available==FALSE)){
  logdat <- c(argv$model,"PACKAGES_UNAVAILABLE",paste(packages,collapse = ","))
  write.table(t(logdat),paste0(outdir,"/Models/",argv$model,".log"),row.names=F,col.names=F,sep=";")
  quit()
}

#set seed for reproducibility
set.seed(as.numeric(argv$seed))

#prep the preprocessing vector
prepro <- c()
if(!is.na(argv$prepro)){
  prepro <- strsplit(argv$prepro,",")[[1]]
}

classes <- train[,colindex]
variables <-train[,-colindex]

#train the model
mod <- try(train(
      x=variables,
      y=classes,
      method=argv$model,
      metric=argv$metric,
      preProcess=prepro,
      trControl=tcontrol))

if(class(mod)[1]=="try-error"){
  logdat <- c(argv$model,"MODEL_FAILED",gsub("\n","",mod[[1]]))
  write.table(t(logdat),paste0(outdir,"/Models/",argv$model,".log"),row.names=F,col.names=F,sep=";")
}else{
  logdat <- c(argv$model,"MODEL_COMPLETE","")
  saveRDS(mod, file=paste0(outdir,"/Models/",argv$model,".rds"))
  write.table(t(logdat),paste0(outdir,"/Models/",argv$model,".log"),row.names=F,col.names=F,sep=";")
}

stopCluster(cl)
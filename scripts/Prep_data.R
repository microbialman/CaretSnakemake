#load packages
library(caret, quietly=TRUE)
library(argparser, quietly=TRUE)

#setup parser
p <- arg_parser("Set-up test and train datasets and trainControl object for modelling.")
# Add command line arguments
p <- add_argument(p, "--file", help="Pre-prepared data file with all observations")
p <- add_argument(p, "--classcol", help="Column header for classification column") 
p <- add_argument(p,"--removecol", help="Columns to be removed (comma seperated list of names)",default=NULL)
p <- add_argument(p, "--seed", help="Seed for randomisation", default = "808") 
p <- add_argument(p, "--trainingper", help="Set the % of data for training (out of 100), remainder used for testing", default = "60")
p <- add_argument(p, "--cv_k", help="Set the k for k-fold cross-validation during training", default = "10")
p <- add_argument(p, "--cv_repeats", help="Set the number of times to repeat k-fold CV during training", default = "5")
p <- add_argument(p, "--selectfunction", help="Function for selecting optimal model (see caret documentation)", default = "best")
p <- add_argument(p, "--outdir", help="Output directory")

# Parse the command line arguments
argv <- parse_args(p)

#read in the data table defined in the args
#rows are samples (except the first which is column headers)
#all columns are used as predictors with the exception of a column defining class and any specified for removal
datafile <- read.table(argv$file,header=T)
#remove cols not in the analysis
if(!is.na(argv$removecol)){
  remcols <- strsplit(argv$removecol,",")[[1]]
  remind <- which(colnames(datafile)%in%remcols)
  if(length(remind)>0){
  filtdat <- datafile[,-remind]}else{
    filtdat <- datafile
  }
}else{
  filtdat <- datafile
}
colindex <- which(colnames(filtdat)==argv$classcol)
#make sure class is a factor
filtdat[,colindex] <- factor(filtdat[,colindex])


#generate the data structures to train models from
set.seed(as.numeric(argv$seed))

#check if the percentage to train is as a percent or fraction
pertrain <- as.numeric(argv$trainingper)
if(pertrain>1){pertrain <- pertrain/100}

#partition to training and test data
trainingRows <- createDataPartition(filtdat[,colindex], p = pertrain, list = F)
train <- as.data.frame(filtdat[trainingRows,])
test <- as.data.frame(filtdat[-trainingRows,])

#generate the trainContol to use for all models
tcontrol <- trainControl(method="repeatedcv", number=as.numeric(argv$cv_k), repeats=as.numeric(argv$cv_repeats),
                         savePredictions = "final", classProbs = T,
                         index=createMultiFolds(train[,colindex], k=as.numeric(argv$cv_k),times=as.numeric(argv$cv_repeats)),
                         summaryFunction = multiClassSummary,
                         allowParallel=T,
                         selectionFunction =argv$selectfunction)

#write the objects to the output directory
save(datafile,filtdat,train,test,tcontrol,colindex,file = paste0(argv$outdir,"/structured_data.rda"))




## CaretSnakemake

A [Snakemake](https://github.com/snakemake/snakemake) pipeline to automate training of multiple machine learning algorithms on a dataset using the [caret](https://github.com/topepo/caret) package.
This enables concurrent training of multiple models on a compute cluster.

CaretSnakemake employs the approach used in [caretEnsemble](https://github.com/zachmayer/caretEnsemble) and [SIMON](https://github.com/genular/simon-frontend), where the resampling of the data used to train models is fixed prior to training the various algorithms available within [caret](https://github.com/topepo/caret). This produces more comparable metrics to benchmark the performance of different algorithms against one another.

Data is split into a training and test set and resampled training datasets are defined for k-fold cross-validation (repeated n times).

Models are then trained from a list of selected caret methods, training models concurrently as separate jobs with independent multi-threading available for each model.
[caret](https://github.com/topepo/caret) will automatically run parameterisation for each model, selecting the best fitting model for the training data across the cross-validation based on the chosen metric.

All generated models are then used to classify the test data and the model performance on the training and test datasets can be compared in the interactive report generated.
The report allows comparison of several different metrics and some basic feature importance visualisation using the varImp function from [caret](https://github.com/topepo/caret).

## Install

CaretSnakemake requires a functional python3 conda install (such as [miniconda](https://docs.conda.io/en/latest/miniconda.html)) with [Snakemake installed](https://snakemake.readthedocs.io/en/stable/).
This repo can then be cloned and the Snakemake pipeline called as detailed below.

## Input

The pipeline input is a tab-delimited text file with a table containing both the predictor and classifier variables for all data (both testing and training). Rows should be samples and columns should be variables, the first line is taken as the column headers.
A copy of the default configuration file (config/default.yml) must also be generated that specifies all the details for the run, such as the column containing the classes and columns to be ignored, the metric to optimise in training and the partitions for test and training and for cross validation, as well as additional parameters that are passed to [caret](https://github.com/topepo/caret).

## Running

Once the input table and config file have been prepared, the pipeline should be run in the directory where the output folder is to be created as follows:

```bash
snakemake --snakefile path_to_repo/Caret_Snakemake/CaretSnakemake.smk --configfile edited_config_file.yml --cores 2 --use-conda
```

Additional arguments are required to submit to a cluster and will depend on the specific cluster configuration, more details are available in the [Snakemake documentation](https://snakemake.readthedocs.io/en/stable/executing/cluster.html).

## Output

The pipeline will produce all output into the directory specified in the configuration file.
This folder will contain individual R objects for each model fit and Report.html, an interactive report summarising model metrics.

## Notes

[caret](https://github.com/topepo/caret) is a wrapper for numerous other machine learning R packages. The pipeline will attempt to install missing packages and dependencies in the modelling stage where possible. However, some packages are not available via CRAN and specific methods may require manual installation. An easy method to see which packages are not installed automatically (but required by the chosen methods) is to run the pipeline once and get the list of missing packages from the table at the end of Report.html.

To install any packages manually you will need to have run the CaretSnakemake pipeline at least once to generate the conda environment (this will be placed in .snakemake/conda/ and have a random alphanumeric name). You then need to activate this (`bash conda activate .snakemake/conda/abc123`) then run R and install packages as required. Alternatively, you can add packages to the conda environment yaml in the envs directory, however when using many different algorithms conda can have trouble solving the environment.




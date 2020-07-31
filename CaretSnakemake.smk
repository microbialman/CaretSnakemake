#This snakefile contains the full pipeline and rules to run CaretSnakemake

#default config file (load own at runtime using --configfile)
configfile: workflow.basedir+"/config/default.yml"

#function to define the model output files from the list in the config
modlist=config["Modelling"]["modlist"].split(",")

#target rule
rule all:
    input:
        expand("{outdir}/Report/combined.log",outdir=config["Outdir"])

#prepare the data
rule dataprep:
    input:
        config["Data"]["file"]
    params:
        classcol=config["Data"]["classcol"],
        removecol=config["Data"]["removecol"],
        seed=config["Data"]["seed"],
        trainper=config["Data"]["trainingper"],
        cvk=config["Modelling"]["cvk"],
        cvn=config["Modelling"]["cvrepeat"],
        selecfun=config["Modelling"]["selectfunction"],
        workd=workflow.basedir,
        odir=config["Outdir"]
    output:
        expand("{outdir}/structured_data.rda",outdir=config["Outdir"])
    conda:
        "envs/caret_snake_R.yml"
    shell:
        "Rscript {params.workd}/scripts/Prep_data.R --file {input} --classcol {params.classcol} --removecol {params.removecol} --seed {params.seed} --trainingper {params.trainper} --cv_k {params.cvk} --cv_repeats {params.cvn} --selectfunction {params.selecfun} --outdir {params.odir}"

#run each of the models in the model list
rule runmods:
    input:
        expand("{outdir}/structured_data.rda",outdir=config["Outdir"])
    params:
        seed=config["Modelling"]["seed"],
        metric=config["Modelling"]["metric"],
        metricmax=config["Modelling"]["metricmax"],
        prepro=config["Modelling"]["prepro"],
        threads=config["Modelling"]["threads"],
        workd=workflow.basedir,
        odir=config["Outdir"]
    threads:
        int(config["Modelling"]["threads"])
    output:
        expand("{outdir}/Models/{{model}}.log",outdir=config["Outdir"])
    conda:
        "envs/caret_snake_R.yml"
    shell:
        "Rscript {params.workd}/scripts/Run_model.R --structureddata {input} --model {wildcards.model} --seed {params.seed} --metric {params.metric} --metricmax {params.metricmax} --prepro {params.prepro} --threads {params.threads} --outdir {params.odir}"

#merge the logs
rule mergelogs:
    input:
        expand("{outdir}/Models/{model}.log",outdir=config["Outdir"],model=modlist)
    output:
        expand("{outdir}/Report/combined.log",outdir=config["Outdir"])
    shell:
        "cat {input} > {output}"
    

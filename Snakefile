import pandas as pd
import os

SNAKEMAKE_DIR = os.path.dirname(workflow.snakefile)

configfile: "%s/config.json" % SNAKEMAKE_DIR
SEX = config.get("sex")
SAMPLE_NAME = config.get("sample")

# Load SRA run manifest and annotate it with a human-readable sample id in the
# format of "<species>_<sex>_<sample_name>".
RUN_INFO = pd.read_csv(config["sra_run_info"])
RUN_INFO["SampleId"] = RUN_INFO.apply(lambda row: "_".join(map(str, (row["ScientificName"].replace(" ", "-"), SEX or row["Sex"], SAMPLE_NAME or row["SampleName"].replace(" ", "-")))), axis=1)
SAMPLES = RUN_INFO["SampleId"].tolist()
RUNS = RUN_INFO["Run"].tolist()

if not os.path.exists("log"):
    os.makedirs("log")

def _get_run_by_sample_id(wildcards):
    pass

localrules: bam, fastq, sra

rule bam:
    input: expand("bam/{sample}/{run}/{run}.bam", zip, sample=SAMPLES, run=RUNS)

rule fastq:
    input: expand("fastq/{sample}/{run}/{run}_1.fastq.gz", zip, sample=SAMPLES, run=RUNS)

rule sra:
    input: expand("sra/{sample}/{run}/{run}.sra", zip, sample=SAMPLES, run=RUNS)

rule get_bam_files_from_sra_file:
    input: "sra/{sample}/{run}/{run}.sra"
    output: "bam/{sample}/{run}/{run}.bam"
    params: sge_opts="-l mfree=30G -l h_rt=4:0:0:0 -l ssd=true", name="{run}.sra"
    shell:
        "rsync --bwlimit=50000 {input} $TMPDIR; "
        "sam-dump -u $TMPDIR/{params.name} | samtools view -b - > {output}"

rule get_fastq_files_from_sra_file:
    input: "sra/{sample}/{run}/{run}.sra"
    output: "fastq/{sample}/{run}/{run}_1.fastq.gz", "fastq/{sample}/{run}/{run}_2.fastq.gz"
    params: sge_opts="-l mfree=4G -l h_rt=1:0:0", run_prefix=lambda wildcards: wildcards.run[:6]
    shell: "fastq-dump --defline-seq '@[$ac_]$sn/$ri' --defline-qual '+' --split-files --gzip --outdir `dirname {output[0]}` `pwd`/{input}"

rule get_sra_by_run:
    output: "sra/{sample}/{run}/{run}.sra"
    params: sge_opts="-l mfree=4G -l h_rt=1:0:0", run_prefix=lambda wildcards: wildcards.run[:6], sra_prefix=lambda wildcards: wildcards.run[:3]
    shell: "ascp -i $MOD_GSASPERA_DIR/connect/etc/asperaweb_id_dsa.putty -L . -l 1 -QTr -l 300m anonftp@ftp-trace.ncbi.nlm.nih.gov:/sra/sra-instant/reads/ByRun/sra/{params.sra_prefix}/{params.run_prefix}/{wildcards.run}/{wildcards.run}.sra `dirname {output}`"

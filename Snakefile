import pandas as pd

configfile: "config.json"

# Load SRA run manifest and annotate it with a human-readable sample id in the
# format of "<species>_<sex>_<sample_name>".
RUN_INFO = pd.read_csv(config["sra_run_info"])
RUN_INFO["SampleId"] = RUN_INFO.apply(lambda row: "_".join((row["ScientificName"].replace(" ", "-"), row["Sex"], row["SampleName"])), axis=1)
SAMPLES = RUN_INFO["SampleId"].tolist()
RUNS = RUN_INFO["Run"].tolist()
print(SAMPLES)

def _get_run_by_sample_id(wildcards):
    pass

rule all:
    input: expand("fastq/{sample}/{run}/{run}_1.fastq.gz", zip, sample=SAMPLES, run=RUNS)

rule get_fastq_files_from_sra_file:
    input: "sra/{sample}/{run}/{run}.sra"
    output: "fastq/{sample}/{run}/{run}_1.fastq.gz", "fastq/{sample}/{run}/{run}_2.fastq.gz"
    params: run_prefix=lambda wildcards: wildcards.run[:6]
    shell: "fastq-dump -I --split-files --gzip --outdir `basedir {output[0]}` `pwd`/{input}"

rule get_sra_by_run:
    output: "sra/{sample}/{run}/{run}.sra"
    params: run_prefix=lambda wildcards: wildcards.run[:6]
    shell: "ascp -i $MOD_GSASPERA_DIR/connect/etc/asperaweb_id_dsa.putty -L . -l 1 -QTr -l 300m anonftp@ftp-trace.ncbi.nlm.nih.gov:/sra/sra-instant/reads/ByRun/sra/SRR/{params.run_prefix}/{wildcards.run}/{wildcards.run}.sra `basedir {output}`"
# sratools

Tools for downloading and processing data from the Sequence Read Archive (SRA)

## Usage

Identify files to download from the [SRA](http://www.ncbi.nlm.nih.gov/sra)
search interface, click the "Send to" dropdown menu , select "File" as the
destination, and set "Format" to "RunInfo".

Copy the `SraRunInfo.csv` file into the current working directory. Optionally,
rename the file with a more descriptive title and update `config.json` to point
to the new file name. Add or remove lines from the run info file to change which
files to download and extract.

Download the source code for `sratools`.

    git clone https://github.com/EichlerLab/sratools.git
    cd sratools

Setup the working environment by adding [Anaconda](https://www.continuum.io),
[Aspera](http://downloads.asperasoft.com/downloads), and [SRA
Toolkit](https://github.com/ncbi/sra-tools) to the environment.

    . config.sh

Download all SRA files grouped by sample id and run accession.

    snakemake sra

Extract compressed FASTQs from the SRA files.

    snakemake fastq

If the SRA run information is missing proper annotations for sex or sample name
for a specific sample, an override value for both of these attributes can be
specified through the Snakemake configuration interface.

    snakemake sra --config sex=F sample=Kamilah

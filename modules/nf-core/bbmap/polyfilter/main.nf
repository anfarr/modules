// TODO nf-core: A module file SHOULD only define input and output files as command-line parameters.
//               All other parameters MUST be provided using the "task.ext" directive, see here:
//               https://www.nextflow.io/docs/latest/process.html#ext
//               where "task.ext" is a string.
//               Any parameters that need to be evaluated in the context of a particular sample
//               e.g. single-end/paired-end data MUST also be defined and evaluated appropriately.

process BBMAP_POLYFILTER {
    tag "$meta.id"
	// TODO self: Probably should be set to process_single
    label 'process_low'

    // TODO nf-core: List required Conda package(s).
    //               Software MUST be pinned to channel (i.e. "bioconda"), version (i.e. "1.10").
    //               For Conda, the build (i.e. "h9402c20_2") must be EXCLUDED to support installation on different operating systems.
    // TODO nf-core: See section in main README for further information regarding finding and adding container addresses to the section below.
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bbmap:39.10--h92535d8_0':
        'biocontainers/bbmap:39.10--h92535d8_0' }"

    input:

    // TODO nf-core: Where applicable please provide/convert compressed files as input/output
    //               e.g. "*.fastq.gz" and NOT "*.fastq", "*.bam" and NOT "*.sam" etc.
    tuple val(meta), path(read)

    output:
    // TODO nf-core: Named file extensions MUST be emitted for ALL output channels
    tuple val(meta), path("*.fastq.gz"), emit: reads
    // TODO nf-core: List additional required output channels/values here
    path "versions.yml" , emit: versions
	tuple val(meta), path("*_clean.fastq.gz"), emit: cleaned
	tuple val(meta), path("*_failed.fastq.gz"), emit: failed


    when:
    task.ext.when == null || task.ext.when

    script:
	def args = task.ext.args ?: ''
	def prefix = task.ext.prefix ?: "${meta.id}"
	def read_1 = meta.single_end ? read : read[0]
	def read_2 = meta.single_end ? "" : "in2=${read[1]}"
	def extra_list = meta.depth_filtering ? "" : "" // TODO: Set a switch to generate a comma separated list for the extra= input file. It must be the same files as the input files for depth based filtering

	"""
	polyfilter.sh \\
		in=$read_1 \\
		$read_2 \\
		out=${prefix}_clean.fastq.gz \\
		outb=${prefix}_failed.fastq.gz \\
		-Xmx${task.memory}.toGiga()g \\
		-eoom
		$args

	cat <<-END_VERSIONS > versions.yml
	"${task.process}":
		polyfilter: \$(polyfilter.sh --version |& sed '2!d ; s/polyfilter//')
	END_VERSIONS
	"""

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${reads.baseName}"
    // TODO nf-core: A stub section should mimic the execution of the original module as best as possible
    //               Have a look at the following examples:
    //               Simple example: https://github.com/nf-core/modules/blob/818474a292b4860ae8ff88e149fbcda68814114d/modules/nf-core/bcftools/annotate/main.nf#L47-L63
    //               Complex example: https://github.com/nf-core/modules/blob/818474a292b4860ae8ff88e149fbcda68814114d/modules/nf-core/bedtools/split/main.nf#L38-L54
    """
    touch ${prefix}.fastq.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        polyfilter: \$(polyfilter.sh --version |& sed '2!d ; s/polyfilter//')
    END_VERSIONS
    """
}

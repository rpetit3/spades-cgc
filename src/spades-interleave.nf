#!/usr/bin/env nextflow
import groovy.json.JsonSlurper
params.help = null
params.output = null
params.sample = null
params.fq = null
params.cpu = 1
params.genome_size = 2814816 // S. aureus, adjust accordingly
params.assembler_only = false
params.clear_cache_on_success = true
params.clear_logs = true

if (params.help) {
    print_usage()
    exit 0
}

check_input_params()


// Set some global variables
sample = params.sample
outdir = params.output ? params.output : './'
cpu = params.cpu
genome_size = params.genome_size
assembler_only = params.assembler_only

/* ==== BEGIN SPADES ASSEMBLY ==== */
process spades_assembly {
    publishDir outdir, mode: 'copy', overwrite: true

    input:
        file fq from create_input_channel(params.fq)
    output:
        file '*.tar.gz'
    shell:
        flag = assembler_only ? '' : '--only-assembler'
        '''
        spades.py --12 !{fq} --careful -t !{cpu} -o ./ !{flag}
        mkdir !{sample}
        assemblathon_stats.pl -genome_size !{genome_size} -json -output_file !{sample}/!{sample}.contigs.json contigs.fasta
        assemblathon_stats.pl -genome_size !{genome_size} -json -output_file !{sample}/!{sample}.scaffolds.json scaffolds.fasta
        cp contigs.fasta !{sample}/!{sample}.contigs.fasta
        cp contigs.paths !{sample}/!{sample}.contigs.paths
        cp scaffolds.fasta !{sample}/!{sample}.scaffolds.fasta
        cp scaffolds.paths !{sample}/!{sample}.scaffolds.paths
        cp assembly_graph.fastg !{sample}/!{sample}.assembly_graph.fastg
        tar czf !{sample}-spades.tar.gz !{sample}/
        '''
}
/* ==== END SPADES ASSEMBLY ==== */

workflow.onComplete {
    if (workflow.success == true && params.clear_cache_on_success) {
        // No need to resume completed run so remove cache.
        file('./work/').deleteDir()
    }
    println """

    Pipeline execution summary
    ---------------------------
    Completed at: ${workflow.complete}
    Duration    : ${workflow.duration}
    Success     : ${workflow.success}
    workDir     : ${workflow.workDir}
    exit status : ${workflow.exitStatus}
    Error report: ${workflow.errorReport ?: '-'}
    """
}

// Utility Functions
def print_usage() {
    log.info 'SPAdes Assembly Pipeline'
    log.info ''
    log.info 'Required Options:'
    log.info '    --fq  FASTQ.GZ     Interleaved input FASTQ, compressed using GZIP'
    log.info '    --sample  STR      A sample name to give the assembly.'
    log.info ''
    log.info 'Optional:'
    log.info '    --output  DIR      Directory to write results to. (Default ./${NAME})'
    log.info '    --genome_size  INT Expected genome size (bp) for coverage estimation.'
    log.info '    --assembler_only   Skip the error correction step in SPAdes.'
    log.info '    --help          Show this message and exit'
    log.info ''
    log.info 'Usage:'
    log.info '    nextflow staphopia.nf --fq input.fastq.gz --sample saureus [more options]'
}

def check_input_params() {
    error = false
    if (!params.sample) {
        log.info('A sample name is required to continue. Please use --sample')
        error = true
    }
    if (!params.fq) {
        log.info('Compressed Interleaved FASTQ (gzip) is required. Please use --fq')
        error = true
    } else if (!file(params.fq).exists()) {
        log.info('Invailid input (--fq), please verify "' + params.fq + '"" exists.')
        error = true
    }
    if (error) {
        log.info('See --help for more information')
        exit 1
    }
}

def create_input_channel(input_1, input_2) {
    if (input_2 != null) {
        return Channel.value([file(input_1), file(input_2)])
    } else {
        return Channel.value(file(input_1))
    }
}

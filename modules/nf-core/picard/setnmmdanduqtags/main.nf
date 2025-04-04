process PICARD_SETNMMDANDUQTAGS {
    tag "$meta.id"
    label 'process_low'
    label 'process_long'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/picard:3.3.0--hdfd78af_0':
        'biocontainers/picard:3.3.0--hdfd78af_0' }"

    input:
    tuple val(meta), path(bam, name:"input/*")
    tuple val(meta2), path(reference)

    output:
    tuple val(meta), path("*.bam")                , emit: bam
    tuple val(meta), path("*.bai"), optional: true, emit: bai
    path "versions.yml"                           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    def avail_mem = 3072
    if (!task.memory) {
        log.info '[Picard SetNmMdAndUqTags] Available memory not known - defaulting to 3GB. Specify process memory requirements to change this.'
    } else {
        avail_mem = (task.memory.mega*0.8).intValue()
    }

    """
    picard \\
        -Xmx${avail_mem}M \\
        SetNmMdAndUqTags \\
        $args \\
        --INPUT ${bam} \\
        --OUTPUT ${prefix}.bam \\
        --REFERENCE_SEQUENCE ${reference}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        picard: \$( echo \$(picard SetNmMdAndUqTags --version 2>&1) | grep -o 'Version:.*' | cut -f2- -d:)
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.bam
    touch ${prefix}.bai

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        picard: \$( echo \$(picard SetNmMdAndUqTags --version 2>&1) | grep -o 'Version:.*' | cut -f2- -d:)
    END_VERSIONS
    """
}

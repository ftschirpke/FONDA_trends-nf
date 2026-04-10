process SMA_RBF {

    tag {"${sraData[0]} ${sraData[1].baseName} (${sraData[2]}-${sraData[3]})" }
    publishDir "${params.outdata}/", mode:'copy'
    container 'davidfrantz/force'

    cpus 10
    memory '40.GB'

    input:
    path( "*" )
    path( "*" ) 
    each sraData
    path( "*" )
    path( "*" )

    output:
    tuple val("${sraData[0]}"), val("${sraData[2]}"), val("${sraData[3]}"), val("${sraData[2]}_${sraData[3]}"), path( "output/${sraData[2]}_${sraData[3]}/${sraData[0]}/*/*" )
    """
    mkdir -p output/${sraData[2]}_${sraData[3]}/${sraData[0]}/ prov 
    force-higher-level ${sraData[1]}
    """

}

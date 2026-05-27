process PHENOLOGY_SOS_EOS {

    container "friedricht/nf-trends:latest"

    input:
    tuple val(id), val(endmember)

    output:
    tuple val(id), val(endmember), emit: ids

    script:

    // TODO: remove hard-coded path
    def trendBasePath = "/data/level3"
    def scriptBasePath = "/data/wf/codes_prm/cef"

    """
    python ${scriptBasePath}/01_Phenology_sos_eos.py ${trendBasePath}/${endmember} ${id}
    """

}

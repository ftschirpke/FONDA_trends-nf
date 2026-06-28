process AR {

    container "friedricht/nf-trends:v2"

    input:
    val(id)

    output:
    val(id),          emit: ids
    path("ar-out/*"), emit: paths

    script:

    // TODO: remove hard-coded path
    def trendBasePath = "/data/level3"
    def scriptBasePath = "/data/wf/codes_prm/AR"
    def outPath = "ar-out/"

    """
    mkdir ${outPath}
    Rscript ${scriptBasePath}/01_AR.R ${trendBasePath}/cef/${id} ${id} ${outPath}
    """

}

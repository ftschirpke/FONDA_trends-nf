process GLS {

    container "friedricht/nf-rscript:latest"
    // TODO: consider a smaller image

    input:
    val(ids)
    path(paths, stageAs: "ar-out/*")

    output:
    val(ids),          emit: ids
    path("gls-out/*"), emit: paths

    script:

    // TODO: remove hard-coded path
    def trendBasePath = "/data/level3"
    def scriptBasePath = "/data/wf/codes_prm/AR"
    def outPath = "gls-out"

    """
    mkdir ${outPath}
    Rscript ${scriptBasePath}/02_GLS_LINUX.R ar-out/ 'DE' ${outPath}
    """

}

process AR {

    container "rocker/geospatial"
    // TODO: consider a smaller image

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
    R ${scriptBasePath}/01_AR.R ${trendBasePath}/cef/${id} ${id} ${outPath}
    """

}

process FOLD_AND_FILL {

    container "pangeo/pangeo-notebook"
    // TODO: consider a smaller image

    input:
    val(id)

    output:
    val(id), emit: ids

    script:

    // TODO: remove hard-coded path
    def trendBasePath = "/data/level3"
    def scriptBasePath = "/data/wf/codes_prm/cef"

    """
    python ${scriptBasePath}/03_FoldAndFill.py ${trendBasePath} ${id}
    """

}

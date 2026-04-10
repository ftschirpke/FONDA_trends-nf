process SOS_EOS {

  tag { "(${aoi}-${aoipar})" }
  publishDir "${params.outdata}/", mode:'copy'

  conda "/data/Jakku/users/lewinska/miniconda3/envs/envpy39/"

  input:
  tuple val(sraData), val(aoi), val(aoipar), val(aoi_aoipar), path(sospath)
  path(soseosCode)

  output:
  tuple val("${aoi}"), val("${aoipar}"), val("${aoi_aoipar}"),
  path( "${sospath}/")

  """
  python ${soseosCode} ${sospath}

  """

}

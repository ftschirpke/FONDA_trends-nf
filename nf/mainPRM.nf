
include { TSA_SMA_RBF_parameters } from './TSA_SMA_RBF_parameters'
include { SMA_RBF } from './SMA_RBF'
include { SOS_EOS } from './SOS_EOS'
include { FNF } from './FNF'
include { CEF } from './CEF'
include { AR } from './AR'
include { GLS } from './GLS'

workflow {

    normalizedLevel2 = Channel.fromPath( "${params.level2norm}" )
    masksChannel = Channel.fromPath( "${params.masks}" )

    Tiles = Channel.fromPath( "${params.DirTiles}" )
    endmembers = Channel.fromPath( "${params.DirEndm}" )
    
    aoiChannel = Channel.of( "SA" )
    aoiparChannes = Channel.of("SA")
    aoiCombinations = aoiChannel.combine(aoiparChannes)

    parametersChannel = Channel.of(
        // endmember+variang (also: name), endmember's no, RMSE{TRUE,FALSE}, RBF: sigma1, sigma2, sigma3,
        // OUTPUT_TSI{TRUE,FALSE}, OUTPUT_SPL{TRUE,FALSE}, OUTPUT_LSP{TRUE,FALSE}
        ["gv",         1,"TRUE",  8,  16, 32, "TRUE", "TRUE",  "TRUE" ],
        ["npv",        2,"FALSE", 8,  16, 32, "TRUE", "FALSE", "FALSE"],
        ["soil",       3,"FALSE", 8,  16, 32, "TRUE", "FALSE", "FALSE"],
        ["shade",      4,"FALSE", 8,  16, 32, "TRUE", "FALSE", "FALSE"],
        ["gv_wide",    1,"FALSE", 16, 48, 96, "TRUE", "FALSE", "FALSE"],
        ["npv_wide",   2,"FALSE", 16, 48, 96, "TRUE", "FALSE", "FALSE"],
        ["soil_wide",  3,"FALSE", 16, 48, 96, "TRUE", "FALSE", "FALSE"],
        ["shade_wide", 4,"FALSE", 16, 48, 96, "TRUE", "FALSE", "FALSE"]
    )

    TSA_SMA_RBF_parameters_input = aoiCombinations.combine(parametersChannel)

    SRAParamFiles = TSA_SMA_RBF_parameters( TSA_SMA_RBF_parameters_input )
    //   val(name),   path( "${name}_config.prm" ), val(aoi), val(aoipar) 
    // = name ("gv"), config_path,                  aoi,      aoipar

    SMA_RBF( normalizedLevel2, masksChannel, SRAParamFiles, Tiles, endmembers)

    // sraData = SRAParamFiles
    // it = val("${sraData[0]}"),     val("${sraData[2]}"), val("${sraData[3]}"), val("${sraData[2]}_${sraData[3]}"), path( "output/${sraData[2]}_${sraData[3]}/${sraData[0]}/*/*" )
    //    = "gv" (endmember+variang), aoi,                  aoipar,               aoi_aoipar,                         aoi_output_path
    smaDataGV = SMA_RBF.out.filter{it[0] == 'gv'}.map{ [ it[0], it[1], it[2], it[3],
                                  (it[4].findAll{it =~"S-LSP.tif"}).parent.parent.unique()]}

    SOS_EOS(smaDataGV, file(params.soeosCode)).view()

    rbfChannel = SMA_RBF.out.map{[it[0], it[1], it[2], it[3], 
                                 (it[4].parent.parent.unique()).collect()]}
                                 .groupTuple(by: 3)
                                 .map{[it[0], it[1], it[2], it[3], it[4].flatten()]}


    FNF(rbfChannel, file(params.fnfCode))

    cefChannel = FNF.out.map{[it[0], it[1], it[2], it[3],
                             (it[4].parent)]}.view()

    CEF(cefChannel, file(params.cefCode))

    arChannel = CEF.out.map{[it[1], it[2], it[3], it[4]]}

    AR(arChannel, file(params.arCode))
    
    glsChannel = AR.out.map{[it[0], it[1], it[2], it[3]]}.view()

    GLS(glsChannel, params.glsCode).view()

}

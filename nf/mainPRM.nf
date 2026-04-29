
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
    // gv    = green vegetation
    // npv   = non-photosenthetically vegetation
    // soil
    // shade

    TSA_SMA_RBF_parameters_input = aoiCombinations.combine(parametersChannel)

    // [CONFIG] Generate configuration files for FORCE
    SRAParamFiles = TSA_SMA_RBF_parameters( TSA_SMA_RBF_parameters_input )
    //   val(name),   path( "${name}_config.prm" ), val(aoi), val(aoipar) 
    // = name,        config_path,                  aoi,      aoipar
    
    // [FEATURE EXTRACTION] Spectral Mixture Analysis (SMA) - extract "endmembers" in or for pixel
    // [INTERPOLATION] Radial Basis Function (RBF) filtering - remove noise and data holes caused by clouds etc.
    SMA_RBF( normalizedLevel2, masksChannel, SRAParamFiles, Tiles, endmembers)

    // sraData = SRAParamFiles
    // it = val("${sraData[0]}"),     val("${sraData[2]}"), val("${sraData[3]}"), val("${sraData[2]}_${sraData[3]}"), path( "output/${sraData[2]}_${sraData[3]}/${sraData[0]}/*/*" )
    //    = "gv" (endmember+variang), aoi,                  aoipar,               aoi_aoipar,                         aoi_output_path
    smaDataGV = SMA_RBF.out.filter{it[0] == 'gv'}.map{ [ it[0], it[1], it[2], it[3],
                                  (it[4].findAll{it =~"S-LSP.tif"}).parent.parent.unique()]}
    // [FEATURE EXTRACTION] determine start of season (SOS) and end of season (EOS) from data
    SOS_EOS(smaDataGV, file(params.soeosCode)).view()

    // sraData = SRAParamFiles
    // it = val("${sraData[0]}"),     val("${sraData[2]}"), val("${sraData[3]}"), val("${sraData[2]}_${sraData[3]}"), path( "output/${sraData[2]}_${sraData[3]}/${sraData[0]}/*/*" )
    //    = name,                     aoi,                  aoipar,               aoi_aoipar (GROUP BY TARGET),       aoi_output_path
    rbfChannel = SMA_RBF.out.map{[it[0], it[1], it[2], it[3], 
                                 (it[4].parent.parent.unique()).collect()]}
                                 .groupTuple(by: 3)
                                 .map{[it[0], it[1], it[2], it[3], it[4].flatten()]}


    // [AGGREGATION AND IMPUTATION] FOLD all data of e.g. a specific month into one, and FILL big holes in data
    FNF(rbfChannel, file(params.fnfCode))

    // it = tuple val(sraData), val("${aoi[0]}"), val("${aoiprm[0]}"), val("${aoi_aoipar}"), path("${sraData[0]}")
    //    = name,               aoi,              aoipar,              aoi_aoipar,           name_path (???)
    cefChannel = FNF.out.map{[it[0], it[1], it[2], it[3],
                             (it[4].parent)]}.view()

    // [AGGREGATION] Cumulative Endmember Fractions (CEF) - Sum up endmember fractions e.g. over month based on SMA
    CEF(cefChannel, file(params.cefCode))

    // it = tuple val(sraData), val(aoi), val(aoiprm), val(aoi_aoipar), path("${in_path}/cef")
    //    = name,               aoi,      aoipar,      aoi_aoipar,      cef_name_path
    arChannel = CEF.out.map{[it[1], it[2], it[3], it[4]]}

    // [TREND ANALYSIS] AutoRegression (AR) - some regression on the time series
    AR(arChannel, file(params.arCode))
    
    // it = tuple val("${aoi}"), val("${aoipar}"), val("${aoi_aoipar}") , path("AR/${aoi_aoipar}")
    //    = aoi,                 aoipar,           aoi_aoipar,            ARpath
    glsChannel = AR.out.map{[it[0], it[1], it[2], it[3]]}.view()

    // [STATISTICS] Generalized Least Squares (GLS) - testing statistical hypotheses (?)
    GLS(glsChannel, params.glsCode).view()
    //    = tuple val("${aoi}"), val("${aoipar}"), val("${aoi_aoipar}"), path("GLS/${aoi_aoipar}")
    //    = aoi,                 aoipar,           aoi_aoipar,           GLSpath

}

 
// This implementation of parameter file generation for FORCE is heavily inspired
// by the one used in nf-core/rangeland.
// (see https://github.com/nf-core/rangeland/blob/21003c9efe984e91f7e43eea8de2c1466005105e/modules/local/force-higher_level/main.nf)

process FORCE_HIGHER_LEVEL {

    container "davidfrantz/force:3.10.04"
    
    input:
    val(id)
    path(cube)
    val(endmember)

    output:
    tuple val(id), path ('trend/*.tif*'), optional: true, emit: trend_files
    path '*.prm'                                          , emit: prm
    path "versions.yml"                                   , emit: versions

    script:

    // paths // TODO: remove hard-coded paths
    def ardBasePath  = "/data/level2_norm/"
    def ardPath      = "$ardBasePath${id}/"
    def maskDirPath = "/work-dir/mask/"
    def maskPath     = "$maskDirPath${id}/"
    def trendPath    = "/work-dir/level3/${endmember}"
    def provPath     = "/work-dir/prov/"

    // def start_date     = "1984-01-01"  // TODO: find correct value
    // def end_date       = "2025-12-31"  // TODO: find correct value
    def start_date     = "2023-07-01"  // TODO: remove this test value
    def end_date       = "2023-12-31"  // TODO: remove this test value
    def sensors_level2 = "LND04 LND05 LND07 LND08 LND09"
    def allow_list     = null

    def defaultEndmemberNums = ["gv": 1, "npv": 2, "soil": 3, "shade": 4]
    def endmemberNums = task.ext.args?.getAt("OUTPUT_FORMAT") ? task.ext.args["OUTPUT_FORMAT"] : defaultEndmemberNums
    def endmemberNum = endmemberNums.getAt(endmember)

    // TODO: configure mask i.e. GRA_2018_10m_conv_noData.tif
    def mask           = false

    // TODO: configure file output options i.e. codes_prm/L2_file_output_options_custom.txt
    // TODO: configure tile ranges i.e. X_TILE_RANGE = 15 108, Y_TILE_RANGE = 22 103
    // TODO: configure file tile i.e. vectors/DE_tiles.txt

    // extract tile
    def xTile = id[1..4]
    def yTile = id[7..10]

    // Input/Output directories
    def dirLower           = "DIR_LOWER = $ardBasePath"
    def dirHigher          = "DIR_HIGHER = $trendPath"
    def dirProv            = "DIR_PROVENANCE = $provPath"

    // Masking
    def dirMask            = mask                                          ? "DIR_MASK = $maskDirPath"                                           : "DIR_MASK = NULL"
    def baseMask           = mask                                          ? "BASE_MASK = $maskPath"                                             : "BASE_MASK = NULL"

    // Output options
    def outputFormat       = task.ext.args?.getAt("OUTPUT_FORMAT")         ? "OUTPUT_FORMAT = ${task.ext.args["OUTPUT_FORMAT"]}"                 : "OUTPUT_FORMAT = GTiff"
    def outputOptions      = task.ext.args?.getAt("FILE_OUTPUT_OPTIONS")   ? "FILE_OUTPUT_OPTIONS = ${task.ext.args["FILE_OUTPUT_OPTIONS"]}"     : "FILE_OUTPUT_OPTIONS = NULL"
    def outputExplode      = task.ext.args?.getAt("OUTPUT_EXPLODE")        ? "OUTPUT_EXPLODE = ${task.ext.args["OUTPUT_EXPLODE"]}"               : "OUTPUT_EXPLODE = FALSE"
    def outputSubDirs      = task.ext.args?.getAt("OUTPUT_SUBFOLDERS")     ? "OUTPUT_SUBFOLDERS = ${task.ext.args["OUTPUT_SUBFOLDERS"]}"         : "OUTPUT_SUBFOLDERS = FALSE"
    def failIfEmpty        = task.ext.args?.getAt("FAIL_IF_EMPTY")         ? "FAIL_IF_EMPTY = ${task.ext.args["FAIL_IF_EMPTY"]}"                 : "FAIL_IF_EMPTY = FALSE"

    // Parallel processing
    def nThreadRead        = task.ext.args?.getAt("NTHREAD_READ")          ? "NTHREAD_READ = ${task.ext.args["NTHREAD_READ"]}"                   : "NTHREAD_READ = 8"
    def nThreadCompute     = task.ext.args?.getAt("NTHREAD_COMPUTE")       ? "NTHREAD_COMPUTE = ${task.ext.args["NTHREAD_COMPUTE"]}"             : "NTHREAD_COMPUTE = 22"
    def nThreadWrite       = task.ext.args?.getAt("NTHREAD_WRITE")         ? "NTHREAD_WRITE = ${task.ext.args["NTHREAD_WRITE"]}"                 : "NTHREAD_WRITE = 4"
    def streaming          = task.ext.args?.getAt("STREAMING")             ? "STREAMING = ${task.ext.args["STREAMING"]}"                         : "STREAMING = TRUE"
    def prettyProgress     = "PRETTY_PROGRESS = FALSE"

    // Processing extent and resolution
    def xTilePrm           = "X_TILE_RANGE = $xTile $xTile"
    def yTilePrm           = "Y_TILE_RANGE = $yTile $yTile"
    def fileTile           = allow_list                                    ? "FILE_TILE = $allow_list"                                           : "FILE_TILE = NULL"
    def chunkSize          = task.ext.args?.getAt("CHUNK_SIZE")            ? "CHUNK_SIZE = ${task.ext.args["CHUNK_SIZE"]}"                       : "CHUNK_SIZE = 0 0"

    def res                = task.ext.args?.getAt("RESOLUTION")            ? "RESOLUTION = ${task.ext.args["RESOLUTION"]}"                       : "RESOLUTION = 10"
    def reducePSF          = task.ext.args?.getAt("REDUCE_PSF")            ? "REDUCE_PSF = ${task.ext.args["REDUCE_PSF"]}"                       : "REDUCE_PSF = FALSE"
    def useL2Improph       = task.ext.args?.getAt("USE_L2_IMPROPHE")       ? "USE_L2_IMPROPHE = ${task.ext.args["USE_L2_IMPROPHE"]}"             : "USE_L2_IMPROPHE = FALSE"

    // Sensor allow list
    def sensors            = task.ext.args?.getAt("SENSORS")               ? "SENSORS = ${task.ext.args["SENSORS"]}"                             : "SENSORS = LND08 LND09 SEN2A SEN2B SEN2C"
    def targetSensor       = task.ext.args?.getAt("TARGET_SENSOR")         ? "TARGET_SENSOR = ${task.ext.args["TARGET_SENSOR"]}"                 : "TARGET_SENSOR = LNDLG"
    def productTypeMain    = task.ext.args?.getAt("PRODUCT_TYPE_MAIN")     ? "PRODUCT_TYPE_MAIN = ${task.ext.args["PRODUCT_TYPE_MAIN"]}"         : "PRODUCT_TYPE_MAIN = BOA"
    def productTypeQuality = task.ext.args?.getAt("PRODUCT_TYPE_QUALITY")  ? "PRODUCT_TYPE_QUALITY = ${task.ext.args["PRODUCT_TYPE_QUALITY"]}"   : "PRODUCT_TYPE_QUALITY = QAI"
    def spectralAdjust     = task.ext.args?.getAt("SPECTRAL_ADJUST")       ? "SPECTRAL_ADJUST = ${task.ext.args["SPECTRAL_ADJUST"]}"             : "SPECTRAL_ADJUST = FALSE"

    // QAI screening
    def qaiScreen          = task.ext.args?.getAt("SCREEN_QAI")            ? "SCREEN_QAI = ${task.ext.args["SCREEN_QAI"]}"                       : "SCREEN_QAI = NODATA CLOUD_OPAQUE CLOUD_BUFFER CLOUD_CIRRUS CLOUD_SHADOW SNOW SUBZERO SATURATION"
    def aboveNoise         = task.ext.args?.getAt("ABOVE_NOISE")           ? "ABOVE_NOISE = ${task.ext.args["ABOVE_NOISE"]}"                     : "ABOVE_NOISE = 0"
    def belowNoise         = task.ext.args?.getAt("BELOW_NOISE")           ? "BELOW_NOISE = ${"BELOW_NOISE"}"                                    : "BELOW_NOISE = 0"

    // Processing timeframe
    def dateRange          = task.ext.args?.getAt("DATE_RANGE")            ? "DATE_RANGE = ${task.ext.args["DATE_RANGE"]}"                       : "DATE_RANGE = 2010-01-01 2019-12-31"
    def doyRange           = task.ext.args?.getAt("DOY_RANGE")             ? "DOY_RANGE = ${task.ext.args["DOY_RANGE"]}"                         : "DOY_RANGE = 1 365"
    def dateIgnoreL7       = task.ext.args?.getAt("DATE_IGNORE_LANDSAT_7") ? "DATE_IGNORE_LANDSAT_7 = ${task.ext.args["DATE_IGNORE_LANDSAT_7"]}" : "DATE_IGNORE_LANDSAT_7 = 2099-12-31"

    // Spectral indexes
    def index              = task.ext.args?.getAt("INDEX")                 ? "INDEX = ${task.ext.args["INDEX"]}"                                 : "INDEX = SMA"
    def standardizeTss     = task.ext.args?.getAt("STANDARDIZE_TSS")       ? "STANDARDIZE_TSS = ${task.ext.args["STANDARDIZE_TSS"]}"             : "STANDARDIZE_TSS = NONE"
    def outputTss          = task.ext.args?.getAt("OUTPUT_TSS")            ? "OUTPUT_TSS = ${task.ext.args["OUTPUT_TSS"]}"                       : "OUTPUT_TSS = FALSE"

    // Spectral mixture analysis
    def endmemberFile      = task.ext.args?.getAt("FILE_ENDMEM")           ? "FILE_ENDMEM = ${task.ext.args["FILE_ENDMEM"]}"                     : "FILE_ENDMEM = NULL"
    def smaSumToOne        = task.ext.args?.getAt("SMA_SUM_TO_ONE")        ? "SMA_SUM_TO_ONE = ${task.ext.args["SMA_SUM_TO_ONE"]}"               : "SMA_SUM_TO_ONE = TRUE"
    def smaNonNeg          = task.ext.args?.getAt("SMA_NON_NEG")           ? "SMA_NON_NEG = ${task.ext.args["SMA_NON_NEG"]}"                     : "SMA_NON_NEG = TRUE"
    def smaShdNorm         = task.ext.args?.getAt("SMA_SHD_NORM")          ? "SMA_SHD_NORM = ${task.ext.args["SMA_SHD_NORM"]}"                   : "SMA_SHD_NORM = TRUE"
    def smaEndmember       = "SMA_ENDMEMBER = ${endmemberNum}"
    def smaOutputRms       = endmember == "gv"                             ? "OUTPUT_RMS = TRUE"                                                 : "OUTPUT_RMS = FALSE"

    // Interpolation parameters
    def interpolateMethod  = task.ext.args?.getAt("INTERPOLATE")           ? "INTERPOLATE = ${task.ext.args["INTERPOLATE"]}"                     : "INTERPOLATE = NONE"
    def movingMax          = endmember == "gv"                             ? "MOVING_MAX = 8"                                                    : "MOVING_MAX = 16"
    def rbfSigma           = task.ext.args?.getAt("RBF_SIGMA")             ? "RBF_SIGMA = ${task.ext.args["RBF_SIGMA"]}"                         : "RBF_SIGMA = 8 16 32"
    def rbfCutoff          = task.ext.args?.getAt("RBF_CUTOFF")            ? "RBF_CUTOFF = ${task.ext.args["RBF_CUTOFF"]}"                       : "RBF_CUTOFF = 0.95"
    def harmonicTrend      = task.ext.args?.getAt("HARMONIC_TREND")        ? "HARMONIC_TREND = ${task.ext.args["HARMONIC_TREND"]}"               : "HARMONIC_TREND = TRUE"
    def harmonicModes      = task.ext.args?.getAt("HARMONIC_MODES")        ? "HARMONIC_MODES = ${task.ext.args["HARMONIC_MODES"]}"               : "HARMONIC_MODES = 3"
    def harmonicFitRanges  = task.ext.args?.getAt("HARMONIC_FIT_RANGE")    ? "HARMONIC_FIT_RANGE = ${task.ext.args["HARMONIC_FIT_RANGE"]}"       : "HARMONIC_FIT_RANGE = 2015-01-01 2017-12-31"
    def outputNrt          = task.ext.args?.getAt("OUTPUT_NRT")            ? "OUTPUT_NRT = ${task.ext.args["OUTPUT_NRT"]}"                       : "OUTPUT_NRT = FALSE"
    def intDayStep         = task.ext.args?.getAt("INT_DAY")               ? "INT_DAY = ${task.ext.args["INT_DAY"]}"                             : "INT_DAY = 16"
    def standardizedTsi    = task.ext.args?.getAt("STANDARDIZE_TSI")       ? "STANDARDIZE_TSI = ${task.ext.args["STANDARDIZE_TSI"]}"             : "STANDARDIZE_TSI = NONE"
    def outputTsi          = task.ext.args?.getAt("OUTPUT_TSI")            ? "OUTPUT_TSI = ${task.ext.args["OUTPUT_TSI"]}"                       : "OUTPUT_TSI = FALSE"

    // Python UDF parameters
    def udfPythonFile      = task.ext.args?.getAt("FILE_PYTHON")           ? "FILE_PYTHON = ${task.ext.args["FILE_PYTHON"]}"                     : "FILE_PYTHON = NULL"
    def udfPythonType      = task.ext.args?.getAt("PYTHON_TYPE")           ? "PYTHON_TYPE = ${task.ext.args["PYTHON_TYPE"]}"                     : "PYTHON_TYPE = PIXEL"
    def udfPythonOutput    = task.ext.args?.getAt("OUTPUT_PYP")            ? "OUTPUT_PYP = ${task.ext.args["OUTPUT_PYP"]}"                       : "OUTPUT_PYP = FALSE"

    // R UDF parameters
    def udfRFile           = task.ext.args?.getAt("FILE_RSTATS")           ? "FILE_RSTATS = ${task.ext.args["FILE_RSTATS"]}"                     : "FILE_RSTATS = NULL"
    def udfRType           = task.ext.args?.getAt("RSTATS_TYPE")           ? "RSTATS_TYPE = ${task.ext.args["RSTATS_TYPE"]}"                     : "RSTATS_TYPE = PIXEL"
    def udfROutput         = task.ext.args?.getAt("OUTPUT_RSP")            ? "OUTPUT_RSP = ${task.ext.args["OUTPUT_RSP"]}"                       : "OUTPUT_RSP = FALSE"

    // Spectral temporal metrics
    def outputStm          = task.ext.args?.getAt("OUTPUT_STM")            ? "OUTPUT_STM = ${task.ext.args["OUTPUT_STM"]}"                       : "OUTPUT_STM = FALSE"
    def stm                = task.ext.args?.getAt("STM")                   ? "STM = ${task.ext.args["STM"]}"                                     : "STM = Q25 Q50 Q75 AVG STD"

    // Folding parameters
    def foldType           = task.ext.args?.getAt("FOLD_TYPE")             ? "FOLD_TYPE = ${task.ext.args["FOLD_TYPE"]}"                         : "FOLD_TYPE = AVG"
    def standardizeFold    = task.ext.args?.getAt("STANDARDIZE_FOLD")      ? "STANDARDIZE_FOLD = ${task.ext.args["STANDARDIZE_FOLD"]}"           : "STANDARDIZE_FOLD = NONE"
    def outputFBY          = task.ext.args?.getAt("OUTPUT_FBY")            ? "OUTPUT_FBY = ${task.ext.args["OUTPUT_FBY"]}"                       : "OUTPUT_FBY = FALSE"
    def outputFBQ          = task.ext.args?.getAt("OUTPUT_FBQ")            ? "OUTPUT_FBQ = ${task.ext.args["OUTPUT_FBQ"]}"                       : "OUTPUT_FBQ = FALSE"
    def outputFBM          = task.ext.args?.getAt("OUTPUT_FBM")            ? "OUTPUT_FBM = ${task.ext.args["OUTPUT_FBM"]}"                       : "OUTPUT_FBM = FALSE"
    def outputFBW          = task.ext.args?.getAt("OUTPUT_FBW")            ? "OUTPUT_FBW = ${task.ext.args["OUTPUT_FBW"]}"                       : "OUTPUT_FBW = FALSE"
    def outputFBD          = task.ext.args?.getAt("OUTPUT_FBD")            ? "OUTPUT_FBD = ${task.ext.args["OUTPUT_FBD"]}"                       : "OUTPUT_FBD = FALSE"
    def outputTRY          = task.ext.args?.getAt("OUTPUT_TRY")            ? "OUTPUT_TRY = ${task.ext.args["OUTPUT_TRY"]}"                       : "OUTPUT_TRY = FALSE"
    def outputTRQ          = task.ext.args?.getAt("OUTPUT_TRQ")            ? "OUTPUT_TRQ = ${task.ext.args["OUTPUT_TRQ"]}"                       : "OUTPUT_TRQ = FALSE"
    def outputTRM          = task.ext.args?.getAt("OUTPUT_TRM")            ? "OUTPUT_TRM = ${task.ext.args["OUTPUT_TRM"]}"                       : "OUTPUT_TRM = FALSE"
    def outputTRW          = task.ext.args?.getAt("OUTPUT_TRW")            ? "OUTPUT_TRW = ${task.ext.args["OUTPUT_TRW"]}"                       : "OUTPUT_TRW = FALSE"
    def outputTRD          = task.ext.args?.getAt("OUTPUT_TRD")            ? "OUTPUT_TRD = ${task.ext.args["OUTPUT_TRD"]}"                       : "OUTPUT_TRD = FALSE"
    def outputCAY          = task.ext.args?.getAt("OUTPUT_CAY")            ? "OUTPUT_CAY = ${task.ext.args["OUTPUT_CAY"]}"                       : "OUTPUT_CAY = FALSE"
    def outputCAQ          = task.ext.args?.getAt("OUTPUT_CAQ")            ? "OUTPUT_CAQ = ${task.ext.args["OUTPUT_CAQ"]}"                       : "OUTPUT_CAQ = FALSE"
    def outputCAM          = task.ext.args?.getAt("OUTPUT_CAM")            ? "OUTPUT_CAM = ${task.ext.args["OUTPUT_CAM"]}"                       : "OUTPUT_CAM = FALSE"
    def outputCAW          = task.ext.args?.getAt("OUTPUT_CAW")            ? "OUTPUT_CAW = ${task.ext.args["OUTPUT_CAW"]}"                       : "OUTPUT_CAW = FALSE"
    def outputCAD          = task.ext.args?.getAt("OUTPUT_CAD")            ? "OUTPUT_CAD = ${task.ext.args["OUTPUT_CAD"]}"                       : "OUTPUT_CAD = FALSE"

    // Land surface phenology parameters (polarmetrics)
    def polStartThresh     = task.ext.args?.getAt("POL_START_THRESHOLD")   ? "POL_START_THRESHOLD = ${task.ext.args["POL_START_THRESHOLD"]}"     : "POL_START_THRESHOLD = 0.2"
    def polMidThresh       = task.ext.args?.getAt("POL_MID_THRESHOLD")     ? "POL_MID_THRESHOLD = ${task.ext.args["POL_MID_THRESHOLD"]}"         : "POL_MID_THRESHOLD = 0.5"
    def polEndThresh       = task.ext.args?.getAt("POL_END_THRESHOLD")     ? "POL_END_THRESHOLD = ${task.ext.args["POL_END_THRESHOLD"]}"         : "POL_END_THRESHOLD = 0.8"
    def polAdaptive        = endmember == "gv"                             ? "POL_ADAPTIVE = TRUE"                                               : "POL_ADAPTIVE = FALSE"
    def pol                = endmember == "gv" \
        ? task.ext.args?.getAt("GV-POL")                                   ? "POL = ${task.ext.args["GV-POL"]}"                                  : "POL = VSS VPS VES VSA RMR IGS"
        : task.ext.args?.getAt("OTHER-POL")                                ? "POL = ${task.ext.args["OTHER-POL"]}"                               : "POL = VSS VPS VES VSA RMR IGS"
    def standardizePol     = task.ext.args?.getAt("STANDARDIZE_POL")       ? "STANDARDIZE_POL = ${task.ext.args["STANDARDIZE_POL"]}"             : "STANDARDIZE_POL = NONE"
    def outputPCT          = task.ext.args?.getAt("OUTPUT_PCT")            ? "OUTPUT_PCT = ${task.ext.args["OUTPUT_PCT"]}"                       : "OUTPUT_PCT = FALSE"
    def outputPOL          = endmember == "gv"                             ? "OUTPUT_POL = TRUE"                                                 : "OUTPUT_POL = FALSE"
    def outputTRO          = task.ext.args?.getAt("OUTPUT_TRO")            ? "OUTPUT_TRO = ${task.ext.args["OUTPUT_TRO"]}"                       : "OUTPUT_TRO = FALSE"
    def outputCAO          = task.ext.args?.getAt("OUTPUT_CAO")            ? "OUTPUT_CAO = ${task.ext.args["OUTPUT_CAO"]}"                       : "OUTPUT_CAO = FALSE"

    // Trend parameters
    def trendTail          = task.ext.args?.getAt("TREND_TAIL")            ? "TREND_TAIL = ${task.ext.args["TREND_TAIL"]}"                       : "TREND_TAIL = TWO"
    def trendConf          = task.ext.args?.getAt("TREND_CONF")            ? "TREND_CONF = ${task.ext.args["TREND_CONF"]}"                       : "TREND_CONF = 0.95"
    def changePenalty      = task.ext.args?.getAt("CHANGE_PENALTY")        ? "CHANGE_PENALTY = ${task.ext.args["CHANGE_PENALTY"]}"               : "CHANGE_PENALTY = FALSE"

    """
    CHUNKSIZE='${chunkSize}'
    if [[ "\$CHUNKSIZE" == "CHUNK_SIZE = 0 0" ]]; then
        TILESIZE=\$(sed '6q;d' $cube)
        CHUNKSIZE="CHUNK_SIZE = \$TILESIZE"
    fi
    echo "Determined chunk size: \$CHUNKSIZE"

    PARAM=./tsa_${id}.prm
    cat <<EOF > \$PARAM
    ++PARAM_TSA_START++
    ${dirLower}
    ${dirHigher}
    ${dirProv}
    ${dirMask}
    ${baseMask}
    ${outputFormat}
    ${outputOptions}
    ${outputExplode}
    ${outputSubDirs}
    ${failIfEmpty}
    ${nThreadRead}
    ${nThreadCompute}
    ${nThreadWrite}
    ${streaming}
    ${prettyProgress}
    ${xTilePrm}
    ${yTilePrm}
    ${fileTile}
    \$CHUNKSIZE
    ${res}
    ${reducePSF}
    ${useL2Improph}
    ${sensors}
    ${targetSensor}
    ${productTypeMain}
    ${productTypeQuality}
    ${spectralAdjust}
    ${qaiScreen}
    ${aboveNoise}
    ${belowNoise}
    ${dateRange}
    ${doyRange}
    ${dateIgnoreL7}
    ${index}
    ${standardizeTss}
    ${outputTss}
    ${endmemberFile}
    ${smaSumToOne}
    ${smaNonNeg}
    ${smaShdNorm}
    ${smaEndmember}
    ${smaOutputRms}
    ${interpolateMethod}
    ${movingMax}
    ${rbfSigma}
    ${rbfCutoff}
    ${harmonicTrend}
    ${harmonicModes}
    ${harmonicFitRanges}
    ${outputNrt}
    ${intDayStep}
    ${standardizedTsi}
    ${outputTsi}
    ${udfPythonFile}
    ${udfPythonType}
    ${udfPythonOutput}
    ${udfRFile}
    ${udfRType}
    ${udfROutput}
    ${outputStm}
    ${stm}
    ${foldType}
    ${standardizeFold}
    ${outputFBY}
    ${outputFBQ}
    ${outputFBM}
    ${outputFBW}
    ${outputFBD}
    ${outputTRY}
    ${outputTRQ}
    ${outputTRM}
    ${outputTRW}
    ${outputTRD}
    ${outputCAY}
    ${outputCAQ}
    ${outputCAM}
    ${outputCAW}
    ${outputCAD}
    ${polStartThresh}
    ${polMidThresh}
    ${polEndThresh}
    ${polAdaptive}
    ${pol}
    ${standardizePol}
    ${outputPCT}
    ${outputPOL}
    ${outputTRO}
    ${outputCAO}
    ${trendTail}
    ${trendConf}
    ${changePenalty}
    ++PARAM_TSA_END++
    EOF

    force-higher-level \$PARAM


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        force: \$(force-higher-level -v)
    END_VERSIONS
    """
}

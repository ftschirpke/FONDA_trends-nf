include { FORCE_HIGHER_LEVEL } from './modules/force.nf'
include { PHENOLOGY_SOS_EOS } from './modules/phenology_sos_eos.nf'
include { FOLD_AND_FILL } from './modules/fold_and_fill.nf'
include { CEF } from './modules/cef.nf'
include { AR } from './modules/ar.nf'
include { GLS } from './modules/gls.nf'

workflow {
    def cube = "/data/level2_norm/datacube-definition.prj"

    // def start_date     = "1984-01-01"  // TODO: find correct value
    // def end_date       = "2025-12-31"  // TODO: find correct value
    def start_date     = "2023-07-01"  // TODO: remove this test value
    def end_date       = "2023-12-31"  // TODO: remove this test value

    def endmembers = Channel.from("gv", "npv", "soil", "shade")

    FORCE_HIGHER_LEVEL (params.ids, cube, endmembers, "/data/level2_norm", null, start_date, end_date)
    PHENOLOGY_SOS_EOS (FORCE_HIGHER_LEVEL.out.ids.filter { id, endmem -> endmem == "gv" } )
    FOLD_AND_FILL (PHENOLOGY_SOS_EOS.out.ids)
    CEF (FOLD_AND_FILL.out.ids)
    AR (CEF.out.ids)
    def ARids = AR.out.ids.collect()
    def ARpaths = AR.out.paths.collect()
    GLS (ARids, ARpaths)
    GLS.out.ids.view()
}


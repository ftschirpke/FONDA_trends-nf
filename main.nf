include { FORCE_HIGHER_LEVEL } from './modules/force.nf'
include { PHENOLOGY_SOS_EOS } from './modules/phenology_sos_eos.nf'

workflow {
    def cube = "/data/level2_norm/datacube-definition.prj"

    def endmembers = Channel.from("gv", "npv", "soil", "shade")

    FORCE_HIGHER_LEVEL (params.ids, cube, endmembers)
    PHENOLOGY_SOS_EOS (FORCE_HIGHER_LEVEL.out.ids.filter { id, endmem -> endmem == "gv" } )
}

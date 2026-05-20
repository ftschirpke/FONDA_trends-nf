include { FORCE_HIGHER_LEVEL } from './modules/force.nf'


workflow {
    def endmember = "https://github.com/nf-core/test-datasets/raw/rangeland/endmember/hostert-2003.txt"
    def cube = "/data/level2_norm/datacube-definition.prj"

    FORCE_HIGHER_LEVEL (params.ids, cube, endmember)
}

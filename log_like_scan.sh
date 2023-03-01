source utils/setup_cmssw.sh
source utils/bashFunctionCollection.sh

TAG=$1
NTUPLETAG=$2
ERA=$3
CHANNEL=$4
WP=$5
WP_ELE=$6

categories=("Pt25to30")


# categories=("Pt20to25" "Pt25to30" "Pt30to35" "Pt35to40" "PtGt40" "DM0" "DM1" "DM10_11" "Inclusive")


tag_folder="simultaneous_fit"


poi=prop_binhtt_mt_1_Run2018_bin14



for cat in ${categories[@]}; do

    if [[ ! -d lscan_/${tag_folder}/${ERA}/${CHANNEL}/${TAG}/${cat}/${poi} ]]
    then
        mkdir -p lscan/${tag_folder}/${ERA}/${CHANNEL}/${WP}/${cat}/${poi}
        mkdir -p lscan/${tag_folder}/${ERA}/${CHANNEL}/${WP}/${cat}/${poi}
    fi

    # DATACARD="/work/olavoryk/sim_fit/smhtt_ul/output/datacards/${NTUPLETAG}-${TAG}/${ERA}_tauid_${WP}/htt_mt_${cat}/"
    # workspace="/work/olavoryk/sim_fit/smhtt_ul/output/datacards/${NTUPLETAG}-${TAG}/${ERA}_tauid_${WP}/htt_mt_${cat}/workspace.root"

    DATACARD="/work/olavoryk/sim_fit/smhtt_ul/output/datacards/${NTUPLETAG}-${TAG}/${ERA}_tauid_${WP}/cmb/"
    workspace="/work/olavoryk/sim_fit/smhtt_ul/output/datacards/${NTUPLETAG}-${TAG}/${ERA}_tauid_${WP}/cmb/out_multidim.root"

                                                   
    cd $DATACARD

    
    combine -M MultiDimFit -n .nominal_${poi} --algo grid --redefineSignalPOIs r_EMB_${cat} -P $poi --floatOtherPOIs 1 --saveInactivePOI 1 --X-rtd MINIMIZER_analytic --cminDefaultMinimizerStrategy 0  --setParameterRanges $poi=-2,2 -m 125 -d $workspace --setParameters $poi=0,r=1.00 -v 2 --points 100 
    
    plot1DScan.py  higgsCombine.nominal_${poi}.MultiDimFit.mH125.root --POI $poi --y-max 16 --output ${TAG}_${ERA}_${CHANNEL}_${WP}_${cat}
    mv ${TAG}_${ERA}_${CHANNEL}_${WP}_${cat}*  /work/olavoryk/sim_fit/smhtt_ul/lscan/${tag_folder}/${ERA}/${CHANNEL}/${WP}/${cat}/${poi}/

done
exit 0


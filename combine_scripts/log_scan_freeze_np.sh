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


tag_folder="simultaneous_fit_freezed"





for cat in ${categories[@]}; do

    if [[ ! -d lscan_/${tag_folder}/${ERA}/${CHANNEL}/${TAG}/${cat}/${poi} ]]
    then
        mkdir -p lscan/${tag_folder}/${ERA}/${CHANNEL}/${WP}/${cat}/${poi}
        mkdir -p lscan/${tag_folder}/${ERA}/${CHANNEL}/${WP}/${cat}/${poi}
    fi



    DATACARD="/work/olavoryk/tight_vs_ele_sfs/smhtt_ul/output/datacards/${NTUPLETAG}-${TAG}/${ERA}_tauid_${WP}/htt_mt_${cat}/"
    # workspace="/work/olavoryk/sim_fit/smhtt_ul/output/datacards/${NTUPLETAG}-${TAG}/${ERA}_tauid_${WP}/cmb/out_multidim.root"
    

                                                   
    cd $DATACARD

    
    combine -M MultiDimFit -n .nominal_postfit  \
            --X-rtd MINIMIZER_analytic --cminDefaultMinimizerStrategy 0 \
            --setParameterRanges r=-2,2 -m 125 -d workspace.root \
             -v 2  --saveWorkspace



    combine -M MultiDimFit -n .nominal_total --algo grid  \
            --X-rtd MINIMIZER_analytic --cminDefaultMinimizerStrategy 0 \
            --setParameterRanges r=0.8,1.2 -m 125 -d higgsCombine.nominal_postfit.MultiDimFit.mH125.root \
             -v 1 --points 100  --snapshotName MultiDimFit 

    
    combine -M MultiDimFit -n .nominal_freeze_SSOS --algo grid  \
            --X-rtd MINIMIZER_analytic --cminDefaultMinimizerStrategy 0 \
            --setParameterRanges r=0.8,1.2 -m 125 -d higgsCombine.nominal_postfit.MultiDimFit.mH125.root \
             -v 1 --points 100  --snapshotName MultiDimFit --freezeParameters CMS_ExtrapSSOS_mt_Run2018


    combine -M MultiDimFit -n .nominal_freeze_bbb_SSOS --algo grid  \
        --X-rtd MINIMIZER_analytic --cminDefaultMinimizerStrategy 0 \
        --setParameterRanges r=0.8,1.2 -m 125 -d higgsCombine.nominal_postfit.MultiDimFit.mH125.root \
            -v 1 --points 100  --snapshotName MultiDimFit --freezeNuisanceGroups autoMCStats --freezeParameters CMS_ExtrapSSOS_mt_Run2018


    combine -M MultiDimFit -n .nominal_freeze_all --algo grid  \
        --X-rtd MINIMIZER_analytic --cminDefaultMinimizerStrategy 0 \
        --setParameterRanges r=0.8,1.2 -m 125 -d higgsCombine.nominal_postfit.MultiDimFit.mH125.root \
            -v 1 --points 100  --snapshotName MultiDimFit \
           --freezeParameters allConstrainedNuisances 


    plot1DScan.py higgsCombine.nominal_total.MultiDimFit.mH125.root --main-label "Total Uncert." \
      --others  higgsCombine.nominal_freeze_SSOS.MultiDimFit.mH125.root:"freeze SSOS":7 \
      higgsCombine.nominal_freeze_bbb_SSOS.MultiDimFit.mH125.root:"freeze bbb+SSOS":8 \
       higgsCombine.nominal_freeze_all.MultiDimFit.mH125.root:"stat only":6  \
       --output breakdown_ch --y-max 10 --y-cut 40 --breakdown "SSOS,bbb,syst,stat"
    
    # plot1DScan.py  higgsCombine.nominal_${poi}.MultiDimFit.mH125.root --POI $poi --y-max 16 --output ${TAG}_${ERA}_${CHANNEL}_${WP}_${cat}
    # mv ${TAG}_${ERA}_${CHANNEL}_${WP}_${cat}*  /work/olavoryk/sim_fit/smhtt_ul/lscan/${tag_folder}/${ERA}/${CHANNEL}/${WP}/${cat}/${poi}/

done


export PYTHONPATH=$PYTHONPATH:$PWD/Dumbledraw
CHANNEL=$1
ERA=$2
NTUPLETAG=$3
TAG=$4
MODE=$5
WP=$6
VS_ELE_WP=$7
DEEP_TAU=$8

VARIABLES="m_vis"
POSTFIX="-ML"
ulimit -s unlimited
source utils/setup_ul_samples.sh $NTUPLETAG $ERA

# Datacard Setup
# WP="medium"
datacard_output="datacards/${NTUPLETAG}-${TAG}/${ERA}_tauid_${WP}"

output_shapes="tauid_shapes-${WP}-${ERA}-${CHANNEL}-${NTUPLETAG}-${TAG}"
CONDOR_OUTPUT=output/condor_shapes/${WP}-${ERA}-${CHANNEL}-${NTUPLETAG}-${TAG}
shapes_output=output/${WP}-${ERA}-${CHANNEL}-${NTUPLETAG}-${TAG}/${output_shapes}
shapes_output_synced=output/${WP}-${ERA}-${CHANNEL}-${NTUPLETAG}-${TAG}/synced
shapes_rootfile=${shapes_output}.root
shapes_rootfile_mm=${shapes_output}_mm.root
shapes_rootfile_synced=${shapes_output_synced}_synced.root

# --setParameterRanges r=0.8,1.2:CMS_htt_tjXsec=-2.0,2.0:CMS_htt_fake_j_Run2018=-2.0,2.0  \ DM10_11 vtight
# --setParameterRanges r=0.8,1.2:CMS_htt_tjXsec=-2.0,2.0 \  "DM0" "DM1" "DM10_11" vvtight
# --setParameterRanges r=0.8,1.2:CMS_htt_tjXsec=-2.0,2.0 \   "DM10_11" medium the range should be CMS_htt_tjXsec=-1.5,1.5




# print the paths to be used
# echo "KINGMAKER_BASEDIR: $KINGMAKER_BASEDIR"
# echo "BASEDIR: ${BASEDIR}"
# echo "output_shapes: ${output_shapes}"
# echo "FRIENDS: ${FRIENDS}"

# categories=("Pt20to25" "Pt25to30" "Pt30to35" "Pt35to40" "PtGt40" "DM0" "DM1" "DM10_11" "Inclusive")
categories=( "DM10_11")

printf -v categories_string '%s,' "${categories[@]}"
# echo "Using Cateogires ${categories_string%,}"


# if [[ $MODE == "DATACARD" ]]; then
#     source utils/setup_cmssw.sh
#     # inputfile
#     inputfile="htt_${CHANNEL}.inputs-sm-Run${ERA}${POSTFIX}.root"
#     # for category in "pt_binned" "inclusive" "dm_binned"
#     $CMSSW_BASE/bin/slc7_amd64_gcc700/MorphingTauID2017 \
#         --base_path=$PWD \
#         --input_folder_mt=$shapes_output_synced \
#         --input_folder_mm=$shapes_output_synced \
#         --real_data=true \
#         --classic_bbb=false \
#         --binomial_bbb=false \
#         --jetfakes=0 \
#         --embedding=1 \
#         --verbose=true \
#         --postfix=$POSTFIX \
#         --use_control_region=true \
#         --auto_rebin=true \
#         --categories="all" \
#         --era=$ERA \
#         --output=$datacard_output
#     THIS_PWD=${PWD}
#     echo $THIS_PWD
#     cd output/$datacard_output/
#     for FILE in htt_mt_*/*.txt; do
#         sed -i '$s/$/\n * autoMCStats 0.0/' $FILE
#     done
#     cd $THIS_PWD

#     echo "[INFO] Create Workspace for datacard"
#     combineTool.py -M T2W -i output/$datacard_output/htt_mt_*/ -o workspace.root --parallel 4 -m 125
#     exit 0
# fi


if [[ $MODE == "IMPACTS" ]]; then
    source utils/setup_cmssw.sh
    
    if [ ! -d "impacts_vs_ele_medium/${ERA}/${CHANNEL}/${WP}" ]; then
        mkdir -p  impacts_vs_ele_medium/${ERA}/${CHANNEL}/${WP}
    fi



    for WSP in ${categories[@]}; do

        if [ ! -d "/work/olavoryk/tauID_SF_ES/smhtt_ul/impacts_vs_ele_medium/${ERA}/${CHANNEL}/${WP}/${WSP}/${TAG}" ]; then

            mkdir -p /work/olavoryk/tauID_SF_ES/smhtt_ul/impacts_vs_ele_medium/${ERA}/${CHANNEL}/${WP}/${WSP}/${TAG}
        fi
    for WSP in output/$datacard_output/htt_mt_*/workspace.root; do
        WORKSPACE=output/$datacard_output/htt_mt_${WSP}/workspace.root
        echo $WORKSPACE
        combineTool.py -M Impacts -d $WORKSPACE -m 125 \
                    --X-rtd MINIMIZER_analytic --cminDefaultMinimizerStrategy 0 \
                    --doInitialFit --robustFit 1 -v 3 \
                    --setParameterRanges r=0.8,1.2  \
                    --setParameters r=1.00 \
                    --parallel 16 \
                    --job-mode script

        bash job_combine_task_0.sh
        mv job_combine_task_0.sh /work/olavoryk/tauID_SF_ES/smhtt_ul/impacts_vs_ele_medium/${ERA}/${CHANNEL}/${WP}/${WSP}/${TAG}/initial_fit.sh
   

        combineTool.py -M Impacts -d $WORKSPACE -m 125 \
                    --X-rtd MINIMIZER_analytic --cminDefaultMinimizerStrategy 0 \
                    --robustFit 1 --doFits \
                    --setParameterRanges r=0.8,1.2 \
                    --setParameters r=1.00 \
                    --parallel 16 \
                    --job-mode script

        mv job_combine_task_*.sh /work/olavoryk/tauID_SF_ES/smhtt_ul/impacts_vs_ele_medium/${ERA}/${CHANNEL}/${WP}/${WSP}/${TAG}/

        combineTool.py -M Impacts -d $WORKSPACE -m 125 \
                    --X-rtd MINIMIZER_analytic --cminDefaultMinimizerStrategy 0 \
                    --robustFit 1 --doFits \
                    --setParameterRanges r=0.8,1.2 \
                    --setParameters r=1.00 \
                    --parallel 16 

        combineTool.py -M Impacts -d $WORKSPACE -m 125 -o /work/olavoryk/tauID_SF_ES/smhtt_ul/impacts_vs_ele_medium/${ERA}/${CHANNEL}/${WP}/${WSP}/${TAG}//tauid_${ERA}_${CHANNEL}_${WP}_${TAG}_${WSP}_impacts_1.json
        plotImpacts.py -i /work/olavoryk/tauID_SF_ES/smhtt_ul/impacts_vs_ele_medium/${ERA}/${CHANNEL}/${WP}/${WSP}/${TAG}/tauid_${ERA}_${CHANNEL}_${WP}_${TAG}_${WSP}_impacts_1.json -o tauid_${ERA}_${CHANNEL}_${WP}_${TAG}_impacts_${WSP}
        mv tauid_${ERA}_${CHANNEL}_${WP}_${TAG}_impacts_${WSP}.pdf /work/olavoryk/tauID_SF_ES/smhtt_ul/impacts_vs_ele_medium/${ERA}/${CHANNEL}/${WP}/${WSP}/${TAG}/
        
        # cleanup the fit files
        # rm higgsCombine*.root

        # move the fit files
        mv higgsCombine*.root /work/olavoryk/tauID_SF_ES/smhtt_ul/impacts_vs_ele_medium/${ERA}/${CHANNEL}/${WP}/${WSP}/${TAG}/
    done
    exit 0
fi

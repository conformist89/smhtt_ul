export PYTHONPATH=$PYTHONPATH:$PWD/Dumbledraw
CHANNEL=$1
ERA=$2
NTUPLETAG=$3
TAG=$4
MODE=$5

CHANNEL="ee"
VARIABLES="m_vis"
ulimit -s unlimited
source utils/setup_ul_samples.sh $NTUPLETAG $ERA

output_shapes="elees_shapes-${ERA}-${CHANNEL}-${NTUPLETAG}-${TAG}"
CONDOR_OUTPUT=output/condor_shapes/${ERA}-${CHANNEL}-${NTUPLETAG}-${TAG}
shapes_output=output/${ERA}-${CHANNEL}-${NTUPLETAG}-${TAG}/${output_shapes}
shapes_output_synced=output/${ERA}-${CHANNEL}-${NTUPLETAG}-${TAG}/synced
shapes_rootfile=${shapes_output}.root
shapes_rootfile_synced=${shapes_output_synced}_synced.root

# Datacard Setup
datacard_output="datacards/${NTUPLETAG}-${TAG}/${ERA}_elees"

# print the paths to be used
echo "KINGMAKER_BASEDIR: $KINGMAKER_BASEDIR"
echo "BASEDIR: ${BASEDIR}"
echo "output_shapes: ${output_shapes}"
echo "XSEC_FRIENDS: ${XSEC_FRIENDS}"

categories=("barrel" "endcap" "Inclusive")
printf -v categories_string '%s,' "${categories[@]}"
echo "Using Cateogires ${categories_string%,}"

if [[ $MODE == "COPY" ]]; then
    source utils/setup_root.sh
    echo "##############################################################################################"
    echo "#      Copy sample to ceph, it not there yet                                                     #"
    echo "##############################################################################################"
    # if the xsec friends directory does not exist, create it
    if [ ! -d "$BASEDIR/$ERA" ]; then
        mkdir -p $BASEDIR/$ERA
    fi
    if [ "$(ls -A $BASEDIR/$ERA)" ]; then
        echo "Ntuples already copied to ceph"
    else
        echo "Copying ntuples to ceph"
        rsync -avhPl $KINGMAKER_BASEDIR$ERA/ $BASEDIR$ERA/
    fi
    exit 0
elif [[ $MODE == "COPY_XROOTD" ]]; then
    source utils/setup_root.sh
    echo "##############################################################################################"
    echo "#      Copy sample to ceph, it not there yet                                                     #"
    echo "##############################################################################################"
    echo "[INFO] Copying ntuples to ceph via xrootd"
    echo "xrdcp -r $KINGMAKER_BASEDIR_XROOTD$ERA/ $BASEDIR$ERA/"
    if [ ! -d "$BASEDIR/$ERA" ]; then
        mkdir -p $BASEDIR/$ERA
    fi
    xrdcp -r $KINGMAKER_BASEDIR_XROOTD$ERA $BASEDIR
    exit 0
fi
# echo "##############################################################################################"
# echo "#      unset multicore bit                                                          #"
# echo "##############################################################################################"

# python3 unset_rootbit.py --basepath ${BASEDIR}

if [[ $MODE == "XSEC" ]]; then
    source utils/setup_root.sh
    echo "##############################################################################################"
    echo "#      Checking xsec friends directory                                                       #"
    echo "##############################################################################################"

    # if the xsec friends directory does not exist, create it
    if [ ! -d "$XSEC_FRIENDS" ]; then
        mkdir -p $XSEC_FRIENDS
    fi
    # if th xsec friends dir is empty, run the xsec friends script
    if [ "$(ls -A $XSEC_FRIENDS)" ]; then
        echo "xsec friends dir already exists"
    else
        echo "xsec friends dir is empty"
        echo "running xsec friends script"
        python3 friends/build_friend_tree.py --basepath $BASEDIR --outputpath $XSEC_FRIENDS --nthreads 20
    fi
    exit 0
fi
echo "##############################################################################################"
echo "#      Producing shapes for ${CHANNEL}-${ERA}-${NTUPLETAG}                                         #"
echo "##############################################################################################"

# if the output folder does not exist, create it
if [ ! -d "$shapes_output" ]; then
    mkdir -p $shapes_output
fi

if [[ $MODE == "CONTROL" ]]; then
    source utils/setup_root.sh
    python shapes/produce_shapes.py --channels $CHANNEL \
        --directory $NTUPLES \
        --${CHANNEL}-friend-directory $XSEC_FRIENDS $FF_FRIENDS \
        --era $ERA --num-processes 4 --num-threads 3 \
        --optimization-level 1 --skip-systematic-variations \
        --special-analysis "EleES" \
        --control-plot-set ${VARIABLES} \
        --output-file $shapes_output
    bash ./shapes/do_estimations.sh 2018 ${shapes_rootfile} 1
    for CATEGORY in "${categories[@]}"; do
        python3 plotting/plot_shapes_control_ee_channel.py -l --era Run${ERA} --input ${shapes_rootfile} --variables ${VARIABLES} --channels ${CHANNEL} --embedding --category $CATEGORY
    done
fi


if [[ $MODE == "CONTROL-SHAPES" ]]; then
    VARIABLES="pt_1,pt_2,eta_1,eta_2,m_vis,jpt_1,jpt_2,jeta_1,jeta_2,mjj,njets,nbtag,bpt_1,bpt_2,mt_1,mt_2,pt_tt,pt_tt_pf,iso_1,pfmet,mt_1_pf,mt_2_pf,met,pzetamissvis,pzetamissvis_pf,metphi,pfmetphi"
    source utils/setup_root.sh
    python shapes/produce_shapes.py --channels $CHANNEL \
        --directory $NTUPLES \
        --${CHANNEL}-friend-directory $XSEC_FRIENDS $FF_FRIENDS \
        --era $ERA --num-processes 4 --num-threads 2 \
        --optimization-level 1 --control-plots \
        --special-analysis "EleES" \
        --control-plot-set ${VARIABLES} --skip-systematic-variations \
        --output-file $shapes_output
    bash ./shapes/do_estimations.sh 2018 ${shapes_rootfile} 1

    python3 plotting/plot_shapes_control_ee_channel.py -l --era Run${ERA} --input ${shapes_rootfile} --variables ${VARIABLES} --channels ${CHANNEL} --embedding
fi

if [[ $MODE == "LOCAL" ]]; then
    source utils/setup_root.sh
    python shapes/produce_shapes.py --channels $CHANNEL \
        --directory $NTUPLES \
        --${CHANNEL}-friend-directory $FRIENDS \
        --era $ERA --num-processes 4 --num-threads 4 \
        --optimization-level 1 \
        --special-analysis "EleES" \
        --control-plot-set ${VARIABLES} --skip-systematic-variations \
        --output-file $shapes_output
fi

if [[ $MODE == "CONDOR" ]]; then
    source utils/setup_root.sh
    echo "[INFO] Running on Condor"
    echo "[INFO] Condor output folder: ${CONDOR_OUTPUT}"
    bash submit/submit_shape_production_ul.sh $ERA $CHANNEL \
        "singlegraph" $TAG 0 $NTUPLETAG $CONDOR_OUTPUT "EleES"
    echo "[INFO] Jobs submitted"
fi
if [[ $MODE == "MERGE" ]]; then
    source utils/setup_root.sh
    echo "[INFO] Merging outputs located in ${CONDOR_OUTPUT}"
    hadd -j 5 -n 600 -f $shapes_rootfile ${CONDOR_OUTPUT}/../analysis_unit_graphs-${ERA}-${CHANNEL}-${NTUPLETAG}-${TAG}/*.root
fi

if [[ $MODE == "SYNC" ]]; then
    source utils/setup_root.sh
    echo "##############################################################################################"
    echo "#      Additional estimations                                      #"

    echo "##############################################################################################"

    bash ./shapes/do_estimations.sh 2018 ${shapes_rootfile} 1 "EleES"


    echo "##############################################################################################"
    echo "#     synced shapes                                      #"
    echo "##############################################################################################"

    # if the output folder does not exist, create it
    if [ ! -d "$shapes_output_synced" ]; then
        mkdir -p $shapes_output_synced
    fi

    python shapes/convert_to_synced_shapes.py -e $ERA \
        -i ${shapes_rootfile} \
        -o ${shapes_output_synced} \
        --variable-selection ${VARIABLES} \
        --special "TauES" \
        -n 1
    POSTFIX="-ML"
    inputfile="htt_${CHANNEL}.inputs-sm-Run${ERA}${POSTFIX}.root"

    hadd -f $shapes_output_synced/$inputfile $shapes_output_synced/${ERA}-${CHANNEL}*.root

    exit 0
fi

if [[ $MODE == "DATACARD" ]]; then
    source utils/setup_cmssw.sh
    # inputfile
    POSTFIX="-ML"
    TAG=
    inputfile="htt_${CHANNEL}.inputs-sm-Run${ERA}${POSTFIX}.root"
    $CMSSW_BASE/bin/slc7_amd64_gcc700/MorphingEleES_UL \
        --base_path=$PWD \
        --input_folder_ee=$shapes_output_synced \
        --real_data=true \
        --classic_bbb=false \
        --verbose=true \
        --postfix=$POSTFIX \
        --auto_rebin=false \
        --rebin_categories=false \
        --era=$ERA \
        --output="output/$datacard_output"

    # done
    combineTool.py -M T2W -i output/$datacard_output/htt_ee_*/ -o workspace.root --parallel 4
    exit 0
fi

if [[ $MODE == "FIT" ]]; then
    source utils/setup_cmssw.sh
    for INPUT in output/$datacard_output/htt_ee_*; do
        echo "[INFO] Fit workspace from path ${INPUT}"
        WORKSPACE=${INPUT}/workspace.root
        combine \
            -M MultiDimFit \
            -n _initialFit_Test \
            --algo singles \
            --redefineSignalPOIs elees,r \
            --setParameterRanges elees=-2.5,2.5:r=0.8,1.2 \
            --robustFit 1 \
            -m 0 -d ${WORKSPACE} \
            --setParameters elees=0.0,r=1.0 \
            --setRobustFitAlgo=Minuit2 \
            --setRobustFitStrategy=0 \
            --setRobustFitTolerance=0.2 \
            --X-rtd FITTER_NEW_CROSSING_ALGO \
            --X-rtd FITTER_NEVER_GIVE_UP \
            --X-rtd FITTER_BOUND \
            --cminFallbackAlgo "Minuit2,0:0.1" \
            --cminFallbackAlgo "Minuit,0:0.1"

        combineTool.py -M MultiDimFit -d ${WORKSPACE} \
            --algo grid \
            --X-rtd MINIMIZER_analytic --cminDefaultMinimizerStrategy 0 \
            -P elees \
            --setParameters elees=-0.45 \
            --floatOtherPOIs 1 \
            --points 47 \
            --setParameterRanges elees=-2.5,2.5 \
            --setRobustFitAlgo=Minuit2 \
            --setRobustFitStrategy=0 \
            --setRobustFitTolerance=0.2 \
            --X-rtd FITTER_NEW_CROSSING_ALGO \
            --X-rtd FITTER_NEVER_GIVE_UP \
            --X-rtd FITTER_BOUND \
            --robustFit 1 \
            -n ${ERA}_elees
        cp higgsCombine${ERA}_elees.MultiDimFit.mH120.root ${INPUT}
    done
    exit 0
fi

if [[ $MODE == "POSTFIT" ]]; then
    source utils/setup_cmssw.sh
    for INPUT in output/$datacard_output/htt_ee_*; do
        python fitting/plot1DScan.py \
            --main ${INPUT}/higgsCombine${ERA}_elees.MultiDimFit.mH120.root \
            --POI elees \
            --y-max 10 \
            --remin-main --improve \
            --output ${ERA}_elees_plot_nll \
            --translate fitting/translate.json
        done
    exit 0
fi

if [[ $MODE == "PLOT-POSTFIT" ]]; then
    source utils/setup_cmssw.sh
    for RESDIR in output/$datacard_output/htt_ee_*; do
        WORKSPACE=${RESDIR}/workspace.root
        echo "[INFO] Printing fit result for category $(basename $RESDIR)"
        FILE=${RESDIR}/postfitshape.root
        FITFILE=${RESDIR}/fitDiagnostics.${ERA}.root
        combine \
            -n .$ERA \
            -M FitDiagnostics \
            -d $WORKSPACE \
            --redefineSignalPOIs elees,r \
            --setParameterRanges elees=-1.2,1.1:r=0.8,1.2 \
            --robustFit 1 -v1 \
            --robustHesse 1 \
            --X-rtd MINIMIZER_analytic \
            --cminDefaultMinimizerStrategy 0
        mv fitDiagnostics.2018.root $FITFILE
        echo "[INFO] Building Prefit/Postfit shapes"
        PostFitShapesFromWorkspace -w ${WORKSPACE} \
            -m 125 -d ${RESDIR}/combined.txt.cmb \
            -o ${FILE} \
            -f ${FITFILE}:fit_s --postfit
    done
    source utils/setup_root.sh
    i=1
    for RESDIR in output/$datacard_output/htt_ee_*; do
        WORKSPACE=${RESDIR}/workspace.root

        CATEGORY=$(basename $RESDIR)
        FILE=${RESDIR}/postfitshape.root
        FITFILE=${RESDIR}/fitDiagnostics.${ERA}.root
        # create output folder if it does not exist
        if [ ! -d "output/postfitplots/" ]; then
            mkdir -p output/postfitplots/
        fi
        echo "[INFO] Postfits plots for category $CATEGORY"
        python3 plotting/plot_shapes.py -l --era ${ERA} --input ${FILE} --channel ${CHANNEL} --embedding --fake-factor --single-category $CATEGORY --categories "None" -o output/postfitplots/ --prefit
        python3 plotting/plot_shapes.py -l --era ${ERA} --input ${FILE} --channel ${CHANNEL} --embedding --fake-factor --single-category $CATEGORY --categories "None" -o output/postfitplots/
        i=$((i + 1))
    done
    exit 0
fi

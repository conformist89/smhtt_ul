source utils/setup_root.sh
export PYTHONPATH=$PYTHONPATH:$PWD/Dumbledraw
CHANNEL=$1
ERA=$2
NTUPLETAG=$3
TAG=$4
MODE=$5
WP=$6
VS_ELE_WP=$7
DEEP_TAU=$8

# VARIABLES="pt_1,pt_2,eta_1,eta_2,m_vis,pzetamissvis,deltaR_ditaupair,phi_1,phi_2,mt_1,mt_2,pt_vis,iso_1,iso_2"
VARIABLES="m_vis,pt_2"
ulimit -s unlimited
source utils/setup_root.sh
source utils/setup_ul_samples.sh $NTUPLETAG $ERA

output_shapes="control_shapes-${ERA}-${CHANNEL}-${NTUPLETAG}-${TAG}"
CONDOR_OUTPUT=output/condor_shapes/${ERA}-${CHANNEL}-${NTUPLETAG}-${TAG}
shapes_output=output/${ERA}-${CHANNEL}-${NTUPLETAG}-${TAG}/${output_shapes}
shape_rootfile=${shapes_output}.root
# print the paths to be used
echo "KINGMAKER_BASEDIR: $KINGMAKER_BASEDIR"
echo "BASEDIR: ${BASEDIR}"
echo "output_shapes: ${output_shapes}"

if [[ $MODE == "XSEC" ]]; then

echo "##############################################################################################"
echo "#      Checking xsec friends directory                                                       #"
echo "##############################################################################################"

    echo "running xsec friends script"
    echo "XSEC_FRIENDS: ${XSEC_FRIENDS}"
    python3 friends/build_friend_tree.py --basepath $KINGMAKER_BASEDIR_XROOTD --outputpath root://cmsxrootd-kit.gridka.de/$XSEC_FRIENDS --nthreads 20
fi

if [[ $MODE == "SHAPES" ]]; then
    echo "##############################################################################################"
    echo "#      Producing shapes for ${CHANNEL}-${ERA}-${NTUPLETAG}                                         #"
    echo "##############################################################################################"

    # if the output folder does not exist, create it
    if [ ! -d "$shapes_output" ]; then
        mkdir -p $shapes_output
    fi

    # python shapes/produce_shapes.py --channels $CHANNEL \
    #     --directory $NTUPLES \
    #     --${CHANNEL}-friend-directory $XSEC_FRIENDS \
    #     --era $ERA --num-processes 3 --num-threads 8 \
    #      --wp $WP \
    #      --vs_ele_wp ${VS_ELE_WP} \
    #     --optimization-level 1 --skip-systematic-variations \
    #     --special-analysis "TauID" \
    #     --control-plot-set ${VARIABLES} \
    #     --output-file $shapes_output  --xrootd

    echo "##############################################################################################"
    echo "#      Additional estimations                                      #"
    echo "##############################################################################################"
    if [[ $CHANNEL == "mm" ]]; then
        python shapes/do_estimations.py -e $ERA -i ${shapes_output}.root --do-qcd
    else
        bash ./shapes/do_estimations.sh ${datacard_era} ${shapes_rootfile} 1
    fi
fi

if [[ $MODE == "PLOT" ]]; then
    echo "##############################################################################################"
    echo "#     plotting                                      #"
    echo "##############################################################################################"

    # python3 plotting/plot_shapes_control.py -l --era Run${ERA} --input ${shapes_output}.root --variables ${VARIABLES} --channels ${CHANNEL} --embedding --fake-factor
    python3 plotting/plot_shapes_control.py -l --era Run${ERA} --input ${shapes_output}.root --variables ${VARIABLES} --channels ${CHANNEL} --embedding
    # python3 plotting/plot_shapes_control.py -l --era Run${ERA} --input ${shapes_output}.root --variables ${VARIABLES} --channels ${CHANNEL}
    # python3 plotting/plot_shapes_control.py -l --era Run${ERA} --input ${shapes_output}.root --variables ${VARIABLES} --channels ${CHANNEL} --fake-factor

    # python2 ~/tools/webgallery/gallery.py Run${ERA}_plots_emb_classic/
fi

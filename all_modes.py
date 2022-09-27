import os 
import argparse

pre_shape_modes = ["CONTROL", "CONTROLREGION", "CONDOR"]

post_shape_modes = ["MERGE", "SYNC", "DATACARD", "FIT",
"POSTFIT", "PLOT-POSTFIT", "PLOT-SF", "IMPACTS", "JSON"
]

# CHANNEL=" mt "
# ERA=" 2018 "
# NTUPLETAG=" 2022_07_v6 "
# TAG=" loose_26Sep_mt_2018UL "

parser = argparse.ArgumentParser(description="Tau Id scale factors computation")
parser.add_argument("--era", type=str, default="2018", help="2016, 2017 or 2018")
parser.add_argument("--channel", type=str, default="mt", help="mt, et, em , tt")
parser.add_argument("--ntupletag", type=str, default="2022_07_v6", help="UL ntuples version")
parser.add_argument("--tag", type=str, default="tight_mt_2018UL", help="user define tag")
parser.add_argument("--mode", type=str, default="cent", help="pre-shape, post-shape")

args = parser.parse_args()

mode = []

if args.mode=="pre-shape":
    mode = pre_shape_modes
if args.mode=="post-shape":
    mode = post_shape_modes
else:
    print("Please provide the correct input")

for i in range(len(mode)):
    os.system("./embeddded_tauID_ul2018.sh "+args.channel+" "+args.era+" "+args.ntupletag+" "+args.tag+" "+mode[i])
    

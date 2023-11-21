import os 
import argparse

mode = "JSON"
vs_ele = "vvloose"

# modes = ["CONTROL", "CONTROLREGION", "MERGE", "SYNC", "DATACARD_COMB", "DATACARD_DM" , "MULTIFIT","MULTIFIT_DM",
#           "POSTFIT", "POSTFIT_DM", "PLOT-MULTIPOSTFIT", "PLOT-MULTIPOSTFIT_DM", "IMPACTS", "IMPACTS_DM", "JSON"]

modes = ["POI_CORRELATION_INCL",]

# modes = ["DATACARD_COMB","DATACARD_DM", "MULTIFIT", "MULTIFIT_DM", 
#          "POSTFIT", "POSTFIT_DM", "PLOT-MULTIPOSTFIT", "PLOT-MULTIPOSTFIT_DM", "IMPACTS", "IMPACTS_DM", "JSON"]




parser = argparse.ArgumentParser(description="Plot the tau ID SF")
parser.add_argument("--vs_jet_wp", type=str, default="tight", help="TauID WP")
parser.add_argument("--era", type=str, default="2016postVFP", help="2016preVFP, 2016postVFP")
parser.add_argument("--ntuples_tag", type=str, default="ntuples", help="")
parser.add_argument("--user_out_tag", type=str, default="tight_2018UL", help="user_out_tag")



args = parser.parse_args()


for mod in modes:

    os.system("bash embeddded_tauID_ul2018.sh mt"+' '+args.era+' '+args.ntuples_tag+' '+args.user_out_tag+' '+ mod+' '+args.vs_jet_wp+' vvloose 2_1')

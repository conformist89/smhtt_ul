from unicodedata import category
import correctionlib._core as core
import correctionlib.schemav2 as schema
import correctionlib.JSONEncoder as JSONEncoder
import ROOT
import json
import argparse
import glob
import os

ROOT.PyConfig.IgnoreCommandLineOptions = True  # disable ROOT internal argument parser


class CorrectionSet(object):
    def __init__(self, name):
        self.name = name
        self.corrections = []

    def add_correction_file(self, correction_file):
        with open(correction_file) as file:
            data = json.load(file)
            corr = schema.Correction.parse_obj(data)
            self.add_correction(corr)

    def add_correction(self, correction):
        if isinstance(correction, dict):
            self.corrections.append(correction)
        elif isinstance(correction, Correction):
            self.corrections.append(correction.correctionset)
        else:
            raise TypeError(
                "Correction must be a Correction object or a dictionary, not {}".format(
                    type(correction)
                )
            )

    def write_json(self, outputfile):
        # Create the JSON object
        cset = schema.CorrectionSet(
            schema_version=schema.VERSION, corrections=self.corrections
        )
        print(f">>> Writing {outputfile}...")
        JSONEncoder.write(cset, outputfile)
        JSONEncoder.write(cset, outputfile + ".gz")


class Correction(object):
    def __init__(
        self,
        tag,
        name,
        outdir,
        configfile,
        era,
        wps,
        fname="",
        data_only=False,
        verbose=False,
    ):
        self.tag = tag
        self.name = name
        self.outdir = outdir
        self.configfile = configfile
        self.ptbinning = []
        self.etabinning = []
        self.inputfiles = []
        self.correction = None
        self.era = era
        self.wps = wps
        self.header = ""
        self.fname = fname
        self.info = ""
        self.verbose = verbose
        self.data_only = data_only
        self.correctionset = None
        self.inputobjects = {}
        self.types = ["Data", "Embedding", "DY"]

    def __repr__(self) -> str:
        return "Correction({})".format(self.name)

    def __str__(self) -> str:
        return "Correction({})".format(self.name)

    def parse_config(self):
        pass

    def setup_scheme(self):
        pass

    def generate_sfs(self):
        pass

    def generate_scheme(self):
        pass


class TauID(Correction):
    def __init__(
        self,
        tag,
        name,
        data,
        era,
        wps, 
        outdir,
        fname="",
        verbose=False,
    ):
        super(TauID, self).__init__(
            tag,
            name,
            outdir,
            data,
            era,
            wps,
            fname,
            data_only=False,
            verbose=False,
        )
        if self.data_only:
            self.types = ["Data"]

    def parse_config(self):
        self.ptbinning = [20, 25, 30, 35, 40, 10000]
        self.dm_categories = ["DM_0", "DM_1", "DM_10_11"]
        self.info = "Missing Info"
        self.header = "Missing Header"
        pt_binning = {"Pt20to25" : 20, "Pt25to30":25, "Pt30to35":30, "Pt35to40":35, "PtGt40":40}
        dm_binning = ["DM_0", "DM_1", "DM_10_11"]
        # self.wps = ["Tight"]

        self.pt_binned_data = {}
        self.dm_binned_data = {}
        for bin in pt_binning.keys():
            for dataentry in data.keys():
                if bin == dataentry:
                    self.pt_binned_data[pt_binning[bin]] = data[dataentry]
        for bin in dm_binning:
            for dataentry in data.keys():
                if bin == dataentry:
                    self.dm_binned_data[bin] = data[dataentry]

    def setup_pt_scheme(self):
        self.correctionset = {
            "version": 0,
            "name": self.name,
            "description": "pt-dependent tau ID scale factor for tau embedded samples",
            "inputs": [
                {
                    "name": "pt",
                    "type": "real",
                    "description": "Tau pT",
                },
                {
                    "name": "type",
                    "type": "string",
                    "description": "Variation: nom, Up, Down",
                },
                {
                    "name": "wp",
                    "type": "string",
                    "description": "DeepTau2017v2p1VSjet working point: VVVLoose-VVTight ",
                },
            ],
            "output": {
                "name": "sf",
                "type": "real",
                "description": "pT-dependent scale factor",
            },
            "data": None,
        }

    def setup_dm_scheme(self):
        self.correctionset = {
            "version": 0,
            "name": self.name,
            "description": "dm-dependent tau ID scale factor for tau embedded samples",
            "inputs": [
                {
                    "name": "decaymode",
                    "type": "int",
                    "description": "Tau decay mode",
                },
                {
                    "name": "type",
                    "type": "string",
                    "description": "Variation: nom, Up, Down",
                },
                {
                    "name": "wp",
                    "type": "string",
                    "description": "DeepTau2017v2p1VSjet working point: VVVLoose-VVTight ",
                },
            ],
            "output": {
                "name": "sf",
                "type": "real",
                "description": "DM-dependent scale factor",
            },
            "data": None,
        }

    def generate_dm_sfs(self):
        data = {"nodetype": "category", "input": "wp", "content": []}
        for wp in self.wps:
            sfs = {
                "nodetype": "category",
                "input": "decaymode",
                "content": [
                    {
                        "key": 0,
                        "value": {
                            "nodetype": "category",
                            "input": "type",
                            "content": [
                                {
                                    "key": "nom",
                                    "value": self.get_tauID_sf("DM_0", "nom", wp, isDM=True,),
                                },
                                {
                                    "key": "up",
                                    "value": self.get_tauID_sf("DM_0", "up", wp, isDM=True),
                                },
                                {
                                    "key": "down",
                                    "value": self.get_tauID_sf(
                                        "DM_0", "down", wp, isDM=True
                                    ),
                                },
                            ],
                        },
                    },
                    {
                        "key": 1,
                        "value": {
                            "nodetype": "category",
                            "input": "type",
                            "content": [
                                {
                                    "key": "nom",
                                    "value": self.get_tauID_sf("DM_1", "nom", wp, isDM=True),
                                },
                                {
                                    "key": "up",
                                    "value": self.get_tauID_sf("DM_1", "up", wp, isDM=True),
                                },
                                {
                                    "key": "down",
                                    "value": self.get_tauID_sf(
                                        "DM_1", "down", wp, isDM=True
                                    ),
                                },
                            ],
                        },
                    },
                    {
                        "key": 10,
                        "value": {
                            "nodetype": "category",
                            "input": "type",
                            "content": [
                                {
                                    "key": "nom",
                                    "value": self.get_tauID_sf(
                                        "DM_10_11", "nom", wp, isDM=True
                                    ),
                                },
                                {
                                    "key": "up",
                                    "value": self.get_tauID_sf("DM_10_11", "up", wp, isDM=True),
                                },
                                {
                                    "key": "down",
                                    "value": self.get_tauID_sf(
                                        "DM_10_11", "down", wp, isDM=True
                                    ),
                                },
                            ],
                        },
                    },
                    {
                        "key": 11,
                        "value": {
                            "nodetype": "category",
                            "input": "type",
                            "content": [
                                {
                                    "key": "nom",
                                    "value": self.get_tauID_sf(
                                        "DM_10_11", "nom", wp, isDM=True
                                    ),
                                },
                                {
                                    "key": "up",
                                    "value": self.get_tauID_sf("DM_10_11", "up", wp, isDM=True),
                                },
                                {
                                    "key": "down",
                                    "value": self.get_tauID_sf(
                                        "DM_10_11", "down", wp, isDM=True
                                    ),
                                },
                            ],
                        },
                    },
                ],
            }
            data["content"].append({"key": wp, "value": sfs})
        return schema.Category.parse_obj(data)

    def generate_pt_sfs(self):
        data = {"nodetype": "category", "input": "wp", "content": []}
        for wp in self.wps:
            sfs = {
                "nodetype": "binning",
                "input": "pt",
                "edges": self.ptbinning,
                "flow": "clamp",
                "content": [
                    {
                        "nodetype": "category",
                        "input": "type",
                        "content": [
                            {
                                "key": "nom",
                                "value": self.get_tauID_sf(pt, "nom", wp, isPt=True),
                            },
                            {
                                "key": "up",
                                "value": self.get_tauID_sf(pt, "up", wp, isPt=True),
                            },
                            {
                                "key": "down",
                                "value": self.get_tauID_sf(pt, "down", wp, isPt=True),
                            },
                        ],
                    }
                    for pt in self.ptbinning[:-1]
                ],
            }
            data["content"].append({"key": wp, "value": sfs})
        return schema.Category.parse_obj(data)

    def get_tauID_sf(self, variable, variation, working_point, isPt=False, isDM=False):
        if isPt:
            data = self.pt_binned_data
            for bin in data.keys():
                if variable == bin:
                    if variation == "nom":
                        return data[bin]["r"]
                    elif variation == "up":
                        return data[bin]["u"]
                    elif variation == "down":
                        return data[bin]["d"]
        elif isDM:
            data = self.dm_binned_data
            for bin in data.keys():
                if variable == bin:
                    if variation == "nom":
                        return data[bin]["r"]
                    elif variation == "up":
                        return data[bin]["u"]
                    elif variation == "down":
                        return data[bin]["d"]
        else:
            raise ValueError("Invalid argument")

    def generate_pt_scheme(self):
        self.parse_config()
        self.setup_pt_scheme()
        self.correctionset["data"] = self.generate_pt_sfs()
        output_corr = schema.Correction.parse_obj(self.correctionset)
        self.correction = output_corr
        # print(JSONEncoder.dumps(self.correction))

    def generate_dm_scheme(self):
        self.parse_config()
        self.setup_dm_scheme()
        self.correctionset["data"] = self.generate_dm_sfs()
        output_corr = schema.Correction.parse_obj(self.correctionset)
        self.correction = output_corr
        # print(JSONEncoder.dumps(self.correction))

    def write_scheme(self):
        if self.verbose >= 2:
            print(JSONEncoder.dumps(self.correction))
        elif self.verbose >= 1:
            print(self.correction)
        if self.fname:
            print(f">>> Writing {self.fname}...")
        JSONEncoder.write(self.correction, self.fname)


def load_fitresults_from_file(filename, sig_bin):
    # print('[INFO] Print fit results from file {}.'.format(filename))
    f = ROOT.TFile(filename)
    if f == None:
        raise Exception("[ERROR] File {} not found.".format(filename))

    tree = f.Get("limit")
    if tree == None:
        raise Exception(
            "[ERROR] Tree {} not found in file {}.".format("limit", filename)
        )
    num_entries = tree.GetEntries()

    indices = {}
    count = 1
    results = {}
    for key in tree.GetListOfBranches():
        name = key.GetName()
        if name == "r_EMB_"+sig_bin:
            indices[name] = count
            count += 2
            results[name] = [-999, -999, -999]


    # print("%%% results = {}".format(results))
    values_lst = []
    for i, row in enumerate(tree):
        for name in indices:
            values_lst.append(getattr(row, name))

    data = {}
    # print("%%% values_lst = {}".format(values_lst))
    results_list = list(set(values_lst))
    results_list.sort()
    # print(results_list)
    for name in results:
        data["r"] = results_list[1]
        data["d"] = results_list[0]
        data["u"] = results_list[2]
        # print('[INFO] {0:<30}: {1:.4f} {2:.4f} +{3:.4f}'.format(name, data['r'], data['d']-data['r'], data['u']-data['r']))
    return data


# first a simple argparser to the the datacard directory
parser = argparse.ArgumentParser(description="Plot the tau ID SF")
parser.add_argument("--wp", type=str, default="tight", help="TauID WP")
parser.add_argument("--user_out_tag", type=str, default="", help="Tag ")
parser.add_argument("--era", type=str, default="2018", help="2016, 2017 or 2018")
parser.add_argument("--channel", type=str, default="mt", help="mt, et, em , tt")
parser.add_argument("--input_pt", type=str, default="", help="input_pt")
parser.add_argument("--input_dm", type=str, default="", help="input_dm")
parser.add_argument("--output", type=str, default="", help="output")

args = parser.parse_args()

data = {}


pt_fitfile = args.input_pt + "cmb/higgsCombine.multidim_pt_fit.MultiDimFit.mH125.root"
dm_fitfile = args.input_dm + "cmb/higgsCombine.multidim_dm_fit.MultiDimFit.mH125.root"

pt_binnames = ["Pt20to25", "Pt25to30", "Pt30to35", "Pt35to40", "PtGt40",]
for binname in pt_binnames:
    data[binname] = load_fitresults_from_file(pt_fitfile, binname)


dm_binnames = ["DM_0", "DM_1", "DM_10_11"]

for binname in dm_binnames:
    data[binname] = load_fitresults_from_file(dm_fitfile, binname)


# print("\n data: ", data)

correctionset = CorrectionSet("TauID_SF")
correction_pt = TauID(
    tag="tag", name="TauID_sf_embedding_ptbinned", data=data, era=args.era, wps = [args.wp],outdir="/"
)
correction_pt.generate_pt_scheme()
correction_dm = TauID(
    tag="tag", name="TauID_sf_embedding_dmbinned", data=data, era=args.era, wps = [args.wp],  outdir="/"
)


correction_dm.generate_dm_scheme()

# print("\n", correction_dm.correction)

correctionset.add_correction(correction_pt)
correctionset.add_correction(correction_dm)
correctionset.write_json("Tau_"+str(args.wp)+"_"+str(args.era)+"UL_"+str(args.channel)+"_"+str(args.user_out_tag)+"_v1.json")


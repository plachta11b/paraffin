import os
import re
import sys
import argparse
from gimmemotifs import tools as tool_classes
from gimmemotifs.motif import read_motifs
import inspect


def pp_predict_motifs(tool_name, motif_type):

    toolio = [
        x[1]()
        for x in inspect.getmembers(
            tool_classes,
            lambda x: inspect.isclass(x)
            and issubclass(x, tool_classes.motifprogram.MotifProgram),
        )
        if x[0] != "MotifProgram"
    ]

    motifs = []
    if tool_name.lower() == "dreme":
        motifs = read_motifs(sys.stdin, fmt="meme")
        for motif in motifs:
            motif.id = "{0}_{1}".format("dreme", motif.id)

    elif tool_name.lower() == "dinamo":
        motifs = read_motifs(sys.stdin, fmt="meme")
        for motif in motifs:
            motif.id = "{0}_{1}".format("dinamo", motif.id)
    elif tool_name.lower() == "homer":
        motifs = read_motifs(sys.stdin, fmt="pwm")
        for i, motif in enumerate(motifs):
            width = "not_known"  # TODO
            motif.id = "{0}_{1}_{2}".format("homer", width, i + 1)

    elif tool_name.lower() == "xxmotif":
        motifs = read_motifs(sys.stdin, fmt="xxmotif")
        for motif in motifs:
            motif.id = "{0}_{1}".format("xxmotif", motif.id)

    elif tool_name.lower() == "prosampler":
        motifs = read_motifs(sys.stdin, fmt="meme")
        for m in motifs:
            m.id = "{0}_{1}".format("prosampler", m.id)
    else:
        for tool in toolio:
            if tool.name.lower() == tool_name.lower():
                if tool_name.lower() == "motifsampler":
                    motifs += tool.parse_out(sys.stdin)
                else:
                    motifs += tool.parse(sys.stdin)

    for motif in motifs:
        # motif.id = "{0}={1}_{2}".format(
        #     "MOTIF_IUPAC", motif.to_consensusv2(), motif.id)
        print(motif.to_meme())


pp_predict_motifs(sys.argv[1], sys.argv[2])

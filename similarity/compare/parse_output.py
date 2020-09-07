#!/usr/bin/python

import sys

file=sys.stdin

def get_matches(file):
	matches = []
	scope="file"
	# file - best_matches - control_motif - read_frame
	# read whole file
	line = file.readline()
	while line:
		# read Best Matches section
		if scope == "file" and "Best Matches for Each Motif" in line:
			scope = "best_matches"
		# read control motif section
		elif scope == "best_matches" and "Motif name: origin_motif" in line:
			scope = "control_motif"
		# add lines or return
		elif scope == "control_motif" and "Best Matches for Motif ID" in line:
			scope = "read_frame"
		elif scope == "read_frame":
			# end on next motif or end of file
			if "Best Matches for Motif" in line or "MOTIFSIM is written by Ngoc Tam L. Tran" in line:
				return matches
			else:
				matches.append(line)
		line = file.readline()
	return matches

lines = get_matches(file)

# Dataset #      Motif ID       Motif name            Matching format of first motif          Matching format of second motif         Direction      Position #     # of overlap   Similarity score
# 2              4              MAT3                  Reverse Complement                      Reverse Complement                      Backward       2              6              0.019060     

for i, line in enumerate(lines):
	if "Similarity score" in line and "Motif ID" in line:
		position_name = line.find("Motif name")
		position_format = line.find("Matching format of first motif")
		position_similarity = line.find("Similarity score")
		format1 = line.find("Matching format of first motif")
		format2 = line.find("Matching format of second motif")
		try:
			format1str = lines[i+1][format1:].split()[0]
			format2str = lines[i+1][format2:].split()[0]
			if format1str != format2str:
				continue
		except IndexError:
			raise "parse_output.py: unable to get complementarity info"
		try:
			name = lines[i+1][position_name:].split()[0]
		except IndexError:
			raise "parse_output.py: unable to get name"
		try:
			similarity = lines[i+1][position_similarity:].split()[0]
		except IndexError:
			raise "parse_output.py: unable to get name"

		print("{}\t{}".format(name,similarity))

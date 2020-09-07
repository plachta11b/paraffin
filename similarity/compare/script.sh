#
# To be executed in motifsim container
# Compare result motifs in prefix folder with motif placed in data directory (with prefix)
# This script is looking for data/$prefix/*.transfac.txt motif
#

motif_file_compareto="$(find /data/compareto -name "*.transfac.txt")"
motif_files="$(find /data/motifs/ -name "result_converted.transfac.txt")"

files="/output/datalist"

while IFS= read -r motif_file; do
	if [ -z "$motif_file" ]; then continue; fi

	file_long_name="$(echo $motif_file | sed 's|/|_|g' | sed 's|^_||g')"
	result_dir="/output/result/$file_long_name"
	rm -rf $result_dir
	mkdir -p $result_dir
	touch $result_dir/$file_long_name
	dataset_dir="/output/dataset/$file_long_name"
	rm -rf $dataset_dir
	mkdir -p $dataset_dir
	cp $motif_file_compareto $dataset_dir/database.txt
	cp $motif_file $dataset_dir/tool.txt
	rm -f $files
	echo "2 database.txt">> $files
	echo "2 tool.txt">> $files

	/wrapper/motifsim.sh --output-format Text --configuration $files --top-motifs 1 --best-matches 50 --dataset-dir $dataset_dir --result-dir $result_dir

	###
	### get similarity score from result file
	###

	# # get result MOTIFSIM file
	# file_with_results=$result_dir/*Results.txt
	# # Start in section where each motif is compared
	# matches_each="$(sed -n '/Best Matches for Each Motif/,$p' $file_with_results)"
	# # Select subsection of selected motif by name
	# selected_motif_name="origin_motif"
	# matches_origin_motif="$(echo "$matches_each" | sed -n "/Motif name: $selected_motif_name/,\$p" | sed -n $'1,/Dataset.*\t\tMotif ID:.*\t\tMotif name:.*/p')"
	# # filter out similari score
	# echo $motif_file >> $result_dir/similarity_score.txt
	# basic_stats_lines="$(echo "$matches_origin_motif" | grep -A1 "Similarity score" | grep --invert-match "Matching format of first motif")"

	# while IFS= read -r stat_line; do
	# 	similarity_score="$(echo "$stat_line" | cut -c 120- | grep -E -o '[+-]?[0-9]+[.][0-9]{6}')"
	# 	# '^\S*' non whitespace from start
	# 	motif_name="$(echo "$stat_line" | sed -E 's/\s*[0-9]+\s+[0-9]+\s+//' | grep -o '^\S*')"
	# 	printf "%s\t%s\n" "$motif_name" "$similarity_score" >> $result_dir/similarity_score.txt
	# done <<< "$basic_stats_lines"

	# get result MOTIFSIM file
	file_with_results=$result_dir/*Results.txt

	# parse file
	output="$(cat $file_with_results | python /output/_parse_output.py)"

	# print source into file with similari score
	echo $motif_file > $result_dir/similarity_score.txt

	# save parsing result
	echo "$output" >> $result_dir/similarity_score.txt

done <<< "$motif_files"


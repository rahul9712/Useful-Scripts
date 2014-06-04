#!/bin/bash
# SCRIPT:  wwdc_doanload.sh
# PURPOSE: Process a file line by line with PIPED while-read loop. And Start the download from the web link mentioned there.

DOWNLOADABLE_Folder=$1
DOWNLOAD_SD=$2
DOWNLOADABLE_LINKS=$DOWNLOADABLE_Folder/wwdc_downloadList_SD.txt
TITLE_LIST=$DOWNLOADABLE_Folder/wwdc_title.txt
count=0

if [[ $DOWNLOAD_SD == 1 ]]; then
	DOWNLOADABLE_LINKS=$DOWNLOADABLE_Folder/wwdc_downloadList_HD.txt
fi

echo "$DOWNLOADABLE_Folder"

cat $DOWNLOADABLE_LINKS | while read LINE
do
	let count++
	echo "Begining downloading file at: $LINE"
# Start the download
	curl -O "$LINE"

done

# Download PDFs
DOWNLOADABLE_LINKS=$DOWNLOADABLE_Folder/wwdc_downloadList_PDF.txt

cat $DOWNLOADABLE_LINKS | while read LINE
do
	let count++
	echo "Begining downloading file at: $LINE"
# Start the download
	curl -O "$LINE"

done


while read line
do
	id=`echo "$line"|cut -d':' -f1`
	name=`echo "$line"|cut -d':' -f2`
	echo "Rneming File: $id - $name"
	find "$DOWNLOADABLE_Folder" -name "$id*" | while read file
	do
		dir="${file%/*}"
		filename="${file%.*}"
		extension="${file##*.}"
		only rename pdf&mov file &srt
		if [[ "$extension" != "mov" && "$extension" != "pdf" ]]; then
			continue
		fi
		echo "Setting up file: $id - $name"
		mv "$file" "$dir/$id - $name.$extension"
	done
 
done < "$TITLE_LIST"

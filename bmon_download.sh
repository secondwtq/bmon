#! /bin/bash

ROOM_ID=""
CONV_OPTS="-f mp4 -c:v libx265 -crf 24 -preset fast -acodec aac -b:a 256k"

# -r - live room id
# -c - ffmpeg conversion option
# -o - output filename
while getopts 'r:c' OPTION; do
    case "$OPTION" in
        r)
            echo "$OPTARG"
            ROOM_ID="$OPTARG"
            ;;
        c)
            CONV_OPTS="$OPTARG"
            ;;
    esac
done

if [[ -z "$ROOM_ID" ]]; then
    echo "please specify live room id with -r"
    exit 1
fi
OUTPUT_FILENAME="$ROOM_ID.$(date +%s)"

echo "downloading ..."
you-get https://live.bilibili.com/$ROOM_ID -O $OUTPUT_FILENAME
if [[ ! -z "$CONV_OPTS" ]]; then
   echo "converting ..."
   # CONVERTED_FILENAME="${OUTPUT_FILENAME%.*}.mp4"
   CONVERTED_FILENAME="$OUTPUT_FILENAME.mp4"
   ffmpeg -i "$OUTPUT_FILENAME.flv" $CONV_OPTS $CONVERTED_FILENAME
fi

#!/usr/bin/env bash

REPO_DIR=$(dirname $(readlink -f "$0"))

declare -a effects=("bass 5"
                    "echo 0.8 0.88 60 0.4"
                    "echo 0.8 0.88 60 0.4 echo 0.8 0.88 60 0.4"
                    "flanger 0 2 0 71 0.5 25 lin"
                    "hilbert -n 5001"
                    "loudness 6"
                    "norm 90"
                    "norm 45"
                    "norm 15"
                    "overdrive 17"
                    "phaser 0.8 0.74 3 0.7 0.5"
                    "phaser 0.8 0.74 3 0.4 0.5"
                    "pitch 2"
                    "pitch 2 pitch 2"
                    "riaa"
                    "sinc 20-4k"
                    "vol 10"
)

declare -a format=("yuv444p"
                   "rgb24"

)

EXT=${1##*.}
echo "EXT=$EXT"
FILE=${1%.*}
echo "FILE=$FILE"

for format in "${format[@]}"
do
  for i in "${effects[@]}"
  do
     EFFECT=${i// /-}
     echo "EFFECTS=$EFFECT"
     OUTPUT="${FILE}_${format}_${EFFECT}.${EXT}" 
     echo "OUTPUT=${OUTPUT} "
     $REPO_DIR/mangle.sh "$1" "${OUTPUT}" --color-format=${format}  $i

  done
done

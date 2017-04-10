#!/usr/bin/env bash

function printHelp()
{
    echo "This script requires ImageMagick, Sox and ffmpeg to be installed"
    echo ""
    echo "$ ./mangle.sh in.jpg out.png [effect [effect]]"
    echo ""
    echo "List of effects:"
    echo "vol 10"
    echo "bass 5"
    echo "sinc 20-4k"
    echo "riaa"
    echo "pitch 2"
    echo "phaser 0.8 0.74 3 0.7 0.5"
    echo "phaser 0.8 0.74 3 0.4 0.5"
    echo "overdrive 17"
    echo "norm 90"
    echo "echo 0.8 0.88 60 0.4"
    echo ""
    echo "A full list of effects can be found here: http://sox.sourceforge.net/sox.html#EFFECTS"

    exit 1
}

function helpNeeded()
{
    if [ -z ${1+x} ]; then
        echo "Input file not provided!"
        printHelp
    elif [ ! -f $1 ]; then
        echo "Input file '$1' not found!"
        printHelp
    fi

    if [ -z ${2+x} ]; then
         echo "Output file not provided!"
        printHelp
    fi

    if [ -z ${3+x} ]; then
         echo "No effect specified"
        printHelp
    fi
}

function cmd()
{
    type $1 >/dev/null 2>&1 || { echo >&2 "$1 is required but it's not installed"; printHelp; exit 1; }
    eval $@ >/dev/null 2>&1 || { echo >&2 "$@"; eval $@;  exit 1; }
}


function args()
{
    export YUV_FMT=rgb24
    export BITS=24
    export S_TYPE=u24
    export YUV_FMT=yuv444p
    export BITS=8
    export S_TYPE=u8
}

helpNeeded $@
args $@

INFO=$(identify $1 || { echo >&2 "$1 is not a valid image"; exit 1; })
RES=$(echo $INFO | cut -f3 -d' ' || { echo >&2 "$1 does not have a resolution?"; exit 1; })
cmd ffmpeg -y -i $1 -pix_fmt $YUV_FMT /tmp/tmp.yuv
cp /tmp/tmp.yuv /tmp/tmp_audio_in.$S_TYPE
cmd sox --bits $BITS -c1 -r44100 --encoding unsigned-integer -t $S_TYPE /tmp/tmp_audio_in.$S_TYPE  \
        --bits $BITS -c1 -r44100 --encoding unsigned-integer -t $S_TYPE /tmp/tmp_audio_out.$S_TYPE \
        ${@:3}
cp /tmp/tmp_audio_out.$S_TYPE /tmp/tmp_out.yuv
cmd ffmpeg -y -f rawvideo -s $RES -pix_fmt $YUV_FMT -i /tmp/tmp_out.yuv -frames 1 $2

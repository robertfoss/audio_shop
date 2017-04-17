#!/usr/bin/env bash

function printDependencies()
{
    echo "Error: \"$1\" could not be found, but is required"
    echo ""
    echo "This script requires ffmpeg and Sox to be installed"

    exit 1
}

function printHelp()
{
    echo "$ ./mangle.sh in.jpg out.png [effect [effect]]"
    echo ""
    echo "Options:"
    echo "--bits=X          -- Set audio sample size in bits, 8/16/24"
    echo "--blend=X         -- Blend the distorted video with original video, 0.5"
    echo "--color-format=X  -- Color space/format, rgb24/yuv444p/yuyv422. Full list: $ ffmpeg -pix_fmts"
    echo "--res=WxH         -- Set output resolution, 1920x1080"
    echo ""
    echo "Effects:"
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
    echo "hilbert -n 5001"
    echo "loudness 6"
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

function parseArgs()
{
    helpNeeded $@

    # Default values
    BITS=8
    YUV_FMT=rgb24

    for i in "${@:3}"
    do
    case $i in
        --res=*)
            export RES=${i#*=}
            RES_COLON=$(echo $RES | tr x :)
            FFMPEG_IN_OPTS="$FFMPEG_IN_OPTS -vf scale=$RES_COLON"
        ;;
        --bits=*)
            BITS=${i#*=}
        ;;
        --blend=*)
            BLEND=${i#*=}
            FFMPEG_OUT_OPTS="$FFMPEG_OUT_OPTS -f rawvideo -pix_fmt \$YUV_FMT -s \${RES} -i /tmp/tmp_audio_in.\${S_TYPE}"
            FFMPEG_OUT_OPTS="$FFMPEG_OUT_OPTS -filter_complex \\\""
            FFMPEG_OUT_OPTS="$FFMPEG_OUT_OPTS [0:v]setpts=PTS-STARTPTS, scale=\${RES}[top]\;"
            FFMPEG_OUT_OPTS="$FFMPEG_OUT_OPTS [1:v]setpts=PTS-STARTPTS, scale=\${RES},"
            FFMPEG_OUT_OPTS="$FFMPEG_OUT_OPTS format=yuva444p,colorchannelmixer=aa=${BLEND}[bottom]\;"
            FFMPEG_OUT_OPTS="$FFMPEG_OUT_OPTS [top][bottom]overlay=shortest=1\\\""
        ;;
        --color-format=*)
            YUV_FMT=${i#*=}
        ;;
        --*)
            echo -e "Option $i not recognized\n"
            printHelp
        ;;
        *)
            # Unknown option, hand them back to SOX
            SOX_OPTS="$SOX_OPTS $i"
        ;;
    esac
    done

    export BITS
    export YUV_FMT

    export S_TYPE="u$BITS"

    export FFMPEG_IN_OPTS
    export FFMPEG_OUT_OPTS
    export UNUSED_ARGS
}

function cmd()
{
    OUTPUT=$(eval $@ 2>&1)
    if [ $? -ne 0 ]; then
        echo -e "\n----- ERROR -----"
        echo -e "\n\$ $@\n\n"
        echo -e "$OUTPUT"
        echo -e "\n----- ERROR -----"
        exit 1
    fi
    echo "$OUTPUT"
}

function cmdSilent()
{
    OUTPUT=$(eval $@ 2>&1)
    if [ $? -ne 0 ]; then
        echo -e "\n----- ERROR -----"
        echo -e "\n\$ $@\n\n"
        echo -e "$OUTPUT"
        echo -e "\n----- ERROR -----"
        exit 1
    fi
}

function getResolution()
{
    eval $(cmd ffprobe -v error -of flat=s=_ -select_streams v:0 -show_entries stream=height,width $1)
    RES=${streams_stream_0_width}${2}${streams_stream_0_height}
    echo $RES
}

function getFrames()
{
    FRAMES=$(cmd ffprobe -v error -select_streams v:0 -show_entries stream=nb_frames -of default=noprint_wrappers=1:nokey=1 $1)
    echo $FRAMES
}

function checkDependencies()
{
    for CMD in "$@"
    do
        if ! type "$CMD" > /dev/null; then
            printDependencies $CMD
        fi
    done
}

checkDependencies ffprobe ffmpeg sox tr
RES=$(getResolution $1 "x")
parseArgs $@
FRAMES=$(getFrames $1)
echo "FFMPEG_IN_OPTS:  $(eval echo $FFMPEG_IN_OPTS)"
echo "FFMPEG_OUT_OPTS: $(eval echo $FFMPEG_OUT_OPTS)"
echo "SOX_OPTS:        $(eval echo $SOX_OPTS)"

echo "Extracting raw image data.."
cmdSilent ffmpeg -y -i $1 -pix_fmt $YUV_FMT $FFMPEG_IN_OPTS /tmp/tmp.yuv
mv /tmp/tmp.yuv /tmp/tmp_audio_in.$S_TYPE

#echo "Exracting sound.."
#ffmpeg -y -i $1 -vn -acodec copy /tmp/tmp_in.aac
echo "Processing as sound.."
cmdSilent sox --bits $BITS -c1 -r44100 --encoding unsigned-integer -t $S_TYPE /tmp/tmp_audio_in.$S_TYPE  \
        --bits $BITS -c1 -r44100 --encoding unsigned-integer -t $S_TYPE /tmp/tmp_audio_out.$S_TYPE \
        $SOX_OPTS
mv /tmp/tmp_audio_out.$S_TYPE /tmp/tmp_out.yuv

echo "Creating image data from audio.."
cmdSilent ffmpeg -y "$(eval echo $FFMPEG_OUT_OPTS)" -f rawvideo -pix_fmt $YUV_FMT -s $RES -i /tmp/tmp_out.yuv -frames $FRAMES $2

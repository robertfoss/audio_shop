#!/usr/bin/env bash

function cleanup()
{
    if [[ -z "${TMP_DIR}" ]]; then
        exit "$1"
    elif [[ !"${TMP_DIR}" == "/tmp/audio_shop/*" ]]; then
        exit "$1"
    fi

    rm -rf "${TMP_DIR}"
    exit "$1"
}

function printDependencies()
{
    echo "Error: \"$1\" could not be found, but is required"
    echo ""
    echo "This script requires ffmpeg and Sox to be installed"

    cleanup 1
}

function printHelp()
{
    echo "$ ./mangle.sh in.jpg out.png [effect [effect]]"
    echo ""
    echo "This script lets you interpret image or video data as sound,"
    echo "and apply audio effects to it before converting it back to"
    echo "image representation"
    echo ""
    echo "Options:"
    echo "--bits=X          -- Set audio sample size in bits, 8/16/24"
    echo "--blend=X         -- Blend the distorted video with original video, 0.5"
    echo "--color-format=X  -- Color space/format, rgb24/yuv444p/yuyv422. Full list: $ ffmpeg -pix_fmts"
    echo "--res=WxH         -- Set output resolution, 1920x1080"
    echo ""
    echo "Effects:"
    echo "bass 5"
    echo "echo 0.8 0.88 60 0.4"
    echo "flanger 0 2 0 71 0.5 25 lin"
    echo "hilbert -n 5001"
    echo "loudness 6"
    echo "norm 90"
    echo "overdrive 17"
    echo "phaser 0.8 0.74 3 0.7 0.5"
    echo "phaser 0.8 0.74 3 0.4 0.5"
    echo "pitch 2"
    echo "riaa"
    echo "sinc 20-4k"
    echo "vol 10"
    echo ""
    echo "Examples:"
    echo "./mangle in.jpg out.jpg vol 11"
    echo "./mangle in.mp4 out.mp4 echo 0.8 0.88 60 0.4"
    echo "./mangle in.mp4 out.mp4 pitch 5 --res=1280x720"
    echo "./mangle in.mp4 out.mp4 pitch 5 --blend=0.75 --color-format=yuv444p --bits=8"
    echo ""
    echo "A full list of effects can be found here: http://sox.sourceforge.net/sox.html#EFFECTS"

    cleanup 1
}

function helpNeeded()
{
    if [[ -z ${1+x} ]]; then
        echo -e "Input file not provided!\n"
        printHelp
    elif [[ ! -f $1 ]]; then
        echo -e "Input file '$1' not found!\n"
        printHelp
    fi

    if [[ -z ${2+x} ]]; then
         echo -e "Output file not provided!\n"
        printHelp
    fi

    if [[ -z ${3+x} ]]; then
         echo -e "No effect specified\n"
        printHelp
    fi
}

function parseArgs()
{
    helpNeeded "$@"

    # Default values
    BITS=8
    YUV_FMT=rgb24

    for i in "${@:3}"
    do
    case $i in
        --res=*)
            export RES=${i#*=}
            RES_COLON=$(echo "$RES" | tr x :)
            FFMPEG_IN_OPTS="$FFMPEG_IN_OPTS -vf scale=$RES_COLON"
        ;;
        --bits=*)
            BITS=${i#*=}
        ;;
        --blend=*)
            BLEND=${i#*=}
            FFMPEG_OUT_OPTS="$FFMPEG_OUT_OPTS -f rawvideo -pix_fmt \$YUV_FMT -s \${RES} -i \${TMP_DIR}/tmp_audio_out.\${S_TYPE}"
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
    OUTPUT=$(eval "$@" 2>&1)
    if (( $? )); then
        echo -e "\n----- ERROR -----"
        echo -e "\n\$ ${*}\n\n"
        echo -e "$OUTPUT"
        echo -e "\n----- ERROR -----"
        cleanup 1
    fi
    echo "$OUTPUT"
}

function cmdSilent()
{
    OUTPUT=$(eval "$@" 2>&1)
    if (( $? )); then
        echo -e "\n----- ERROR -----"
        echo -e "\n\$ ${*}\n\n"
        echo -e "$OUTPUT"
        echo -e "\n----- ERROR -----"
        cleanup 1
    fi
}

function getResolution()
{
    eval $(cmd ffprobe -v error -of flat=s=_ -select_streams v:0 -show_entries stream=height,width \"$1\")
    RES="${streams_stream_0_width}${2}${streams_stream_0_height}"
    echo "$RES"
}

function getFrames()
{
    FRAMES=$(cmd ffprobe -v error -select_streams v:0 -show_entries stream=nb_frames -of default=noprint_wrappers=1:nokey=1 \"$1\")
    REGEXP_INTEGER='^[0-9]+$'
    if ! [[ $FRAMES =~ $REGEXP_INTEGER ]] ; then
        echo ""
        return 0
    fi
    echo "-frames $FRAMES"
    return 0
}

function getAudio()
{
    AUDIO=$(cmd ffprobe -i \"$1\" -show_streams -select_streams a -loglevel error)
    [[ $AUDIO = *[!\ ]* ]] && echo "-i $TMP_DIR/audio_out.${AUDIO_TYPE}"
}

function checkDependencies()
{
    for CMD in "$@"
    do
        if ! type "$CMD" > /dev/null; then
            printDependencies "$CMD"
        fi
    done
}

checkDependencies ffprobe ffmpeg sox tr
parseArgs "$@"

AUDIO_TYPE="mp3"
TMP_DIR=$(mktemp -d "/tmp/audio_shop-XXXXX")
RES=${RES:-"$(getResolution "$1" x)"}
VIDEO=${VIDEO:-"$(getFrames "$1")"}
AUDIO=${AUDIO:-"$(getAudio "$1")"}

echo "TMP_DIR:         $TMP_DIR"
echo "RES:             $RES"
echo "VIDEO:           $VIDEO"
echo "AUDIO:           $AUDIO"
echo "FFMPEG_IN_OPTS:  $(eval echo "$FFMPEG_IN_OPTS")"
echo "FFMPEG_OUT_OPTS: $(eval echo "$FFMPEG_OUT_OPTS")"
echo "SOX_OPTS:        $(eval echo "$SOX_OPTS")"

echo "Extracting raw image data.."
cmdSilent "ffmpeg -y -i \"$1\" -pix_fmt $YUV_FMT $FFMPEG_IN_OPTS  $TMP_DIR/tmp.yuv"

[[ $AUDIO = *[!\ ]* ]] && echo "Extracting audio track.."
[[ $AUDIO = *[!\ ]* ]] && cmdSilent "ffmpeg -y -i \"$1\" -q:a 0 -map a $TMP_DIR/audio_in.${AUDIO_TYPE}"

echo "Processing as sound.."
mv "$TMP_DIR"/tmp.yuv "$TMP_DIR"/tmp_audio_in."$S_TYPE"
cmdSilent sox --bits "$BITS" -c1 -r44100 --encoding unsigned-integer -t "$S_TYPE" "$TMP_DIR"/tmp_audio_in."$S_TYPE"  \
              --bits "$BITS" -c1 -r44100 --encoding unsigned-integer -t "$S_TYPE" "$TMP_DIR"/tmp_audio_out."$S_TYPE" \
              "$SOX_OPTS"

[[ $AUDIO = *[!\ ]* ]] && echo "Processing audio track as sound.."
[[ $AUDIO = *[!\ ]* ]] && cmdSilent sox "$TMP_DIR"/audio_in.${AUDIO_TYPE}  \
                                        "$TMP_DIR"/audio_out.${AUDIO_TYPE} \
                                        "$SOX_OPTS"

echo "Recreating image data from audio.."
cmdSilent ffmpeg -y \
                 "$(eval echo $FFMPEG_OUT_OPTS)" \
                 -f rawvideo -pix_fmt $YUV_FMT -s $RES \
                 -i $TMP_DIR/tmp_audio_out.$S_TYPE \
                 $AUDIO \
                 $VIDEO \
                 \"$2\"

#[[ $AUDIO = *[!\ ]* ]] && echo "Injecting modified audio.."
#[[ $AUDIO = *[!\ ]* ]] && cmdSilent ffmpeg -y \
#                                           -i \"$2\" \
#                                           $AUDIO \
#                                           \"$2\"

cleanup 0

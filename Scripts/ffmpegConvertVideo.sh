#!/bin/bash
# ========================================
# Global Variables
# ========================================
scriptName="$(basename -- $0)"

# Color variables.
colBlack="\033[0;30m"
colRed="\033[0;31m"
colGreen="\033[0;32m"
colBlue="\033[0;34m"
colYellow="\033[0;33m"
colMagenta="\033[0;35m"
colCyan="\033[0;36m"

bgBlack="\033[0;40m"
bgRed="\033[0;41m"
bgGreen="\033[0;42m"
bgYellow="\033[0;43m"
bgBlue="\033[0;44m"
bgMagenta="\033[0;45m"
bgCyan="\033[0;46m"

# Clear the color after that.
colClear="\033[0m"

# Catch ctrl-c.
trap Cancel INT


# ========================================
# Functions
# ========================================
# Display help.
function Help() {
    echo -e "\033[4mConvert video with FFMPEG.\033[m"
    echo "Platform: $(uname) - ${OSTYPE}"
    echo
    echo "Options:"
    echo "  -a  {value}  Audio options."
    echo "                  - an       => No audio."
    echo "                  - [Codec]  => Assume valid codec to use. (Default: copy)"
    echo "  -f  {value}  Format container. (Default: mp4)"
    echo "                  - list     => Print supported formats."
    echo "  -h           Print this Help."
    echo "  -l           Print supported codecs."
    echo "  -s* {value}  Source [file|path]."
    echo "  -t  {value}  Target [file|path]."
    echo "  -v  {value}  Video options."
    echo "                  - vn       => No video."
    echo "                  - [Codec]  => Assume valid codec to use. (Default: copy)"
    echo
    echo "* Required argument."
    echo
    echo "Examples:"
    echo "Convert a single file."
    echo "${scriptName} -f mp4 -s SourceFile.mp4 -t OutputFile.mp4"
    echo
    echo "Convert files in the source directory and output into destination path."
    echo "${scriptName} -f webm -s SourcePath -t OutputPath"
    echo
    echo "Choosing codes."
    echo "${scriptName} -s SourceFile.mp4 -t OutFile.mp4 -a mp3 -v libx264"
    echo
}

# Exit with error.
function ExitAbnormal() {
    Help
    exit 1
}

# Check flags.
function CheckFlags() {
    PrintInfo "Selected Options:"

    if [ "${flagAudio}" = "an" ]; then
        PrintWarning "  * Remove Audio Track"
        flagAudio="-an"
    elif [ ! "${flagAudio}" = "" ]; then
        PrintInfo "  * Select Audio Codec: ${flagAudio}"
        flagAudio="-c:a ${flagAudio}"
    fi

    if [ "${flagVideo}" = "vn" ]; then
        PrintWarning "  * Remove Video Track"
        flagVideo="-vn"
    elif [ ! "${flagVideo}" = "" ]; then
        PrintInfo "  * Select Video Codec: ${flagVideo}"
        flagVideo="-c:v ${flagVideo}"
    fi
}

# Run FFMPEG.
# Parameters:
#   1   => Source file.
#   2   => Target file.
function RunFFMPEG() {
    params="-i ${1} -f ${flagFormat}"
    if [ ! "${flagAudio}" = "" ]; then
        params="${params} ${flagAudio}"
    fi
    if [ ! "${flagVideo}" = "" ]; then
        params="${params} ${flagVideo}"
    fi
    params="${params} ${2}"
    PrintInfo "- Run ----------------"
    PrintInfo "ffmepg ${params}"
    PrintInfo "----------------------"
    ffmpeg ${params}
}

# Prints.
# Colour formatting:
#   Start sequence: \033[Color1;Color2m
#   Stop sequence:  \033[0m
function PrintMsg() {
    echo -e "${1}${2}${colClear}"
}

function PrintInfo() {
    echo -e "${colCyan}[INFO]${colClear} ${1}"
}

function PrintError() {
    echo -e "${colRed}[ERROR]${colClear} ${1}"
}

function PrintWarning() {
    echo -e "${colRed}[WARNING]${colClear} ${1}"
}

function PrintSuccess() {
    echo -e "${colGreen}${1}${colClear}"
}

# Cancel.
function Cancel() {
    PrintWarning "-- Process Interupted --"
    PrintWarning "Terminating...."
    exit 0
}


# ========================================
# Main
# ========================================
echo "================="
echo "= Convert Video ="
echo "================="


# Working variables.
source=""
target=""
#flagAudio="-c:a copy"
#flagVideo="-c:v copy"
flagAudio=""
flagFormat="mp4"
flagVideo=""


# Parsing arguments.
while getopts ":a:f:hls:t:v:" flag
do
    case "${flag}" in
        h)  # Display help.
            Help
            exit;;
        a)  # Audio.
            flagAudio=${OPTARG};;
        f)  # Format.
            flagFormat=${OPTARG};;
        l)  # List of codecs.
            ffmpeg -codecs; exit;;
        s)  # Source [file|path].
            source=${OPTARG};;
        t)  # Target [file|path].
            target=${OPTARG};;
        v)  # Video.
            flagVideo=${OPTARG};;
        :)  PrintError "Missing argument: -${OPTARG}\n\n" >&2; ExitAbnormal;;
        \?) PrintError "Unknown option: -${OPTARG}\n\n" >&2; ExitAbnormal;;
    esac
done

# Special cases.
if [ "${1}" = "" ] || [ "${1}" = "?" ]; then
    Help
    exit
fi

if [ "${flagFormat}" = "list" ]; then
    ffmpeg -formats
    exit
fi

# Require arguments.
if [ "$source" = "" ]; then
    PrintError "(-s) Missing source.\n\n"
    Help
    exit
fi

# Validating.
if [ ! -f "$source" ] && [ ! -d "$source" ]; then
    PrintError "[$source] doesn't exists."
    exit
fi


# --------------------
# Single Conversion
# --------------------
# If source is a file, when convert the file.
if [ -f "${source}" ]; then
    echo "---------------------"
    echo "- Single Conversion -"
    echo "---------------------"
    CheckFlags

    if [ ! -f "${source}" ]; then
        PrintError "[${source}] file doesn't exists."
        exit
    fi

    # If destination is not specified, append suffix to output.
    if [ "${target}" = "" ]; then
        target="${source%.*}"
        if [ "${source}" = "${target}.${flagFormat}" ]; then
            target="${target}_Converted.${flagFormat}"
            PrintWarning "File exists, make new output name."
            PrintWarning "  => ${target}"
        else
            target="${target}.${flagFormat}"
        fi

        PrintWarning "New target: ${target}"
    fi

    #ffmpeg -i ${source} -f mp4 -vcodec libx264 ${flagAudio} ${target}
    RunFFMPEG ${source} ${target}
fi


# --------------------
# Multiple Conversions
# --------------------
# If source is a directory, when process for all files.
if [ -d "${source}" ]; then
    echo "-----------------------"
    echo "- Multiple Conversion -"
    echo "-----------------------"
    CheckFlags

    if [ ! -d "${source}" ]; then
        PrintError "[${source}] directory doesn't exists."
        exit
    fi

    if [ "${source: -1}" = "/" ]; then
        source="${source%?}"
    fi

    if [ ! "${target}" = "" ]; then
        if [ ! -d "${target}" ]; then
            PrintInfo "Creating output directory: ${target}"
            mkdir "${target}"
        fi

        if [ ! "${target: -1}" = "/" ]; then
            target="${target}/"
        fi
    fi


    FILTERS="mov mp4 webm"
    FILES="${source}/*"
    for f in ${FILES}
    do
        ext="${f#*.}"
        PrintInfo "Processing [${f}]...."

        # Skip not video files.
        skip="1"
        for e in ${FILTERS}
        do
            if [ "${e}" = "${ext}" ]; then
                skip="0"
                break
            fi
        done

        # Process conversion if valid.
        if [ ${skip} = "0" ]; then
            # Get only file name if target is specified.
            if [ "${target}" = "" ]; then
                newTarget="${f%.*}"
            else
                newTarget="${target}$(basename -- ${f%.*})"
            fi

            if [ "$f" = "${newTarget}.${flagFormat}" ]; then
                newTarget="${newTarget}_Converted.${flagFormat}"
                PrintInfo "File exists, make new output name."
                PrintInfo "  => ${newTarget}"
            else
                newTarget="${newTarget}.${flagFormat}"
            fi

            #ffmpeg -i ${f} -f mp4 -vcodec libx264 ${flagAudio} ${newTarget}
            RunFFMPEG ${f} ${newTarget}
        else
            PrintWarning "** Not supported file type (${ext}). **"
            PrintWarning "  => Skip processing [${f}]...."
        fi
    done
fi


PrintSuccess "-- PROCESS COMPLETED --"

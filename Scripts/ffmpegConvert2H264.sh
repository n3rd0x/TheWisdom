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
    echo "Convert video to H264."
    echo
    echo "Syntax: ${scriptName} [-a|h|-s|-t]"
    echo "Options:"
    echo "  a  Remove audio track."
    echo "  h  Print this Help."
    echo "  s* Source [file|path]."
    echo "  t  Target [file|path]."
    echo
    echo "* Required argument."
    echo
    echo "Examples:"
    echo "Convert a single file."
    echo "${scriptName} -s MyFile.mp4 -t OutFile.mp4"
    echo
    echo "Convert files in the source directory and output into destination path."
    echo "${scriptName} -s MyPath -t OutPath"
}

# Exit with error.
function ExitAbnormal() {
    Help
    exit 1
}

# Check audio flag.
function AudioFlag() {
    if [ "${flagAudio}" = "-an" ]; then
        PrintWarning "* Remove Audio Track"
    fi
}

# Run FFMPEG.
# Parameters:
#   1   => Source file.
#   2   => Target file.
function RunFFMPEG() {
    params="-i ${1} -f mp4 -c:v libx264"
    if [ ! "${flagAudio}" = "" ]; then
        params="${params} ${flagAudio}"
    fi
    params="${params} ${2}"
    PrintInfo "- Run ----------------"
    PrintInfo " ffmepg ${params}"
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
echo -e "==========================="
echo -e "= Convert Video Into H264 ="
echo -e "==========================="


# Working variables.
source=""
target=""
#flagAudio="-c:a copy"
flagAudio=""


# Parsing arguments.
while getopts ":ahs:t:" flag
do
    case "${flag}" in
        h)  # Display help.
            Help
            exit;;
        a)  # Remove audio track.
            flagAudio="-an";;
        s)  # Source [file|path].
            source=${OPTARG};;
        t)  # Target [file|path].
            target=${OPTARG};;
        :)  PrintError "Missing argument: -${OPTARG}\n\n" >&2; ExitAbnormal;;
        \?) PrintError "Illegal option: -${OPTARG}\n\n" >&2;ExitAbnormal;;
    esac
done

# Special cases.
if [ "$1" = "" ] || [ "$1" = "?" ]; then
    Help
    exit
fi


# Require arguments.
if [ "$source" = "" ]; then
    PrintError "(-s) Missing source."
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
    AudioFlag

    if [ ! -f "${source}" ]; then
        PrintError "[${source}] file doesn't exists."
        exit
    fi

    # If destination is not specified, append suffix to output.
    if [ "${target}" = "" ]; then
        target="${source%.*}"
        if [ "${source}" = "${target}.mp4" ]; then
            target="${target}_Converted.mp4"
            PrintWarning "File exists, make new output name."
            PrintWarning "  => ${target}"
        else
            target="${target}.mp4"
        fi

        PrintWarning "Set destination as: [${target}]"
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
    AudioFlag

    if [ ! -d "${source}" ]; then
        PrintError "[${source}] directory doesn't exists."
        exit
    fi

    if [ "${source: -1}" = "/" ]; then
        source="${source%?}"
    fi

    if [ ! "${target}" = "" ]; then
        if [ ! -d "${target}" ]; then
            PrintInfo "Creating output directory: [${target}]"
            mkdir "${target}"
        fi

        if [ ! "${target: -1}" = "/" ]; then
            target="${target}/"
        fi
    fi


    FILES="${source}/*"
    for f in ${FILES}
    do
        ext="${f#*.}"
        PrintInfo "Processing [${f}]...."
        if [ ${ext} = "mov" ] || [ ${ext} = "mp4" ]; then
            # Get only file name if target is specified.
            if [ "${target}" = "" ]; then
                newTarget="${f%.*}"
            else
                newTarget="${target}$(basename -- ${f%.*})"
            fi

            if [ "$f" = "${newTarget}.mp4" ]; then
                newTarget="${newTarget}_Converted.mp4"
                PrintInfo "File exists, make new output name."
                PrintInfo "  => ${newTarget}"
            else
                newTarget="${newTarget}.mp4"
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

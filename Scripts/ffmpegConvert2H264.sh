#!/bin/bash
# ========================================
# Global Variables
# ========================================
scriptName="$(basename -- $0)"



# ========================================
# Functions
# ========================================
# Display help.
Help() {
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
ExitAbnormal() {
Help
exit 1
}

# Check audio flag.
AudioFlag() {
if [ ! "${flagAudio}" = "" ]; then
    echo "  * Remove Audio Track"
fi
}


# ========================================
# Main
# ========================================
echo "==========================="
echo "= Convert Video Into H264 ="
echo "==========================="


# Working variables.
source=""
target=""
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
        :)  printf "[ERROR] Missing argument: -%s\n\n" "${OPTARG}" >&2; ExitAbnormal;;
        \?) printf "[ERROR] Illegal option: -%s\n\n" "${OPTARG}" >&2;ExitAbnormal;;
    esac
done

# Special cases.
if [ "$1" = "" ] || [ "$1" = "?" ]; then
    Help
    exit
fi


# Require arguments.
if [ "$source" = "" ]; then
    echo "[ERROR] (-s) Missing source."
    Help
    exit
fi

# Validating.
if [ ! -f "$source" ] && [ ! -d "$source" ]; then
    echo "[ERROR] [$source] doesn't exists."
    exit
fi


# --------------------
# Single Conversion
# --------------------
# If source is a file, when convert the file.
if [ -f "${source}" ]; then
    echo "====================="
    echo "= Single Conversion ="
    echo "====================="
    AudioFlag

    if [ ! -f "${source}" ]; then
        echo "[ERROR] [${source}] file doesn't exists."
        exit
    fi

    # If destination is not specified, append suffix to output.
    if [ "${target}" = "" ]; then
        target="${source%.*}"
        if [ "${source}" = "${target}.mp4" ]; then
            target="${target}_Converted.mp4"
            echo "[VERBOSE] File exists, make new output name."
            echo "[VERBOSE]   => ${target}"
        else
            target="${target}.mp4"
        fi

        echo "[WARNING] Set destination as: [${target}]"
    fi

    ffmpeg -i ${source} -f mp4 -vcodec libx264 ${flagAudio} ${target}
fi


# --------------------
# Multiple Conversions
# --------------------
# If source is a directory, when process for all files.
if [ -d "${source}" ]; then
    echo "======================="
    echo "= Multiple Conversion ="
    echo "======================="
    AudioFlag

    if [ ! -d "${source}" ]; then
        echo "[ERROR] [${source}] directory doesn't exists."
        exit
    fi

    if [ ! "${target}" = "" ]; then
        if [ ! -d "${target}" ]; then
            echo "[VERBOSE] Creating output directory: [${target}]"
            mkdir "${target}"
        fi

        target="${target}/"
    fi


    FILES="${source}/*"
    for f in ${FILES}
    do
        ext="${f#*.}"
        echo "[VERBOSE] Processing [${f}]...."
        if [ ${ext} = "mov" ] || [ ${ext} = "mp4" ]; then
            NewOutput="${target}${f%.*}"
            if [ "$f" = "${NewOutput}.mp4" ]; then
                NewOutput="${NewOutput}_Converted.mp4"
                echo "[VERBOSE] File exists, make new output name."
                echo "[VERBOSE]   => ${NewOutput}"
            else
                NewOutput="${NewOutput}.mp4"
            fi

            ffmpeg -i ${f} -f mp4 -vcodec libx264 ${flagAudio} ${NewOutput}
        else
            echo "[WARNING] ** Not supported file type (${ext}). **"
            echo "[WARNING]   => Skip processing [${f}]...."
        fi
    done
fi

echo "====================="
echo "= PROCESS COMPLETED ="
echo "====================="
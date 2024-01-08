#!/bin/bash

# This script converts audio files in specified directories to various FreeSwitch mod_native_file formats.
#   - Supported formats: 
#       - source: wav, mp3
#       - destination: GSM, L16, PCMA, PCMU, G722, G726, G723, G729
#   - It ensure that the resulted audio files has the same user and group as of the original.
#   - Normalizing audio in the ffmpeg and sox convert stages.
#   - Converter used: sox, ffmpeg, astconv
# Usage: ./script_name.sh [minutes]
#   - If 'minutes' is specified, it processes files modified in the last 'minutes' minutes.
#   - If not specified, it defaults to 60 minutes.
#   - If set to 0, process all.

# Directories containing audio files to be processed.
audio_dirs=("/usr/local/freeswitch/sounds)

# Default time interval in minutes.
t=60

# Color variables
BLUE="\e[34m"
GREEN="\e[32m"
CYAN="\e[36m"
RESET="\e[0m"

# Check if the first argument is provided and a non-negative integer.
if [ -n "$1" ] && [[ "$1" =~ ^[0-9]+$ ]]; then
    t="$1"
fi

# Format conversion mapping.
declare -A format_map=(["gsm"]="GSM" ["l16"]="L16" ["al"]="PCMA" ["ul"]="PCMU" ["g722"]="G722" ["g726"]="G726-16" ["g723"]="G723" ["g729"]="G729")

# Function to process file conversion.
process_file() {
    local file=$1
    local sln_file="${file%.*}.sln"
    local format=$2
    local intermediate_file="${file%.*}.${format}"
    local target_file="${file%.*}.${format_map[$format]}"
    local dir=$(dirname "$file")
    local owner_group=$(stat -c "%u:%g" "$file")

    local b_sln=$(basename "$sln_file")
    local b_intermediate=$(basename "$intermediate_file")
    local b_file=$(basename "$file")
    local b_target=$(basename "$target_file")

    # Convert to .sln format only once per original file
    if [ ! -e "$sln_file" ]; then
        echo -e "${BLUE}Converting $file to $sln_file for intermediate processing.${RESET}"
        docker run --rm -v "$dir:/workspace" audio-convert \
            ffmpeg -i "/workspace/$b_file" -f s16le -acodec pcm_s16le -ac 1 -ar 8000 -af loudnorm "/workspace/$b_sln"
    fi

    echo -e "${GREEN}Converting $sln_file to $intermediate_file in format $format.${RESET}"

    # Conversion commands based on format
    case $format in
        gsm)
            docker run --rm -v "$dir:/workspace" audio-convert \
                sox "/workspace/$b_sln" -e $format "/workspace/$b_intermediate"
            ;;
        al)
            docker run --rm -v "$dir:/workspace" audio-convert \
                sox "/workspace/$b_sln" -e a-law -t raw "/workspace/$b_intermediate"
            ;;
        ul)
            docker run --rm -v "$dir:/workspace" audio-convert \
                sox "/workspace/$b_sln" -e u-law -t raw "/workspace/$b_intermediate"
            ;;
        l16)
            docker run --rm -v "$dir:/workspace" audio-convert \
                ffmpeg -i "/workspace/$b_file" -f s16le -acodec pcm_s16le -ac 1 -ar 8000 -af loudnorm "/workspace/$b_intermediate"
            ;;
        g722)
            docker run --rm -v "$dir:/workspace" audio-convert \
                ffmpeg -i "/workspace/$b_file" -acodec $format -ac 1 -ar 16000 -af loudnorm "/workspace/$b_intermediate"
            ;;
        g726)
            # g726 needs to be mono
            docker run --rm -v "$dir:/workspace" audio-convert \
                ffmpeg -i "/workspace/$b_file" -acodec $format -ac 1 -ar 8000 -b:a 16k -f $format -af loudnorm "/workspace/$b_intermediate"
            ;;
        g723)
            docker run --rm -v "$dir:/workspace" audio-convert \
                astconv /usr/lib/codec_${format}.so -e 480 "/workspace/$b_sln" "/workspace/$b_intermediate"
            ;;
        g729)
            docker run --rm -v "$dir:/workspace" audio-convert \
                astconv /usr/lib/codec_${format}.so -e 160 "/workspace/$b_sln" "/workspace/$b_intermediate"
            ;;
    esac

    # Rename the file to the final format and change its owner and group to match the original file
    mv "$dir/$b_intermediate" "$dir/$b_target"
    chown $owner_group "$dir/$b_target"

    echo -e "${CYAN}Conversion complete: $file to $target_file.${RESET}"
}

# Main loop to find and process files.
for dir in "${audio_dirs[@]}"; do
    if [ "$t" -eq 0 ]; then
        files=$(find "$dir" -maxdepth 1 -type f \( -name "*.wav" -o -name "*.mp3" \))
    else
        files=$(find "$dir" -maxdepth 1 -type f \( -name "*.wav" -o -name "*.mp3" \) -mmin -$t)
    fi

    for file in $files; do
        for format in "${!format_map[@]}"; do
            process_file "$file" "$format"
        done
        # Remove .sln file after all conversions for one original file
        sln_file="${file%.*}.sln"
        if [ -e "$sln_file" ]; then
            # echo -e "${BLUE}Removing intermediate file: $sln_file${RESET}"
            rm -f "$sln_file"
        fi
    done
done
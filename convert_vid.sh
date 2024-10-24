#!/bin/bash

# This script converts video files to MP4, copying streams if possible, or re-encoding if necessary.

# Function to display usage instructions
usage() {
    echo "Usage: $0 -i input_file [-o output_file]"
    echo "  -i input_file     Specify the input video file."
    echo "  -o output_file    Specify the output MP4 file (optional)."
    exit 1
}

# Function to get codec info using ffprobe
get_codec() {
    ffprobe -v error -select_streams "$1" -show_entries stream=codec_name \
    -of default=noprint_wrappers=1:nokey=1 "$input_file"
}

# Parse command-line arguments
while getopts ":i:o:" opt; do
    case $opt in
        i) input_file="$OPTARG"
        ;;
        o) output_file="$OPTARG"
        ;;
        *) usage
        ;;
    esac
done

# Check if input file is provided
if [ -z "$input_file" ]; then
    echo "Error: Input file is required."
    usage
fi

# Check if input file exists
if [ ! -f "$input_file" ]; then
    echo "Error: Input file '$input_file' does not exist."
    exit 1
fi

# Set default output file name if not provided
if [ -z "$output_file" ]; then
    # Remove the extension from the input file and append .mp4
    output_file="${input_file%.*}.mp4"
fi

# Check if output file already exists
if [ -f "$output_file" ]; then
    echo "Warning: Output file '$output_file' already exists and will be overwritten."
fi

# Determine video codec compatibility
video_codec=$(get_codec v:0)
audio_codec=$(get_codec a:0)

# Initialize codec options
video_codec_option="-c:v copy"
audio_codec_option="-c:a copy"

# Check video codec compatibility
case "$video_codec" in
    h264|mpeg4|hevc|h265)
        # Compatible video codecs
        ;;
    *)
        echo "Video codec '$video_codec' is not compatible with MP4. Re-encoding video stream."
        video_codec_option="-c:v libx264 -preset medium -crf 23"
        ;;
esac

# Check audio codec compatibility
case "$audio_codec" in
    aac|mp3|ac3)
        # Compatible audio codecs
        ;;
    *)
        echo "Audio codec '$audio_codec' is not compatible with MP4. Re-encoding audio stream."
        audio_codec_option="-c:a aac -b:a 128k"
        ;;
esac

# Perform the conversion using FFmpeg
ffmpeg -i "$input_file" $video_codec_option $audio_codec_option -movflags +faststart "$output_file"

# Check if the conversion was successful
if [ $? -eq 0 ]; then
    echo "Conversion successful! Output file: '$output_file'"
else
    echo "Conversion failed."
    exit 1
fi

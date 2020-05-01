#!/bin/sh

# set env vars to defaults if not already set
export FRAME_RATE="${FRAME_RATE:-25}"
export GOP_LENGTH="${GOP_LENGTH:-${FRAME_RATE}}"
export VIDEO_BITRATE="${VIDEO_BITRATE:-100k}"

if [ "${FRAME_RATE}" = "30000/1001" -o "${FRAME_RATE}" = "60000/1001" ]; then
  echo "drop frame"
	  export FRAME_SEP="."
	else
	  export FRAME_SEP=":"
	fi
	
	export LOGO_OVERLAY="${LOGO_OVERLAY-https://raw.githubusercontent.com/unifiedstreaming/live-demo/master/ffmpeg/usp_logo_white.png}"
	
	if [ -n "${LOGO_OVERLAY}" ]; then
	  export LOGO_OVERLAY="-i ${LOGO_OVERLAY}"
	  export OVERLAY_FILTER=", overlay=eval=init:x=W-15-w:y=15"
	fi
	
	# validate required variables are set
	if [ -z "${PUB_POINT_URI}" ]; then
	  echo >&2 "Error: PUB_POINT_URI environment variable is required but not set."
	  exit 1
	fi
	
	# get current time in microseconds
	export DATE_MICRO=$(LANG=C date +%s.%6N)
	export DATE_PART1=${DATE_MICRO%.*}
	export DATE_PART2=${DATE_MICRO#*.}
	# the -ism_offset option has a timescale of 10,000,000, so add an extra zero
	export ISM_OFFSET=${DATE_PART1}${DATE_PART2}0
	# the number of seconds into the current day
	export DATE_MOD_DAYS=$((${DATE_PART1}%86400))
	
	set -x
	
	exec "$@"
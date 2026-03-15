#!/usr/bin/env bash
#
# Stream Spool
# Download a stream and watch in a video player while it downloads.
# https://github.com/ryanhellyer/stream-spool/
#

set -euo pipefail

# Colours
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_GREEN='\033[32m'
C_YELLOW='\033[33m'
C_CYAN='\033[36m'
C_DIM='\033[2m'

WORK_DIR="stream-spool"
SEGMENTS_DIR="$WORK_DIR/segments"
MASTER_TS="streaming_output.ts"
LAST_STITCHED_FILE="$WORK_DIR/last_stitched.txt"
URLS_FILE="$WORK_DIR/segment_urls.txt"
LAST_URL_FILE="$WORK_DIR/last_stream_url.txt"
PARALLEL_JOBS=15
STITCH_INTERVAL=20
STITCHER_PID=""

check_deps() {
    local missing=()
    command -v curl &>/dev/null || missing+=(curl)
    command -v ffmpeg &>/dev/null || missing+=(ffmpeg)
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${C_RESET}Error: Missing required tools: ${missing[*]}${C_RESET}" >&2
        exit 1
    fi
}

get_base_url() {
    local url="$1"
    if [[ "$url" == */* ]]; then
        echo "${url%/*}/"
    else
        echo "./"
    fi
}

parse_manifest() {
    local stream_url="$1"
    local prev_url=""
    [[ -f "$LAST_URL_FILE" ]] && read -r prev_url < "$LAST_URL_FILE" || true
    if [[ "$stream_url" != "$prev_url" ]]; then
        rm -f "$MASTER_TS" "$LAST_STITCHED_FILE"
    fi
    echo "$stream_url" > "$LAST_URL_FILE"
    echo -e "${C_DIM}Fetching playlist...${C_RESET}"
    BASE_URL=$(get_base_url "$stream_url")
    mkdir -p "$WORK_DIR" "$SEGMENTS_DIR"
    local manifest
    manifest=$(curl -sS -L --retry 3 --retry-delay 2 -- "$stream_url") || { echo -e "${C_RESET}Failed to fetch playlist.${C_RESET}" >&2; return 1; }

    if grep -q '\.m3u8' <<< "$manifest"; then
        local first_sub
        first_sub=$(grep -v '^#' <<< "$manifest" | head -1)
        if [[ -n "$first_sub" ]]; then
            if [[ "$first_sub" != http* ]]; then
                first_sub="${BASE_URL}${first_sub}"
            fi
            echo -e "${C_DIM}Following playlist...${C_RESET}"
            manifest=$(curl -sS -L --retry 3 --retry-delay 2 -- "$first_sub") || { echo -e "${C_RESET}Failed to fetch playlist.${C_RESET}" >&2; return 1; }
            BASE_URL=$(get_base_url "$first_sub")
        fi
    fi

    grep -v '^#' <<< "$manifest" | grep -E '\.ts' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$' > "$URLS_FILE" || true
    SEGMENT_COUNT=$(wc -l < "$URLS_FILE")
    if [[ "$SEGMENT_COUNT" -eq 0 ]]; then
        echo -e "${C_RESET}No segments found in playlist.${C_RESET}" >&2
        return 1
    fi

    local tmp
    tmp=$(mktemp)
    while IFS= read -r line; do
        if [[ "$line" == http* ]]; then
            echo "$line"
        else
            echo "${BASE_URL}${line}"
        fi
    done < "$URLS_FILE" > "$tmp"
    mv "$tmp" "$URLS_FILE"
    echo -e "${C_GREEN}Ready.${C_RESET}"
}

show_stream_tips() {
    echo -e "${C_YELLOW}How to find the stream URL:${C_RESET}"
    echo -e "  ${C_DIM}• In Chrome/Edge: F12 → Network tab → filter by \"m3u8\" or \"media\" → play the video → copy the request URL${C_RESET}"
    echo -e "  ${C_DIM}• In Firefox: F12 → Network → filter \"m3u8\" → play video → right‑click the request → Copy URL${C_RESET}"
    echo -e "  ${C_DIM}• Some sites show it in the page source or in a \"Copy stream link\" option${C_RESET}"
    echo ""
}

ask_input() {
    echo -e "${C_BOLD}${C_CYAN}=== Stream Spool ===${C_RESET}"
    echo ""
    show_stream_tips
    read -rp "Stream URL: " stream_url
    stream_url=$(echo "$stream_url" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    if [[ -z "$stream_url" ]]; then
        echo -e "${C_RESET}URL required.${C_RESET}" >&2
        return 1
    fi
    parse_manifest "$stream_url" || return 1
}

download_segment() {
    local idx="$1"
    local url="$2"
    local outfile="$SEGMENTS_DIR/segment_$(printf "%05d" "$idx").ts"
    if [[ -f "$outfile" ]]; then
        return 0
    fi
    curl -sS -L --retry 3 --retry-delay 2 -o "$outfile" -- "$url" || {
        echo "Failed: $url" >&2
        return 1
    }
}

export -f download_segment
export SEGMENTS_DIR

run_stitch() {
    local last=0
    [[ -f "$LAST_STITCHED_FILE" ]] && read -r last < "$LAST_STITCHED_FILE" || true
    local i
    for (( i=last+1; i<=SEGMENT_COUNT; i++ )); do
        local f="$SEGMENTS_DIR/segment_$(printf "%05d" "$i").ts"
        if [[ ! -f "$f" ]]; then
            break
        fi
        if [[ ! -f "$MASTER_TS" ]]; then
            cat "$f" > "$MASTER_TS"
        else
            cat "$f" >> "$MASTER_TS"
        fi
        last=$i
        echo "$last" > "$LAST_STITCHED_FILE"
    done
}

background_stitcher() {
    while true; do
        sleep "$STITCH_INTERVAL"
        [[ -f "$URLS_FILE" ]] || exit 0
        run_stitch 2>/dev/null || true
    done
}

do_download() {
    if [[ ! -f "$URLS_FILE" ]] || [[ "${SEGMENT_COUNT:-0}" -eq 0 ]]; then
        echo -e "${C_RESET}No playlist. Enter a stream URL first.${C_RESET}" >&2
        return 1
    fi
    mkdir -p "$WORK_DIR" "$SEGMENTS_DIR"
    echo -e "${C_CYAN}Downloading...${C_RESET}"
    if [[ -f "$MASTER_TS" ]]; then
        echo -e "${C_DIM}Resuming — $MASTER_TS is already available to view in a video player.${C_RESET}"
    else
        echo -e "${C_DIM}$MASTER_TS will appear once ready — you can open it in a video player to watch while it downloads.${C_RESET}"
    fi
    background_stitcher &
    STITCHER_PID=$!
    trap 'kill "$STITCHER_PID" 2>/dev/null; trap - EXIT' EXIT

    local idx=0
    while IFS= read -r url; do
        (( idx++ )) || true
        printf '%d\0%s\0' "$idx" "$url"
    done < "$URLS_FILE" | xargs -0 -P "$PARALLEL_JOBS" -n 2 bash -c 'download_segment "$1" "$2"' _

    kill "$STITCHER_PID" 2>/dev/null || true
    trap - EXIT
    run_stitch

    if [[ -f "$MASTER_TS" ]]; then
        echo -e "${C_GREEN}Done. You can watch ${C_BOLD}$MASTER_TS${C_GREEN} in a video player.${C_RESET}"
    fi
}

do_finalize() {
    if [[ ! -f "$MASTER_TS" ]]; then
        echo -e "${C_RESET}Nothing to finalize. Run a download first.${C_RESET}" >&2
        return 1
    fi
    local out="final_video.mp4"
    echo -e "${C_CYAN}Creating $out...${C_RESET}"
    ffmpeg -y -i "$MASTER_TS" -c copy -bsf:a aac_adtstoasc "$out" -nostats -loglevel warning
    echo -e "${C_GREEN}Created $out${C_RESET}"
    read -rp "Delete temporary files? [y/N] " cleanup
    if [[ "${cleanup,,}" == y ]]; then
        rm -f "$MASTER_TS"
        rm -rf "$WORK_DIR"
        echo -e "${C_GREEN}Cleanup done.${C_RESET}"
    fi
}

main() {
    check_deps
    ask_input || exit 1
    do_download || exit 1
    echo ""
    read -rp "Finalize to MP4? [Y/n] " final
    if [[ "${final,,}" != n ]]; then
        do_finalize
    else
        echo -e "${C_DIM}Open $MASTER_TS in a video player. Run this script again to finalize to MP4 later.${C_RESET}"
    fi
}

main "$@"

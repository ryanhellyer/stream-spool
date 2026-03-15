# Stream Spool

Download a stream and watch in a video player while it downloads. Resumable; finalize to MP4 when done.

Many streaming sites use **HLS** (HTTP Live Streaming), which delivers video as a series of small **.ts** segment files. Stream Spool downloads these segments and stitches them into a single file so you can watch the stream in real time in a video player—without the buffering and stutter that often happens when playing HLS directly (for example, pauses between segments). When the download is complete, you can create an **MP4** file to keep for later viewing.

## Requirements

- **curl**
- **ffmpeg**

## Install

One command: it downloads the script and installs to a directory that’s already in your PATH, or to `~/.local/bin` (creating it if needed).

```bash
curl -sSL https://raw.githubusercontent.com/ryanhellyer/stream-spool/master/stream-spool.sh -o /tmp/stream-spool.sh && chmod +x /tmp/stream-spool.sh && bash -c 'set -e; d=; if [[ -w /usr/local/bin ]]; then d=/usr/local/bin; elif command -v sudo >/dev/null 2>&1; then sudo install -m 755 /tmp/stream-spool.sh /usr/local/bin/streamspool; echo "Installed to /usr/local/bin/streamspool"; exit 0; elif [[ -d "$HOME/.local/bin" && -w "$HOME/.local/bin" ]]; then d=$HOME/.local/bin; elif [[ -d "$HOME/bin" && -w "$HOME/bin" ]]; then d=$HOME/bin; else mkdir -p "$HOME/.local/bin"; d=$HOME/.local/bin; fi; if [[ -n "$d" ]]; then install -m 755 /tmp/stream-spool.sh "$d/streamspool"; echo "Installed to $d/streamspool"; if ! echo ":$PATH:" | grep -q ":$d:"; then echo "Add to PATH (e.g. in ~/.bashrc): export PATH=\"$d:\$PATH\""; fi; fi'
```

Then run `streamspool`.

## Usage

```bash
streamspool
```

Enter the stream URL when prompted (usually a playlist URL). The script will download and build `streaming_output.ts`; open it in a video player to watch as it grows. When finished, you can finalize to `final_video.mp4` and optionally delete temporary files.

## Finding the stream URL

- **Chrome / Edge:** F12 → Network tab → filter by "m3u8" or "media" → play the video → copy the request URL.
- **Firefox:** F12 → Network → filter "m3u8" → play video → right‑click the request → Copy URL.
- Some sites show the stream link in the page source or a "Copy stream link" option.

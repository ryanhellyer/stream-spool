# Stream Spool

Download a stream and watch in a video player while it downloads. Resumable; finalize to MP4 when done.

Many streaming sites use **HLS** (HTTP Live Streaming), which delivers video as a series of small **.ts** segment files. Stream Spool downloads these segments and stitches them into a single file so you can watch the stream in real time in a video player—without the buffering and stutter that often happens when playing HLS directly (for example, pauses between segments). When the download is complete, you can create an **MP4** file to keep for later viewing.

## Requirements

- **curl**
- **ffmpeg**

## Install

```bash
mkdir -p ~/.local/bin
curl -sSL https://raw.githubusercontent.com/ryanhellyer/stream-spool/master/stream-spool.sh -o ~/.local/bin/streamspool
chmod +x ~/.local/bin/streamspool
```

Ensure `~/.local/bin` is in your PATH (many distros add it automatically). If not, add to `~/.bashrc` or `~/.profile`:

```bash
export PATH="$HOME/.local/bin:$PATH"
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

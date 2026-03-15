# Stream Spool

Download a stream and watch in VLC while it downloads. Resumable; finalize to MP4 when done.

## Requirements

- **curl**
- **ffmpeg**

## Install

```bash
curl -sSL https://raw.githubusercontent.com/ryanhellyer/stream-spool/master/stream-spool.sh -o /tmp/stream-spool.sh
chmod +x /tmp/stream-spool.sh
sudo install -m 755 /tmp/stream-spool.sh /usr/local/bin/streamspool
```

Then run `streamspool`.

## Usage

```bash
streamspool
```

Enter the stream URL when prompted (usually a playlist URL). The script will download and build `streaming_output.ts`; open it in VLC to watch as it grows. When finished, you can finalize to `final_video.mp4` and optionally delete temporary files.

## Finding the stream URL

- **Chrome / Edge:** F12 → Network tab → filter by "m3u8" or "media" → play the video → copy the request URL.
- **Firefox:** F12 → Network → filter "m3u8" → play video → right‑click the request → Copy URL.
- Some sites show the stream link in the page source or a "Copy stream link" option.

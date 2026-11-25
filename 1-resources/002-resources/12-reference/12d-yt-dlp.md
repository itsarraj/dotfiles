
---
id: 20250519082203
title: yt-dlp list of videos & specific ones
date: 2025-05-19 08:22
type: reference # note | concept | snippet | bug | journal | reference
status: stable # draft | stable | evergreen
tags: []
links: []
---
# Log
- 2025-05-19 08:22 - Created note.

# Notes

- []() - Add link context: why notes are connected
- []() - Add link context: why notes are connected

---
# yt-dlp list of videos & specific ones


## 💡 Extra Tip: Dry Run Before Downloading


```bash
# Preview what will be downloaded (dry run):
yt-dlp --match-title "Lecture 1" --flat-playlist --print "%(title)s [https://youtu.be/%(id)s]" https://www.youtube.com/@6.824/videos

# List all video titles from a channel/playlist:
yt-dlp --flat-playlist --print "%(title)s" https://www.youtube.com/@6.824/videos

# Count total number of videos:
yt-dlp --flat-playlist --print "%(title)s" https://www.youtube.com/@6.824/videos | wc -l

# List video IDs only:
yt-dlp --flat-playlist --print "%(id)s" https://www.youtube.com/@6.824/videos

# List titles with full YouTube URLs:
yt-dlp --flat-playlist --print "%(title)s [https://youtu.be/%(id)s]" https://www.youtube.com/@6.824/videos
```

> **Notes:**
> - `--flat-playlist`: Prevents downloading video details and speeds up listing
> - `--print "%(title)s"`: Prints each video title
> - `--print "%(id)s"`: Prints each video ID
> - `| wc -l`: Counts how many lines (i.e., how many videos)

## Specific Videos Download

Download only specific videos or ranges from YouTube channels/playlists.

### Option 1: Download Range of Videos
```bash
# Download videos 5 through 10 from a playlist/channel:
yt-dlp -f bestvideo+bestaudio --merge-output-format mp4 --playlist-start 5 --playlist-end 10 https://www.youtube.com/@6.824/videos
```

### Option 2: Download Specific Video Numbers
```bash
# Download videos 1, 3, 7, and 10 (non-continuous):
yt-dlp -f bestvideo+bestaudio --merge-output-format mp4 --playlist-items 1,3,7,10 https://www.youtube.com/@6.824/videos
```

### Option 3: Filter by Title (Include/Exclude)
```bash
# Include only videos with "Lecture 10" in title:
yt-dlp --match-title "Lecture 10" https://www.youtube.com/@6.824/videos

# Exclude videos with "Blockstack" in title:
yt-dlp --reject-title "Blockstack" https://www.youtube.com/@6.824/videos

# Use regex for complex patterns:
yt-dlp --match-title "Lecture (1[0-9]|20)" https://www.youtube.com/@6.824/videos
```

### Option 4: Resume Downloads (Skip Previously Downloaded)
```bash
# Use archive file to track downloaded videos:
yt-dlp --download-archive downloaded.txt -f bestvideo+bestaudio --merge-output-format mp4 https://www.youtube.com/@6.824/videos
```

### Option 5: Download from URL List File
Create a `urls.txt` file with video URLs:
```
https://www.youtube.com/watch?v=VIDEO_ID1
https://www.youtube.com/watch?v=VIDEO_ID2
```

```bash
# Download all videos listed in urls.txt:
yt-dlp -a urls.txt -f bestvideo+bestaudio --merge-output-format mp4
```

> **Notes:**
> - `--playlist-start` and `--playlist-end`: Define range of videos to download
> - `--playlist-items`: Specify exact video numbers (comma-separated)
> - `--match-title`/`--reject-title`: Filter videos by title patterns
> - `--download-archive`: Creates a file tracking downloaded videos
> - `-a`: Read URLs from a text file


## Installation & Basic Usage

```bash
# Install yt-dlp and ffmpeg (Arch Linux):
sudo pacman -S yt-dlp ffmpeg

# Quick test - download audio from a channel:
yt-dlp -x --audio-format mp3 --audio-quality 320K https://www.youtube.com/@iumaiumaiuma
```

### General Command Structure
```
yt-dlp [OPTIONS] URL
```

### Video Download Templates

#### From Channels
```bash
# Download all videos from a channel (MP4):
yt-dlp -f bestvideo+bestaudio --merge-output-format mp4 https://www.youtube.com/@CHANNEL_NAME/videos

# Download all releases from a channel (MP4):
yt-dlp -f bestvideo+bestaudio --merge-output-format mp4 https://www.youtube.com/@CHANNEL_NAME/releases
```

#### From Playlists
```bash
# Download entire playlist (MP4):
yt-dlp -f bestvideo+bestaudio --merge-output-format mp4 https://www.youtube.com/playlist?list=PLAYLIST_ID
```

#### Single Videos
```bash
# Download specific video (MP4):
yt-dlp -f bestvideo+bestaudio --merge-output-format mp4 https://www.youtube.com/watch?v=VIDEO_ID
```

### Audio Download Templates

#### From Channels
```bash
# Download all videos as audio from a channel (MP3):
yt-dlp -x --audio-format mp3 --audio-quality 320K https://www.youtube.com/@CHANNEL_NAME/videos

# Download all releases as audio from a channel (MP3):
yt-dlp -x --audio-format mp3 --audio-quality 320K https://www.youtube.com/@CHANNEL_NAME/releases
```

#### From Playlists
```bash
# Download entire playlist as audio (MP3):
yt-dlp -x --audio-format mp3 --audio-quality 320K https://www.youtube.com/playlist?list=PLAYLIST_ID
```

#### Single Videos
```bash
# Download specific video as audio (MP3):
yt-dlp -x --audio-format mp3 --audio-quality 320K https://www.youtube.com/watch?v=VIDEO_ID
```

## Examples with Real Channels

### Philipp Dittberner Official Channel
```bash
# Download all videos (MP4):
yt-dlp -f bestvideo+bestaudio --merge-output-format mp4 https://www.youtube.com/@PhilippDittbernerOfficial/videos

# Download all releases as audio (MP3):
yt-dlp -x --audio-format mp3 --audio-quality 320K https://www.youtube.com/@PhilippDittbernerOfficial/releases

# Download specific video (MP4):
yt-dlp -f bestvideo+bestaudio --merge-output-format mp4 https://www.youtube.com/watch?v=SPECIFIC_VIDEO_ID

# Download specific video as audio (MP3):
yt-dlp -x --audio-format mp3 --audio-quality 320K https://www.youtube.com/watch?v=SPECIFIC_VIDEO_ID
```

## Custom Filename Formatting

Add playlist index numbers to downloaded files:

```bash
# Download with numbered filenames (001., 002., etc.):
yt-dlp -f bestvideo+bestaudio --merge-output-format mp4 -o "%(playlist_index)03d. %(title)s.%(ext)s" https://www.youtube.com/playlist?list=PLAYLIST_ID
```

### Filename Template Options:
- `%(playlist_index)03d.` → Adds numbering like `001.`, `002.`, etc.
- `%(title)s` → Keeps the original video title
- `%(title).150B` → Limits title to 150 bytes (removes YouTube video ID)
- `%(ext)s` → Uses correct file extension

### Example Output:
```
001. Php Tutorial in Hindi #1 Introduction.mp4
002. Php Tutorial in Hindi #2 what is PHP.mp4
003. Php Tutorial in Hindi #3 PHP Installation in macOS.mp4
```

> **Note:** Replace `CHANNEL_NAME`, `VIDEO_ID`, and `PLAYLIST_ID` with actual values. Use `%(title).150B` to avoid long filenames and remove YouTube video IDs.

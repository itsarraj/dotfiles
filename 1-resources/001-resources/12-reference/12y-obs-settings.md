
---
id: 20260107000001
title: OBS Settings
date: 2026-01-07 00:00
type: reference # note | concept | snippet | bug | journal | reference
status: stable # draft | stable | evergreen
tags: [obs, streaming, settings]
links: []
---
# Log
- 2026-01-07 00:00 - Created note.

# Notes

# MIC Settings

refer to this video - https://www.youtube.com/watch?v=OcLUJ3bR4Yk&t=38s
## Filter

### Compressor
Ratio - 4.00.1
Threshold - 0.00db
Attack - 2ms
Release - 100ms
Output Gain - 00db

with low voice sound increase output gain a little for low voice till bar on audio mixer of mic does not exceed the end of yellow
after this
speak loudly and make sure to increase threshold such that the bar on audio mixer of mic does not exceed the mid of red

If it feels like the first and last letter of word is not audible or recording then decrease the ratio a little (move left)

### Expander
Ratio - 4.00.1
Threshold - -60.00db (left end)
Attack - 2ms
Release - 100ms
Output Gain - 00db

to make sure the keyboard sound is not triggering the microphone, increase the threshold ultil the key press or bench tap sound is completely erased from the bar on audio mixer. Simply means no recording of small bench taps or keyboard sound. So it will only pick sound of certain threshold ( that's my voice )

If it feels like the first and last letter of word is not audible or recording then decrease the ratio a little (move left)

After increasing the threshold i had to decrease the ratio just to get the first and last letter audible.

### Noise Suppression

After previous step the Noise Suppression has taken care of background noise that was there with the keypress.

### Limiter
Just set a threshold for high volume sound
-6.00 dB

### Noise Gate



### OBS Settings for Separate Screen, Webcam and Audio Tracks
### sepate audio tracks

from advanced audio properties select the separate tracks I am using for the recoding certain audio source
for examples

Track 1 | Track 2 | Track 3 | Track 4 | Track 5 | Track 6
streaming | vod | mic | discord | gameplay | music

be sure not to put two conflicting audio on the same track




### For separate obs webcam and screen
From menu click on profile and duplicate it.
then change the resolution to double the width and double or 2.5x times the quality of recording.
1920x1080 becomes 3840x1080
and drop the CQP a little from 15 to 14
or if using CBR then make it 2.5x times.



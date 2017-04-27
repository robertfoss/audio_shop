# Audio Shop
Your friendly neighborhood script for mangling images or video using audio editing tools.

If you'd like to read more about how this actually works, have a look [here](http://memcpy.io/audio-editing-images.html).

## Usage
    $ ./mangle.sh in.jpg out.png [effect [effect]]

    This script lets you interpret image or video data as sound,
    and apply audio effects to it before converting it back to
    image representation

    Options:
    --bits=X          -- Set audio sample size in bits, 8/16/24
    --blend=X         -- Blend the distorted video with original video, 0.5
    --color-format=X  -- Color space/format, rgb24/yuv444p/yuyv422. Full list: $ ffmpeg -pix_fmts
    --res=WxH         -- Set output resolution, 1920x1080

    Effects:
    bass 5
    echo 0.8 0.88 60 0.4
    flanger 0 2 0 71 0.5 25 lin
    hilbert -n 5001
    loudness 6
    norm 90
    overdrive 17
    phaser 0.8 0.74 3 0.7 0.5
    phaser 0.8 0.74 3 0.4 0.5
    pitch 2
    riaa
    sinc 20-4k
    vol 10

    Example:
    ./mangle in.jpg out.jpg vol 11
    ./mangle in.mp4 out.mp4 echo 0.8 0.88 60 0.4
    ./mangle in.mp4 out.mp4 pitch 5 --res=1280x720
    ./mangle in.mp4 out.mp4 pitch 5 --blend=0.75 --color-format=yuv444p --bits=8

    A full list of effects can be found here: http://sox.sourceforge.net/sox.html#EFFECTS

    
## Dependencies
 * ffmpeg
 * sox


## Videos
### Overdrive Hilbert
[![Alt text](/../media/apollo_b8_fyuv444p_overdrive_hilbert.gif?raw=true "Apollo 11 launch")](/../media/apollo_b8_fyuv444p_overdrive_hilbert.mp4?raw=true)

### Phaser
[![Alt text](/../media/wright_b24_frgb48be_phaser.gif?raw=true "Wright")](/../media/wright_b24_frgb48be_phaser.gif?raw=true)

## Images
### Bass
![Alt text](/../media/eiffel_tower_bass.jpg?raw=true "eiffel_tower bass")

### Echo
![Alt text](/../media/eiffel_tower_echo.jpg?raw=true "eiffel_tower echo")

### Overdrive
![Alt text](/../media/eiffel_tower_overdrive.jpg?raw=true "eiffel_tower overdrive")

### Phaser
![Alt text](/../media/eiffel_tower_phaser.jpg?raw=true "eiffel_tower phaser")

### Sinc
![Alt text](/../media/eiffel_tower_sinc.jpg?raw=true "eiffel_tower sinc")

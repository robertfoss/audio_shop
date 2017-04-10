# Audio Shop
Your frinedly neighbourhood script for mangling images using audio editing tools.

If you'd like to read more about how this acutally works, have a look [here](http://memcpy.io/audio-editing-images.html)

## Usage
    $ ./mangle.sh in.jpg out.png [effect [effect]]
    
    List of effects:
    vol 10
    bass 5
    sinc 20-4k
    riaa
    pitch 2
    phaser 0.8 0.74 3 0.7 0.5
    phaser 0.8 0.74 3 0.4 0.5
    overdrive 17
    norm 90
    echo 0.8 0.88 60 0.4
    
    A full list of effects can be found here: http://sox.sourceforge.net/sox.html#EFFECTS
    
## Dependencies
 * ffmpeg
 * imagemagick
 * sox

## Effects
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

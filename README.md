# bc-mkv
a customizable bash script that converts a ZIP file with mp3s to an MKV featuring on-vid metadata.

optionally, you can also upload rendered videos to YouTube straight from the command line.

## getting started

### requirements
* a linux based distro
* ffmpeg
* mpg123
* unzip
* id3v2
* curl (optional)

### installation
* clone this repository with git.
* make 4 directories in the same folder you cloned to, titled "newvid" "newzip" "oldzip" and "work"
* make `vm-caption.sh` and `gen-from-zip.sh` executable, if not already. `chmod +x vm-caption.sh && chmod +x gen-from-zip.sh`
* **OPTIONAL:** if you intend to directly upload your videos to youtube after rendering, open `gen-from-zip.sh` in a text editor and follow the instructions listed to retrieve your API credentials.
* open 2 terminals and run `./vm-caption.sh` in one. i use screen to run it, you probably should too.
* Put a zip of mp3s in "newzip", with your cover file as "cover.jpg"
* Run `./gen-from-zip.sh` in the other terminal, and wait for the file to render.

## credits & special thanks
*  myke420247 for building & helping with the base script

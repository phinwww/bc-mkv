#!/bin/bash
# take bandcamp zip files and generate videos for them

ZIPSRC="newzip"
WORK="work"
NEWVID="newvid"
DONE="oldzip"
MP3="/radio/mp3"

for z in $ZIPSRC/*.zip ; do
    echo "Processing $z ..."
    unzip -jd "$WORK" "$z"

    # 2021-11-12: Copy mp3s to mp3 dump first as they are now renamed for index order
##    for f in "$WORK"/*.mp3 ; do
##	cp -v "$f" "$MP3"
##    done  
    
    COVER=$( ls $WORK/*cover*.* $WORK/*Cover*.* | head -1 )
    if [ -z "$COVER" ] ; then
	echo "FATAL: could not find a cover image, bailing..."
	exit 1
    fi

    NEWIMAGE=fixed-$( basename "$COVER" ).jpg
    ffmpeg \
	-i "$COVER" \
	-vf "scale=(iw*sar)*min(1280/(iw*sar)\,720/ih):ih*min(1280/(iw*sar)\,720/ih), pad=1280:720:(1280-iw*min(1280/iw\,720/ih))/2:(720-ih*min(1280/iw\,720/ih))/2" \
	"$NEWIMAGE"

    # 2021-11-12: Rename mp3 files to their index numbers with leading zeros so they are in correct album order, at last
    cd "$WORK"
    for f in *.mp3 ; do
	idxnum=$( printf "%03d" $( id3v2 -R "$f"  | grep TRCK | cut -d ' ' -f 2 ) )
	echo "$f -> $idxnum.mp3"
	mv "$f" $idxnum.mp3
    done
    cd -

    MKV=$( basename "$z" .zip ).mkv
    # caption file can not be completely empty, bootstrap it
    cp startup-caption.txt caption.txt

    mpg123 --long-tag -s $WORK/*.mp3 2> mp3log.txt | \
	nice -n 5 ffmpeg \
	     -thread_queue_size 256 -filter_threads 16 \
	     -f s16le -ac 2 -i pipe:0 \
	     -loop 1 -i "$NEWIMAGE" \
	     -tune stillimage -shortest \
	     -c:v libx264 -preset fast -maxrate 6000k -bufsize 30000k -g 60 -r 30 \
	     -pix_fmt yuv420p -profile:v high -level 4.0 -bf 2 -coder 1 -movflags +faststart \
	     -c:a mp3 -b:a 320k -ar 44100 -ac 2 \
	     -vf drawtext="unifont.ttf: textfile=caption.txt: reload=1: \
	     	fontcolor=#FFFFFF: fontsize=32: box=1: boxcolor=#000000@0.85: \
	       	boxborderw=5: x=20: y=20" \
	     "$NEWVID/$MKV"

    rm -v "$NEWIMAGE"
    # 2021-11-12: These are now copied before video generation
#    for f in "$WORK"/*.mp3 ; do
#	mv -v "$f" "$MP3"
#    done  
    rm -rf "$WORK"/*
    mv -v "$z" "$DONE"
done

#!/bin/bash
# take bandcamp zip files and generate videos for them

ZIPSRC="newzip"
WORK="work"
NEWVID="newvid"
DONE="oldzip"
MP3="/radio/mp3"

# yt setup:
# Goto https://console.developers.google.com
# Create app, enable Youtube Data API and create OAuth credentials, client id and client secret.
# Goto https://developers.google.com/oauthplayground/ to authorize yourself and get a refresh token
# make sure you enable "use your own oauth credentials" and then place your id/secret before getting your refresh token

# Plug in client id, client secret and refresh token here
client_id="[REPLACE]"
client_secret="[REPLACE]"
refresh_token="[REPLACE]"

cid_base_url="apps.googleusercontent.com"

token_url="https://accounts.google.com/o/oauth2/token"
api_base_url="https://www.googleapis.com/upload/youtube/v3"
api_url="$api_base_url/videos?part=snippet"
access_token=$(curl -H "Content-Type: application/x-www-form-urlencoded" -d refresh_token="$refresh_token" -d client_id="$client_id" -d client_secret="$client_secret"  -d grant_type="refresh_token" $token_url| awk -F '"' '/access/{print $4}')
auth_header="Authorization: Bearer $access_token"

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
curl -v --data-binary "@$NEWVID/$MKV" -H "Content-Type: application/octet-stream" -H "$auth_header" "$api_url"
done

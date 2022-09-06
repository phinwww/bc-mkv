#!/bin/sh
# Generate captions used by the VM video generator
MP3LOG="mp3log.txt"

cp startup-caption.txt caption.txt
while true ; do
    tail -7 "$MP3LOG" | head -6 > newcap.txt
    diff -q newcap.txt caption.txt
    if [ $? -eq 1 ] ; then
	# make sure it's done by looking for the magic word
	tail -1 newcap.txt | grep -q 'Comment:'
	RES=$?
	while [ $RES -gt 0 ] ; do
	    echo "Bad caption data, waiting..."
	    sleep 1
	    tail -7 "$MP3LOG" | head -6 > newcap.txt
	    tail -1 newcap.txt | grep -q 'Comment:'
	    RES=$?
	done
	sed 's/%/\\%/' newcap.txt > fixedcap.txt
	mv fixedcap.txt caption.txt
	echo "Caption updated at "`date`
	cat caption.txt
	echo "---"
    fi
    sleep 1
done


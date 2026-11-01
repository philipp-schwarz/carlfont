#!/bin/bash

#!/bin/bash

WATCH=false

if [[ "$1" == "--watch" ]]; then
    WATCH=true
fi

function createFontJs() {
	local pngFile="$1"
	local jsFile="$2"
	local name="$3"

	echo "var fontImage = 'data:image/png;base64,$(base64 -w 0 "$pngFile")';" > "$jsFile"
	echo "if (window.Draw16) Draw16.loadFontAsync('$name', fontImage);" >> "$jsFile"
}

process() {
	echo -n "Processing font.png..."

	rm -f fontstrip_*.png

	convert font.png \
	    -background white \
	    -alpha remove \
	    -alpha off \
	    -colorspace Gray \
	    -threshold 50% \
	    -crop 4096x16 \
	    +repage \
	    -depth 1 \
	    -define png:color-type=0 \
	    -define png:bit-depth=1 \
	    fontstrip_%02d.png

	pngquant --ext _min.png fontstrip_*.png

	cp fontstrip_00_min.png ../font/carl5.png
	createFontJs "../font/carl5.png" "../font/js/carl5.js" "carl5"

	cp fontstrip_01_min.png ../font/carl6.png
	createFontJs "../font/carl6.png" "../font/js/carl6.js" "carl6"

	cp fontstrip_02_min.png ../font/carl8.png
	createFontJs "../font/carl8.png" "../font/js/carl8.js" "carl8"

	cp fontstrip_03_min.png ../font/carl5bold.png
	createFontJs "../font/carl5bold.png" "../font/js/carl5bold.js" "carl5bold"

	cp fontstrip_04_min.png ../font/carl6bold.png
	createFontJs "../font/carl6bold.png" "../font/js/carl6bold.js" "carl6bold"

	cp fontstrip_05_min.png ../font/carl8bold.png
	createFontJs "../font/carl8bold.png" "../font/js/carl8bold.js" "carl8bold"

	bash png2ttf.sh ../font/carl5.png ../font/ttf/carl5-regular.ttf "Carl 5 Regular" 1 4
	bash png2ttf.sh ../font/carl5.png ../font/ttf/carl5-pad-regular.ttf "Carl 5 Pad Regular" 2 4
	bash png2ttf.sh ../font/carl6.png ../font/ttf/carl6-regular.ttf "Carl 6 Regular" 1 4
	bash png2ttf.sh ../font/carl6.png ../font/ttf/carl6-pad-regular.ttf "Carl 6 Pad Regular" 2 4
	bash png2ttf.sh ../font/carl8.png ../font/ttf/carl8-regular.ttf "Carl 8 Regular" 1 4
	bash png2ttf.sh ../font/carl8.png ../font/ttf/carl8-pad-regular.ttf "Carl 8 Pad Regular" 2 4
	bash png2ttf.sh ../font/carl5bold.png ../font/ttf/carl5-bold.ttf "Carl 5 Bold" 1 4
	bash png2ttf.sh ../font/carl5bold.png ../font/ttf/carl5-pad-bold.ttf "Carl 5 Pad Bold" 2 4
	bash png2ttf.sh ../font/carl6bold.png ../font/ttf/carl6-bold.ttf "Carl 6 Bold" 1 4
	bash png2ttf.sh ../font/carl6bold.png ../font/ttf/carl6-pad-bold.ttf "Carl 6 Pad Bold" 2 4
	bash png2ttf.sh ../font/carl8bold.png ../font/ttf/carl8-bold.ttf "Carl 8 Bold" 1 4
	bash png2ttf.sh ../font/carl8bold.png ../font/ttf/carl8-pad-bold.ttf "Carl 8 Pad Bold" 2 4

	rm -f fontstrip_*.png

	echo "done!"
}

waitForWrite() {
	local LAST=""
	local CURRENT=""
	local STABLE=0

	while (( STABLE < 3 )); do
		CURRENT=$(stat -c '%s:%y' font.png 2>/dev/null || echo "")

		if [[ -n "$CURRENT" && "$CURRENT" == "$LAST" ]]; then
			((STABLE++))
		else
			STABLE=0
		fi

		LAST="$CURRENT"
		sleep 0.2
	done
}



process

$WATCH || exit 0

LAST=$(stat -c %Y font.png)

while true; do
	sleep 0.2

	CURRENT=$(stat -c %Y font.png 2>/dev/null || echo "")

	if [[ "$CURRENT" != "$LAST" && -n "$CURRENT" ]]; then
		waitForWrite
		LAST=$CURRENT
		process
	fi
done

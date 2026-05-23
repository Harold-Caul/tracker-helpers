# after we rip 100% flacs from cds, transmogrify them into 320kbps and V0 MP3's as well. Then do the other things.
#
# To do:
# X Assign Genre Tag
# X Pass metadata correctly
# - Rename album to release year (unless a possible year is found in album name)
# - Alert missing important metadata (genre, year, w/e)
# - Approve spectrograms first
# - Optional mkbrr
# - Optional Picard
# - Config
# - Offer to open bandcamp URL when entering genre tag. Offer to suggest genres from puddletag list or from Picard.
# - Autoexecute on bandcamp flac downloads?
# - I will find problems with my own stuff. This is very instructional to make.

# Current default paths create folders that look like this,
#
# Parent Directory
# ├─ FLAC Album ── FLACs, .cue, .log; art
# ├─ 320  "   " ── MP3s, art
# ├─ v0   "   " ── MP3s, art
# ├─ Next Album
#
# You may prefer something different. This is for ease of using mkbrr.


function projection {
shopt -s nullglob
local FLAC_FILES=(*.flac)

if [ ${#FLAC_FILES[@]} -eq 0 ]; then
	echo "No .flac's here, boss."
	return 1
else
	echo -e "\nLet's do some quick setup here."
	echo -e "\nWIP Script means you need to do the following:\n - Rename the directory to include the album year.\n - Find and open the bandcamp URL yourself.\n - Check the spectrographs that will be put in this folder.\n - Run 'for d in */; do mkbrr create -P --preset-- \"$d\"; done'\n"
	read -p "Got that?"
	has_genre=$(metaflac --show-tag=GENRE "${FLAC_FILES[0]}" | cut -d= -f2)
fi

if [ -n "$has_genre" ]; then
	echo "Found genre tag already: '$has_genre'"
	read -p "Overwrite it? (y/N): " choice
	if [[ "$choice" =~ ^[Yy] ]]; then
		read -p "Genre tag for all files: " new_genre
  else	 
    echo "Heard you, keeping '$has_genre' tag."
	fi
else
	echo "No genre tag."
	read -p "Genre tag for all files: " new_genre
fi 

if [ -n "$new_genre" ]; then
	for f in "${FLAC_FILES[@]}"; do
	metaflac --remove-tag=GENRE "$f"
	metaflac --set-tag="GENRE=$new_genre" "$f"
  done
	echo "Set all files to genre tag '$new_genre'."
fi 

# Current problem is we need to stream this info out of the flac.
# The raw PCM that goes into LAME has no metadata.


local CDIR=$(basename "$PWD")
local PDIR=$(dirname "$PWD")

if [[ ! "$CDIR" =~ " - FLAC" ]]; then
local	ALBUM="$CDIR"
else
	echo "WIP exception, unclean album dir name"
	return 1
fi

local	FLACD="${PDIR}/${ALBUM} - FLAC"
local	v0D="${PDIR}/${ALBUM} - v0"
local	cbrD="${PDIR}/${ALBUM} - 320"


echo -e "Making v0 mp3 directory:\n$v0D"
mkdir -p "$v0D"
echo -e "Making 320kbps mp3 directory:\n$cbrD"
mkdir -p "$cbrD"

local cover_files=(*cover*.* *album*.* *folder*.* *.jpg *.png)
for art in "${cover_files[@]}"; do
	# Double-check it is an actual file, not a directory or a false match
	if [ -f "$art" ]; then
		echo -e "\nCopying album cover '$art' to v0 directory."
		cp -a "$art" "$v0D/"
		echo -e "And '$art' to 320kbps directory."
		cp -a "$art" "$cbrD/"
	fi
done


for f in "${FLAC_FILES[@]}"; do
	local TRACKNAME=$(basename "${f%.flac}")

# The raw PCM that goes into LAME has no metadata and we're not using ffmpeg so we're doing this by hand.
	
	unset TITL ARTS DATE ALBM TRNO GENR DISC DSCT COMP ALRT CMNT PUBL # Reset for each track obviously.
	
	while IFS='=' read -r rawtag rawvalue; do # Fix lead/trail whitespace.	
		tag=$(echo "$rawtag" | xargs)
		value=$(echo "$rawvalue" | xargs) 
		
		case "${tag^^}" in #Force Caps
			TITLE)                        TITL="$value" ;; # To do abbreviations, just start spelling it, then quick
			ARTIST)    	                  ARTS="$value" ;;
			DATE)                         DATE="${value:0:4}" ;; #just YYYY
			ALBUM)                        ALBM="$value" ;;
			TRACKNUMBER)                  TRNO="$value" ;;
			GENRE)                        GENR="$value" ;;
			DISCNUMBER|DISC)              DISC="$value" ;;
			DISCTOTAL|TOTALDISCS)         DSCT="$value" ;;
			COMPOSER)                     COMP="$value" ;;
			ALBUMARTIST)                  ALRT="$value" ;; # This and Comment most commonly for Bandcamp.
			COMMENT|DESCRIPTION|NOTES)    CMNT="$value" ;; # Diff standards. 
			ORGANIZATION|PUBLISHER|LABEL) PUBL="$value" ;; 
		esac
	done < <(metaflac --export-tags-to=- "$f") # <(~~~) makes a temp "file" and then the < sends it right into the loop. You learn new stuff every day.
  # If we piped it it'd forget all of it the moment it left the loop.

	local id3meta=( # Make an array.
    -tt "${TITL:-}"
    -ta "${ARTS:-}"
    -ty "${DATE:-}"
    -tl "${ALBM:-}"
    -tn "${TRNO:-}"
    -tg "${GENR:-}" 
		${DISC:+--tv "TPOS=${DISC}${DSCT:+/$DSCT}"}
		${COMP:+--tv "TCOM=$COMP"}
    ${ALRT:+--tv "TPE2=$ALRT"} # Why is this ever even put on non-VA albums 
    ${CMNT:+--comment "$CMNT"} # Bandcamp "visit link" tag most often than not.
		${PUBL:+--tv "TPUB=$PUBL"}
  )

	echo -e "\n-------Doing v0 for $TRACKNAME.-------"
	
	flac -dc "$f" | lame -V 0 -q 0 --id3v2-only "${id3meta[@]}" - "$v0D/${TRACKNAME}.mp3" 

	echo -e "\n-------doing 320 for $TRACKNAME.-------"
		
	flac -dc "$f" | lame -b 320 -q 0 --id3v2-only "${id3meta[@]}" - "$cbrD/${TRACKNAME}.mp3"

done

echo -e 

echo -e "\nFixing FLAC album name. \n $FLACD\n"
cd "$PDIR" || return 1
mv "$CDIR" "$FLACD"
cd "$FLACD" || return 1


echo -e "\nGenerating Spectrograms in FLAC folder."
for f in "${FLAC_FILES[@]}"; do
	local TRACKNAME=$(basename "${f%.flac}")
	
	sox "$f" -n remix 1 spectrogram -x 3000 -y 513 -z 120 -w Kaiser -o "$TRACKNAME-full.png"

	sox "$f" -n remix 1 spectrogram -X 500 -y 1025 -z 120 -w Kaiser -S 1:00 -d 0:02 -o "$TRACKNAME-zoom.png"

done

shopt -u nullglob
echo -e "\nDone."
}

I made projection before I knew about [smoked-salmon](https://github.com/smokin-salmon/smoked-salmon). I will still probably continue working on projection because it's been highly educational for me to do so, but also for the express purpose of a single continuous process that will turn a single folder out of EAC, Bandcamp, wherever, and with supervision give you the folders and torrents to upload of them.

I'm unsure if I want to add uploading capabilities to it, but it would likely involve filling a small form and generating the description to summarize its process that compresses the key steps of the script.

e.g.

>  [Custom description]
>
>  Downloaded album from bandcamp at [link found in comment] OR some explanation of how it was acquired that you will be asked for, "did you extract or download this, howso/from where?"
>
>  Changed genre to XYZ via terminal command `for f in *; do	metaflac --set-tag="GENRE=XYZ" "$f" done`
>
>  Then encoded via terminal command `for f in *; do flac -dc "$f" | lame -b 320 -q 0 - "${f%.flac}.mp3"; done`
>
>  Used flac 1.4.3, lame 64bit 3.100, mkbrr 1.23.0, [other tools mentioned]
>
>  Uploaded via Projection
>
>  [Other custom description]

This way we can ensure we have a thorough informative description that largely writes itself, continuing our theme of merely supervising the program and doing what little we need to do. I simply personally feel descriptions should be this thorough, and I find descriptions that simply mention they were automated and nothing else to be pointless.

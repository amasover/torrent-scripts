#!/usr/bin/env bash

# Prevent sudo timeout
sudo -v # ask for sudo password up-front
while true; do
  # Update user's timestamp without running a command
  sudo -nv; sleep 60
  # Exit when the parent process is not running any more. In fact this loop
  # would be killed anyway after being an orphan(when the parent process
  # exits). But this ensures that and probably exit sooner.
  kill -0 $$ 2>/dev/null || exit
done &

dest="$1"
shift

while (( "$#" )); do

rsync -a --info=progress2 --no-perms "${1%/}" "$dest"

mv "$1" ../copied/

xslash_name="${1//\\/}" #strip backslash
xslash_name="${xslash_name//\//}" #strip slash

info=$(sudo iocage exec transmission transmission-remote -l)
header=$(echo "$info" | sed -n 1p)
body=$(echo "$info" | sed -ne:n -e '1d;N;1,10bn' -eP\;D )

position=$(echo "$header" | awk 'match($0,"Name"){print RSTART}')

names=$(echo "$body" | cut -c"$position"-)
ids=$(echo "$body" | awk '{ print $1 }')

data=$(paste -d ':' <(echo "$ids") <(echo "$names"))

while read -r line; do
    id=$(echo "$line" | awk -F: '{ print $1 }')
    name=$(echo "$line" | awk -F: '{ print $2 }')
    if [ "$xslash_name" = "$name" ]; then
        echo "I found \"${name}\" in the list of torrents. It has an id ${id}. Notifying Transmission of the new location"
        sudo iocage exec transmission transmission-remote -t"$id" --find "/media/copied"
    fi
done <<< "$data"

shift

done
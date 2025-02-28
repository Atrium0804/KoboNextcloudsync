#!/bin/sh

# Description
# Syncs remote shares as defined in the rclone.conf file to a local destination
# Deletes local files removed from server
# Creates covers for downloaded books.
#
# uses:
# kepubify: https://github.com/pgaskin/kepubify
# jq:       https://github.com/stedolan/jq
# rclone:   https://github.com/rclone/rclone

#load config
. $(dirname $0)/config.sh

echo
echo "$YELLOW ======================================================"
echo "`$Dt` start"

# clear the rclone logfile
echo "`$Dt`" > "$rcloneLogfile"

# check working network connection
$SH_HOME/checkNetwork.sh
hasNetwork=$?
if [ $hasNetwork -ne 0 ];
then
    echo "No network connection, aborting"
    exit 1
fi

#  get remote shares and download files
echo "get shares"
shares=`$rclone listremotes $rcloneOptions | sed 's/://' `
if [ -z $shares ];
then
    echo "No shares in configfile $rcloneConfig"
    exit 1
fi

# download remote files for each share
echo "$shares" |
while IFS= read -r currentShare; do
    echo "processing share $currentShare"
    $HOME/opt/downloadFiles.sh "$currentShare"
done

# check network again as the kobo might close the wifi after a while
# check working network connection
echo "Pruning folders"
$SH_HOME/checkNetwork.sh
hasNetwork=$?
if [ $hasNetwork -ne 0 ];
then
    echo "No network connection, aborting"
    exit 1
fi
$SH_HOME/pruneFolders.sh

if [ -f $booksdownloadedTrigger ]; then
    # generate covers
    echo "Generating Covers"
    $covergen "$KoboFolder" > /dev/null
    $seriesmeta "$KoboFolder" > /dev/null
    rm -f $booksdownloadedTrigger
    inkscr "cloudsync: rescan your e-books."
else
    echo "kobocloudsync ready, no new e-books"
fi
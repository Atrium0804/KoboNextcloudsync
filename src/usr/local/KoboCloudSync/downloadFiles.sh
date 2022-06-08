#!/bin/sh

#load config
. $(dirname $0)/config.sh
  
echo "`$Dt` starting downloadFiles.sh for share '$1'"

currentShare=$1
echo "$GREEN processing share: $currentShare $NC"    

# get all remote objects (files/folders)
theJsonListing=`$rclone lsjson -R  $currentShare:/ $rcloneOptions`
# echo "theJsonListing: $theJsonListing"
# remove directories
theRemoteFilepaths=`echo "$theJsonListing" | $jq  -c '.[] | select(.IsDir==false).Path' `

# remove double quotes
theRemoteFilepaths=`echo "$theRemoteFilepaths" | sed "s/\"//g"`

# remove incompatible files
theRemoteFilepaths=`echo "$theRemoteFilepaths" | grep -i -f $ExtensionPatterns`

# Process the files in the current share
echo "$theRemoteFilepaths" |
while IFS= read -r theRemoteFile; do
	# echo "theRemoteFile: $theRemoteFile"
	theFilename=`basename "$theRemoteFile"`									# the original filename without path
	theTargetFilename=`echo "$theFilename" | sed "$kepubRenamePattern"`		# the target filename with .epub renamed to .kepub.epub
	theLocalFolder=`dirname "$DocumentRoot/$currentShare/$theRemoteFile"`	# the destination folder (including remote subfolders)
	theHashfile="$theLocalFolder/$theTargetFilename.sha1"

	# if the file is not compatible with the device, skip download
	# if the MD5-hash of the local file is differend from the remote file, the file should be downloaded
		# download the file
		# if successfull, download the MD5-hash to file
	# if the tempfilename is different from the local filename, convert epub to kepub-epub
	
	$rclone sha1sum "$currentShare":"$theRemoteFile" --checkfile="$theHashfile" $rcloneOptions  >/dev/null 2>&1
	hashcompare=$?
	
	echo
	echo "$CYAN processing $theFilename  $theLocalFolder/$theTargetFilename  $NC"
	echo "$CYAN hashcompare $hashcompare $NC"
	theTargegFilepath="$theLocalFolder/$theTargetFilename" 
	if [ ! -f "$theTargegFilepath" ]; then
		echo "file does not exist: $theTargegFilepath"
	fi
	
	
	# if the hash is different or the local file is missing, download the file
	if [ $hashcompare -eq 1 ] || [ ! -f "$theTargegFilepath" ];
		then
		inkscr "Downloading: $theFilename"
		$rclone sync  "$currentShare":"$theRemoteFile" "$theLocalFolder/" $rcloneOptions
		$rclone sha1sum "$currentShare":"$theRemoteFile" --output-file="$theHashfile" $rcloneOptions
		if [ "$theFilename" != "$theTargetFilename" ]; then 
			inkscr "Converting: $theFilename"
			$kepubify "$theLocalFolder/$theFilename"  -o "$theTargegFilepath" 
			rm -f "$theLocalFolder/$theFilename"
		fi
	else
		echo "no change: $theFilename"
	fi
done
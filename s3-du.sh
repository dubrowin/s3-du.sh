#!/bin/bash

#########################
## Compute Prefix (dir) size
## similar to the Linux du
## command, but for S3 buckets
## 
## By: Shlomo Dubrowin
## May 28, 2019
#########################

#########################
## Functions
#########################

function Debug {
        if [ "$DEBUG" == "Y" ]; then
                echo -e "$1"
        fi
}

function Help {
	echo -e "\n\tusage: $( basename "$0" ) \n\t\t[ -d | --debug ] \n\t\t[ -a | --all ] -- check all the buckets in your account \n\t\t[ -h | --help ] \n\t\t<Bucket: s3://bucket-name/> -- if not checking all, specify a bucket\n"	
	exit

}

function GetSizing {
	Debug "Debug: aws s3 ls ${BUCK}/${DIR} --recursive --human-readable --summarize"
	OUTPUT="$( aws s3 ls ${BUCK}/${DIR} --recursive --human-readable --summarize | grep "Total\ Objects:\|Total\ Size:" | tr '\n' ' ' | awk '{print $3 "\t\t" $6 " " $7}')"
	if [ "$DIR" == "" ]; then
		DIR="/"
	fi
	echo -e "$OUTPUT \t $DIR"
}

function CheckBucket {
	Debug "CheckBucket"
	## If there is no Bucket listed, exit
	if [ -z "$BUCK" ]; then
		Debug "Sending to Help, BUCK ($BUCK) is empty"
        	Help
	fi

	## Remove a trailing slash if there is one
	SLASH=`echo $BUCK | rev | cut -c 1 | rev`
	
	if [ "$SLASH" == "/" ]; then
        	BUCK=`echo $BUCK | rev | cut -c 2- | rev`
	fi
	
	Debug "Debug: BUCK $BUCK"
	
	## Start Output with Headers
	echo -e "Objects \t Size \t Dir"
	
	Debug "Debug DIR: $( aws s3 ls $BUCK | grep PRE )"
	
	## Loop through the Prefixes (dir) found to produce the sizes
	for DIR in $( aws s3 ls ${BUCK}/ | grep PRE ); do
        	if [ "$DIR" != "PRE" ]; then
                	#Debug "Debug: aws s3 ls ${BUCK}/${DIR} --recursive --human-readable --summarize"
                	#OUTPUT="$( aws s3 ls ${BUCK}/${DIR} --recursive --human-readable --summarize | grep "Total\ Objects:\|Total\ Size:" | tr '\n' ' ' | awk '{print $3 "\t\t" $6 " " $7}')"
                	#echo -e "$OUTPUT \t $DIR"
			GetSizing
        	fi
	done
	
	# Get the root Direcotry
	DIR=""
	GetSizing
	
}

#########################
## CLI Opotions
#########################

if [ -z $1 ]; then
	Help
fi

while [ "$1" != "" ]; do
        case $1 in
                -d | --debug )
                        DEBUG="Y"
                        echo "Turning on Debug"
                        ;;
		-a | --all )
			TOT="$( aws s3 ls | wc -l )"
			COUNT=1
			echo -e "Checking all buckets in your account ($TOT)\n"
			for BUCK in $( aws s3 ls | awk '{print $3}' ); do
				echo "Bucket $COUNT of $TOT: s3://$BUCK"
				CheckBucket
				echo ""
				let "COUNT = $COUNT + 1"
			done
			;;
		-h | --help )
			Debug "Case help"
			Help
			;;
                *)
			Debug "Case *"
                        BUCK="$1"
			CheckBucket
                        ;;
        esac
        shift
done

#########################
## Main Code
#########################


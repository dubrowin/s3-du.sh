#!/bin/bash


## CLI Opotions

while [ "$1" != "" ]; do
        case $1 in
                -d | --debug )
                        DEBUG="Y"
                        echo "Turning on Debug"
                        ;;
                *)
                        BUCK="$1"
                        ;;
        esac
        shift
done

## Remove a trailing slash if there is one
SLASH=`echo $BUCK | rev | cut -c 1 | rev`

if [ "$SLASH" == "/" ]; then
        BUCK=`echo $BUCK | rev | cut -c 2- | rev`
fi



if [ -z "$BUCK" ]; then
        echo -e "\n\tEnter a bucket\n"
        exit 1
fi

function Debug {
        if [ "$DEBUG" == "Y" ]; then
                echo -e "$1"
        fi
}

Debug "Debug: BUCK $BUCK"

echo -e "Objects \t Size \t Dir"

Debug "Debug DIR: $( aws s3 ls $BUCK | grep PRE )"

for DIR in $( aws s3 ls ${BUCK}/ | grep PRE ); do
        if [ "$DIR" != "PRE" ]; then
                Debug "Debug: aws s3 ls ${BUCK}/${DIR} --recursive --human-readable --summarize"
                OUTPUT="$( aws s3 ls ${BUCK}/${DIR} --recursive --human-readable --summarize | grep "Total\ Objects:\|Total\ Size:" | tr '\n' ' ' | awk '{print $3 "\t\t" $6 " " $7}')"
                echo -e "$OUTPUT \t $DIR"
        fi
done
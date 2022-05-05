#!/bin/bash  

# Generate userdata xml files for cluster

input=MTS-MCC-U.csv

template=cluster.xml

userdata_path=./userdata/

lines=0

while IFS= read -r line
do
  baseMgt=$(echo "$line" | awk -F ';' '/^[0-9]+/{print $9}' | sed 's;/;\\/;g' )
  baseInternal=$(echo "$line" | awk -F ';' '/^[0-9]+/{print $10}' | sed 's;/;\\/;g' )
  baseInternalMaster=$(echo "$line" | awk -F ';' '/^[0-9]+/{print $11}' | sed 's;/;\\/;g' )
  nodetype=$(echo "$line" | awk -F ';' '/^[0-9]+/{print $12}')
  userdata=$(echo "$line" | awk -F ';' '/^[0-9]+/{print $13}')

#  echo "mgt=$baseMgt base1=$baseInternal base2=$baseInternalMaster nodetype=$nodetype"
  if [ -n "$userdata" ]
  then

    cat $template | sed -e "s/__baseMgt__/${baseMgt}/" -e "s/__baseInternal__/${baseInternal}/" -e "s/__baseInternalMaster__/$baseInternalMaster/" -e "s/__nodetype__/$nodetype/" >$userdata_path$userdata

	echo $userdata

	lines=$((lines+1))
  fi

done < "$input"

echo done, processed $lines lines

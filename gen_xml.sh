#!/bin/bash  

# Generate userdata xml files for cluster

input=MTS-MCC-C.csv

template_cpm_ssm=cluster.xml
template_mcm=cluster-mcm.xml

userdata_path=./userdata/

if [ ! -d "$userdata_path" ]
then
		echo directory $userdata_path does not exist, exiting
		exit 1
fi

lines=0

while IFS= read -r line
do
  node=$(echo "$line" | awk -F ';' '/^[0-9]+/{print $1}' | sed 's;/;\\/;g' )
  cluster=$(echo "$line" | awk -F ';' '/^[0-9]+/{print $4}' | sed 's;/;\\/;g' )
  
  baseMgt=$(echo "$line" | awk -F ';' '/^[0-9]+/{print $9}' | sed 's;/;\\/;g' )
  baseInternal=$(echo "$line" | awk -F ';' '/^[0-9]+/{print $10}' | sed 's;/;\\/;g' )
  baseInternalMaster=$(echo "$line" | awk -F ';' '/^[0-9]+/{print $11}' | sed 's;/;\\/;g' )
  
  nodetype=$(echo "$line" | awk -F ';' '/^[0-9]+/{print $12}')
  userdata=$(echo "$line" | awk -F ';' '/^[0-9]+/{print $13}')

  if [ -n "$userdata" ]
  then
	if [ "$nodetype" == "mcm" ]
	then
			template=$template_mcm
	else
			template=$template_cpm_ssm
	fi

    cat $template | sed -e "s/__baseMgt__/${baseMgt}/" \
			-e "s/__baseInternal__/${baseInternal}/" \
			-e "s/__baseInternalMaster__/$baseInternalMaster/" \
			-e "s/__nodetype__/$nodetype/" \
			-e "s/__node__/$node/" \
			-e "s/__cluster__/$cluster/" >$userdata_path$userdata

	echo $userdata

	lines=$((lines+1))
  fi

done < "$input"

echo done, processed $lines lines

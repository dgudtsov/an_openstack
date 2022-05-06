#!/bin/bash 

# Generate openstack commands to deploy cluster

###
# Constants
###

input=MTS-MCC-C.csv

userdata_path=./userdata/

image_mcm="an-11.1.0.6-31.REL.ide"
image_payload="an-11.1.0.6-31.REL.payload.ide"

net_baseA="10149904-ee34-48e5-a497-484e549f7190"
net_baseB="1abbb1d8-50f2-44b4-8331-489bd0e1c421"
net_MGMT="6663cac7-bca0-465b-b447-dde90b1667f9"

###
# Templates
###

osp_port_create="openstack port create --network __NETWORK__ --vnic-type direct __PORT__ --disable-port-security "

osp_server_create_ssm="openstack server create --image $image_payload --flavor __FLAVOR__ \
--nic net-id=$net_baseA \
--nic net-id=$net_MGMT,v4-fixed-ip=__MGT__ \
--nic net-id=$net_baseB \
--nic port-id=__EW1__ \
--nic port-id=__NS1__ \
--nic port-id=__NS2__ \
--nic port-id=__EW2__ \
--availability-zone __AZ__ --user-data __USERDATA__ --config-drive true --wait --fit-width __VM__"

osp_server_create_cpm="openstack server create --image $image_payload --flavor __FLAVOR__ \
--nic net-id=$net_baseA \
--nic net-id=$net_MGMT,v4-fixed-ip=__MGT__ \
--nic net-id=$net_baseB \
--nic port-id=__EW1__ \
--nic port-id=__EW2__ \
--availability-zone __AZ__ --user-data __USERDATA__ --config-drive true --wait --fit-width __VM__"

osp_server_create_mcm="openstack server create --image $image_mcm --flavor __FLAVOR__ \
--nic net-id=$net_baseA \
--nic net-id=$net_MGMT,v4-fixed-ip=__MGT__ \
--nic net-id=$net_baseB \
--availability-zone __AZ__ --user-data __USERDATA__ --config-drive true --wait --fit-width __VM__"

###
# CODE
###

lines=0

while IFS= read -r
do
  line=$(echo -n $REPLY | tr -d '\r\n')

  Mgt=$(echo "$line" | awk -F ';' '/^[0-9]+/{print $5}' | sed 's;/;\\/;g' )
  
  nodetype=$(echo "$line" | awk -F ';' '/^[0-9]+/{print $12}')
  userdata=$(echo "$line" | awk -F ';' '/^[0-9]+/{print $13}')

  nw_ew1=$(echo "$line" | awk -F ';' '/^[0-9]+/{print $15}')
  nw_ew2=$(echo "$line" | awk -F ';' '/^[0-9]+/{print $16}')
  nw_ns1=$(echo "$line" | awk -F ';' '/^[0-9]+/{print $17}')
  nw_ns2=$(echo "$line" | awk -F ';' '/^[0-9]+/{print $18}')

  networks=($nw_ew1 $nw_ew2 $nw_ns1 $nw_ns2)

  p_ew1=$(echo "$line" | awk -F ';' '/^[0-9]+/{print $19}')
  p_ew2=$(echo "$line" | awk -F ';' '/^[0-9]+/{print $20}')
  p_ns1=$(echo "$line" | awk -F ';' '/^[0-9]+/{print $21}')
  p_ns2=$(echo "$line" | awk -F ';' '/^[0-9]+/{print $22}')

  ports=($p_ew1 $p_ew2 $p_ns1 $p_ns2)
  
  vm=$(echo "$line" | awk -F ';' '/^[0-9]+/{print $24}')
  az=$(echo "$line" | awk -F ';' '/^[0-9]+/{print $26}')
  flavor=$(echo "$line" | awk -F ';' '/^[0-9]+/{print $27}')

  case "$nodetype" in
	"cpm")
		osp_server_create=$osp_server_create_cpm
				  ;;
	"ssm")
		osp_server_create=$osp_server_create_ssm
				;;
	"mcm")
		osp_server_create=$osp_server_create_mcm
				;;
  esac
  
  port_ids=()

  for i in ${!networks[@]}; do
   echo $osp_port_create | sed -e "s/__NETWORK__/${networks[$i]}/" -e "s/__PORT__/${ports[$i]}/"

   port_id=$i

#   CMD=$(echo $osp_port_create | sed -e "s/__NETWORK__/${networks[$i]}/" -e "s/__PORT__/${ports[$i]}/" | awk -F '|' '/ id/{print $3}')
   CMD=$(echo $osp_port_create | sed -e "s/__NETWORK__/${networks[$i]}/" -e "s/__PORT__/${ports[$i]}/" )
 
   port_id=$($CMD | awk -F '|' '/ id/{print $3}')
   echo created port id: $port_id


   port_ids+=($port_id)

  done

  if [ -n "$userdata" ]
  then

  	CMD=$(echo $osp_server_create | sed \
		  -e "s/__FLAVOR__/$flavor/" \
		  -e "s/__MGT__/$Mgt/" \
		  -e "s/__AZ__/$az/" \
		  -e "s/__VM__/$vm/" \
		  -e "s/__USERDATA__/$userdata_path$userdata/" \
		  -e "s/__EW1__/${port_ids[0]}/" \
		  -e "s/__EW2__/${port_ids[1]}/" \
		  -e "s/__NS1__/${port_ids[2]}/" \
		  -e "s/__NS2__/${port_ids[3]}/")
	echo $CMD
	$($CMD)
	echo $userdata

	lines=$((lines+1))
  fi

done < "$input"

echo done, processed $lines lines


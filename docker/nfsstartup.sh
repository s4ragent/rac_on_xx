cd /root/rac_on_xx

source ./common.sh
if [ ! -e  /root/disablesecuritydone ]; then
  bash ./disablesecurity.sh
fi

if [ ! -e /root/createnfsdone ]; then
  bash ./createnfs.sh
fi

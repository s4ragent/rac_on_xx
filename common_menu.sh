#!/bin/bash
case "$1" in
  "crsctl" ) shift;common_crsctl $*;;
  "execansible" ) shift;common_execansible $*;;
  "iperf" ) shift;common_iperf $*;;
  "cvu" ) shift;common_cvu $*;;  
  "jdbcrunner" ) shift;common_jdbcrunner $*;;
  "jdbcrunner_only" ) shift;common_jdbcrunner_only $*;;
  "preinstall" ) shift;common_preinstall $*;;
  "preinstall_with_vnc" ) shift;common_preinstall_with_vnc $*;;
  "preinstall_with_xrdp" ) shift;common_preinstall_with_xrdp $*;;
  "after_runonly" ) shift;common_after_runonly $*;;
  "install_dbca" ) shift;common_install_dbca $*;;
  "gridrootsh" ) shift;common_gridrootsh $*;;
  "heatrun") shift;common_heatrun $*;;
  "runall" ) shift;common_runall $*;;
  "ssh" ) shift;common_ssh $*;;
  "replaceinventory" ) shift;common_all_replaceinventory $*;;
  "create_inventry" ) shift;common_create_inventry "$@";;
  "run" ) shift;run $*;;
  "runonly" ) shift;common_runonly $*;;
  "deleteall" ) shift;common_deleteall $*;;
  "buildimage" ) shift;buildimage $*;;
  "get_External_IP" ) shift;get_External_IP $*;;
  "get_Internal_IP" ) shift;get_Internal_IP $*;;
esac

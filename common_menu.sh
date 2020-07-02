#!/bin/bash
case "$1" in
  "crsctl" ) shift;common_crsctl $*;;
  "execansible" ) shift;common_execansible $*;;
  "iperf" ) shift;common_iperf $*;;
  "iperf_only" ) shift;common_iperf_only $*;;
  "cvu" ) shift;common_cvu $*;;  
  "cvu_only" ) shift;common_cvu_only $*;;  
  "jdbcrunner" ) shift;common_jdbcrunner $*;;
  "jdbcrunner_only" ) shift;common_jdbcrunner_only $*;;
  "preinstall" ) shift;common_preinstall $*;;
  "preinstall_with_vnc" ) shift;common_preinstall_with_vnc $*;;
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
  "stop" ) shift;stop $*;;
  "start" ) shift;start $*;;
  "addClient" ) shift;common_addClient $*;;
  "deletedatabase" ) shift;common_deletedatabase $*;;
esac

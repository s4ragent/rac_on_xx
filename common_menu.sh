#!/bin/bash
case "$1" in
  "crsctl" ) shift;common_crsctl $*;;
  "execansible" ) shift;common_execansible $*;;
  "cvu" ) shift;common_cvu $*;;  
  "cvu_only" ) shift;common_cvu_only $*;;  
  "jdbcrunner" ) shift;common_jdbcrunner $*;;
  "jdbcrunner_single" ) shift;common_jdbcrunner_single $*;;
  "preinstall" ) shift;common_preinstall $*;;
  "preinstall_with_vnc" ) shift;common_preinstall_with_vnc $*;;
  "after_runonly" ) shift;common_after_runonly $*;;
  "install_dbca" ) shift;common_install_dbca $*;;
  "heatrun") shift;common_heatrun $*;;
  "heatrun_single") shift;common_heatrun_single $*;;
  "runall" ) shift;common_runall $*;;
  "runall_single" ) shift;common_runall_single $*;;
  "ssh" ) shift;common_ssh $*;;
  "replaceinventory" ) shift;common_all_replaceinventory $*;;
  "create_inventry" ) shift;common_create_inventry "$@";;
  "run" ) shift;run $*;;
  "runonly" ) shift;common_runonly $*;;
  "runonly_single" ) shift;common_runonly_single $*;;
  "deleteall" ) shift;common_deleteall $*;;
  "buildimage" ) shift;buildimage $*;;
  "get_External_IP" ) shift;get_External_IP $*;;
  "get_Internal_IP" ) shift;get_Internal_IP $*;;
  "stop" ) shift;stop $*;;
  "start" ) shift;start $*;;
  "addClient" ) shift;common_addClient $*;;
  "addStorage" ) shift;common_addStorage $*;;
  "addDbServer" ) shift;common_addDbServer $*;;
  "deletedatabase" ) shift;common_deletedatabase $*;;
  "reboot_crsctl" ) shift;common_reboot_crsctl $*;;
esac

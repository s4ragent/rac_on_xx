#!/bin/bash
case "$1" in
  "execansible" ) shift;common_execansible $*;;
  "iperf" ) shift;common_iperf $*;;
  "preinstall" ) shift;common_preinstall $*;;
  "after_runonly" ) shift;common_after_runonly $*;;
  "install_dbca" ) shift;common_install_dbca $*;;
  "startall" ) shift;common_startall $*;;
  "start" ) shift;common_start $*;;
  "stop" ) shift;common_stop $*;;
  "stopall" ) shift;common_stopall $*;;
  "heatrun") shift;common_heatrun $*;;
  "heatrun_full") shift;common_heatrun_full $*;;
  "runall" ) shift;common_runall $*;;
  "ssh" ) shift;common_ssh $*;;
  "replaceinventory" ) shift;replaceinventory $*;;
  "create_inventry" ) shift;common_create_inventry "$@";;
  "run" ) shift;run $*;;
  "runonly" ) shift;runonly $*;;
  "deleteall" ) shift;deleteall $*;;
  "buildimage" ) shift;buildimage $*;;
  "get_External_IP" ) shift;get_External_IP $*;;
  "get_Internal_IP" ) shift;get_Internal_IP $*;;
  "create_box" ) shift;common_create_box $*;;
esac

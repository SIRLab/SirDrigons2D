#!/bin/sh

echo "******************************************************************"
echo " HELIOS base"
echo " National Institute of Advanced Industrial Science and Technology"
echo " Created by Hidehisa Akiyama and Hiroki Shimora"
echo " Copyright 2000-2007.  Hidehisa Akiyama"
echo " Copyright 2007-2010.  Hidehisa Akiyama and Hiroki Shimora"
echo " All rights reserved."
echo "******************************************************************"


LIBPATH=/usr/local/lib
if [ x"$LIBPATH" != x ]; then
  if [ x"$LD_LIBRARY_PATH" = x ]; then
    LD_LIBRARY_PATH=$LIBPATH
  else
    LD_LIBRARY_PATH=$LIBPATH:$LD_LIBRARY_PATH
  fi
  export LD_LIBRARY_PATH
fi

DIR=`dirname $0`

player="${DIR}/sample_player"
coach="${DIR}/sample_coach"
trainer="${DIR}/sample_trainer"

keeper_teamname="Keeper"
taker_teamname="Taker"

host="localhost"
port=6000
coach_port=""
debug_server_host=""
debug_server_port=""

player_conf="${DIR}/player.conf"

keeper_config_dir="${DIR}/formations-keeper"
taker_config_dir="${DIR}/formations-taker"

coach_conf="${DIR}/coach.conf"
team_graphic="--use_team_graphic off"

number=11
usecoach="true"

unum=0

sleepprog=sleep
goaliesleep=1
sleeptime=0

debugopt=""
coachdebug=""

offline_logging=""
offline_mode=""
fullstateopt=""

usage()
{
  (echo "Usage: $0 [options]"
   echo "Available options:"
   echo "      --help                   prints this"
   echo "  -h, --host HOST              specifies server host (default: localhost)"
   echo "  -p, --port PORT              specifies server port (default: 6000)"
   echo "  -P  --coach-port PORT        specifies server port for online coach (default: 6002)"
   echo "  -f, --formation DIR          specifies the formation directory"
   echo "  --offline-logging            writes offline client log (default: off)"
   echo "  --offline-client-mode        starts as an offline client (default: off)"
   echo "  --debug                      writes debug log (default: off)"
   echo "  --debug_DEBUG_CATEGORY       writes DEBUG_CATEGORY to debug log"
   echo "  --debug-server-connect       connects to the debug server (default: off)"
   echo "  --debug-server-host HOST     specifies debug server host (default: localhost)"
   echo "  --debug-server-port PORT     specifies debug server port (default: 6032)"
   echo "  --debug-server-logging       writes debug server log (default: off)"
   echo "  --log-dir DIRECTORY          specifies debug log directory (default: /tmp)"
   echo "  --debug-log-ext EXTENSION    specifies debug log file extension (default: .log)"
   echo "  --fullstate FULLSTATE_TYPE   specifies fullstate model handling"
   echo "                               FULLSTATE_TYPE is one of [ignore|reference|override].") 1>&2
}

while [ $# -gt 0 ]
do
  case $1 in

    --help)
      usage
      exit 0
      ;;

    -h|--host)
      if [ $# -lt 2 ]; then
        usage
        exit 1
      fi
      host="${2}"
      shift 1
      ;;

    -p|--port)
      if [ $# -lt 2 ]; then
        usage
        exit 1
      fi
      port="${2}"
      shift 1
      ;;

    -P|--coach-port)
      if [ $# -lt 2 ]; then
        usage
        exit 1
      fi
      coach_port="${2}"
      shift 1
      ;;

    -f|--formation)
      if [ $# -lt 2 ]; then
        usage
        exit 1
      fi
      config_dir="${2}"
      shift 1
      ;;

    --offline-logging)
      offline_logging="--offline_logging"
      ;;

    --offline-client-mode)
      offline_mode="on"
      ;;

    --debug)
      debugopt="${debugopt} --debug"
      coachdebug="${coachdebug} --debug"
      ;;

    --debug_*)
      debug_opt="${debug_opt} ${1}"
      ;;

    --debug-server-connect)
      debugopt="${debugopt} --debug_server_connect"
      ;;

    --debug-server-host)
      if [ $# -lt 2 ]; then
        usage
        exit 1
      fi
      debug_server_host="${2}"
      shift 1
      ;;

    --debug-server-port)
      if [ $# -lt 2 ]; then
        usage
        exit 1
      fi
      debug_server_port="${2}"
      shift 1
      ;;

    --debug-server-logging)
      debugopt="${debugopt} --debug_server_logging"
      ;;

    --log-dir)
      if [ $# -lt 2 ]; then
        usage
        exit 1
      fi
      debugopt="${debugopt} --log_dir ${2}"
      shift 1
      ;;

    --debug-log-ext)
      if [ $# -lt 2 ]; then
        usage
        exit 1
      fi
      debugopt="${debugopt} --debug_log_ext ${2}"
      shift 1
      ;;

    --fullstate)
      if [ $# -lt 2 ]; then
        usage
        exit 1
      fi
      fullstate_type="${2}"
      shift 1

      case "${fullstate_type}" in
        ignore)
          fullstateopt="--use_fullstate false --debug_fullstate false"
          ;;

        reference)
          fullstateopt="--use_fullstate false --debug_fullstate true"
          ;;

        override)
          fullstateopt="--use_fullstate true --debug_fullstate true"
          ;;

        *)
          usage
          exit 1
          ;;
      esac
      ;;

    *)
      echo 1>&2
      echo "invalid option \"${1}\"." 1>&2
      echo 1>&2
      usage
      exit 1
      ;;
  esac

  shift 1
done

if  [ X"${offline_logging}" != X'' ]; then
  if  [ X"${offline_mode}" != X'' ]; then
    echo "'--offline-logging' and '--offline-mode' cannot be used simultaneously."
    exit 1
  fi
fi

if [ X"${coach_port}" = X'' ]; then
  coach_port=`expr ${port} + 2`
fi

if [ X"${debug_server_host}" = X'' ]; then
  debug_server_host="${host}"
fi

if [ X"${debug_server_port}" = X'' ]; then
  debug_server_port=`expr ${port} + 32`
fi

opt="--player-config ${player_conf}"
opt="${opt} -h ${host} -p ${port}"
opt="${opt} ${fullstateopt}"
opt="${opt} --debug_server_host ${debug_server_host}"
opt="${opt} --debug_server_port ${debug_server_port}"
opt="${opt} ${offline_logging}"
opt="${opt} ${debugopt}"

i=1
while [ $i -le 3 ] ; do
  offline_number=""
  if  [ X"${offline_mode}" != X'' ]; then
    offline_number="--offline_client_number ${i}"
  fi

  $player ${opt} -t ${keeper_teamname} --config_dir ${keeper_config_dir} ${offline_number} &
  $sleepprog $sleeptime
  i=`expr $i + 1`
done

$sleepprog 1

i=1
while [ $i -le 2 ] ; do
  offline_number=""
  if  [ X"${offline_mode}" != X'' ]; then
    offline_number="--offline_client_number ${i}"
  fi

  $player ${opt} -t ${taker_teamname} --config_dir ${taker_config_dir} ${offline_number} &
  $sleepprog $sleeptime
  i=`expr $i + 1`
done

if  [ -z "${offline_mode}" ]; then
  $trainer -h ${host} -t ${keeper_teamname} --use_ear on
fi

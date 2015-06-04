!/bin/bash

# Run the TODO <GENERIC SERVICE NAME> get the <HEALTHCHECK CRITERIA>
# convert dates for easy math
# See if the upload is under the age threshold

servicename="elasticsearch"

while [[ $# -gt 0 ]]
do
  key="$1"
  case $key in
    -h|--help|help)
      usage=1
      shift
      ;;
    -p|--port)
      port=$2
      shift
      ;;
    -s|--server)
      server=$2
      shift
      ;;
    -t|--threshold)
      threshold_minutes=$2
      shift
      ;;
    -d|--debug)
      debug=1
      ;;
    *)
      ;;
  esac
  shift
done

check_arguments() {
  if [[ -z "$threshold" ]]; then
    threshold='10'
  fi
  if [[ -z "$port" ]]; then
    port='9200'
  fi
  if [[ -z "$server" ]]; then
    server='localhost'
  fi
}

get_record_timestamp() {
  today=$(date +%Y.%m.%d)
  index="logstash-${today}"
  urltail="_search?_source=@timestamp&size=1&sort=@timestamp:desc&format=yaml"
  logtime=$(curl -s XGET "${server}:${port}/${index}/${urltail}" | grep timestamp | cut -d'"' -f2)
  record_epoch=$(date -d "$logtime" +%s)

  if ! [[ $record_epoch =~ [0-9]{9} ]]; then
    echo "CRITICAL - Invalid timestamp! Timestamp: $record_epoch"
    exit 2
  fi
}

do_date_math() {
  threshold=$(( threshold_minutes * 60 ))
  now_epoch=$(date +%s)
  age_in_seconds=$(( now_epoch - record_epoch ))
}

check_delta_against_threshold() {
  if [ $age_in_seconds -gt $threshold ]; then
    echo "CRITICAL - Newest $servicename record is STALE! (threshold: $threshold, value: $age_in_seconds)"
    exit 2
  else
    echo "OK - Newest $servicename record is fresh (threshold: $threshold, value: $age_in_seconds)"
    exit 0
  fi
}

debug() {
  echo "record time is $logtime"
  echo "record epoch is $record_epoch"
  echo "now_epoch is $now_epoch"
  echo "delta is $age_in_seconds"
}

usage() {
  echo "usage: $0 -t [threshold] "
  echo "usage: $0 -t [threshold] -s [server] -d [debug_flag]"
  echo "example: $0 -t 10 "
  echo "example: $0 -s localhost -p 9200 -d "
}

run_the_program(){
  if [ "$usage" = 1 ]; then
    usage
  fi

  check_arguments
  get_record_timestamp
  do_date_math

  if [[ "$debug" == 1 ]]; then
    debug
  fi

  check_delta_against_threshold
  exit 0
}

run_the_program

#!/bin/bash

# header total number of rows
SCRIPT_HEADSIZE=$(head -200 "${0}" | grep -n "^# END_OF_HEADER" | cut -f1 -d:)
# Script name
SCRIPT_NAME="$(basename "${0}")"
# Version
VERSION="0.0.1"

currentTime=`date "+%Y-%m-%d %H:%M:%S"`

# usage
usage(){

  head -"${SCRIPT_HEADSIZE:-99}" "${0}"/a | grep -e "^#%"/a | sed -e "s/^#%//g" -e "s/\${SCRIPT_NAME}/${SCRIPT_NAME}/g" -e "s/\${VERSION}/${VERSION}/g"

}

# Send ding message
sendDingMessage() {
  curl -s "${1}" -H'Content-Type: application/json' -d "${2}"
}

# Check the validity of parameter input
checkParameters() {
  # -a, -t, -c parameters must be entered for verification
  if [ -z "${ACCESS_TOKEN}" ] || [ -z "${MSG_TYPE}" ] || [ -z "${CONTENT}" ]; then
    printf "Parameter [-a,-t,-c] is required!\n"
    exit 1
  fi

  # -t is: when markdown, the test parameter -T must be input
  if [ "X${MSG_TYPE}" = "Xmarkdown" ] && [ -z "${TITLE}" ]; then
    printf "When [-t] is'markdown', you must enter the parameter [-T]!\n"
    exit 1
  fi

  # -A and -m are mutually exclusive, only one method can be selected
  if [ "X${IS_AT_ALL}" = "Xtrue" ] && [ -n "${MOBILES}" ]; then
    printf "Only one of the parameters [-A] and [-m] can be entered!\n"
    exit 1
  fi
}

# markdown Message content
markdownMessage() {
  # Title
  title=${1}
  # Message content
  text=${2}
  # @ the way
  at=${3}

  # Determine whether it is @Everyone or a designated person
  if [ -z "${at}" ]; then
    atJson=""
  elif [ "X${at}" = "Xtrue" ]; then
    atJson='"at": {
        "isAtAll": true }'
  else
    # Determine whether there are multiple mobile phone numbers
    result=$(echo "${at}" | grep ",")

    # N mobile phone numbers
    if [ "X${result}" != "X" ]; then
      # Convert to mobile phone number array
      mobileArray=${at//,/}
      # Loop through the array and organize json format strings
      for mobile in "${mobileArray[@]}"; do
        mobiles="${mobile}",${mobiles}
        # @ Designated Person
        atMobiles="@${mobile}",${atMobiles}
      done

    # 1 mobile phone number
    else
      mobiles="${at}"
      # @ Designated person
      atMobiles="@${at}"
    fi

    # @json content
    atJson='"at": {
        "atMobiles": [
            '${mobiles/%,/}'
        ]
    }'

    # Content information add @specified person
    text="${text}\n${atMobiles/%,/}"
  fi

  message='{
       "msgtype": "markdown",
       "markdown": {
           "title":"'${title}'",
           "text": "'${text}'"},
        '${atJson}'
   }'

  echo "${message}"
}

# text Message content
textMessage() {
  # Message content
  text=${1}
  # @ the way
  at=${2}

  # Determine whether it is @Everyone or a designated person
  if [ -z "${at}" ]; then
    atJson=""
  elif [ "X${at}" = "Xtrue" ]; then
    atJson='"at": {
        "isAtAll": true }'
  else
    # Determine whether there are multiple mobile phone numbers
    result=$(echo "${at}" | grep ",")

    # N mobile phone numbers
    if [ "X${result}" != "X" ]; then
      # Convert to mobile phone number array
      mobileArray=${at//,/}
      # Loop through the array and organize json format strings
      for mobile in "${mobileArray[@]}"; do
        mobiles="${mobile}",${mobiles}
        # @ Designated Person
        atMobiles="@${mobile}",${atMobiles}
      done

    # 1 mobile phone number
    else
      mobiles="${at}"
      # @ Designated person
      atMobiles="@${at}"
    fi

    # @json content
    atJson='"at": {
        "atMobiles": [
            '${mobiles/%,/}'
        ]
    }'

    # Content information add @specified person
    text="${text}\n${atMobiles/%,/}"
  fi

  message='{
       "msgtype": "text",
       "text": {
           "content": "'${text}'"},
        '${atJson}'
   }'

  echo "${message}"
}

# Main method
main() {
  echo $currentTime

  # Check the validity of parameter input
  checkParameters

  # Determine the type of message sent
  case ${MSG_TYPE} in
  markdown)
    # Judgment @ Method
    if [ -n "${MOBILES}" ]; then
      DING_MESSAGE=$(markdownMessage "${TITLE}" "${CONTENT}" "${MOBILES}")
    elif [ -n "${IS_AT_ALL}" ]; then
      DING_MESSAGE=$(markdownMessage "${TITLE}" "${CONTENT}" "${IS_AT_ALL}")
    else
      DING_MESSAGE=$(markdownMessage "${TITLE}" "${CONTENT}")
    fi
    ;;
  text)
    if [ -n "${MOBILES}" ]; then
      DING_MESSAGE=$(textMessage "${CONTENT}" "${MOBILES}")
    elif [ -n "${IS_AT_ALL}" ]; then
      DING_MESSAGE=$(textMessage "${CONTENT}" "${IS_AT_ALL}")
    else
      DING_MESSAGE=$(textMessage "${CONTENT}")
    fi
    ;;
  *)
    printf "Unsupported message type, currently only [text, markdown] are supported!"
    exit 1
    ;;
  esac

  sendDingMessage "${DING_URL}" "${DING_MESSAGE}"
}

# Determine the number of parameters
if [ $# -eq 0 ]; then
  usage
  exit 1
fi

# getopt command line parameters
# if ! ARGS=$(getopt -o vAa:t:T:c:m: --long help,version -n "${SCRIPT_NAME}" - "$@"); then
#   # Invalid option, exit
#   exit 1
# fi

# Command line parameter formatting
eval set - "${ARGS}"

while [ -n "$1" ]; do
echo "test"
echo $ARGS
echo $1
  case "$1" in
  -a)
    # Webhook access_token
    ACCESS_TOKEN=$2
    # Dingding robot url address
    DING_URL="https://oapi.dingtalk.com/robot/send?access_token=${ACCESS_TOKEN}"
    echo "TOKEN"
    shift 2
    ;;

  -t)
    MSG_TYPE=$2
    shift 2
    ;;

  -T)
    TITLE=$2
    shift 2
    ;;

  -c)
    CONTENT=$2
    shift 2
    ;;

  -m)
    MOBILES=$2
    shift 2
    ;;

  -A)
    IS_AT_ALL=true
    shift 2
    ;;

  -M)
    PIPE="$2"
    CURRENT_STAMP=$(date -d "$currentTime" +%s)
    PIPE_STAMP=$(date -d "$PIPE" +%s)
    TIME_STRING=$((CURRENT_STAMP-PIPE_STAMP))
    CONTENT=$CONTENT$TIME_STRING"秒"
    shift 2
    ;;

  -U)
    MERGE_URL="$2"
    MARKDOWN_URL="### [pullRequest]($MERGE_URL)"
    CONTENT=$MARKDOWN_URL"\n"$CONTENT
    shift 2
    ;;

  -v | --version)
    printf "%s version %s\n" "${SCRIPT_NAME}" "${VERSION}"
    exit 1
    ;;

  --help)
    usage
    exit 1
    ;;

  --)
    shift
    break
    ;;



  *)
    printf "%s is not an option!" "$1"
    exit 1
    ;;



  esac
done

main

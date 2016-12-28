#!/bin/bash

trap 'xexit $?' 0 SIGHUP SIGINT SIGTERM

set -eo pipefail

if [[ $DEBUG -gt 0 ]]; then
    set -x
else
    set +x
fi

usage () {
    printf "Send Weekly Report by Email.\n"
    printf "${0##*/}\n"
    printf "\t[-n]\n"
    printf "\t[-f]\n"
    printf "\t[-w WEEK]\n"
    printf "\t[-y YEAR]\n"
    printf "\t[-h]\n\n"

    printf "OPTIONS\n"
    printf "\t[-n]\n\n"
    printf "\tNo test, sending report to the real recipients.\n\n"

    printf "\t[-f]\n\n"
    printf "\tForce to send even if the report was already marked as SENT.\n\n"

    printf "\t[-w WEEK]\n\n"
    printf "\tWeek number of the year, default is current week. \n"
    printf "\tUsing ISO 8601 calendar (Monday as the first day of the week) as a number (1-53).\n"
    printf "\tIf the week containing January 1 has four or more days in the new year, then it is week 1; \n"
    printf "\totherwise it is the last week of the previous year.\n\n"

    printf "\t[-y YEAR]\n\n"
    printf "\tYear with century as a number, default is current year.\n\n"

    printf "\t[-h]\n\n"
    printf "\tThis help.\n\n"
    exit 255
}

get_mail_file () {
    MAIL_FILE="$WR_REPO/$YEAR$(get_mail_file_extension)"
}

get_mail_file_extension () {
    case $WR_CONTENT_TYPE in
        plain)
            echo ".txt"
            ;;
        markdown)
            echo ".md"
            ;;
        *)
            echo "Unsupported content type: $WR_CONTENT_TYPE" >&2
            return 255
            ;;
    esac
}

concat_recipients () {
    while [[ $# -gt 0 ]]; do
        printf "$1,"
        shift
    done
}

xexit () {
    if [[ $1 -eq 0 ]]; then
        say -i "Succeeded."
    else
        say -i "Failed."
    fi
    exit $1
}

# Default
WEEK=$(date '+%V')
YEAR=$(date '+%Y')

while getopts nfw:y:h opt; do
    case $opt in
        n)
            NO_TEST=1
            ;;
        f)
            FORCE=1
            ;;
        w)
            WEEK=$OPTARG
            ;;
        y)
            YEAR=$OPTARG
            ;;
        h|*)
            usage >&2
            ;;
    esac
done

say -i "Weekly Report Sender started, year $YEAR and week $WEEK."

# WR_REPO
if [[ -z $WR_REPO ]]; then
    printf "Please set environment variable WR_REPO in your .bash_profile first.\n" >&2
    exit 255
fi

# Config
if [[ ! -s $WR_REPO/weekreport.conf ]]; then
    printf "Please config $WR_REPO/weekreport.conf first.\n" >&2
    exit 255
fi
source "$WR_REPO/weekreport.conf"

# File
get_mail_file

# Test or non-test
if [[ $NO_TEST -eq 1 ]]; then
    send_to="$(concat_recipients "${WR_TO[@]}")"
    cc_to="$(concat_recipients "${WR_CC[@]}")"
    bcc_to="$(concat_recipients "${WR_BCC[@]}")"
else
    send_to="$(concat_recipients "${WR_TEST_TO[@]}")"
    cc_to="$(concat_recipients "${WR_TEST_CC[@]}")"
    bcc_to="$(concat_recipients "${WR_TEST_BCC[@]}")"
fi

# Regex
REGEX_BEGIN="^## W${WEEK:?}$"
REGEX_BEGIN_FORCE="^## W${WEEK:?}( SENT)*$"
REGEX_END="^## W[0-9]{1,2}( SENT)*$"
SENT_MARKER="## W${WEEK:?} SENT"

# Subject
WR_SUBJECT=${WR_SUBJECT/<YEAR>/$YEAR}
WR_SUBJECT=${WR_SUBJECT/<WEEK>/$WEEK}

# Body
MAIL_BODY="$(awk -v begin="${REGEX_BEGIN_FORCE:?}" -v end="${REGEX_END:?}" \
    '{if (match($0, begin) > 0) {flag=1; next}; if(flag && match($0, end) > 0) {print lines; exit}; if (flag) lines=lines ORS $0}' "${MAIL_FILE:?}")"

if [[ -z $MAIL_BODY ]]; then
    printf "Not found report in $MAIL_FILE.\n" >&2
    exit 255
fi

if [[ $FORCE -ne 1 ]]; then
    MAIL_BODY="$(awk -v begin="${REGEX_BEGIN:?}" -v end="${REGEX_END:?}" \
        '{if (match($0, begin) > 0) {flag=1; next}; if(flag && match($0, end) > 0) {print lines; exit}; if (flag) lines=lines ORS $0}' "${MAIL_FILE:?}")"
fi

if [[ -z $MAIL_BODY ]]; then
    say -i "Report was already sent." >&2
    printf "Use -f to force send this report again.\n" >&2
    exit
fi

case $WR_CONTENT_TYPE in
    plain)
        WR_MAIL_CONTENT_TYPE="text/plain; charset=UTF-8"
        ;;
    markdown)
        WR_MAIL_CONTENT_TYPE="text/html; charset=UTF-8"
        MAIL_BODY="$(echo "$MAIL_BODY" | markdown)"
        ;;
    *)
        echo "Unsupported content type: $WR_CONTENT_TYPE" >&2
        exit 255
        ;;
esac

# Sending
sendmail -f "${WR_SENDER:?}" -F "${WR_SENDER_NAME:?}" -t "${send_to:?}" << EOF
MIME-Version: 1.0
To: ${send_to:?}
Cc: $cc_to
Bcc: $bcc_to
Subject: ${WR_SUBJECT:?}
Content-Type: ${WR_MAIL_CONTENT_TYPE:?}

${MAIL_BODY:?}


$WR_SIGNATURE
EOF

# Mark report as SENT
sed -E -i '' "s/${REGEX_BEGIN_FORCE:?}/${SENT_MARKER:?}/" "${MAIL_FILE:?}"

exit

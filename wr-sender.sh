#!/bin/bash

[[ $DEBUG -gt 0 ]] && set -x

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
    MAIL_FILE="$WR_REPO/$YEAR.txt"
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
WEEK=$(date '+%V') || xexit $?
YEAR=$(date '+%Y') || xexit $?

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

say -i "Weekly Report Sender started, week ${WEEK} of year $YEAR."

# WR_REPO
if [[ -z $WR_REPO ]]; then
    printf "Please set environment variable WR_REPO in your .bash_profile first.\n" >&2
    xexit 255
fi

# Config
if [[ ! -s $WR_REPO/wr-tool.conf ]]; then
    printf "Please config $WR_REPO/wr-tool.conf first.\n" >&2
    xexit 255
fi
source "$WR_REPO/wr-tool.conf" || xexit $?

# File
get_mail_file || xexit $?

# Test or non-test
if [[ $NO_TEST -eq 1 ]]; then
    WR_TEST_TO="${WR_TO:?}"
    WR_TEST_CC="$WR_CC"
    WR_TEST_BCC="$WR_BCC"
fi

# Regex
REGEX_BEGIN="^# W${WEEK:?}$" || xexit $?
REGEX_BEGIN_FORCE="^# W${WEEK:?}( SENT)*$" || xexit $?
REGEX_END="^# W[0-9]{1,2}$" || xexit $?
SENT_MARKER="# W${WEEK:?} SENT" || xexit $?

# Subject
WR_SUBJECT=${WR_SUBJECT/<YEAR>/$YEAR} || xexit $?
WR_SUBJECT=${WR_SUBJECT/<WEEK>/$WEEK} || xexit $?

# Body
MAIL_BODY="$(awk "/${REGEX_BEGIN_FORCE:?}/{flag=1;next}/${REGEX_END:?}/{flag=0}flag" "${MAIL_FILE:?}")" || xexit $?
if [[ -z $MAIL_BODY ]]; then
    printf "Not found report in $MAIL_FILE.\n" >&2
    xexit 255
fi
if [[ $FORCE -ne 1 ]]; then
    MAIL_BODY="$(awk "/${REGEX_BEGIN:?}/{flag=1;next}/${REGEX_END:?}/{flag=0}flag" "${MAIL_FILE:?}")" || xexit $?
fi
if [[ -z $MAIL_BODY ]]; then
    printf "Report was already sent.\n" >&2
    printf "Use -f to force send this report again.\n" >&2
    xexit 255
fi

# Sending
sendmail -f "${WR_SENDER:?}" -F "${WR_SENDER_NAME:?}" -t "${WR_TEST_TO:?}" << EOF || xexit $?
MIME-Version: 1.0
To: ${WR_TEST_TO:?}
Cc: $WR_TEST_CC
Bcc: $WR_TEST_BCC
Subject: ${WR_SUBJECT:?}
Content-Type: ${WR_CONTENT_TYPE:?}

${MAIL_BODY:?}


$WR_SIGNATURE
EOF

# Mark report as SENT
sed -E -i '' "s/${REGEX_BEGIN_FORCE:?}/${SENT_MARKER:?}/" "${MAIL_FILE:?}"

xexit $?

# weekreport-tool

A tool to send Weekly Report by Email.

Tested on Mac OS X 10.11.

## Dependencies

### macos-aws-ses

```
git clone https://github.com/alexzhangs/macos-aws-ses
sudo sh macos-aws-ses/install.sh
macos-aws-ses-setup -h
```

## Installation

```
git clone https://github.com/alexzhangs/weekreport-tool
sudo sh weekreport-tool/install.sh
```

## Configuration

1. Create a directory to store report files and config file.

    This example is using '~/Desktop/weekreport'

    ```
    mkdir ~/Desktop/weekreport
    ```

2. Copy config file.

    ```
    cp weekreport-tool/wr-tool-template.conf ~/Desktop/weekreport/wr-tool.conf
    ```

3. Open ~/Desktop/weekreport/wr-tool.conf to make change.

4. Setup an Environment Variable in your ~/.bash_profile.

    ```
    export WR_REPO=~/Desktop/weekreport
    ```

5. Create a report file.

    One report file one year.

    ```
    touch ~/Desktop/weekreport/$(date '+%Y').txt
    ```

6. Open report file to write your week report.

    ```
    # W30
    This is the weekly report of week 30.
    
    Each report is started from a WRS(Weekly Report Signature) from a
    new line, contains '# W' and followed by the <WEEK NUMBER> of the
    year.

    The week number must comply with ISO-8601, and this is not default
    setting in Mac OS X 10.11, you should change it in both System
    settings and Calendar settings on Mac.

    To get week number from command line:

    date '+%V' # ISO 8601 complied

    When you are done with this report, put a next WRS after the report.
    Then wr-sender knows that this report is ready to be sent.

    # W31
    ```

7. Make sure macos-aws-ses-setup run successfully.

8. Test sending report.

    ```
    wr-sender -w 30
    ```

    Check your Email configured in config file.

    After report is sent, wr-sender will mark this report is SENT, and
    prevent to send it again.

    Use -f to force to send a report again.

9. Send the report really, no test anymore.

    Use -n.

    ```
    wr-sender -n -w 30
    ```

    The more to see the Usage.

## Usage

```
wr-sender.sh
	[-n]
	[-f]
	[-w WEEK]
	[-y YEAR]
	[-h]

OPTIONS
	[-n]

	No test, sending report to the real recipients.

	[-f]

	Force to send even if the report was already marked as SENT.

	[-w WEEK]

	Week number of the year, default is current week.
	Using ISO 8601 calendar (Monday as the first day of the week) as a number (1-53).
	If the week containing January 1 has four or more days in the new year, then it is week 1;
	otherwise it is the last week of the previous year.

	[-y YEAR]

	Year with century as a number, default is current year.

	[-h]

	This help.
```

### Example

```
wr-sender.sh -w 31 -y 2016
```

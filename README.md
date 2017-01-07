# weekreport-tool

A tool to send Weekly Report by Email.

Tested on Mac OS X 10.11.

## Dependencies

### macos-aws-ses

```
git clone https://github.com/alexzhangs/macos-aws-ses
sudo sh macos-aws-ses/install.sh
```

See how to use:

```
macos-aws-ses-setup -h
```

### macos-postfix-autostart

Run below step after `macos-aws-ses` is configured.

```
git clone https://github.com/alexzhangs/macos-postfix-autostart
sudo sh macos-aws-ses/install.sh
sudo macos-postfix-autostart-setup.sh
```

### markdown

If you plan to use Markdown to write the report, then must install
`markdown` tool, which is used to automatically render Markdown
content to HTML before sending out.

If you plan to use plain text to write the report, skip this step.

Install `markdown` with `brew` on Mac.

```
brew install markdown # 1.0.1 here
```

If you don't get `brew` or any like that, jump to [markdown project home
page](http://daringfireball.net/projects/markdown/) to download &
install it by yourself.

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
    cp weekreport-tool/weekreport-template.conf ~/Desktop/weekreport/weekreport.conf
    ```

3. Open ~/Desktop/weekreport/weekreport.conf to make change.

4. Setup an Environment Variable in your ~/.bash_profile.

    ```
    export WR_REPO=~/Desktop/weekreport
    ```

5. Create a report file.

    One report file one year.

    In plain text, the file name extension must be `.txt`.

    ```
    touch ~/Desktop/weekreport/$(date '+%Y').txt
    ```

    Or in Markdown, the file name extension must be `.md`.

    ```
    touch ~/Desktop/weekreport/$(date '+%Y').md
    ```

6. Open report file to write your weekly report.

    In plain text:

    ```
    ## W30
    This is the weekly report of week 30.
    These 3 lines(including followed blank line) will be sent by Email.

    ## W31
    ```

    Or in Markdown:

    ```
    # Weekly Report of 2016

    ## W30

    This is the weekly report of week 30.

    This report is written in Markdown format and will be converted to
    HTML format before sending out.
    
    ### This week
    1. Item 1
    1. Item 2
    
    ### Next week
    1. Item 1
    1. Item 2

    ## W31
    ```

    Each report is started from a `WRS` (Weekly Report Signature) at a
    new line, contains `## W` and followed by the `<WEEK NUMBER>` of the
    year.

    The week number must comply with `ISO-8601`, and this is not default
    setting in Mac OS X 10.11, you should change it in both System
    settings and Calendar settings on Mac.

    To get week number from command line:

    ```
    date '+%V' # ISO 8601 complied
    ```

    When you are done with this report, put a next `WRS` after the report.
    So `wr-sender` knows that this report is ready to be sent.

7. Make sure macos-aws-ses-setup run successfully.

8. Test sending report.

    ```
    wr-sender -w 30
    ```

    Check your Email configured in config file.

    After report is sent, `wr-sender` will mark this report is SENT, and
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
	Using ISO 8601 calendar (Monday as the first day of the week) as a number (01-53).
	If the week containing January 1 has four or more days in the new year, then it is week 01;
	otherwise it is the last week of the previous year.

	[-y YEAR]

	Year with century as a number, default is current year.

	[-h]

	This help.
```

## Run as cron job

Send weekly report at 18:00 every Friday.

```
0 18 * * 5 . ~/.bash_profile; /usr/local/bin/wr-sender -n
```

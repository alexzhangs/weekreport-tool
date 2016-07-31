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

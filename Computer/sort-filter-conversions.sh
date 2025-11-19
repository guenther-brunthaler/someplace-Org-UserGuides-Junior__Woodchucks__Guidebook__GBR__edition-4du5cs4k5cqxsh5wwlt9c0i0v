#! /bin/sh
set -e
case $1 in
	title) echo 'Data Formats';;
	filename) echo 'Data Format Conversions.txt';;
	filter) LC_COLLATE=C sort -u;;
	*) false
esac

#! /bin/sh
# v2021.68

set -e

emit_sortline() {
	printf '%s %s %s\n' "$section" "$slnum" "$1"
	slnum=`expr $slnum + 1`
}

name2sortkey() {
	printf '%s\n' "$1" | awk '{print tolower($0)}' | od -vt x1 \
	| awk '
		{for (i= 2; i <= NF; ++i) if (length($i) == 2) o= o $i}
		END {print o}
	'
}

process_match() {
	section=`name2sortkey "$1"``printf '%08x' $gsnum`
	gsnum=`expr $gsnum + 1` # Global section number.
	slnum=1
}

sections2sortlines() {
	# Each section consists two empty lines, followed by a one-line
	# section title (which will be converted to lower case for sorting
	# comparisons), followed by a line containing only a run (at least 2)
	# of $1 characters, followed by another empty line, followed by the
	# optional section body until the next section starts.
	#
	# In other words, something like this:
	#
	# $1=EMPTY
	# $2=EMPTY
	# $3=NAME
	# $4=RUN
	# $5=EMPTY
	wcap=5; section=0; slnum=1; gsnum=1
	xrx=x"[$1]"'\{2,\}$'; shift
	# Slide all lines through the matching window.
	while IFS= read -r line
	do
		# Add new line to sliding window.
		case $# in
			$wcap) emit_sortline "$1"; shift
		esac
		set -- "$@" "$line"
		# Check for section match.
		case $1$2$5 in
			'')
				case $3 in
					'') ;;
					*)
						if expr x"$4" : "$xrx" >& 7
						then
							process_match "$3"
						fi
				esac
		esac
	done 7> /dev/null
	# Emit any lines left in the window.
	for line
	do
		emit_sortline "$line"
	done
}

sortlines2sections() {
	sed 's/^[^ ]\{1,\} [^ ]\{1,\} //'
}

sort_asciidoc_sections() {
	sections2sortlines "$1" \
	| LC_COLLATE=C LC_NUMERIC=C sort -t ' ' -k 1,1 -k 2,2n \
	| sortlines2sections
}

# Convert tabs to spaces, eliminate runs of more than one space, strip leading
# and trailing spaces.
norm_ws() {
	sed 's/[[:space:]]\{1,\}$/ /g; s/^ //; s/ $//'
}

flush_delayed() {
	case $delayed in
		0) return
	esac
	while :
	do
		echo
		delayed=`expr $delayed - 1` || break
	done
	:
}

# Eliminate all runs of more than two consecutive empty lines. Eliminate all
# leading or trailing empty lines.
squeeze_empties() {
	delayed=0; first=true
	while IFS= read -r line
	do
		case $line in
			'')
				case $delayed in
					2) ;;
					*) delayed=`expr $delayed + 1`
				esac
				;;
			*)
				case $first in
					true) first=false;;
					*) flush_delayed
				esac
				printf '%s\n' "$line"
		esac
	done
}

case $1 in
	title) echo 'Algorithms';;
	filename) echo 'Algorithm Reviews.adoc';;
	filter) norm_ws | squeeze_empties | sort_asciidoc_sections '-';;
	*) false
esac

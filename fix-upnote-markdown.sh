#!/bin/bash

# Usage: ./fix-upnote-markdown.sh input.md output.md

INPUT="$1"
OUTPUT="$2"

if [ -z "$INPUT" ] || [ -z "$OUTPUT" ]; then
  echo "Usage: $0 input.md output.md"
  exit 1
fi

# Convert Windows line endings to Unix
dos2unix "$INPUT" 2>/dev/null

# Separate YAML frontmatter from body
awk '
BEGIN { in_yaml=0 }
/^---$/ {
  print;
  in_yaml = !in_yaml;
  next;
}
{
  if (in_yaml) {
    print;
  } else {
    print "__BODY_LINE__" $0;
  }
}' "$INPUT" | \
perl -CSD -pe '
  # Only apply cleanup to body lines
  if (/^__BODY_LINE__/) {

    s/^__BODY_LINE__//;

    # Remove emojis and variation selectors
    s/[\x{1F300}-\x{1F6FF}\x{1F900}-\x{1F9FF}\x{2600}-\x{26FF}\x{2700}-\x{27BF}]/ /g;

    s/[\x{200B}-\x{200D}\x{2060}\x{FE0F}\x{00AD}]//g;

    # Remove <br> tags
    s/<br>//gi;

    # Remove UpNote highlight tags
    s/==([^=]+)==/$1/g;


    # Merge headings split across lines like:
    # ### 
    # ==Heading==
    if ($prev_line =~ /^###\s*$/ && /^==(.+?)==$/) {
      $_ = "### $1\n";
      $prev_line = "";
      next;
    }

    # Fix inline headings like ### ==Heading==
    s/^###\s+==(.+?)==/### $1/;

    # Remove stray "###" lines
    s/^###\s*$//;

    # Remove stray ==...==
    s/==(.+?)==/$1/g;

    # Fix numbered lists like ".1 " → "1. "
    s/^\.(\d+)\s/$1. /;

    # Remove wiki-style [[links]]
    s/\[\[([^\]]+)\]\]/$1/g;

    # Normalize bold wrappers before processing
    s/^\*\*(Encounter:.*?)\*\*$/$1/;
    s/^\*\*(Show image:.*?)\*\*$/$1/;

    # Match bolded or unbolded Encounter:
    if (/\*\*?Encounter:\*\*?\s*(.*)/ || /^Encounter:\s*(.*)/) {
      my $content = $1;
      $_ = "::: highlightencounterbox\n$content\n:::\n";
    }
    # Match bolded or unbolded Show image:
    elsif (/\*\*?Show image:\*\*?\s*(.*)/ || /^Show image:\s*(.*)/) {
      my $content = $1;
      $_ = "::: highlightshowimagebox\n$content\n:::\n";
    }

    # Remove lines that only contain formatting junk
    s/^(\s*[*_-]+\s*)$//;

    # Remove empty markdown headers like "#", "##", or "###" with optional spaces
    s/^\s*#{1,6}\s*$//;

  } else {
    s/^__BODY_LINE__//;
  }
' > "$OUTPUT.tmp"

# Collapse multiple blank lines into one (except after frontmatter)
awk '
BEGIN { blank=0 }
/^$/ {
  if (blank == 0) {
    print;
    blank = 1;
  }
  next;
}
{
  blank = 0;
  print;
}
' "$OUTPUT.tmp" > "$OUTPUT"

rm "$OUTPUT.tmp"
echo "✅ Cleanup complete: $OUTPUT"

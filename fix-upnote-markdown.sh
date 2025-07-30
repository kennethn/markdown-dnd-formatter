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

#########################################
# Step 1: Wrap Monster Blocks
#########################################
awk '
BEGIN {
  inside_monsters_section = 0;
  inside_block = 0;
}
{
  if ($0 ~ /^# Monsters$/) {
    inside_monsters_section = 1;
    print;
    next;
  }

  if (inside_monsters_section && $0 ~ /^# /) {
    if (inside_block) {
      print ":::";
      inside_block = 0;
    }
  }

  if (inside_monsters_section && $0 ~ /^# /) {
    print "::: {.monsterblock}";
    inside_block = 1;
  }

  print;
}
END {
  if (inside_block) print ":::";
}
' "$INPUT" > "$INPUT.tmp.monsters"

#########################################
# Step 2: Separate YAML Frontmatter
#########################################
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
}' "$INPUT.tmp.monsters" > "$INPUT.tmp.tagged"

#########################################
# Step 3: Perl Cleanup Transformations
#########################################
perl -CSD -pe '
BEGIN {
  our @table_rows = ();
  our $in_table = 0;
  our $inside_showimagebox = 0;
  our $prev_line = "";
}

if (/^__BODY_LINE__/) {
  s/^__BODY_LINE__//;

  if (/^\|.*\|$/) {
    $in_table = 1;
    push @table_rows, $_;
    $_ = "";
    next;
  }
  elsif ($in_table && /^\s*$/) {
    $in_table = 0;
    if (@table_rows >= 2) {
      my $header = shift @table_rows;
      my $divider = shift @table_rows;
      my @headers = split /\|/, $header;
      @headers = map { s/^\s+|\s+$//gr } @headers;         # Trim whitespace
      @headers = grep { $_ ne "" } @headers;               # Remove empties

      # Defensive fix: fallback if nothing is left
      @headers = ("~", "~") if scalar(@headers) < 1;
      @headers = map { $_ =~ /^\s*$/ ? "~" : $_ } @headers;
      my $cols = scalar(@headers);
      $_ = "\\begin{center}\n"
        . "{\\sffamily\\fontsize{8pt}{8pt}\\selectfont\n"
        . "\\rowcolors{2}{encountercolor}{white}\n"
        . "\\begin{tabular}{" . ("l" x $cols) . "}\n";

      $_ .= "\\toprule\n";
      for my $i (0 .. $#headers) {
        $headers[$i] =~ s/\*\*(.*?)\*\*/\\sffamily\\fontsize{8pt}{8pt}\\selectfont\\textbf{$1}/g;
        $headers[$i] =~ s/(\*|_)(.*?)\1/\\emph{$2}/g;
        $headers[$i] =~ s/(<br\s*\/?>)+/\\\\/gi;
        if ($headers[$i] =~ /\\\\/) {
          $headers[$i] = "\\shortstack[t]{" . $headers[$i] . "}";
        } else {
          $headers[$i] = "\\textbf{" . $headers[$i] . "}";
        }
      }
      $_ .= join(" & ", @headers) . " \\\\\n";

      $_ .= "\\midrule\n";
      foreach my $line (@table_rows) {
        my @cells = split /\s*\|\s*/, $line;
        @cells = grep { $_ ne "" } @cells;
        for my $i (0 .. $#cells) {
          $cells[$i] =~ s/\*\*(.*?)\*\*/\\textbf{$1}/g;
          $cells[$i] =~ s/(\*|_)(.*?)\1/\\emph{$2}/g;
          $cells[$i] =~ s/(<br\s*\/?>)+/\\\\ /gi;  # Convert <br> to LaTeX line break
        }

        $_ .= join(" & ", @cells) . " \\\\\n";
      }
      $_ .= "\\bottomrule\n\\end{tabular}}\n\\end{center}\n";
    }
    @table_rows = ();
  }
  elsif ($in_table) {
    push @table_rows, $_;
    $_ = "";
    next;
  }

  # General cleanup
  # Strip stray control characters (Unicode 0x00–0x1F except newline/tab)
  s/[\x00-\x08\x0B\x0C\x0E-\x1F]//g;
  #s/[\x{1F300}-\x{1F6FF}\x{1F900}-\x{1F9FF}\x{2600}-\x{26FF}\x{2700}-\x{27BF}]/ /g;
 s/([\x{1F300}-\x{1F6FF}\x{1F900}-\x{1F9FF}\x{1F1E6}-\x{1F1FF}\x{2600}-\x{26FF}\x{2700}-\x{27BF}\x{2B00}-\x{2BFF}])/
  "\\textnormal{\\emojifont\\char\"".sprintf("%X", ord($1))."}"
/ge;
  
  # Find H4 - #### and convert to subsubsubsection
  s{^#### (.+)$}{::: {.subsubsubsection}\n$1\n:::}gm;

  s/[\x{200B}-\x{200D}\x{2060}\x{FE0F}\x{00AD}]//g;

  unless ($in_table) {
    # If the line starts with > and contains <br>, split into multiple > lines
    if (/^>\s?.*<br\s*\/?>/i) {
      s/<br\s*\/?>/\n> /gi;
    } else {
      s/<br\s*\/?>//gi;
    }
  }

  s/==([^=]+)==/$1/g;

  # Remove the "# Monsters" H1 if it appears alone
  s/^# Monsters\s*\n/\\clearpage/mg;

  # Convert <br> after images to line break
  s{(!\[[^\]]*\]\([^)]+\))\n(?!\n)}{$1\n\n}g;

  # Heading cleanup
  if ($prev_line =~ /^###\s*$/ && /^==(.+?)==$/) {
    $_ = "### $1\n";
    $prev_line = "";
    next;
  }
  s/^###\s+==(.+?)==/### $1/;
  s/^###\s*$//;
  s/==(.+?)==/$1/g;

  # List fix
  s/^\.(\d+)\s/$1. /;

  # Wrap standalone negative numbers in texttt
  s{(?<![`0-9])\\?(-\d+)(?![\d`])}{"\\texttt{$1}"}ge;

  # Fix number ranges like "5--6" or "5 - 6"
  s/(\d)\s*--\s*(\d)/$1-$2/g;
  s/(\d)\s*-\s*(\d)/$1--$2/g;

  # Encounter, image, and remember boxes
  s/^\*\*(Encounter:.*?)\*\*$/$1/;
  s/^\*\*(Image:.*?)\*\*$/$1/;
  s/^\*\*(Remember:.*?)\*\*$/$1/;

  if (/\*\*?Encounter:\*\*?\s*(.*)/ || /^Encounter:\s*(.*)/) {
    my $content = $1;
    $_ = "::: highlightencounterbox\n$content\n:::\n";
    $prev_line = "";
    next;
  }
  elsif (/\*\*?Show image:\*\*?\s*(.*)/ || /^Image:\s*(.*)/) {
    my $content = $1;
    $content =~ s/\[\[([^\]]+)\]\]/$1/g;  # Remove [[...]] in title
    $_ = "::: highlightshowimagebox\n$content\n:::\n";
    $prev_line = "";
    next;
  }
  elsif (/\*\*?Show image:\*\*?\s*(.*)/ || /^Remember:\s*(.*)/) {
    my $content = $1;
    $content =~ s/\[\[([^\]]+)\]\]/$1/g;  # Remove [[...]] in title
    $_ = "::: rememberbox\n$content\n:::\n";
    $prev_line = "";
    next;
  }

  # Track when inside highlightshowimagebox
  if (/^:::\s*highlightshowimagebox\b/) {
    $inside_showimagebox = 1;
  }
  elsif (/^:::\s*$/ && $inside_showimagebox) {
    $inside_showimagebox = 0;
  }

  # Apply wikilink span only if not in showimagebox
  if ($inside_showimagebox) {
    s/\[\[([^\]]+)\]\]/$1/g;
  } else {
    s/\[\[([^\]]+)\]\]/<span class="wikilink">$1<\/span>/g;
  }

  s/^(\s*[*_-]+\s*)$//;
  s/^\s*#{1,6}\s*$//;

  $prev_line = $_;
} else {
  s/^__BODY_LINE__//;
}
' "$INPUT.tmp.tagged" > "$OUTPUT.tmp"

#########################################
# Step 4: Collapse Multiple Blank Lines
#########################################
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

rm "$INPUT.tmp.monsters" "$INPUT.tmp.tagged" "$OUTPUT.tmp"
echo "✅ Cleanup complete: $OUTPUT"

# #########################################
# # Step 5: Promote first H1 to YAML frontmatter - TODO
# #########################################

# # Extract first H1 from body and remove it
# doc_title=$(grep -m 1 '^# ' "$OUTPUT" | sed 's/^# //')
# if [ -n "$doc_title" ]; then
#   awk -v title="$doc_title" '
#     BEGIN { print "---\ntitle: \"" title "\"\n---" }
#     {
#       if (!found && /^# /) {
#         found = 1
#         next
#       }
#       print
#     }
#   ' "$OUTPUT" > "$OUTPUT.withtitle"
#   mv "$OUTPUT.withtitle" "$OUTPUT"
# fi

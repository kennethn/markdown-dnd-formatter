#!/usr/bin/perl
# transform-content.pl - Content transformation for D&D markdown preprocessing
# Usage: perl -CSD scripts/lib/transform-content.pl input.md > output.md

use utf8;
use strict;
use warnings;
use JSON::PP;
use File::Basename;

binmode(STDIN, ":encoding(UTF-8)");
binmode(STDOUT, ":encoding(UTF-8)");

# =========================
# Load callout config
# =========================

my $script_dir = dirname($0);
my $config_path = "$script_dir/../../config/transform-config.json";

my $config;
{
    open my $fh, '<:encoding(UTF-8)', $config_path
        or die "Cannot open config $config_path: $!\n";
    local $/;
    $config = decode_json(<$fh>);
    close $fh;
}

# Build callout patterns from config
my @callout_types;
for my $ct (@{$config->{callout_types}}) {
    my @patterns;

    # Text trigger patterns (bold/italic-wrapped and plain)
    for my $trigger (@{$ct->{text_triggers}}) {
        my $escaped = quotemeta($trigger);
        push @patterns, qr/\*\*?$escaped\*\*?\s*(.*)/;
        push @patterns, qr/^$escaped\s*(.*)/;
    }

    # Emoji trigger patterns
    for my $cp (@{$ct->{emoji_codepoints}}) {
        my $chr_val = chr(hex($cp));
        my $emoji_re = qr/$chr_val(?:\x{FE0F})?/;
        push @patterns, qr/\*\*?$emoji_re\s*(.*)/;
        push @patterns, qr/^$emoji_re\s*(.*)/;
    }

    # Obsidian callout pattern
    if ($ct->{obsidian_tag}) {
        my $tag = quotemeta($ct->{obsidian_tag});
        push @patterns, qr/^\s*>\s*\[\\?!$tag\]\s*(.*)/;
    }

    push @callout_types, {
        div_class       => $ct->{div_class},
        patterns        => \@patterns,
        strip_wikilinks => $ct->{strip_wikilinks} ? 1 : 0,
        text_triggers   => $ct->{text_triggers},
    };
}

# =========================
# State variables
# =========================

our @table_rows = ();
our $in_table = 0;
our $inside_showimagebox = 0;
our $prev_line = "";

# =========================
# Main processing loop
# =========================

while (<>) {

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
        . "{\\selectfont\\monsterFont\n"
        . "\\rowcolors{2}{highlightcolor}{white}\n"
        . "\\begin{tabular}{" . ("l" x $cols) . "}\n";

      $_ .= "\\rowcolor{tableheadercolor}\n";
      for my $i (0 .. $#headers) {
        $headers[$i] =~ s/&/\\&/g;  # Escape ampersands
        $headers[$i] =~ s/\*\*(.*?)\*\*/\\selectfont\\monsterFont\\textbf{$1}/g;
        $headers[$i] =~ s/(\*|_)(.*?)\1/\\emph{$2}/g;
        $headers[$i] =~ s/(<br\s*\/?>)+/\\\\/gi;
        if ($headers[$i] =~ /\\\\/) {
          $headers[$i] = "\\shortstack[t]{" . $headers[$i] . "}";
        } else {
          $headers[$i] = "\\textcolor{white}{\\textbf{" . $headers[$i] . "}}";
        }
      }
      $_ .= join(" & ", @headers) . " \\\\\n";

      foreach my $line (@table_rows) {
        my @cells = split /\s*\|\s*/, $line;
        @cells = grep { $_ ne "" } @cells;
        for my $i (0 .. $#cells) {
          $cells[$i] =~ s/&/\\&/g;  # Escape ampersands
          $cells[$i] =~ s/\*\*(.*?)\*\*/\\textbf{$1}/g;
          $cells[$i] =~ s/(\*|_)(.*?)\1/\\emph{$2}/g;
          $cells[$i] =~ s/(<br\s*\/?>)+/\\\\ /gi;  # Convert <br> to LaTeX line break
        }

        $_ .= join(" & ", @cells) . " \\\\\n";
      }
      $_ .= "\\arrayrulecolor{black}\\bottomrule\n\\end{tabular}}\n\\end{center}\n\n";
    }
    @table_rows = ();
  }
  elsif ($in_table) {
    push @table_rows, $_;
    $_ = "";
    next;
  }

  # Find H4 - #### and convert to subsubsubsection (commented in original)
  # s{^#### (.+)$}{::: {.subsubsubsection}\n$1\n:::}gm;

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
  s/^# Monsters\s*\n/\\cleardoublepage/mg;

  # Convert <br> after images to line break
  s{(!\[[^\]]*\]\([^)]+\))\n(?!\n)}{\n$1\n\n}g;

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

  # Preserve negative numbers but don't wrap in texttt (per user preference)
  s{(?<![`0-9])\\?(-\d+)(?![\d`])}{$1}ge;

  # Fix en and em dashes to markdown
  s/(\d)\s*\x{2014}\s*(\d)/$1---$2/g;
  s/(\d)\s*\x{2013}\s*(\d)/$1--$2/g;

  # Strip bold wrapping from callout triggers (config-driven)
  for my $ct (@callout_types) {
    for my $trigger (@{$ct->{text_triggers}}) {
      my $escaped = quotemeta($trigger);
      s/^\*\*($escaped.*)\*\*/$1/;
    }
  }

  # Match callout patterns (config-driven)
  my $matched_callout = 0;
  CALLOUT: for my $ct (@callout_types) {
    for my $pattern (@{$ct->{patterns}}) {
      if (/$pattern/) {
        my $content = $1;
        if ($ct->{strip_wikilinks}) {
          $content =~ s/\[\[([^\]]+)\]\]/$1/g;
        }
        $_ = "::: $ct->{div_class}\n$content\n:::\n";
        $prev_line = "";
        $matched_callout = 1;
        last CALLOUT;
      }
    }
  }
  next if $matched_callout;

  # Track when inside highlightshowimagebox
  if (/^:::\s*highlightshowimagebox\b/) {
    $inside_showimagebox = 1;
  }
  elsif (/^:::\s*$/ && $inside_showimagebox) {
    $inside_showimagebox = 0;
  }

  # Apply wikilink span only if not in showimagebox
  if ($inside_showimagebox) {
    s/\[\[([^\]]+)\]\]/
      my $content = $1;
      $content =~ m!\|(.+)$! ? $1 : $content/gex;
  } else {
    s/\[\[([^\]]+)\]\]/
      my $content = $1;
      my $display_text = $content =~ m!\|(.+)$! ? $1 : $content;
      "\\textcolor{sectioncolor}{\\uline{" . ($display_text =~ s!&!\\&!gr) . "}}"/gex;
  }

  # Convert markdown links [text](url) to bold text (like wikilinks)
  unless ($inside_showimagebox) {
    s/\[([^\]]+)\]\([^)]+\)/"\\textcolor{sectioncolor}{\\uline{" . ($1 =~ s!&!\\&!gr) . "}}"/ge;
  }

  s/^(\s*[*_-]+\s*)$//;
  s/^\s*#{1,6}\s*$//;

  # Convert inline code (backtick-enclosed text) to monospace font
  s/`([^`]+)`/\\texttt{$1}/g;
  # Strip any remaining backticks (unpaired or from code fences)
  s/`//g;

  # General cleanup
  # Strip stray control characters (Unicode 0x00-0x1F except newline/tab)
  s/[\x00-\x08\x0B\x0C\x0E-\x1F]//g;
  # Convert ALL emojis to LaTeX format with \emojifont
  s/([\x{2300}-\x{23FF}\x{2600}-\x{26FF}\x{2700}-\x{27BF}\x{2B00}-\x{2BFF}\x{1F1E6}-\x{1F1FF}\x{1F300}-\x{1F6FF}\x{1F7E0}-\x{1F7FF}\x{1F900}-\x{1F9FF}\x{1FA70}-\x{1FAFF}])/
  "\\textnormal{\\emojifont\\char\"".sprintf("%X", ord($1))."}"/uge;

  s/[\x{2003}]/\\hspace*{1.5em}/g; # em space

  $prev_line = $_;
} else {
  s/^__BODY_LINE__//;
}

} continue {
  print;
}

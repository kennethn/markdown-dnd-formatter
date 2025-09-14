#!/usr/bin/env perl
# content-transformer.pl - Perl-based content transformations

use strict;
use warnings;
use utf8;
use Encode;

binmode(STDIN, ":encoding(UTF-8)");
binmode(STDOUT, ":encoding(UTF-8)");

# Global state variables
our @table_rows = ();
our $in_table = 0;
our $inside_showimagebox = 0;
our $prev_line = "";

# Load configuration
my $config = load_config();

# Main processing loop
while (my $line = <STDIN>) {
    chomp $line;
    $line = process_line($line, $config);
    print "$line\n" if defined $line;
}

# =========================
# Configuration Management
# =========================

sub load_config {
    return {
        # Unicode patterns for callout boxes
        crossed_swords => qr/\x{2694}(?:\x{FE0F})?/,
        picture_frame => qr/\x{1F5BC}\x{FE0F}?/,
        warning_sign => qr/\x{26A0}(?:\x{FE0F})?/,
        music_note => qr/\x{1F3B5}(?:\x{FE0F})?/,
        
        # Processing flags
        debug => $ENV{DEBUG_TRANSFORM} // 0,
    };
}

# =========================
# Line Processing
# =========================

sub process_line {
    my ($line, $config) = @_;
    
    # Skip non-body lines (YAML frontmatter)
    return $line unless $line =~ s/^__BODY_LINE__//;
    
    # Process different content types
    $line = process_tables($line);
    return undef if !defined $line;  # Skip if consumed by table processing
    
    $line = process_unicode_cleanup($line);
    $line = process_callout_boxes($line, $config);
    return undef if !defined $line;  # Skip if converted to callout box
    
    $line = process_wiki_links($line);
    $line = process_text_formatting($line);
    $line = process_general_cleanup($line);
    
    $prev_line = $line;
    return $line;
}

# =========================
# Table Processing
# =========================

sub process_tables {
    my ($line) = @_;
    
    # Start of table
    if ($line =~ /^\|.*\|$/) {
        $in_table = 1;
        push @table_rows, $line;
        return undef;  # Consume line
    }
    
    # End of table (blank line)
    if ($in_table && $line =~ /^\s*$/) {
        $in_table = 0;
        my $table_latex = generate_table_latex(\@table_rows);
        @table_rows = ();
        return $table_latex;
    }
    
    # Continue table
    if ($in_table) {
        push @table_rows, $line;
        return undef;  # Consume line
    }
    
    return $line;
}

sub generate_table_latex {
    my ($rows_ref) = @_;
    my @rows = @$rows_ref;
    
    return "" if @rows < 2;
    
    my $header = shift @rows;
    my $divider = shift @rows;  # Skip divider row
    
    # Parse headers
    my @headers = split /\|/, $header;
    @headers = map { s/^\s+|\s+$//gr } @headers;  # Trim
    @headers = grep { $_ ne "" } @headers;        # Remove empties
    
    # Defensive fallback
    @headers = ("~", "~") if @headers < 1;
    @headers = map { $_ =~ /^\s*$/ ? "~" : $_ } @headers;
    
    my $cols = scalar(@headers);
    my $latex = "\\begin{center}\n" .
                "{\\selectfont\\monsterFont\n" .
                "\\rowcolors{2}{highlightcolor}{white}\n" .
                "\\begin{tabular}{" . ("l" x $cols) . "}\n";
    
    # Process header row
    $latex .= "\\rowcolor{tableheadercolor}\n";
    for my $i (0 .. $#headers) {
        $headers[$i] = format_table_cell($headers[$i], 1);  # is_header = 1
    }
    $latex .= join(" & ", @headers) . " \\\\\n";
    
    # Process data rows
    for my $row (@rows) {
        my @cells = split /\s*\|\s*/, $row;
        @cells = grep { $_ ne "" } @cells;
        
        for my $i (0 .. $#cells) {
            $cells[$i] = format_table_cell($cells[$i], 0);  # is_header = 0
        }
        
        $latex .= join(" & ", @cells) . " \\\\\n";
    }
    
    $latex .= "\\arrayrulecolor{black}\\bottomrule\n" .
              "\\end{tabular}}\n\\end{center}\n";
    
    return $latex;
}

sub format_table_cell {
    my ($cell, $is_header) = @_;
    
    # Escape LaTeX special characters
    $cell =~ s/&/\\&/g;  # Escape ampersands
    
    # Basic markdown formatting
    $cell =~ s/\*\*(.*?)\*\*/\\textbf{$1}/g;
    $cell =~ s/(\*|_)(.*?)\1/\\emph{$2}/g;
    $cell =~ s/(<br\s*\/?>)+/\\\\ /gi;
    
    if ($is_header) {
        if ($cell =~ /\\\\/) {
            $cell = "\\shortstack[t]{$cell}";
        } else {
            $cell = "\\textcolor{white}{\\textbf{$cell}}";
        }
    }
    
    return $cell;
}

# =========================
# Callout Box Processing
# =========================

sub process_callout_boxes {
    my ($line, $config) = @_;
    
    my $crossed_swords = $config->{crossed_swords};
    my $picture_frame = $config->{picture_frame};
    my $warning_sign = $config->{warning_sign};
    my $music_note = $config->{music_note};
    
    # Clean up bold markers
    $line =~ s/^\*\*(Encounter:.*?)\*\*$/$1/;
    $line =~ s/^\*\*(Image:.*?)\*\*$/$1/;
    $line =~ s/^\*\*(Show image:.*?)\*\*$/$1/;
    $line =~ s/^\*\*(Remember:.*?)\*\*$/$1/;
    
    # Encounter boxes
    if ($line =~ /\*\*?Encounter:\*\*?\s*(.*)/ || 
        $line =~ /^Encounter:\s*(.*)/ || 
        $line =~ /\*\*?$crossed_swords\s*(.*)/ || 
        $line =~ /^$crossed_swords\s*(.*)/) {
        my $content = $1;
        $prev_line = "";
        return "::: highlightencounterbox\n$content\n:::\n";
    }
    
    # Image boxes
    if ($line =~ /^Show image:\s*(.*)/ || 
        $line =~ /^Image:\s*(.*)/ || 
        $line =~ /\*\*?$picture_frame\s*(.*)/ || 
        $line =~ /^$picture_frame\s*(.*)/) {
        my $content = $1;
        $content =~ s/\[\[([^\]]+)\]\]/$1/g;  # Remove wiki links
        $prev_line = "";
        return "::: highlightshowimagebox\n$content\n:::\n";
    }
    
    # Remember boxes
    if ($line =~ /^Remember:\s*(.*)/ || 
        $line =~ /\*\*?$warning_sign\s*(.*)/ || 
        $line =~ /^$warning_sign\s*(.*)/) {
        my $content = $1;
        $content =~ s/\[\[([^\]]+)\]\]/$1/g;
        $prev_line = "";
        return "::: rememberbox\n$content\n:::\n";
    }
    
    # Music boxes
    if ($line =~ /^Music:\s*(.*)/ || 
        $line =~ /\*\*?$music_note\s*(.*)/ || 
        $line =~ /^$music_note\s*(.*)/) {
        my $content = $1;
        $content =~ s/\[\[([^\]]+)\]\]/$1/g;
        $prev_line = "";
        return "::: musicbox\n$content\n:::\n";
    }
    
    return $line;
}

# =========================
# Wiki Link Processing
# =========================

sub process_wiki_links {
    my ($line) = @_;
    
    # Track when inside show image box
    if ($line =~ /^:::\s*highlightshowimagebox\b/) {
        $inside_showimagebox = 1;
    } elsif ($line =~ /^:::\s*$/ && $inside_showimagebox) {
        $inside_showimagebox = 0;
    }
    
    # Process wiki links differently based on context
    if ($inside_showimagebox) {
        $line =~ s/\[\[([^\]]+)\]\]/$1/g;  # Remove brackets
    } else {
        $line =~ s/\[\[([^\]]+)\]\]/\\textcolor{sectioncolor}{\\textbf{$1}}/g;
    }
    
    return $line;
}

# =========================
# Text Formatting
# =========================

sub process_text_formatting {
    my ($line) = @_;
    
    # Remove highlight markers
    $line =~ s/==([^=]+)==/$1/g;
    
    # Handle line breaks
    unless ($in_table) {
        if ($line =~ /^>\s?.*<br\s*\/?>/i) {
            $line =~ s/<br\s*\/?>/\n> /gi;
        } else {
            $line =~ s/<br\s*\/?>//gi;
        }
    }
    
    # Heading cleanup
    if ($prev_line =~ /^###\s*$/ && $line =~ /^==(.+?)==$/) {
        $prev_line = "";
        return "### $1";
    }
    $line =~ s/^###\s+==(.+?)==/### $1/;
    $line =~ s/^###\s*$//;
    
    # List formatting
    $line =~ s/^\.(\d+)\s/$1. /;
    
    # Wrap standalone negative numbers
    $line =~ s{(?<![`0-9])\\?(-\d+)(?![\d`])}{"\\texttt{$1}"}ge;
    
    # Fix dashes
    $line =~ s/(\d)\s*—\s*(\d)/$1---$2/g;
    $line =~ s/(\d)\s*–\s*(\d)/$1--$2/g;
    
    return $line;
}

# =========================
# General Cleanup
# =========================

sub process_unicode_cleanup {
    my ($line) = @_;
    
    # Remove zero-width characters
    $line =~ s/[\x{200B}-\x{200D}\x{2060}\x{FE0F}\x{00AD}]//g;
    
    # Convert emojis to LaTeX
    $line =~ s/([\x{2300}-\x{23FF}\x{2600}-\x{26FF}\x{2700}-\x{27BF}\x{2B00}-\x{2BFF}\x{1F1E6}-\x{1F1FF}\x{1F300}-\x{1F6FF}\x{1F900}-\x{1F9FF}\x{1FA70}-\x{1FAFF}])/
        "\\textnormal{\\emojifont\\char\"".sprintf("%X", ord($1))."}"/uge;
    
    # Handle special spaces
    $line =~ s/[\x{2003}]/\\hspace*{1.5em}/g;  # em space
    
    return $line;
}

sub process_general_cleanup {
    my ($line) = @_;
    
    # Remove monster section headers
    $line =~ s/^# Monsters\s*\n/\\\cleardoublepage/mg;
    
    # Image line break handling
    $line =~ s{(!\[[^\]]*\]\([^)]+\))\n(?!\n)}{\n$1\n\n}g;
    
    # Remove empty formatting lines
    $line =~ s/^(\s*[*_-]+\s*)$//;
    $line =~ s/^\s*#{1,6}\s*$//;
    
    # Strip control characters (except newline/tab)
    $line =~ s/[\x00-\x08\x0B\x0C\x0E-\x1F]//g;
    
    return $line;
}
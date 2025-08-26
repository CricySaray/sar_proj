#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;

# Default configuration
my $start_pattern = qr/# ---------/;      # Default start pattern (partial match)
my $end_pattern   = undef;                # Default no end pattern
my $keyword       = '';                    # Keyword for filtering
my $invert        = 0;                     # Invert match (show non-matching)
my $case_insensitive = 0;                  # Case insensitive matching
my $min_lines     = 0;                     # Minimum lines in chunk
my $max_lines     = 0;                     # Maximum lines in chunk
my $debug         = 0;                     # Debug mode flag
my $help          = 0;                     # Help flag
my $man           = 0;                     # Manual flag

# Parse command line options
GetOptions(
  'start=s'           => \$start_pattern,
  'end:s'             => \$end_pattern,    # : means optional value
  'keyword=s'         => \$keyword,
  'invert'            => \$invert,
  'case-insensitive'  => \$case_insensitive,
  'min-lines=i'       => \$min_lines,
  'max-lines=i'       => \$max_lines,
  'debug'             => \$debug,
  'help'              => \$help,
  'man'               => \$man,
) or pod2usage(2);

pod2usage(1) if $help;
pod2usage(-verbose => 2) if $man;

# Validate input file
my $file = $ARGV[0];
pod2usage("Please specify an input file") unless $file && -e $file;

# Compile regex patterns with possible case insensitivity
my $regex_flags = $case_insensitive ? '(?i)' : '';
$start_pattern = qr/$regex_flags$start_pattern/;
$end_pattern   = qr/$regex_flags$end_pattern/ if defined $end_pattern && $end_pattern ne '';

debug("Using start pattern: $start_pattern");
debug("Using end pattern: " . (defined $end_pattern ? $end_pattern : 'none'));
debug("Case insensitive mode: " . ($case_insensitive ? 'on' : 'off'));

# Read and process the file
my @chunks = parse_chunks($file);
debug("Successfully parsed " . scalar(@chunks) . " total chunks");

my @filtered_chunks = filter_chunks(\@chunks);
debug("Filtered down to " . scalar(@filtered_chunks) . " chunks");

# Output results
print_chunks(\@filtered_chunks);

# Parse the file into chunks based on patterns
sub parse_chunks {
  my ($file) = @_;
  my @chunks;
  my $current_chunk = [];
  my $in_chunk = 0;
  my $line_number = 0;

  open(my $fh, '<', $file) or die "Cannot open file $file: $!";
  
  while (my $line = <$fh>) {
    $line_number++;
    chomp $line;
    my $original_line = $line;  # Preserve original for debug
    
    # Check for start pattern (partial match)
    if ($line =~ $start_pattern) {
      debug("Line $line_number: Found start pattern");
      
      # If we're already in a chunk, finalize it
      if ($in_chunk) {
        debug("Line $line_number: Finalizing previous chunk (new start found)");
        push @chunks, $current_chunk;
      }
      
      # Start new chunk
      $current_chunk = [$original_line];
      $in_chunk = 1;
      debug("Line $line_number: Started new chunk");
    }
    # Check for end pattern if we're in a chunk and end pattern is defined
    elsif ($in_chunk && defined $end_pattern && $line =~ $end_pattern) {
      debug("Line $line_number: Found end pattern");
      push @$current_chunk, $original_line;
      push @chunks, $current_chunk;
      $current_chunk = [];
      $in_chunk = 0;
      debug("Line $line_number: Ended current chunk");
    }
    # Add line to current chunk if we're in one
    elsif ($in_chunk) {
      push @$current_chunk, $original_line;
      debug("Line $line_number: Added to current chunk");
    }
    else {
      debug("Line $line_number: Not part of any chunk");
    }
  }
  
  close $fh;
  
  # Add the last chunk if we're still in one
  if ($in_chunk && @$current_chunk) {
    debug("End of file: Adding final chunk");
    push @chunks, $current_chunk;
  }
  
  return @chunks;
}

# Filter chunks based on criteria
sub filter_chunks {
  my ($chunks_ref) = @_;
  my @filtered;
  
  foreach my $i (0 .. $#$chunks_ref) {
    my $chunk = $chunks_ref->[$i];
    my $include = 1;
    my $chunk_text = join("\n", @$chunk);
    my $chunk_size = scalar @$chunk;
    
    debug("\nChecking chunk " . ($i + 1) . " (size: $chunk_size lines)");
    
    # Keyword filter
    if ($keyword) {
      my $keyword_re = $case_insensitive ? qr/$keyword/i : qr/$keyword/;
      my $has_keyword = $chunk_text =~ $keyword_re;
      $include = $invert ? !$has_keyword : $has_keyword;
      
      debug("Keyword check: " . ($has_keyword ? "found" : "not found") . 
            " '$keyword'" . ($invert ? " (inverted)" : ""));
    }
    
    # Minimum lines filter
    if ($include && $min_lines > 0) {
      $include = $chunk_size >= $min_lines ? 1 : 0;
      debug("Min lines check ($min_lines): " . ($include ? "passed" : "failed"));
    }
    
    # Maximum lines filter
    if ($include && $max_lines > 0) {
      $include = $chunk_size <= $max_lines ? 1 : 0;
      debug("Max lines check ($max_lines): " . ($include ? "passed" : "failed"));
    }
    
    if ($include) {
      push @filtered, $chunk;
      debug("Chunk " . ($i + 1) . " included");
    } else {
      debug("Chunk " . ($i + 1) . " excluded");
    }
  }
  
  return @filtered;
}

# Print the chunks with separators
sub print_chunks {
  my ($chunks_ref) = @_;
  my $chunk_num = 1;
  
  foreach my $chunk (@$chunks_ref) {
    print "=== Chunk $chunk_num ===\n";
    print join("\n", @$chunk), "\n\n";
    $chunk_num++;
  }
  
  print "Total chunks: ", scalar @$chunks_ref, "\n";
}

# Debug printing function
sub debug {
  my ($message) = @_;
  print "DEBUG: $message\n" if $debug;
}

__END__

=head1 NAME

report_chunker.pl - Split report-style files into chunks and filter them

=head1 SYNOPSIS

report_chunker.pl [options] input_file

 Options:
   --start=PATTERN      Pattern defining chunk start (default: # ---------)
   --end=PATTERN        Pattern defining chunk end (optional)
   --keyword=WORD       Filter chunks containing this keyword
   --invert             Invert the match (show non-matching chunks)
   --case-insensitive   Case insensitive matching
   --min-lines=N        Minimum number of lines in chunk
   --max-lines=N        Maximum number of lines in chunk
   --debug              Show debug information
   --help               Show this help message
   --man                Show full documentation

=head1 DESCRIPTION

This script splits report-style files into logical chunks based on start and end patterns.
It can then filter these chunks based on various criteria. Patterns are matched partially
by default (any part of the line matching the pattern will work). If no end pattern is
specified, chunks end when a new start pattern is found.

=cut


#!/usr/bin/perl
# --------------------------
# author    : sar song
# date      : 2025/09/20 23:30:04 Saturday
# label     : format_sub
#   tcl  -> (atomic_proc|display_proc|gui_proc|task_proc|dump_proc|check_proc|math_proc|package_proc|test_proc|datatype_proc|db_proc|flow_proc|report_proc|cross_lang_proc|misc_proc)
#   perl -> (format_sub|getInfo_sub|perl_task)
# descrip   : The build_level subroutine recursively constructs a level of the tree structure starting from the highest indentation level, processing a node and its children to form a complete subtree.
# return    : print tree
# usage     : The input file should contain lines with indentation using only 2 or 4 spaces (as multiples of these), may include empty lines (which are ignored), and each 
#             non-empty line's content will be treated as a node, with indentation levels determining hierarchical relationships.
# ref       : link url
# --------------------------
use strict;
use warnings;

# Global debug flag
my $DEBUG = 0;

# Main program
sub main {
  # Check command line arguments
  my ($input_file) = @ARGV;
  if (!defined $input_file || $input_file eq '--debug') {
    $DEBUG = 1 if defined $input_file && $input_file eq '--debug';
    $input_file = $ARGV[1] if $DEBUG && @ARGV > 1;
  }
  die "Usage: $0 [--debug] <input_file>\n" unless defined $input_file && -f $input_file;
  
  my $filename = (split '/', $input_file)[-1];
  print "Debug: Processing file - $filename\n" if $DEBUG;
  
  # Read and process file content
  open my $fh, '<', $input_file or die "Cannot open $input_file: $!";
  my @lines = <$fh>;
  close $fh;
  
  # Build tree structure
  my $tree = build_tree(\@lines, $filename);
  
  # Print the final tree
  print join("\n", @$tree);
  print "\n";
}

# Main tree building function
sub build_tree {
  my ($lines_ref, $root_name) = @_;
  my @all_lines = @$lines_ref;
  
  # Preprocess: extract indent and content, skip empty lines
  my @processed;
  foreach my $line (@all_lines) {
    chomp $line;
    next if $line =~ /^\s*$/;  # Skip empty lines
    
    my ($indent, $content) = $line =~ /^(\s*)(.*)$/;
    push @processed, {
      indent => length($indent),
      content => $content,
      level => 0,  # To be calculated
      index => scalar @processed,  # Original index in processed array
      children => []  # Will store child indices
    };
  }
  
  print "Debug: Found " . scalar(@processed) . " non-empty lines\n" if $DEBUG;
  return [$root_name] unless @processed;  # Only root if no content
  
  # Determine indent width (2 or 4)
  my $indent_width = determine_indent_width(\@processed);
  die "Invalid indentation - must use 2 or 4 space increments\n" unless defined $indent_width;
  print "Debug: Determined indent width - $indent_width\n" if $DEBUG;
  
  # Calculate levels for all lines
  foreach my $line (@processed) {
    $line->{level} = int($line->{indent} / $indent_width);
    die "Invalid indent for line '$line->{content}' (not multiple of $indent_width)\n"
      if $line->{indent} % $indent_width != 0;
  }
  
  # Find minimum and maximum levels
  my @levels = map { $_->{level} } @processed;
  my $min_level = (sort { $a <=> $b } @levels)[0];
  my $max_level = (sort { $b <=> $a } @levels)[0];
  print "Debug: Level range - $min_level to $max_level\n" if $DEBUG;
  
  # Identify parent-child relationships (children stored in parent's children array)
  foreach my $i (0 .. $#processed) {
    my $line = $processed[$i];
    my $target_level = $line->{level} - 1;
    
    # Find nearest parent (previous line with level = target_level)
    for (my $j = $i - 1; $j >= 0; $j--) {
      if ($processed[$j]->{level} == $target_level) {
        push @{$processed[$j]->{children}}, $i;
        last;
      }
    }
  }
  
  # Split into small trees based on minimum level
  my @small_tree_roots = map { $_->{index}  } 
                        grep { $_->{level} == $min_level  } @processed;
  my @small_trees;
  
  foreach my $root_idx (@small_tree_roots) {
    # Build each small tree from bottom up
    my $tree_output = build_level(\@processed, $root_idx, $max_level, $min_level);
    push @small_trees, $tree_output;
  }
  
  print "Debug: Total small trees created - " . scalar(@small_trees) . "\n" if $DEBUG;
  
  # Combine small trees under root (filename)
  my @final_tree = ($root_name);
  my $total_small_trees = scalar @small_trees;
  print "Debug: Combining $total_small_trees small trees under root\n" if $DEBUG;
  
  for (my $i = 0; $i < $total_small_trees; $i++) {
    my $is_last = ($i == $total_small_trees - 1) ? 1 : 0;
    my $small_tree = $small_trees[$i];
    
    # Add root of small tree with proper connection to main root
    my $small_root = shift @$small_tree;
    my $root_prefix = $is_last ? '└── ' : '├── ';
    push @final_tree, $root_prefix . $small_root;
    print "Debug: Added small tree root - $small_root (last: " . ($is_last ? "yes" : "no") . ")\n" if $DEBUG;
    
    # Add remaining lines of small tree with adjusted prefixes
    my $child_prefix = $is_last ? '    ' : '│   ';
    foreach my $line (@$small_tree) {
      push @final_tree, $child_prefix . $line;
    }
  }
  
  return \@final_tree;
}

# Recursive subroutine to build a level of the tree, starting from highest level
sub build_level {
  my ($processed, $node_idx, $current_level, $min_level) = @_;
  my $node = $processed->[$node_idx];
  
  # If we're at the highest level, return just this node
  if ($node->{level} == $current_level) {
    return [ $node->{content} ];
  }
  
  # Otherwise, process children first (bottom-up approach)
  my @child_outputs;
  my $children = $node->{children};
  
  # Process children in order, but first build their subtrees
  foreach my $child_idx (@$children) {
    my $child = $processed->[$child_idx];
    my $child_level = $child->{level};
    
    # Recursively build child subtree, starting from highest level
    my $subtree = build_level($processed, $child_idx, $current_level, $min_level);
    push @child_outputs, $subtree;
  }
  
  # Build current node with its children
  my @node_output = ($node->{content});
  my $total_children = scalar @child_outputs;
  
  for (my $i = 0; $i < $total_children; $i++) {
    my $is_last = ($i == $total_children - 1) ? 1 : 0;
    my $child_subtree = $child_outputs[$i];
    
    # Add child root with appropriate connector
    my $child_root = shift @$child_subtree;
    my $prefix = $is_last ? '└── ' : '├── ';
    push @node_output, $prefix . $child_root;
    
    # Add remaining lines of child subtree with adjusted prefixes
    my $child_prefix = $is_last ? '    ' : '│   ';
    foreach my $line (@$child_subtree) {
      push @node_output, $child_prefix . $line;
    }
  }
  
  return \@node_output;
}

# Determine valid indent width (2 or 4)
sub determine_indent_width {
  my ($lines_ref) = @_;
  
  my @indents = grep { $_ > 0 } map { $_->{indent} } @$lines_ref;
  if (!@indents) {
    print "Debug: No indented lines found, using default 2\n" if $DEBUG;
    return 2;  # Default if no indents
  }
  
  # Check minimum indent
  my $min_indent = (sort { $a <=> $b } @indents)[0];
  return 2 if $min_indent == 2;
  return 4 if $min_indent == 4;
  
  # Verify all indents are multiples of 2 or 4
  my $all_2 = 1;
  my $all_4 = 1;
  foreach my $indent (@indents) {
    $all_2 = 0 if $indent % 2 != 0;
    $all_4 = 0 if $indent % 4 != 0;
  }
  
  if ($all_2) {
    print "Debug: All indents are multiples of 2\n" if $DEBUG;
    return 2;
  }
  if ($all_4) {
    print "Debug: All indents are multiples of 4\n" if $DEBUG;
    return 4;
  }
  
  return undef;  # Invalid indentation
}

# Run main program
main();


#!/usr/bin/perl -w
open IN, "$ARGV[0]" or die;
while (<IN>) {
    chomp;
    s/\\$//;
    s/\s*//g;
    if (/^\/eda/) {
        print $_, "\n" unless -e $_;
    }
}
close IN;

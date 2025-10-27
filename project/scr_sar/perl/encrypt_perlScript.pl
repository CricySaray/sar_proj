#!/usr/bin/perl
use strict;
use warnings;
# 仅加载 CryptFile 模块（无需调用函数，用其过滤器特性）
use Filter::Crypto::CryptFile;
use File::Basename;
use Getopt::Long;

# Initialize variables
my $overwrite = 0;  # Default: don't overwrite
my $help = 0;
my $source_file;

# Parse command line options
GetOptions(
  'o|overwrite=i' => \$overwrite,  # Short: -o, Long: --overwrite
  'h|help'        => \$help         # Short: -h, Long: --help
) or do {
  print "Error in command line arguments\n";
  print_usage();
  exit 1;
};

# Display help if requested
if ($help) {
  print_usage();
  exit 0;
}

# Get source file from remaining arguments
$source_file = $ARGV[0];

# Validate source file argument
unless (defined $source_file && $source_file ne '') {
  print "Error: Source script file is required\n";
  print_usage();
  exit 1;
}

# Validate overwrite option
if ($overwrite !~ /^[01]$/) {
  print "Error: Overwrite option must be either 0 or 1\n";
  print_usage();
  exit 1;
}

# Check if source file exists and is readable
unless (-e $source_file) {
  print "Error: Source file '$source_file' does not exist\n";
  exit 1;
}
unless (-f $source_file) {
  print "Error: '$source_file' is not a regular file\n";
  exit 1;
}
unless (-r $source_file) {
  print "Error: No read permission for file '$source_file'\n";
  exit 1;
}

# Check if source file is already encrypted
open my $in_fh_check, '<', $source_file or do {
  print "Error: Unable to open source file '$source_file': $!\n";
  exit 1;
};
my $first_line = <$in_fh_check>;
close $in_fh_check;
if (defined $first_line && ($first_line =~ /use Filter::Crypto::Decrypt;/ || $first_line =~ /use Filter::Crypto::CryptFile;/)) {
  print "Error: '$source_file' appears to be already encrypted\n";
  exit 1;
}

# Determine destination file name
my $dest_file;
if ($overwrite == 1) {
  $dest_file = $source_file;
  # Check write permission for source file
  unless (-w $source_file) {
    print "Error: No write permission for file '$source_file'\n";
    exit 1;
  }
} else {
  my ($name, $path, $ext) = fileparse($source_file, qr/\.[^.]*/);
  $dest_file = $path . 'encrypted_' . $name . $ext;
  
  # Check if destination file already exists
  if (-e $dest_file) {
    print "Error: Destination file '$dest_file' already exists\n";
    print "Please delete it manually or choose a different source file\n";
    exit 1;
  }
}

# Read source file content（复用文件句柄，避免警告）
open my $in_fh_read, '<', $source_file or do {
  print "Error: Unable to open source file '$source_file': $!\n";
  exit 1;
};
local $/;  # 读取整个文件内容
my $code = <$in_fh_read>;
close $in_fh_read;

# 关键修改：直接拼接“CryptFile过滤器声明 + 原代码”，无需调用encrypt_script
# 加密原理：运行加密文件时，Perl会先加载CryptFile过滤器，自动解密后续代码
my $encrypted_code = <<"END_CODE";
#!/usr/bin/perl
use Filter::Crypto::CryptFile;  # 过滤器声明（替代原Decrypt，兼容当前模块）
$code
END_CODE

# Write to temporary file first for safety
my $temp_file = $dest_file . '.tmp';
open my $out_fh, '>', $temp_file or do {
  print "Error: Unable to create temporary file '$temp_file': $!\n";
  exit 1;
};
print $out_fh $encrypted_code;
close $out_fh or do {
  print "Error: Failed to write to temporary file '$temp_file': $!\n";
  unlink $temp_file;  # Clean up
  exit 1;
};

# Set executable permission
chmod 0755, $temp_file or do {
  print "Warning: Unable to set executable permission on temporary file: $!\n";
};

# Move temporary file to destination
if (rename($temp_file, $dest_file)) {
  if ($overwrite == 1) {
    print "Successfully encrypted and overwrote source file: '$dest_file'\n";
  } else {
    print "Successfully encrypted file to: '$dest_file'\n";
  }
  print "You can run it with: perl $dest_file or directly: ./$dest_file\n";
} else {
  print "Error: Failed to rename temporary file to '$dest_file': $!\n";
  unlink $temp_file;  # Clean up
  exit 1;
}

# Print usage information with detailed help
sub print_usage {
  my $script_name = basename($0);
  print "\n$script_name - Encrypt Perl scripts while maintaining executability\n";
  print "=====================================================================\n\n";
  print "Usage: $script_name [options] <source_script_file>\n\n";
  
  print "Options:\n";
  print "  -o, --overwrite 0|1   Specify whether to overwrite the source file\n";
  print "                        0 = Create new file with 'encrypted_' prefix (default)\n";
  print "                        1 = Overwrite the original source file\n";
  print "  -h, --help            Display this detailed help message\n\n";
  
  print "Examples:\n";
  print "  $script_name my_script.pl\n";
  print "  - Encrypts my_script.pl to encrypted_my_script.pl\n\n";
  print "  $script_name -o 1 my_script.pl\n";
  print "  $script_name --overwrite 1 my_script.pl\n";
  print "  - Encrypts my_script.pl and overwrites the original file\n\n";
  
  print "Important Notes:\n";
  print "  1. Always backup your original scripts before encryption\n";
  print "  2. The --overwrite option (1) will permanently replace your original file\n";
  print "  3. Encrypted files require Perl and Filter::Crypto module to run\n";
  print "  4. Do not encrypt already encrypted files - this will cause errors\n";
  print "  5. Encrypted files cannot be easily decrypted - ensure you keep backups\n";
  print "  6. If Filter::Crypto is not installed, use: cpan Filter::Crypto\n\n";
}

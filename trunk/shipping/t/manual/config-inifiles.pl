#!/usr/bin/perl
#
# Test the Config::IniFiles
#

use strict;
use warnings;
use diagnostics;

use Config::IniFiles;

my $cfg = Config::IniFiles->new( -file => "config/config.ini" );
	
#
# Test reading in all sections and parameters...
#
my @sections = $cfg->Sections();
foreach my $section ( @sections ) {
	print "$section:\n";
	for ( $cfg->Parameters( $section ) ) {
		print "\t$_:\t\t\t" . $cfg->val( $section, $_ ) . "\n";
	}
	print "\n";
}

#
# Test tying a hash
#


1;
__END__

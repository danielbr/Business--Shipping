#!/usr/bin/perl

use strict;
use warnings;
use English;

=pod

=head1 DESCRIPTION

new-release - the Business::Shipping release script.

=head1 RELEASE STEPS

 # 
 # Manual: Update the CHANGELOG
 #
 
 #
 # Make sure all the files (documentation, etc.) are up to date.
 # Then commit to CVS
 #
 perl Makefile.PL 
 make docs manifest && make && make test
 cvs commit
 
 #
 # Delete old file, make new file, and upload to server.
 # Upload the new version to CPAN, for PAUSE
 # Update to the next verision in Makefile.PL (if you haven't already)
 #
 export VERSION_AFTER_THIS_UPLOAD=1.05 
 rm Business-Shipping-*.tar.gz
 make tardist
 bin/new-release.pl Business-Shipping-*.tar.gz
 cpan-upload -user `cat ~/.apps/.PAUSE-user` -password `cat ~/.apps/.PAUSE-password` -mailto 'db@kavod.com' -non_interactive Business-Shipping-*.tar.gz
 perl -pi -e "s/\$VERSION = \'.\...\'/\$VERSION = \'${VERSION_AFTER_THIS_UPLOAD}\'/g" Makefile.PL
 
=cut 

my ( $file ) = @ARGV;

print "Usage: $PROGRAM_NAME Business-Shipping-n.nn.tar.gz\n" and exit 
	unless $file;

$file =~ m/^(Business-Shipping-\d\.\d\d)\.tar\.gz$/;
my $version = $1;

print "version = $version\n";
print "file=$file\n";

myexec( "scp $file kavod\@kavod\.com:html/" );

my $cmd = qq{ssh kavod\@kavod\.com \<\<EOF
cd html/Business-Shipping

# Move old releases to the 'older' folder
rm Business-Shipping-latest
rm Business-Shipping-latest.tar.gz
mv Business-Shipping-* older/

# Pull in the new file.
cd ..
mv $file Business-Shipping
cd Business-Shipping

# Unpack it and make links
tar zxf $file
ln -s $file Business-Shipping-latest.tar.gz
ln -s $version Business-Shipping-latest

# Update CVS
cd CVS-Business-Shipping
cvs up

# Update version number
cd ..
echo '$version' > .version

EOF
};

myexec( $cmd );

sub myexec
{
	my $cmd = shift;
	print "Going to execute \"$cmd\"...\n";
	return system ( $cmd );
}


# Makefile.PL - Installation script for Business::Shipping
# 
# $Id$
#
# Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved.
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself. See LICENSE for more info.

use 5.006000;
use ExtUtils::MakeMaker;
use File::Copy;
use English;

# Auto-update REQUIRED MODULES documentation if needed
#eval "use Devel::Required text => [ '' ], pod => [qw(lib/Business/Shipping.pm), qw(doc/README.pod), qw(doc/INSTALL.pod), qw(UserTag/business-shipping.tag)]";

# Defaults

my %my_globals = (
	SUPPORT_FILES_DIR	=> '/var/perl/Business-Shipping'
);

WriteMakefile(
    NAME			=> 'Business::Shipping',
    VERSION_FROM	=> 'lib/Business/Shipping.pm',
    ABSTRACT		=> 'Business::Shipping - Cost estimation and tracking for UPS and USPS',
    AUTHOR		    => 'Dan Browning <db@kavod.com>',
	CONFIGURE		=> \&extra_WriteMakefile_options,
    PREREQ_PM		=>	{
		'Bundle::DBD::CSV'		     => 0,
		'Cache::FileCache'		     => 0,
		'Class::MethodMaker::Engine' => 0,
		'Clone'					     => 0,
		'Config::IniFiles'		     => 0,
		'Crypt::SSLeay'			     => 0,
		'Getopt::Mixed'		      	 => 0,
		'Log::Log4perl'              => 0,
        'LWP::UserAgent'		     => 0,
		'Math::BaseCnv'			     => 0,
		'Scalar::Util'			     => '1.10',
		'XML::DOM' 				     => 0,
		'XML::Simple'			     => '2.05',
	},
		#'Archive::Zip'			     => 0,      # For updates only
    	#'Devel::Required'	      	 => '0.03', # For documentation updates only

);

# Override the standard "install" target, so that it calls "support_files_install"

sub MY::install {
	package MY;
	my $inherited = shift->SUPER::install(@_);
	my $new; 
	for ( split( "\n", $inherited ) ) {
		if ( /^install :: / ) {
			$_ .= " support_files_install";
		}
		$new .= "$_\n";
	}
	return $new;
}

sub MY::postamble {
	return qq{
docs :
	podchecker -nowarnings doc/INSTALL.pod doc/README.pod
	find lib -name '*.pm' -exec podchecker -nowarnings {} \\;
	pod2text doc/README.pod > README
	pod2html doc/README.pod > doc/README.html
	pod2text doc/INSTALL.pod > INSTALL
	pod2html doc/INSTALL.pod > doc/INSTALL.html
	pod2text lib/Business/Shipping.pm > doc/usage.txt
	pod2html lib/Business/Shipping.pm > doc/usage.html
	
support_files_install :
	\@echo "Installing support files (database, configuration, etc.) to $my_globals{SUPPORT_FILES_DIR}"
	\@\$(MKPATH) $my_globals{SUPPORT_FILES_DIR}/log
	\@\$(MKPATH) $my_globals{SUPPORT_FILES_DIR}/data
	\@\$(MKPATH) $my_globals{SUPPORT_FILES_DIR}/config
	\@\$(CP) --recursive --force data/*   $my_globals{SUPPORT_FILES_DIR}/data/
	\@\$(CP) --recursive --force config/* $my_globals{SUPPORT_FILES_DIR}/config/
};  #/qq
}

sub extra_WriteMakefile_options {
    
    my $question = qq(
             ---  Business::Shipping support files directory  ---
  
Business::Shipping comes with various support files for configuration, database,
etc.  Please input the path you would like to copy these files to.  You can 
modify the path later by changing the Business/Shipping/Config.pm file.

On many systems, this directory will only be accessible by the user who 
installed perl, typically root.

Business::Shipping support files directory:);

	$my_globals{ SUPPORT_FILES_DIR } = prompt( 
        $question, 
		$my_globals{ SUPPORT_FILES_DIR },
	);
    
	$my_globals{ SUPPORT_FILES_DIR } =~ s:[\\/]\s*$::;
	$my_globals{ SUPPORT_FILES_DIR } =~ s:^\s*::;

    # Now we are going to substitute the support files directory in 
    # lib/Business/Shipping/Config.pm
    
    subst( 
        variables => {
            SUPPORT_FILES_DIR => $my_globals{ SUPPORT_FILES_DIR }
        },
        files     => [
            'lib/Business/Shipping/Config.pm',
            'config/log4perl.conf'
        ]
    );

	my %EXTRA_CONFIG_OPTIONS;
    #$EXTRA_CONFIG_OPTIONS{ } 
	#$EXTRA_CONFIG_OPTIONS{ OPTION_NAME } = 'value';
    
	return \%EXTRA_CONFIG_OPTIONS;
}


=head2 * subst( files => [ ], variables => { } )

Converts variables, like so:
 
 $a = '~_~SUPPORT_FILES_DIR~_~';

into

 $a = '/blah/blah/';

=cut

# TODO: Make this Windows compatible

sub subst
{
    my ( %opt ) = @_;

    return unless $opt{ files } and $opt{ variables };
    
    my $base_path = '.';
    
    foreach my $file ( @{ $opt{ files } } ) {
        $file = "$base_path/$file";
        
        copy( $file, "$file.tmp"  ) or die "Copy failed: $OS_ERROR";
        open( NEW,   ">$file"     ) or die "Open failed: $OS_ERROR";
        open( OLD,   "<$file.tmp" ) or die "Open failed: $OS_ERROR";
        
        # Read in the entire file for speed.
        # This regex taken from Interchange (http://www.icdevgroup.org).
        
        undef $INPUT_RECORD_SEPARATOR;
        $_ = <OLD>;
        s{.*\n(#(.*)~_~(\w+)~_~(.*))}{$2 . $opt{ variables }->{ $3 } . "$4\n$1"}eg;
        print NEW $_;
        
        close NEW;
        close OLD;
        
        unlink "$file.tmp" or die "Delete failed: $OS_ERROR";
    }
    
    return;
}

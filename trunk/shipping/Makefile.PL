# Makefile.PL - Installation script for Business::Shipping
# 
# $Id: Makefile.PL,v 1.30 2004/03/31 19:11:03 danb Exp $
#
# Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved.
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself. See LICENSE for more info.
#

use 5.006000;
use ExtUtils::MakeMaker;

#
# Auto-update REQUIRED MODULES documentation if needed
#
eval "use Devel::Required text => [ '' ], pod => [qw(lib/Business/Shipping.pm), qw(doc/README.pod), qw(doc/INSTALL.pod), qw(UserTag/business-shipping.tag)]";

#
# Defaults
#
my %my_globals = (
	SUPPORT_FILES_DIR	=> '/var/perl/Business-Shipping'
);

WriteMakefile(
    NAME			=> 'Business::Shipping',
    VERSION			=> '1.07',
    ABSTRACT		=> 'Business::Shipping - Interface for shippers (UPS, USPS)',
    AUTHOR		    => 'Dan Browning <db@kavod.com>',
	CONFIGURE		=> \&extra_WriteMakefile_options,
    PREREQ_PM		=>	{
		'Archive::Zip'			=> 0,
		'Bundle::DBD::CSV'		=> 0,
		'Cache::FileCache'		=> 0,
		'Class::MethodMaker'	=> '2.00',
		'Clone'					=> 0,
		'Config::IniFiles'		=> 0,
		'Crypt::SSLeay'			=> 0,
		'Data::Dumper'			=> 0,
		'Devel::Required'		=> '0.03',
		'Error'					=> 0,
		'Getopt::Mixed'			=> 0,
		'LWP::UserAgent'		=> 0,
		'Math::BaseCnv'			=> 0,
		'Scalar::Util'			=> '1.10',
		'XML::DOM' 				=> 0,
		'XML::Simple'			=> '2.05',
        #Module::Build #for Log::Dispatch::File
        #Log::Log4perl (comes with File and Screen Appenders)
        #Log::Dispatch
        #Log::Dispatch::Email?
	},
);

#
# Override the standard "install" target, so that it calls "support_files_install"
#
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
	$my_globals{SUPPORT_FILES_DIR} = prompt(
			"\n"
		.	"  ---  Business::Shipping support files directory  ---  \n"
		.	"\n"
		.	"Business::Shipping has various support files for configuration, database, etc.\n"
		.	"(The path to these files can be overridden later on a per-user basis.)\n"
		.	"I need to know the path to the \'system\' level, or \'default\' files.\n"
		.	"On many systems, this directory will only be accessible by root.\n"
		.	"\n"
		.	"Business::Shipping default support files directory:", 
		$my_globals{SUPPORT_FILES_DIR},
	);
	$my_globals{SUPPORT_FILES_DIR} =~ s:[\\/]\s*$::;
	$my_globals{SUPPORT_FILES_DIR} =~ s:^\s*::;
	
	my %X;
	#$X{ EXTRA_CONFIG_OPTION } = "value";
	return \%X;
}

use 5.006000;
use ExtUtils::MakeMaker;

#
# auto-update documentation if needed
#
eval "use Devel::Required text => [ '' ], pod => [qw(lib/Business/Shipping.pm), qw(doc/README.pod), qw(doc/INSTALL.pod), qw(UserTag/business-shipping.tag)]";

# Version for Business-Shipping as a whole.
$VERSION = '1.04';

#
# Defaults
#
my %my_globals = (
	SUPPORT_FILES_DIR	=> '/var/perl/Business-Shipping'
);

WriteMakefile(
    NAME			=> 'Business::Shipping',
    VERSION_FROM	=> 'Makefile.PL',
    ABSTRACT_FROM	=> 'lib/Business/Shipping.pm',
    AUTHOR		    => 'Dan Browning <db@kavod.com>',
	CONFIGURE		=> \&extra_WriteMakefile_options,
    PREREQ_PM		=>	{
		'XML::Simple'			=> '2.05',
		'XML::DOM' 				=> 0,
		'Data::Dumper'			=> 0,
		'LWP::UserAgent'		=> 0,
		'Crypt::SSLeay'			=> 0,
		'Error'					=> 0,
		'Cache::FileCache'		=> 0,
		'Class::MethodMaker'	=> 0,
		'Config::IniFiles'		=> 0,
		'Bundle::DBD::CSV'		=> 0,
		'Archive::Zip'			=> 0,
		'Devel::Required'		=> '0.03',
		'Math::BaseCnv'			=> 0,
		'Scalar::Util'			=> '1.10',
		'Getopt::Mixed'			=> 0,
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
	\@\$(MKPATH) $my_globals{SUPPORT_FILES_DIR}/data
	\@\$(MKPATH) $my_globals{SUPPORT_FILES_DIR}/config
	\@\$(CP) --recursive --force data/*   $my_globals{SUPPORT_FILES_DIR}/data/
	\@\$(CP) --recursive --force config/* $my_globals{SUPPORT_FILES_DIR}/config/
};
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

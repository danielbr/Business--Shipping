use strict;
use warnings;
use ExtUtils::MakeMaker;

my %my_globals = (
	SUPPORT_FILES_DIR	=> '/var/perl/Business-Shipping'
);

WriteMakefile(
    NAME                => 'Business::Shipping::DataTools',
    AUTHOR              => 'Dan Browning <db@kavod.com>',
    VERSION_FROM        => 'lib/Business/Shipping/DataTools.pm',
    ABSTRACT_FROM       => 'lib/Business/Shipping/DataTools.pm',
    CONFIGURE		    => \&extra_WriteMakefile_options,
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Business-Shipping-DataTools-*' },
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
	find lib -name '*.pm' -or -name '*.pod' -exec podchecker -nowarnings {} \\;
	
support_files_install :
	\@echo "Installing data files to $my_globals{SUPPORT_FILES_DIR}/srcdata"
	\@\$(MKPATH) $my_globals{SUPPORT_FILES_DIR}/srcdata
	\@\$(CP) --recursive --force srcdata/*   $my_globals{SUPPORT_FILES_DIR}/srcdata/
};  #/qq
}

sub extra_WriteMakefile_options {
    my $module = "Business::Shipping::DataTools";
    
    # TODO: Try to determine the directory by using 
    # Business::Shipping::Config::support_files()
    
    
    eval {
        use Business::Shipping;
        my $support_files_installed = Business::Shipping::Config::support_files();
        if ( $support_files_installed ) {
            $my_globals{ SUPPORT_FILES_DIR } = $support_files_installed;
        }
    };
    
    # ignore errors.  If Business::Shipping isn't installed, don't make
    # a big deal about it.
    
    $@ = ''; 
    
    
    my $question = qq(
             ---  $module Support files directory  ---
  
$module module comes with various support files for configuration, database, 
etc.  Please input the path you would like to copy these files to.  You can 
modify the path later by changing the Config.pm file.

On many systems, this directory will only be accessible by the user who 
installed perl, typically root.

$module Support files directory:);

	$my_globals{ SUPPORT_FILES_DIR } = prompt( 
        $question, 
		$my_globals{ SUPPORT_FILES_DIR },
	);
    
	$my_globals{ SUPPORT_FILES_DIR } =~ s:[\\/]\s*$::;
	$my_globals{ SUPPORT_FILES_DIR } =~ s:^\s*::;

	my %EXTRA_CONFIG_OPTIONS;
    #$EXTRA_CONFIG_OPTIONS{ } 
	#$EXTRA_CONFIG_OPTIONS{ OPTION_NAME } = 'value';
    
	return \%EXTRA_CONFIG_OPTIONS;
}

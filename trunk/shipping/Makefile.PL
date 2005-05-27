use 5.006000;
use ExtUtils::MakeMaker;
use File::Copy;
use English;
use strict;
use warnings;

# Auto-update REQUIRED MODULES documentation if needed
#eval "use Devel::Required text => [ '' ], pod => [qw(lib/Business/Shipping.pm), qw(doc/README.pod), qw(doc/INSTALL.pod), qw(UserTag/business-shipping.tag)]";

# Defaults

my %my_globals = (
    PREFIX_DIR  => '/usr/local/B_Shipping'
	#CONFIG_DIR	=> '/usr/local/B_Shipping/config', # These are set manually later on, so don't bother 
    #LOG_DIR     => '/usr/local/B_Shipping/log',   # defaulting them.
    #DATA_DIR	=> '/usr/local/B_Shipping/data',
);

=head1 USAGE

 perl Makefile.PL [--use_defaults=<1|0>] [-u=<1|0>]
 
 -u=1 or --use_defaults=1: Use default values, do not ask for values.  
 
 This option is only available if you have Getopt::Mixed installed.

=cut

$::UseDefaults = $ENV{ BS_USE_DEFAULTS } ? 1 : 0;
$::UseOptions = 0;

if ( @ARGV ) {
    eval "use Getopt::Mixed";
    if ( ! $@ ) {
        $::UseOptions = 1;
    }
}

if ( $::UseOptions ) {
    our $opt_u;
    Getopt::Mixed::getOptions( 'u:i use_defaults>u' );
    my %rr_params;
    if ( $opt_u ) {
        $::UseDefaults = 1;
    }
}

WriteMakefile(
    NAME			=> 'Business::Shipping',
    VERSION_FROM	=> 'lib/Business/Shipping.pm',
    ABSTRACT		=> 'Business::Shipping - Rates and tracking for UPS and USPS',
    AUTHOR		    => 'Dan Browning <db@kavod.com>',
	CONFIGURE		=> \&extra_WriteMakefile_options,
    PREREQ_PM		=> { 
        'Class::MethodMaker::Engine' => 0,
        'Log::Log4perl'              => 0,
        'Scalar::Util'               => 0,
        'Test::More'                 => 0.40,
    },
    EXE_FILES       => [
        'bin/Business-Shipping-UPS_Offline-update-fuel-surcharge.pl',
    ]
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


# Currently there is no data files installation, because the data files are installed by the DataFiles module.
sub MY::postamble {
	return qq{
docs :
	find lib -name '*.pm' -or -name '*.pod' -exec podchecker -nowarnings {} \\;
	pod2text doc/INSTALL.pod > doc/INSTALL
	pod2html doc/INSTALL.pod > doc/INSTALL.html
	pod2text doc/INSTALL.pod > doc/INSTALL.txt
	pod2text lib/Business/Shipping.pm > README
	pod2text lib/Business/Shipping.pm > doc/README.txt
	pod2html lib/Business/Shipping.pm > doc/README.html
	
support_files_install :
	\@echo "Installing configuration files to $my_globals{CONFIG_DIR}"
	\@\$(MKPATH) $my_globals{LOG_DIR}
	\@\$(MKPATH) $my_globals{CONFIG_DIR}
	\@\$(CP) --recursive --force config/* $my_globals{CONFIG_DIR}/
};  #/qq
}

sub extra_WriteMakefile_options {
    
    
    if ( not $::UseDefaults ) {
        my $module = 'Business::Shipping';
        
        my $question = qq(
             ---  $module configuration, logging, and data directory  ---
  
What directory should be used for storing configuration files, logging files, and data?

$module support files directory:);

    
        $my_globals{ PREFIX_DIR } = prompt( 
            $question, 
            $my_globals{ PREFIX_DIR },
        );
    
        $my_globals{ PREFIX_DIR } =~ s:[\\/]\s*$::;
        $my_globals{ PREFIX_DIR } =~ s:^\s*::;
    } # end if not use defaults
    
    $my_globals{ CONFIG_DIR } = $my_globals{ PREFIX_DIR } . '/config';
    $my_globals{ LOG_DIR    } = $my_globals{ PREFIX_DIR } . '/log';
    $my_globals{ DATA_DIR   } = $my_globals{ PREFIX_DIR } . '/data';
    
    # Now we are going to substitute the support files directory in 
    # lib/Business/Shipping/Config.pm
    
    subst( 
        variables => {
            DEFAULT_CONFIG_DIR  => $my_globals{ CONFIG_DIR },
            DEFAULT_LOG_DIR     => $my_globals{ LOG_DIR    },
            DEFAULT_DATA_DIR    => $my_globals{ DATA_DIR   },
        },
        files     => [
            'lib/Business/Shipping/Config.pm',
            'config/log4perl.conf',
        ]
    );

    subst( 
        variables => {
            UPS_ONLINE_DISABLED => 1,
        },
        files     => [
            'lib/Business/Shipping/UPS_Online/RateRequest.pm',
            'lib/Business/Shipping/UPS_Online/Tracking.pm',
        ]
    );
    
    

	my %EXTRA_CONFIG_OPTIONS;
    #$EXTRA_CONFIG_OPTIONS{ } 
	#$EXTRA_CONFIG_OPTIONS{ OPTION_NAME } = 'value';
    
	return \%EXTRA_CONFIG_OPTIONS;
}

=head1 METHODS



=head2 subst( files => [ ], variables => { } )

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

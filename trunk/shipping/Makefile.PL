use 5.006000;
use ExtUtils::MakeMaker;

# Version for Business-Ship as a whole.
$VERSION = '0.03';

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Business::Ship',
    'VERSION_FROM'	=> 'Makefile.PL', # finds $VERSION
    'PREREQ_PM'		=>	{
							'XML::DOM' 			=> '1.0',
							'LWP::UserAgent'	=> '1.0',
							'XML::Simple'		=> '2.05',
							
						},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Ship.pm', # retrieve abstract from module
       AUTHOR     => 'Dan Browning <db@kavod.com>') : ()),
);

sub MY::postamble {
	return <<'MAKE_README';
readme :
	pod2text doc/README.pod > README
MAKE_README
}


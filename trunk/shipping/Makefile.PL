use 5.006000;
use ExtUtils::MakeMaker;

# Version for Business-Shipping as a whole.
$VERSION = '0.75';

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Business::Shipping',
    'VERSION_FROM'	=> 'Makefile.PL', # finds $VERSION
    'PREREQ_PM'		=>	{
							'Data::Dumper'			=> 0,
							'Digest::SHA1'			=> 0,
							'LWP::UserAgent'		=> 0,
							'Crypt::SSLeay'			=> 0,
							'XML::Simple'			=> '2.05',
							'XML::DOM' 				=> 0,
							'Error'					=> 0,
							'Cache::FileCache'		=> 0,
							'Class::MethodMaker'	=> 0,
						},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Business/Shipping.pm', # retrieve abstract from module
       AUTHOR     => 'Dan Browning <db@kavod.com>') : ()),
);

sub MY::postamble {
	return <<'MAKE_README';
readme :
	pod2text doc/README.pod > README
MAKE_README
}

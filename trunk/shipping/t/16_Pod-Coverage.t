use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => '' if $@;  # I prefer a silent skip

my @all_modules = Test::Pod::Coverage::all_modules();
my @ignore = qw/
    Business::Shipping::ClassInfo
    Business::Shipping::KLogging
    Business::Shipping::Tracking
    /;

for my $ignore ( @ignore ) {
    @all_modules = grep( !/^${ignore}$/, @all_modules );
}

for ( @all_modules ) {
    pod_coverage_ok( $_ );
}



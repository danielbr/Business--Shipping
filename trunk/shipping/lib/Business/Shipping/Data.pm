# Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved.
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself. See LICENSE for more info.

package Business::Shipping::Data;

=head1 NAME

Business::Shipping::Data - Database interface

=head1 VERSION

$Id$

=head1 DESCRIPTION

Uses DBI for CSV file access.

=head1 METHODS

=over 4

=cut

$VERSION = do { my $r = q$Rev$; $r =~ /\d+/; $&; };
@EXPORT = qw( record );

use strict;
use warnings;
use base ( 'Exporter' );
use Business::Shipping::Logging;
use Business::Shipping::Config;
use DBI;

=item * record( $table, $field, $key, $opt )

Performs a single-record lookup.  Analagous to Interchange tag_data() function.

=cut

sub record
{
    my ( $table, $field, $key, $opt ) = @_;
    trace( 'called' );
    
    my $key_column = $opt->{ foreign } || get_primary_key( $table );
    return unless $key_column;
    debug3( "key_column = $key_column" );
    
    # Apparently, with DBD::CSV, '*' is required instead of the field name.
    
    my $query = "SELECT * FROM $table WHERE $key_column = \'$key\'";
    debug( $query );
    my $sth = sth( $query )
        or die "Could not get sth: $@";
    my $hashref = $sth->fetchrow_hashref();
    #debug3( "hashref = " . Dumper( $hashref ) );
    
    return $hashref->{ $field };
}    

sub sth
{
    my ( $query ) = @_;
    
    return unless $query;
    
    my $dbh = dbh();
    
    my $sth = $dbh->prepare( $query )
        or die "Cannot prepare: " . $dbh->errstr();
    
    $sth->execute() or die "Cannot execute: " . $sth->errstr();;
    
    return $sth;    
}

sub dbh
{
    if ( ! defined $::dbh_store ) {
        $::dbh_store = {};
        my $support_files = Business::Shipping::Config::support_files();
        my $dsn = cfg()->{Database}{DSN} || "DBI:CSV:f_dir=$support_files/data";
        $dsn .= ";csv_eol=\n;";
        
        my $dbh = DBI->connect( $dsn )
            or die "Cannot connect: " . $DBI::errstr;
    
        if ( $dsn =~ /^DBI:CSV/ ) {

            # Try to find tables in the configuration that have
            # extra settings.

            foreach my $section ( cfg_obj()->Sections() ) {
                if ( $section =~ /^Table_/ ) {
                    my $table = $section;
                    $table =~ s/^Table_.+_//;
                    
                    
                    my $table_attributes_hash = cfg()->{ $section };
                    $table_attributes_hash->{ file } ||= "$table.csv";
                    $table_attributes_hash->{ eol } =~ s/cr/\r/;
                    $table_attributes_hash->{ eol } =~ s/nl/\n/;
                    $table_attributes_hash->{ eol } ||= "\n";
                    
                    #debug3( "adding special csv attributes for $table.  They are:" . Dumper( $table_attributes_hash ) );
                    
                    # TODO: only allow a restricted list of attributes to be set
                    # instead of letting anything in the config file be set.

                    $dbh->{ csv_tables }->{ $table } = $table_attributes_hash;
                }
            }
        }
        
        # Currently, only one DBH is allowed.

        $::dbh_store->{ main } = $dbh;
    }
    return $::dbh_store->{ main };
}

sub get_primary_key
{
    my ( $table ) = @_;
    
    my $sth = sth( "select * from $table limit 1" );
    
    # TODO: Use some DBI method to determine the real primary key
    # Or, allow the primary key to be specified in the config.
    #
    # For now, we assume that the first column is the primary key.

    return $sth->{ NAME }->[ 0 ];
}

1;

__END__

=back

=head1 AUTHOR

Dan Browning E<lt>F<db@kavod.com>E<gt>, Kavod Technologies, L<http://www.kavod.com>.

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2003-2004 Kavod Technologies, Dan Browning. All rights reserved.
This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself. See LICENSE for more info.

=cut

package Business::Shipping::DataTools;

use warnings;
use strict;

=head1 NAME

Business::Shipping::DataTools - Convert tables from original format into usable format.  

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

This is an optional module.  It is used to update Business::Shipping::DataFiles.
These tools convert the original source data obtained from shippers into a 
format that Business::Shipping can use.

=cut

=item * download_to_file( $url, $file )

=cut

sub download_to_file
{
    my ( $url, $file ) = @_;
    trace "( $url, $file )";
    
    return unless $url and $file;
    
    eval {
        use LWP::UserAgent;
        my $ua = LWP::UserAgent->new;
        my $req = HTTP::Request->new(GET => $url);
        open( NEW_ZONE_FILE, "> $file" );
        print( NEW_ZONE_FILE $ua->request($req)->content() );        
        close( NEW_ZONE_FILE );
    };
    warn $@ if $@;
    
    return;
}

=item * _unzip_file( $zipName, $destination_directory )

=cut

# Extracts all files from the given zip

=pod

sub _unzip_file
{
    my ( $zipName, $destination_directory ) = @_;
    $destination_directory ||= './';
    
    use Archive::Zip qw(:ERROR_CODES);

    my $zip = Archive::Zip->new();
    my $status = $zip->read( $zipName );
    if ( $status != AZ_OK )  {
        my $error = "Read of $zipName failed";
        #$self->user_error( $error );
        logdie $error;
    }
    if ( $@ ) { logdie "_unzip_file error: $@"; }
    
    $zip->extractTree( '', $destination_directory );
    
    return;
}

=cut

=item * filename_only( $path )

=cut

sub filename_only
{
    trace "( $_[0] )";
    my $filename_with_extension = $_[0];
    
    my $filename_only = $filename_with_extension; 
    $filename_only =~ s/\..+$//;
    
    return $filename_only;
}

=item * split_dir_file( $path )

=cut

# Return ( directory_path, file_name ) from any path.
# TODO: Use correct File:: Module, and be Windows-compatible

sub split_dir_file
{
    my $path = shift;
    
    my @path_components = split( '/', $path );
    my $file = pop @path_components;
    my $dir = join( '/', @path_components );
    return ( $dir, $file ); 
}

=item * remove_extension( $file )

=cut

sub remove_extension
{
    my $file = shift;
    trace "( $file )";
    
    my $filename_only = filename_only( $file );
    rename( $file, $filename_only );
    
    return $filename_only;
}

=item * remove_windows_carriage_returns( $path )

=cut

# TODO: Windows compat: call binmode() if Windows.

sub remove_windows_carriage_returns
{
    my $file = shift;
    trace "( $file )";
    
    open(    IN,        $file      );
    flock(   IN,        LOCK_EX    );
    
    open(    OUT,       ">$file.1" );
    flock(   OUT,       LOCK_EX    );

    # read it all in at once.

    undef $/;
    my $contents = <IN>;
    $contents =~ s/\r\n/\n/g;
    print OUT $contents;
    
    flock(  IN,        LOCK_UN     );
    close(  IN                     );
    flock(  OUT,       LOCK_UN     );
    close(  OUT                    );
    copy(   "$file.1", $file       );
    unlink( "$file.1"              );
    

    # return to normal line endings.
    # TODO: Use English;

    $/ = "\n";
    return;
}

sub convert_ups_rate_file
{
    trace "( $_[0] )";
    
    my ( $file ) = @_;
    my $file2 = "$file.new";
    if ( ! -f $file ) { return; }
    
    open(         RATE_FILE,        $file            ) or logdie $@;
    binmode(     RATE_FILE                         ) if $Global::Windows;
    flock(         RATE_FILE,         LOCK_EX         ) or logdie $@;
    open(         NEW_RATE_FILE,    ">$file2"        ) or logdie $@;
    binmode(     NEW_RATE_FILE                     ) if $Global::Windows;
    flock(         NEW_RATE_FILE,    LOCK_EX            ) or logdie $@;
    
    my $line;

    #
    # Line ending is now \n (might have been changed to nothing ealier)
    #
    $/ = "\n";

    #
    # Remove all the lines until we get to the line with "Weight Not To Exceed"
    #
    while ( $line = <RATE_FILE> ) {
        last if ( $line =~ /^Weight Not To Exceed/ );
    }
    
    if ( $line ) {
        # Remove "Weight Not To " from this line
        $line =~ s/^Weight Not To//;
        
        # Remove all occurences of "Zone" from this line
        $line =~ s/Zone//g;
        
        # Remove all the left-over spaces.
        $line =~ s/ //g;
        
        # Now-adjusted Header
        print NEW_RATE_FILE $line;
    }
    
    #
    # Remove blank lines before the data starts, if any
    #
    
    while ( $line = <RATE_FILE> ) {
        #
        # Skip the line if it is empty, or just has commas.
        #
        debug3( "checking line... $line" );
        
        next if ! $line;
        next if $line =~ /^\s+$/; 
        next if $line =~ /^(\,|\ )+$/;
        
        #
        # wwrates/ww-xp*
        # I don't really know what "Min" and "Per Pd." are for, so I'm deleting them.
        #
        last if $line =~ /^UPS Worldwide Express Box/;
        last if $line =~ /^Min/;
        last if $line =~ /^Per Pd\./;
        
        debug3( "Writing line... $line" );
        
        print NEW_RATE_FILE $line;
    }

    flock(     RATE_FILE,         LOCK_UN    ) or logdie $@;
    close(     RATE_FILE                 ) or logdie $@;
    flock(    NEW_RATE_FILE,     LOCK_UN    ) or logdie $@;
    close(    NEW_RATE_FILE             ) or logdie $@;
    copy(     $file2,         $file     ) or logdie $@;
    unlink( $file2                     ) or logdie $@;
    
    return;
}

=item * do_download

=cut

sub do_download
{
    my ( $self ) = @_;
    my $data_dir = Business::Shipping::Config::data_dir();
    debug( "data_dir = $data_dir" );
    
    my $us_origin_rates_url = cfg()->{ ups_information }->{ us_origin_rates_url };
    my $us_origin_zones_url = cfg()->{ ups_information }->{ us_origin_zones_url };
    my $us_origin_rates_filenames = cfg()->{ ups_information }->{ us_origin_rates_filenames };
    my $us_origin_zones_filenames = cfg()->{ ups_information }->{ us_origin_zones_filenames };
    
    for ( @$us_origin_zones_filenames ) {
        s/\s//g;
        Business::Shipping::Util::download_to_file( "$us_origin_zones_url/$_", "$data_dir/$_" );
    }
    for ( @$us_origin_rates_filenames ) {
        s/\s//g;
        Business::Shipping::Util::download_to_file( "$us_origin_rates_url/$_", "$data_dir/$_" ) ;
    }
}

=item * do_unzip

=cut

sub do_unzip
{
    for ( 
            @{ cfg()->{ ups_information }->{ us_origin_rates_filenames } },
            @{ cfg()->{ ups_information }->{ us_origin_zones_filenames } },
        )
    {
        #
        # Remove any leading spaces.
        #
        s/^\s//g;
        my $filename_without_extension = Business::Shipping::Util::filename_only( $_ );
        my $data_dir = Business::Shipping::Config::data_dir();
        #
        # Disable splitting up the data.  I just want them in one big flat directory, for now.
        #
        #my $destionation_dir = "$filename_without_extension/";
        my $destionation_dir = '';
        debug3( "Going to unzip: $data_dir/$_ into directory $data_dir/$destionation_dir" );
        Business::Shipping::Util::_unzip_file(  "$data_dir/$_", "$data_dir/$destionation_dir" )
    }
    
    return;
}

=item * do_convert_data()

Find all data .csv files and convert them from the vanilla UPS CSV format
into one that Business::Shipping can use.

=cut

sub do_convert_data
{
    trace '()';
    my $self = shift;
    
    #
    # * Find all *rate* csv files in the data directory (and sub-dirs)
    # * Ignore zone files (because they can be used as-is) 
    # * Ignore other files (zip files, extented area, residential, domestic, fuel surcharge, etc. files).
    #
    
    my @files_to_process;
    my $find_rates_files_sub = sub {
        
        #
        # Now, we do translate zone files.
        #
        return if ( $File::Find::dir =~ /zone/i );
        return if ( $_ =~ /zone/i );
        return if ( $_ =~ /\d\d\d/ );
        my $cvs_files_skip_regexes = cfg()->{ ups_information }->{ csv_files_skip_regexes };
        foreach my $cvs_files_skip_regex ( @$cvs_files_skip_regexes ) {
            $cvs_files_skip_regex =~ s/\s//g;
            return if ( $_ eq $cvs_files_skip_regex );
        }
        
        # Only csv files
        return if ( $_ !~ /\.csv$/i );
        
        # Ignore CVS files
        return if ( $_ eq '.' );
        return if ( $File::Find::dir =~ /CVS$/ );
        return if ( $_ eq 'CVS' );
        
        # Ignore Dirs
        return unless ( -f $_ );
        
        debug3( "$_\n" );
        
        push ( @files_to_process, $File::Find::name );
        return;
    };
    
    find( $find_rates_files_sub, Business::Shipping::Config::data_dir() );
    
    my $cannot_convert_at_this_time = cfg()->{ ups_information }->{ cannot_convert };
    
    #
    # add the data dir
    #
    my @temp;
    for ( @$cannot_convert_at_this_time ) {
        debug( "cannot convert $_" );
        push @temp, Business::Shipping::Config::data_dir() . "/$_";
    }
    $cannot_convert_at_this_time = \@temp;

    #
    # Remove the files that we cannot convert at this time.
    #
    @files_to_process = Business::Shipping::Util::remove_elements_of_x_that_are_in_y( \@files_to_process, $cannot_convert_at_this_time );
    
    debug3( "files_to_process = " . join( "\n", @files_to_process ) );
    for ( @files_to_process ) {
        Business::Shipping::Util::remove_windows_carriage_returns( $_ );
        convert_ups_rate_file( $_ );
        
        $_ = Business::Shipping::Util::remove_extension( $_ );
        $_ = rename_tables_that_start_with_numbers( $_);
        $_ = rename_tables_that_have_a_dash( $_ );
    }
    #
    # Convert the ewwzone.csv file manually, since it is skipped, above.
    #
    Business::Shipping::Util::remove_windows_carriage_returns( 
        Business::Shipping::Config::data_dir() . '/ewwzone.csv' 
    );
    $self->convert_zone_file( 'ewwzone.csv' );
    
}

=item * convert_zone_file

=cut

sub convert_zone_file
{
    my ( $self, $file ) = @_;
    trace "( $file )";
    $file =  Business::Shipping::Config::data_dir() . "/$file";
    my $file2 = "$file.new";

    open(         ZONE_FILE,        $file            ) or logdie "Could not open file $file. $@";
    binmode(     ZONE_FILE                         ) if $Global::Windows;
    flock(         ZONE_FILE,         LOCK_EX         ) or logdie $@;
    open(         NEW_ZONE_FILE,    ">$file2"        ) or logdie $@;
    binmode(     NEW_ZONE_FILE                     ) if $Global::Windows;
    flock(         NEW_ZONE_FILE,    LOCK_EX            ) or logdie $@;
    
    my $line;

    #
    # Line ending is now \n (might have been changed to nothing ealier)
    #
    $/ = "\n";

    #
    # Remove all the lines until we get to the line with "Weight Not To Exceed"
    #
    debug( "check zone file for ExpressSM..." );
    while ( $line = <ZONE_FILE> ) {
        if ( $line =~ /ExpressSM/ ) {
            debug( "changing ExpressSM to ExpressSM_WC, etc..." );
            #
            # Change *just* the first occurrence of ExpressSM to ExpressSM
            #
            $line =~ s/ExpressSM,/ExpressSM_WC,/;
            $line =~ s/ExpeditedSM,/ExpeditedSM_WC,/;
            
            #
            # Change *just* the first occurence (which will now ignore the "WC")
            #
            $line =~ s/ExpressSM,/ExpressSM_EC,/;
            $line =~ s/ExpeditedSM,/ExpeditedSM_EC,/;
            
            #
            # Remove the space in "Express Plus"
            #
            $line =~ s/Express PlusSM/ExpressPlusSM/;
        }
        print NEW_ZONE_FILE $line;
    }
    
    flock(     ZONE_FILE,         LOCK_UN    ) or logdie $@;
    close(     ZONE_FILE                 ) or logdie $@;
    flock(    NEW_ZONE_FILE,     LOCK_UN    ) or logdie $@;
    close(    NEW_ZONE_FILE             ) or logdie $@;
    copy(     $file2,         $file     ) or logdie $@;
    unlink( $file2                     ) or logdie $@;

    return;
}

=item * rename_tables_that_start_with_numbers

=cut

sub rename_tables_that_start_with_numbers
{
    my $path = shift;
    trace "( $path )";
    
    $_ = $path;
    my $new_file = $_;
    
    my ( $dir, $file ) = Business::Shipping::Util::split_dir_file( $path );
    
    if ( $file =~ /^\d/ ) {
        $new_file = "$dir/a_$file";
        debug( "renaming $path => $new_file" );
        rename( $path, $new_file );
    }
    
    return $new_file;
}

=item * rename_tables_that_have_a_dash

=cut

sub rename_tables_that_have_a_dash
{
    my $path = shift;
    trace "( $path )";
    
    $_ = $path;
    my $new_file = $_;
    
    my ( $dir, $file ) = Business::Shipping::Util::split_dir_file( $path );
    
    if ( $file =~ /\-/ ) {
        $file =~ s/\-/\_/g;
        $new_file = "$dir/$file";
        debug( "renaming $path => $new_file" );
        rename( $path, $new_file );
    }
    
    return $new_file;
}

=item * auto_update

=cut

sub auto_update
{
    my ( $self ) = @_;
    $self->update( 1 );
    $self->do_update();
}

=item * do_update

=cut

sub do_update
{
    my ( $self ) = @_;
    
    if ( $self->update ) {
        $self->download( 1 );
        $self->unzip( 1 );
        $self->convert( 1 );
    }
    
    $self->do_download()         if $self->download;
    $self->do_unzip()             if $self->unzip;
    $self->do_convert_data()    if $self->convert;
    
    return;
}

=item * get_fh( $filename )

=cut

sub get_fh
{
    my ( $filename ) = @_;

    my $file_handle;
    open $file_handle, "$filename" 
        || carp "could not open file: $filename.  Error: $!";
    
    return $file_handle;
}

=item * close_fh( $file_handle )

=cut

sub close_fh
{
    my ( $file_handle ) = @_;
    
    close $file_handle;
    
    return;
}

=head1 AUTHOR

Dan Browning, C<< <db@kavod.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-business-shipping-datatools@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2004 Dan Browning, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Business::Shipping::DataTools

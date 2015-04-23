#!perl
use strict;
use warnings;

use constant DEFAULT_INPUT_FILE => '../copshot.csv';

use IO::File;
use Date::Manip::Date;
use Text::CSV;
use Time::HiRes qw(usleep);

use Geo::Coder::Google;

# Where is our input data file?
my $input_file;
{
  while (1) {
     print "Where is your data file? [", DEFAULT_INPUT_FILE, "] ";
     chomp($input_file = <STDIN>);
     $input_file ||= DEFAULT_INPUT_FILE;
     if (! -e $input_file) {
	print "$input_file doesn't exist...\nplease try again.\n\n";
     }else{
	last;
     }
  }
}

# Our output data file just includes _latlong at the end.
(my $output_file = $input_file) =~ s/(.*)(\..*)/$1.'_complete'.$2/e;

# Initialize our Objects
my $csv = Text::CSV->new({binary => 1, eol => "\n"}) or
		die "can't use CSV: ", Text::CSV->error_diag();

my $date = Date::Manip::Date->new();
my $geocoder = Geo::Coder::Google->new(apiver => 3);

# Get Our Files ready
my $in = IO::File->new($input_file, O_RDONLY) or
	die "can't define input file: $!";
my $out = IO::File->new($output_file, O_WRONLY | O_APPEND | O_CREAT) or
	die "can't define output file: $!";

# IF the output_file exists - how many lines have been processed?
my $lines = -e $output_file ? (split /\s+/, `wc -l $output_file`)[1] : 0;

#open (my $in, '<', INPUT_FILE) or die "can't open: ", INPUT_FILE, ": $!";
#open (my $out, '>>', OUTPUT_FILE) or die "can't open: ", OUTPUT_FILE, ": $!";

# Print out our header
     my $header = $csv->getline($in);

     my ($date_col) = grep { $header->[$_] =~ /Date/ } 0..$#$header;

     # we need the address, city, state and to calculate the lat and long what
     #   are the column numbers associated with each?
     my @cols;
     {
       # we need the order of State, City and Address for our loc
       my $idx = 0;
       ($cols[0]) = grep { $header->[$_] =~ /State/ } 0..$#$header;
       ($cols[1]) = grep { $header->[$_] =~ /City/  } 0.. $#$header;
       ($cols[2]) = grep { $header->[$_] =~ /Address/ } 0..$#$header;
     }

     # clean up our headers
     for (0..$#$header) {
	 $header->[$_] = lc($header->[$_]);		   # lowercase
	 if ($header->[$_] =~ /\b(date|city|address)\b/) { # date city address (one word)
	    $header->[$_] = $1;
	 }else{
	    $header->[$_] =~ s/#\s*//g;		           # remove # symbols
	    $header->[$_] =~ s/.*\b(incident)\b.*/$1/;     # incident characteristics? seriously?
	 }
	 $header->[$_] =~ s/^\s+|\s+$//g;	           # beg / end spaces
	 $header->[$_] =~ s/\s+/_/g;		           # multiple words contain underscore now
     }

     push(@$header, ("postalcode", "display_address", "latitude", "longitude"));

     $csv->print($out, $header) if !$lines;

     while (my $row = $csv->getline($in)) {
	   next if $. < $lines;

	   # reformat the date column
	   {
	     $date->parse($row->[$date_col]);
	     $row->[$date_col] = $date->printf("%Y-%m-%d");
	   }

	   # gather up our location
	   {
	     my @loc = latlng(map $row->[$_], @cols); # State, City, Address -> formatted address, lat, lng

	     use Data::Dumper;
	     warn "LOC: ", Dumper(\@loc);
     	     push(@$row, @loc);
	   }

	   $csv->print($out, $row);
     }

sub latlng {
    sleep(1);

    my ($state, $city, $address) = @_;

    my $location;
    eval {$location = $geocoder->geocode(location => $address .', '. $city. ', '. $state) };
    if ($@ =~ /ZERO_RESULTS/) {
	return ('','','');
    }elsif ($@) {
	die "LOC ERROR: $@ ", Dumper($location);
    }

    my $zipcode;
    {
      for my $entry (@{$location->{address_components}}) {
	  next unless $entry->{types}->[0] eq 'postal_code';
	  $zipcode = $entry->{short_name};
	  last;
      }
      $zipcode ||= '';
    }

($zipcode, $location->{formatted_address}, map($location->{geometry}->{location}->{$_}, qw/lat lng/))
}

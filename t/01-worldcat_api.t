# vi:syntax=perl

use strict;
use warnings;
use lib qw(lib);
use local::lib qw(local);

use Test::Deep;
use Test::Fatal;
use Test::More;
use WorldCat::API;

SPECS: {
  use constant VALID_RECORD   => '829428';
  use constant INVALID_RECORD => '999999999';

  use constant CONTROLFIELD_SPEC => {
    content => re('.*'),
    tag     => re('^\d+$'),
  };

  use constant SUBFIELD_SPEC => {
    code    => re('.+'),
    content => re('.*'),
  };

  use constant DATAFIELD_SPEC => {
    ind1     => re('.*'),
    ind2     => re('.*'),
    subfield => any(SUBFIELD_SPEC, array_each(SUBFIELD_SPEC)),
    tag      => re('^\d+$'),
  };

  use constant RECORD_SPEC => {
    leader       => re('.*'),
    xmlns        => 'http://www.loc.gov/MARC21/slim',
    controlfield => array_each(CONTROLFIELD_SPEC),
    datafield    => array_each(DATAFIELD_SPEC),
  };
}

subtest 'find_by_oclc_number returns a valid result' => sub {
  my $api = WorldCat::API->new;
  my $record = $api->find_by_oclc_number(VALID_RECORD);

  isa_ok $record, 'MARC::Record';
};

subtest 'find_by_oclc_number throws 401 on invalid authorization' => sub {
  my $api = WorldCat::API->new(secret => 'invalid');

  my $err = exception { $api->find_by_oclc_number(VALID_RECORD) };
  isa_ok $err, 'HTTP::Response';
  is $err->code, '401';
};

subtest 'find_by_oclc_number returns nil on 404' => sub {
  my $api = WorldCat::API->new;

  ok !$api->find_by_oclc_number(INVALID_RECORD);
};

done_testing;

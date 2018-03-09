use strict;
use warnings;
package WorldCat::API;

# ABSTRACT: Fetch MARC::Records from OCLC's WorldCat API

=pod

=head1 SYNOPSIS

  my $api = WorldCat::API->new(
    institution_id         => "...",
    principle_id           => "...",
    principle_id_namespace => "...",
    secret                 => "...",
    wskey                  => "...",
  );

  my $marc_record = $api->find_by_oclc_number("123") or die "Not Found!";

=head1 CONTRIBUTING

This project uses Dist::Zilla to set things up. You can run that directly or (more easily) by using Docker. For starters, create the build container:

  $ docker build -t worldcatapi .

The container contains Perl, cpanm, dzil, and all of the build dependencies. Shell into it to use it as a dev environment:

  $ docker run --volume="$PWD:/app" --entrypoint=/bin/bash worldcatapi

The "volume" flag syncs your local directory into the container, allowing you to develop interactively. That also means that if you build the app within the container, the build products will be reflected on your host machine:

  $ docker run --volume="$PWD:/app" worldcatapi build
  $ ls -l
  …
  WorldCat-API-1.002
  WorldCat-API-1.002.tar.gz
  …

=head1 TESTING

To test, you must set (staging!) API credentials in the container environment. An easy solution is to add them to a .env file at the root of the project, which you can load with Docker:

  $ cat <<EOF > .env
  WORLDCAT_API_INSTITUTION_ID="..."
  WORLDCAT_API_PRINCIPLE_ID="..."
  WORLDCAT_API_PRINCIPLE_ID_NAMESPACE="..."
  WORLDCAT_API_SECRET="..."
  WORLDCAT_API_WSKEY="..."
  EOF
  $ docker run --volume="$PWD:/app" --env-file=.env worldcatapi test

=cut

use feature qw(say);

use Moo;
use Carp qw(croak);
use Digest::SHA qw(hmac_sha256_base64);
use HTTP::Request;
use HTTP::Status qw(:constants);
use LWP::UserAgent;
use MARC::Record;
use Math::Random::Secure qw(irand);
use Readonly;
use WorldCat::MARC::Record::Monkeypatch;
use XML::Simple qw(XMLin);

Readonly my $DEFAULT_RETRIES => 5;

sub _from_env {
  my ($attr) = @_;
  return $ENV{uc "WORLDCAT_API_$attr"} // die "Attribute $attr is required";
}

has institution_id => (
  is => 'ro',
  required => 1,
  default => sub { _from_env('institution_id') },
);

has principle_id => (
  is => 'ro',
  required => 1,
  default => sub { _from_env('principle_id') },
);

has principle_id_namespace => (
  is => 'ro',
  required => 1,
  default => sub { _from_env('principle_id_namespace') },
);

has secret => (
  is => 'ro',
  required => 1,
  default => sub { _from_env('secret') },
);

has wskey => (
  is => 'ro',
  required => 1,
  default => sub { _from_env('wskey') },
);

sub _query_param {
  return "$_[0]=\"$_[1]\"";
}

# OCLC returns encoding=UTF-8, format=MARC21+xml.
sub find_by_oclc_number {
  my ($self, $oclc_number, %opts) = @_;

  my $retries = $opts{retries} // $DEFAULT_RETRIES;

  # Fetch the record with retries and exponential backoff
  my $res;
  my $ua = $self->_new_ua;
  for my $try (0..($retries - 1)) {
    $res = $ua->get("https://worldcat.org/bib/data/$oclc_number");
    say "Got HTTP Response Code: @{[$res->code]}";

    last if not $res->is_server_error; # only retry 5xx errors
    sleep 2 ** $try;
  }

  # Return MARC::Record on success
  if ($res->is_success) {
    my $xml = XMLin($res->decoded_content)->{entry}{content}{record};
    return MARC::Record->new_from_marc21xml($xml);
  }

  # Return nil if record not found
  return if $res->code eq HTTP_NOT_FOUND;

  # An error occurred, throw the response
  croak $res;
}

# Generate the authorization header. It's complicated; see the docs:
#
#   https://www.oclc.org/developer/develop/authentication/hmac-signature.en.html
#   https://github.com/geocolumbus/hmac-language-examples/blob/master/perl/hmacAuthenticationExample.pl
sub _create_auth_header {
  my ($self) = @_;

  my $signature = $self->_create_signature;

  return 'http://www.worldcat.org/wskey/v2/hmac/v1 ' . join(q{,},
    _query_param(clientId      => $self->wskey),
    _query_param(principalID   => $self->principle_id),
    _query_param(principalIDNS => $self->principle_id_namespace),
    _query_param(nonce         => $signature->{nonce}),
    _query_param(signature     => $signature->{value}),
    _query_param(timestamp     => $signature->{timestamp}),
  );
}

sub _create_signature {
  my ($self, %opts) = @_;

  my $nonce = $opts{nonce} || sprintf q{%x}, irand;
  my $timestamp = $opts{timestamp} || time;

  my $signature = hmac_sha256_base64(join(qq{\n},
    $self->wskey,
    $timestamp,
    $nonce,
    q{}, # Hash of the body; empty because we're just GET-ing
    "GET", # all-caps HTTP request method
    "www.oclc.org",
    "443",
    "/wskey",
    q{}, # query params
  ), $self->secret) . q{=};

  return {
    value     => $signature,
    nonce     => $nonce,
    timestamp => $timestamp,
  };
}

sub _new_ua {
  my ($self) = @_;

  my $ua = LWP::UserAgent->new;
  $ua->default_header(Accept => q{application/atom+xml;content="application/vnd.oclc.marc21+xml"});
  $ua->default_header(Authorization => $self->_create_auth_header);
  return $ua;
}

1;

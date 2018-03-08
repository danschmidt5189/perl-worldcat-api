use strict;
use warnings;
package WorldCat::MARC::Record::Monkeypatch;

# ABSTRACT: Monkeypatch MARC::Record to add useful methods

=pod

=head1 SYNOPSIS

  use feature 'say';
  use MARC::Record;
  use WorldCat::MARC::Record::Monkeypatch;

  my $marc_record = MARC::Record->new_from_marc21xml($xmlobj);
  say $marc_record->oclc_number;

=cut

use feature qw(say);
use Time::Piece;

# Specs:
#   https://www.oclc.org/support/services/batchload/controlnumber.en.html
#
# NOTE(dcschmidt): Definitely incomplete; needs more tests/sample data.
sub MARC::Record::oclc_number {
  my ($self) = @_;

  if (my $f001 = $self->field('001')) {
    if ($f001->data =~ qr/^(ocm|ocn|on\.)(\d+)$/) {
      return int $2;
    }
  }

  if (my $f019 = $self->field('019')) {
    return int $f019->data;
  }

  if (my $f035a = $self->subfield('035', 'a')) {
    if ($f035a->data =~ qr/OCoLC.(\d+)$/) {
      return int $1;
    }
  }
}

sub MARC::Record::new_from_marc21xml {
  my ($class, $raw) = @_;

  my $marc_rec = "$class"->new;
  $marc_rec->leader($raw->{leader});

  # Add control fields
  for my $cfield (@{$raw->{controlfield}}) {
    $marc_rec->append_fields(MARC::Field->new(
      $cfield->{tag},
      $cfield->{content},
    ));
  }

  # Add data fields
  for my $dfield (@{$raw->{datafield}}) {
    my $content   = $dfield->{content};
    my $ind1      = $dfield->{ind1};
    my $ind2      = $dfield->{ind2};
    my $subfields = $dfield->{subfield};
    my $tag       = $dfield->{tag};

    # Normalize subfields to an array of hashrefs
    my %subfields = map { @{$_}{qw(code content)} } @{
      ref $subfields eq 'HASH' ? [$subfields] : $subfields
    };

    $marc_rec->append_fields(MARC::Field->new($tag, $ind1, $ind2, %subfields));
  }

  return $marc_rec;
}

1;

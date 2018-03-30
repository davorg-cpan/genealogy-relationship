=head1 NAME

Genealogy::Relationship - calculate the relationship between two people

=head1 SYNOPSIS

    use Genealogy::Relationship;
    use Person; # Imaginary class modelling people

    my $rel = Genealogy::Relationship->new;

    my $grandfather = Person->new( ... );
    my $father      = Person->new( ... );
    my $me          = Person->new( ... );
    my $aunt        = Person->new( ... );
    my $cousin      = Person->new( ... );

    my $common_ancestor = $rel->get_most_recent_common_ancestor(
      $me, $cousin,
    );
    say $common_ancestor->name; # Grandfather's name

    say $rel->get_relationship($me, $grandfather); # Grandson
    say $rel->get_relationship($grandfather, $me); # Grandfather

    say $rel->get_relationship($father, $cousin);  # Uncle
    say $rel->get_relationship($cousin, $father);  # Niece

=head1 DESCRIPTION



=cut

package Genealogy::Relationship;

use Moo;
use Types::Standard qw[Str HashRef];
use List::Util qw[first];
use List::MoreUtils qw[firstidx];

has parent_field_name => (
  is => 'ro',
  isa => Str,
  default => 'parent',
);

has identifier_field_name => (
  is => 'ro',
  isa => Str,
  default => 'id',
);

has gender_field_name => (
  is => 'ro',
  isa => Str,
  default => 'gender',
);

has relationship_table => (
  is => 'ro',
  isa => HashRef,
  builder => '_build_relationship_table',
);

sub _build_relationship_table {
  return {
    m => [
    [ undef, 'Father', 'Grandfather', 'Great grandfather', 'Great, great grandfather' ],
    ['Son', 'Brother', 'Uncle', 'Great uncle', 'Great, great uncle' ],
    ['Grandson', 'Nephew', 'First cousin', 'First cousin once removed', 'First cousin twice removed' ],
    ['Great grandson', 'Great nephew', 'First cousin once removed', 'Second cousin', 'Second cousin once removed'],
    ['Great, great grandson', 'Great, great nephew', 'First cousin twice removed', 'Second cousin once removed', 'Third cousin',],
    ],
    f => [
    [ undef, 'Mother', 'Grandmother', 'Great grandmother', 'Great, great grandmother' ],
    ['Daughter', 'Sister', 'Aunt', 'Great aunt', 'Great, great aunt' ],
    ['Granddaughter', 'Niece', 'First cousin', 'First cousin once removed', 'First cousin twice removed'],
    ['Great granddaughter', 'Great niece', 'First cousin once removed', 'Second cousin', 'Second cousin once removed'],
    ['Great, great granddaughter', 'Great, great niece', 'First cousin twice removed', 'Second cousin once removed', 'Third cousin',],
    ],
  }
}

sub most_recent_common_ancestor {
  my $self = shift;
  my ($person1, $person2) = @_;

  # Are they the same person?
  return $person1 if $person1->id == $person2->id;

  my @ancestors1 = ($person1, $self->get_ancestors($person1));
  my @ancestors2 = ($person2, $self->get_ancestors($person2));

  for my $anc1 (@ancestors1) {
    for my $anc2 (@ancestors2) {
      return $anc1 if $anc1->id == $anc2->id;
    }
  }

  die "Can't find a common ancestor.\n";
}

sub get_ancestors {
  my $self = shift;
  my ($person) = @_;

  my @ancestors = ();

  while (defined ($person = $person->parent)) {
    push @ancestors, $person;
  }

  return @ancestors;
}

sub get_relationship {
  my $self = shift;
  my ($person1, $person2) = @_;

  my ($x, $y) = $self->get_relationship_coords($person1, $person2);

  return $self->relationship_table->{$person1->gender}[$x][$y];
}

sub get_relationship_coords {
  my $self = shift;
  my ($person1, $person2) = @_;

  # If the two people are the same person, then return (0, 0).
  return (0, 0) if $person1->id == $person2->id;

  my @ancestors1 = ($person1, $self->get_ancestors($person1));
  my @ancestors2 = ($person2, $self->get_ancestors($person2));

  for my $i (0 .. $#ancestors1) {
    for my $j (0 .. $#ancestors2) {
      return ($i, $j) if $ancestors1[$i]->id == $ancestors2[$j]->id;
    }
  }

  die "Can't work out the relationship.\n";
}

1;

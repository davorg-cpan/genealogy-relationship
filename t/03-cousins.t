use strict;
use warnings;

use Test::More;
use Test::Exception;
use FindBin '$Bin';
use Genealogy::Relationship;
use lib "$Bin/lib";
use TestPerson;

my @generations;

push @generations, TestPerson->new(
  id => 1,
  name => 'Person 1',
  gender => 'm',
);

my @expected = (
  [ undef, undef ],
  [ 'Brother',        'Brother'],
  [ 'First cousin',   'Uncle' ],
  [ 'Second cousin',  'Great uncle' ],
  [ 'Third cousin',   'Great, great uncle' ],
  [ 'Fourth cousin',  'Great, great, great uncle' ],
  [ 'Fifth cousin',   'Great, great, great, great uncle' ],
  [ 'Sixth cousin',   'Great, great, great, great, great uncle' ],
  [ 'Seventh cousin', 'Great, great, great, great, great, great uncle' ],
  [ 'Eighth cousin',  'Great, great, great, great, great, great, great uncle' ],
  [ 'Ninth cousin',   'Great, great, great, great, great, great, great, great uncle' ],
);

for my $g (1 .. 10) {
  my @parents;
  if (ref $generations[-1] eq 'ARRAY') {
    @parents = @{$generations[-1]};
  } else {
    @parents = ($generations[-1]) x 2;
  }

  my @ids = ($parents[0]->id + 1, $parents[0]->id + 100);

  my $p1 = TestPerson->new(
    id => $ids[0],
    name => "Person $ids[0]",
    parent => $parents[0],
    gender => 'm',
  );

  my $p2 = TestPerson->new(
    id => $ids[1],
    name => "Person $ids[1]",
    parent => $parents[1],
    gender => 'm',
  );

  push @generations, [$p1, $p2];
}

my $rel = Genealogy::Relationship->new;

for (1 .. 10) {
  is($rel->get_relationship(@{$generations[$_]}), $expected[$_][0]);
  is($rel->get_relationship($generations[1][0], $generations[$_][1]), $expected[$_][1]);
}

is($rel->get_relationship($generations[8][0], $generations[10][1]),
   'Seventh cousin twice removed');
is($rel->get_relationship($generations[3][0], $generations[9][1]),
   'Second cousin six times removed');
is($rel->get_relationship($generations[9][0], $generations[9][1]),
   'Eighth cousin');
is($rel->get_relationship($generations[8][0], $generations[5][1]),
   'Fourth cousin three times removed');

done_testing;
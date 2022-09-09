#!/usr/bin/env perl
package dotplot {
  use v5.32;
  use feature qw/signatures say/;
  use warnings; use strict;
  use Class::Struct;
  struct('TrialInfo', { i => '$', iti_xnorm => '$', dot_xnorm => '$', diff=>'$', dot_pos=>'$',
                        iti_seq=>'@', dot_seq=>'@', cur=>'$' } );
  my @XPOS=();    # array of X_Corrected_Gaze
  my @TRIALS=();  # array of TrialInfo
  
  my %CFACT=( 'iti'=>1, 'dot'=>2,'exp'=>3,'diff'=>4 );

  # X_Corrected_Gaze is 6th field. 5th index
  # TotalTime is 1
  sub add_data { push @XPOS, (split /\s+/)[5]; }
  
  sub dot2arr($p) { return ($p+1)/2; }
  sub dot2diff($p) { return $p; }

  sub norm {
      my @a = sort(@_);
      my $midi=int($#a/2);
      return $a[$midi];
  }
  
  # iti happens first, then dot event
  # line like:
  #stat tottime  tr ev  pos
  #  12 1.894626 1 dot -0.2
  sub add_interval{
      my @line  = split /\s+/;
      my $norm = norm(@XPOS);
      my $last =  $TRIALS[$#TRIALS];
  
      # iti has no additional info: status time msg==iti
      if ($line[2] =~ m/iti/) {
          if($#TRIALS>-1){
              my $iti = $last->iti_xnorm();
              $last->diff($norm - $iti) if $iti;
              $last->dot_xnorm($norm);
          }
          push @TRIALS, new TrialInfo(cur=>'iti');
      } elsif($#line>2 && $line[3] =~ /dot/) {
          my ($trial, $dot_pos) = @line[2,4];
          $last->cur("dot");
          $last->iti_seq([@XPOS]);
          $last->iti_xnorm($norm);
          $last->i($trial);
          $last->dot_pos(dot2diff($dot_pos));
      } else {
       # okay for the last iti (if it exists) to not get counted
       say STDERR "# unknown msg: $line[2]: @line" unless $line[2] eq "END";
     }

     @XPOS=();
  }
  
  sub MAIN{
   #open my $fh, "<", "./sub-short" or die $!;
   open my $fh, "<", "/tmp/x.txt" or die $!;
   #my $fh = *STDIN;
   while($_=<$fh>){
    chomp;
    if(m/^10/) { add_data; }
    elsif(m/^12/){ add_interval; }
   }
  
   # 
   foreach my $t (@TRIALS){
       say join "\t", $t->i, $t->dot_xnorm, "dot", $CFACT{"dot"} if $t->dot_xnorm;
       say join "\t", $t->i, $t->dot_pos,   "exp", $CFACT{"exp"} if $t->dot_pos;
       say join "\t", $t->i, $t->iti_xnorm, "iti", $CFACT{"iti"} if $t->iti_xnorm;
       say join "\t", $t->i, $t->diff, "diff", $CFACT{"diff"} if $t->diff;
   }
  
   my $cur_trial = ($#TRIALS<0?0:($TRIALS[$#TRIALS]->i() or $TRIALS[$#TRIALS-1]->i()))||0;
   my $last = $TRIALS[$#TRIALS];
   my $cur_event = $last?$last->cur:"iti";

   # plot all iti if we're aready on dot (otherwise skipped)
   while ($last and my ($i,$v) = each @{$last->iti_seq}){
      say join("\t", $cur_trial+($i/120), $v, "iti", $CFACT{"iti"});
   }
   # plot whatever we're on
   while (my ($i,$v) = each @XPOS){
      say join("\t", $cur_trial+($i/120), $v, $cur_event, $CFACT{$cur_event});
   }
  }

}

dotplot->MAIN() unless (caller);

1;
__END__

=head1

=cut

use Test2::V0;
use Test::Exception;
require 'dotplot.pl';

is dotplot::norm(1,2,3,4,5), 3, "median norm";
is dotplot::norm((1,4,5,2,3)), 3, "median norm";

is dotplot::dot2arr(-1), 0, "dot left";
is dotplot::dot2arr(-.5), .25, "dot near left";
is dotplot::dot2arr(.5), .75, "dot near right";
is dotplot::dot2arr(1), 1, "dot right";

done_testing;

#!/usr/bin/perl

eval 'exec /usr/bin/perl  -S $0 ${1+"$@"}'
    if 0; # not running under some shell

################################################################
#
#   WARNING:  THIS IS A ***BETA*** RELEASE OF Net::FullAuto
#
#   Net::FullAuto is powerful network process automation
#   software that has been in un-released development for
#   more than eleven years. For this reason, you may find
#   it to be useful for many process automation projects.
#   Because it has been worked on for so long, it may appear
#   to work well, and pass a number of non-intensive tests.
#
#   DO NOT - I REPEAT - DO !!NOT!! USE IN A PRODUCTION
#   ENVIRONMENT! This is newly released software that has
#   not had the benefit of wide exposure - and the presence
#   of here-to-now undetected bugs and design flaws is a
#   virtual certainty. DO NOT USE IN IN/FOR A PROCESS WHERE
#   DATA LOSS IS UNRECOVERABLE. DO NOT USE IN/FOR A PROCESS
#   WHERE DATA INTEGRITY IS CRITICAL. DO NOT USE IN/FOR A
#   PROCESS THAT IS TIME SENSITIVE, UNMONITORED, OR
#   PERSISTENCE CRITICAL. DO NOT USE THIS SOFTWARE WITHOUT
#   ANOTHER METHOD FOR RUNNING THE PROCESS YOU WISH TO
#   AUTOMATE WITH Net::FullAuto. DO NOT USE IN/FOR A PROCESS
#   WHERE FAILURE OF "ANY KIND" IS UNACCEPTABLE.
#
################################################################

use strict;
use warnings;

BEGIN {

   my $edit=0;my $earg='';my $cnt=-1;
   my $VERSION=0;my $version=0;
   our $planarg=0;our $cronarg=0;
   foreach my $arg (@ARGV) {
      if ($arg=~/^--ed*i*t*$/) {
         $edit=1;
         if ($ARGV[$cnt+1]!~/^--/) {
            $earg=$ARGV[$cnt+1];last;
         } else { last }
      } elsif ($arg=~/^-[a-df-zA-Z]*e\s*(.*)/) {
         $earg=$1;
         $edit=1;
         chomp $earg; 
         $earg='' if $earg=~/^\s*$/;
      } elsif ($arg=~/^-[a-df-zA-UW-Z]*V/ ||
               $arg=~/^--VE*R*S*I*O*N*$/) {
         $VERSION=1;
      } elsif ($arg=~/^-[a-df-uw-zA-Z]*v/ ||
               $arg=~/^--VE*R*S*I*O*N*$/) {
         $version=1;
      } elsif ($arg=~/^--plan$/) {
         $planarg=1;
      } elsif ($arg=~/^--cron$/) {
         $cronarg=1;
      }
      $cnt++;
   }
   if ($edit) {
      require Net::FullAuto::FA_Core;
      &Net::FullAuto::FA_Core::edit($earg);
      exit;
   } elsif ($VERSION) {
      require Net::FullAuto::FA_Core;
      &Net::FullAuto::FA_Core::VERSION();
      exit;
   } elsif ($version) {
      require Net::FullAuto::FA_Core;
      &Net::FullAuto::FA_Core::version();
      exit;
   }

   our $fa_custom_code='fa_code.pm';
   our $fa_menu_config='fa_menu.pm';

}

use Net::FullAuto;

fa_login;

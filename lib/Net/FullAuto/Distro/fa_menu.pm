package fa_menu;

################################################################
#
#   WARNING:  THIS IS A ***BETA*** RELEASE OF Net::FullAuto
#
#   Net::FullAuto is powerful network process automation
#   software that has been in un-released development for
#   more than seven years. For this reason, you may find
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
require Exporter;
our @ISA = qw(Exporter);
our $VERSION = 1.00;

#################################################################
##  Do NOT alter code ABOVE this block.
#################################################################
##  -------------------------------------------------------------
##  ADD CUSTOM MENU BLOCKS HERE:
##  -------------------------------------------------------------

our @EXPORT = qw(%Menu_1 %Menu_2 %Menu_5 %Menu_15 %Menu_30);

my @PortalApps=(
   'Member-Employer-Framework','Provider (Physician)',
   'Broker','Broker-Employer','Broker Rate Tool',
);

my @StaticAppDestinations=('ProdWeb01','ProdWeb02','ProdWeb03','ProdWeb04',
                           'ProdWeb05','ProdWeb06','ProdWeb07','ProdWeb08',
                           'ProdWeb09','ProdWeb10');

our %Menu_1=(

   Label  => 'Menu_1',
   Item_1 => {

      Text   => "Deploy (Non-Secure Static) Build",
      Convey => "Non-Secure",
      Result => \%Menu_2

   },
   Item_2 => {

      Text   => "Deploy Web Build",
      Convey => "Web",
      Result => \%Menu_5

   },

   Item_3 => {

      Text   => "Deploy Hospital (Facility) Build",
      Convey => "Hospital (Facility)",
      Result => \%Menu_30

   },

   Select => 'One',
   Banner => "\n   Choose a Task to Perform :"
);

our $start_menu_ref=\%Menu_1;

our %Menu_2=(
   
   Label  => 'Menu_2',
   Item_1 => {

      Text   => "Deploy ]P[ FROM ]Convey[",
      Convey => [ 'Teamsite','Clearcase' ],
      Result => \%Menu_15

   },
   Select => 'One',
   Banner => "\n   Choose a Task to Perform :"
);

our %Menu_30=(

   Label  => 'Menu_30',
   Item_1 => {

      Text   => "Deploy ]P[ FROM Development",
      Convey => "Development",
      Result => \%Menu_31

   },
   Item_2 => {

      Text   => "Deploy ]P[ FROM SOURCE CONTROL",
      Convey => ["SOURCE CONTROL"],
      Result => \%Menu_32

   },
   Select => 'One',
   Banner => "\n   Choose a Task to Perform :"
);

our %Menu_5=(

   Label  => 'Menu_5',
   Item_1 => {

      Text   => "Deploy Web TO ]Convey[",
      Convey => \@StaticAppDestinations,
      Result => "&DeployStaticApp(\"]S[\",'Web')"

   },
   Select => 'One',
   Display => 7,
   Banner => "\n   Choose a Task to Perform :"
);

our %Menu_15=(

   Label  => 'Menu_15',
   Item_1 => {

      Text   => "Deploy Non-Secure FROM ]P[ TO \"]C[\"",
      Convey => \@StaticAppDestinations,
      Result => "&hello_world(\"]S[\",'Non-Secure')"
      #Result => "&DeployStaticApp(\"]S[\",'Non-Secure')"

   },
   Select => 'One',
   Display => 7,
   Banner => "\n   Choose the Host to Deploy MicroSite TO :"
);

########### END OF MENUS ########################
## Important! The '1' at the Bottom is NEEDED!
1;

package fa_menu_demo;

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

#################################################################
##  Do NOT alter code ABOVE this block.
#################################################################
##  -------------------------------------------------------------
##  ADD CUSTOM MENU BLOCKS HERE:
##  -------------------------------------------------------------

our %Menu_1=(

   Label  => 'Menu_1',
   Item_1 => {

      Text   => "HELLO WORLD TEST",
      Result => "&hello_world()",

   },
   Item_2 => {

      Text   => "HOWDY WORLD TEST",
      Result => "&howdy_world()",

   },
   Item_3 => {

      Text   => "Image Magick",
      Result => "&image_magick()",

   },

   Select => 'One',
   Banner => "\n   Choose a Task to Perform :"
);

our $start_menu_ref=\%Menu_1;

########### END OF MENUS ########################
## Important! The '1' at the Bottom is NEEDED!
1;

package fa_menu_demo;

### OPEN SOURCE LICENSE - GNU PUBLIC LICENSE Version 3.0 #######
#
#    Net::FullAuto - Powerful Network Process Automation Software
#    Copyright (C) 2000-2014  Brian M. Kelly
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but **WITHOUT ANY WARRANTY**; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
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
   Item_4 => {

      Text   => "Menu Demo",
      Result => "&menu_demo()",

   },

   Select => 'One',
   Banner => "\n   Choose a Task to Perform :"
);

our $start_menu_ref=\%Menu_1;

########### END OF MENUS ########################
## Important! The '1' at the Bottom is NEEDED!
1;

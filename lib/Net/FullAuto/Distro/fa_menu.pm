package fa_menu;

### OPEN SOURCE LICENSE - GNU PUBLIC LICENSE Version 3.0 #######
#
#    Net::FullAuto - Powerful Network Process Automation Software
#    Copyright (C) 2011  Brian M. Kelly
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

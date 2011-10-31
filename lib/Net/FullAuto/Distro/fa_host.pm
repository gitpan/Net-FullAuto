package fa_host;

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
require Exporter;
our @ISA     = qw(Exporter);
our @EXPORT  = qw(@Hosts);

our @Hosts = (
#################################################################
##  Do NOT alter code ABOVE this block.
#################################################################
##  -------------------------------------------------------------
##  ADD HOST BLOCKS HERE:
##  -------------------------------------------------------------

       {
          'IP'             => '198.201.10.1',
          'HostName'       => 'computer_one',
          'Label'          => 'REMOTE COMPUTER ONE',
          #'LoginID'        => 'bkelly',
          'LogFile'        => "/tmp/FAlog${$}d".
                              "$Net::FullAuto::FA_Core::invoked[2]".
                              "$Net::FullAuto::FA_Core::invoked[3].txt",
       },
       {
          'IP'             => '198.201.10.2',
          'HostName'       => 'computer_two',
          'Label'          => 'REMOTE COMPUTER TWO',
          'LogFile'        => "/tmp/FAlog${$}d".
                              "$Net::FullAuto::FA_Core::invoked[2]".
                              "$Net::FullAuto::FA_Core::invoked[3].txt",
       },
       {
          'IP'             => '10.10.10.10',
          'Label'          => 'Laptop',
          'LoginID'        => 'KB06606',
          'LogFile'        => "/tmp/FAlog${$}d".
                              "$Net::FullAuto::FA_Core::invoked[2]".
                              "$Net::FullAuto::FA_Core::invoked[3].txt",
       },
       {
          'IP'             => '10.10.10.10',
          'Label'          => 'Solaris',
          'LoginID'        => 'opens',
          'sshport'        => '2223',
          'LogFile'        => "/tmp/FAlog${$}d".
                              "$Net::FullAuto::FA_Core::invoked[2]".
                              "$Net::FullAuto::FA_Core::invoked[3].txt",
       },
       {
          'IP'             => '10.10.10.10',
          'Label'          => 'Ubuntu',
          'LoginID'        => 'reedfish_laptop',
          'sshport'        => '2222',
          'LogFile'        => "/tmp/FAlog${$}d".
                              "$Net::FullAuto::FA_Core::invoked[2]".
                              "$Net::FullAuto::FA_Core::invoked[3].txt",
       },


#################################################################
##  Do NOT alter code BELOW this block.
#################################################################
);

## Important! The '1' at the Bottom is NEEDED!
1;

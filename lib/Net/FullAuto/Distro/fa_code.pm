package fa_code;

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
our $test=0;our $timeout=0;
require Exporter;
#use threads ();
#use Thread::Queue;
our @ISA = qw(Exporter Net::FullAuto::FA_Core);
use Net::FullAuto::FA_Core;

#################################################################
##  Do NOT alter code ABOVE this block.
#################################################################

##  -------------------------------------------------------------
##  SET CONFIGURATION PARAMETERS HERE:
##  -------------------------------------------------------------

############  TEST TOGGLE  ###################

$test=1; # comment-out this line for Production mode

##############################################

############  LOG  TOGGLE  ###################
#$log=1; # comment-out this line to turn off Logging
##############################################

#----------  TEST PARAMETERS  ----------------

our $build_type= $test ? 'test' : '';
our $toggle_rootdir= $build_type ? 'tmp' : 'usr'; 
our $toggle_staticdir= $build_type ? 'tmp' : 'webfs';

#---------------------------------------------

############  SET TIMEOUT  ###################
$timeout=90;
##############################################

######## SET PASSWORD FILE LOCATION  #########
if ($^O eq 'cygwin') {
   $passwd_file_loc="/passwds_ms";
} else {
   $passwd_file_loc="/passwds_ux"
}
##############################################

#####  SET EMAIL AUTOMATION SETTINGS  ########
%email_addresses=(
   'bkelly' => 'Brian.Kelly@fullautosoftware.net',
);
my $email_to=[
               ']USERNAME[',
               'Brian.Kelly@fullautosoftware.net',
             ];
#%email_defaults=(
#   Usage       => 'notify_on_error',
#   Mail_Method => 'smtp',
#   Mail_Server => 'mailserver.fullautosoftware.net',
#   Reply_To    => 'Brian.Kelly@fullautosoftware.net',
#   To          => $email_to,
#   From        => "$progname\@fullautosoftware.net"
#);
##############################################

##  -------------------------------------------------------------
##  WRITE "RESULT" SUBROUTINES HERE:
##  -------------------------------------------------------------


sub hello_world {

    #print "\nFIRST PARAMETER=$_[0]\n";
    #print "SECOND PARAMETER=$_[1]\n";
    my $hostname=$localhost->cmd('hostname');
    my $stdout='';
    my $stderr='';
    my $computer_zero='';
    my $computer_one='';
    ($computer_zero,$stderr)=connect_host('Zero'); # Connect to
                                        # Remote Host via ssh
    if ($stderr) {
       print "We Have an ERROR when attempting to connect to Zero! : $stderr\n";
    }

    if ($hostname eq 'bkelly-laptop') {
       $computer_one=connect_ssh('VB_Ubuntu'); # Connect to
                                            # Remote Host via ssh
    } else {
       $computer_one=connect_host('Ubuntu'); # Connect to
                                            # Remote Host via ssh
    }
    print "\nHELLO=",$localhost->cmd('echo "hello world"'),"\n";
    print "HOSTNAME=$hostname\n";
    print "HELLO WORLD\n";
    ($stdout,$stderr)=$computer_one->cmd('hostname');
    print "Ubuntu=$stdout\n";
    ($stdout,$stderr)=$computer_zero->cmd('hostname');
    print "Zero=$stdout\n\n";
    ($stdout,$stderr)=$computer_zero->cwd('/develop/deployment/dest');
    print "STDERR=$stderr<==\n" if $stderr;
    my $file='';
    ($file,$stderr)=$computer_zero->cmd('ls ID*');
    print "Zero File=$file<==\n\n";
    return unless $file;
    ($stdout,$stderr)=$computer_zero->get($file); # Get the File
    if ($stderr) {                                # Check Results
       print "We Have an ERROR! : $stderr\n";
    }
    ($stdout,$stderr)=$computer_one->cwd('/home/qa/import');
    print "STDERR=$stderr\n" if $stderr;
    ($stdout,$stderr)=$computer_one->put($file); # Get the File
    if ($stderr) {                               # Check Results
       print "We Have an ERROR! : $stderr\n";
    }
    ($stdout,$stderr)=$computer_one->cmd('ls');
    print $computer_one->{_hostlabel}->[0]," ls output:\n\n$stdout\n";
    ($stdout,$stderr)=$computer_one->cmd('pwd');
    print "CURDIR=$stdout\n\n" if $stdout;

}

sub remote_hostname {

    my ($computer_one,$stdout,$stderr);      # Scope Variables

    $computer_one=connect_ssh('REMOTE COMPUTER ONE'); # Connect to
                                             # Remote Host via ssh

    ($stdout,$stderr)=$computer_one->cmd('hostname');

    print "REMOTE ONE HOSTNAME=$stdout\n";

}

sub get_file_from_one {

   my ($computer_one,$stdout,$stderr);         # Scope Variables

   $computer_one=connect_reverse('REMOTE COMPUTER ONE'); # Connect
                                               # to Remote Host via
                                               # ssh *and* sftp

   ($stdout,$stderr)=$computer_one->cmd(
                     'echo test > test.txt');  # Run Remote Command

   ($stdout,$stderr)=$computer_one->cmd(
                     'zip /tmp/test test.txt');     # Run Remote Command

   if ($stderr) {                              # Check Results
      print "We Have an ERROR! : $stderr\n";
   } else {
      print "Output of zip command from Computer One:".
            "\n\n$stdout\n\n";
   }

   ($stdout,$stderr)=$computer_one->get(
                     '/tmp/test.zip');              # Get the File

   if ($stderr) {                              # Check Results
      print "We Have an ERROR! : $stderr\n";
   } else {
      print "Output of zip command from Computer One:".
            "\n\n$stdout\n\n";
   }

   ($stdout,$stderr)=$localhost->cmd(
                     'unzip test.zip');        # Run Local Command

   if ($stderr) {                              # Check Results
      print "We Have an ERROR! : $stderr\n";
   } else {
      print "Output of unzip command from Computer One:".
            "\n\n$stdout\n\n";
   }

}

########### END OF SUBS ########################

#################################################################
##  Do NOT alter code BELOW this block.
#################################################################

## Important! The '1' at the Bottom is NEEDED!
1

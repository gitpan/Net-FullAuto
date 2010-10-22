package Term::Menus;

#    Menus.pm
#
#    Copyright (C) 2000, 2001, 2002, 2003, 2004
#                  2005, 2006, 2007, 2008, 2010
#    by Brian M. Kelly. <Brian.Kelly@fullautosoftware.net>
#
#    You may distribute under the terms of the GNU General
#    Public License, as specified in the LICENSE file.
#    (http://www.opensource.org/licenses/gpl-license.php).
#
#    http://www.fullautosoftware.net/

## See user documentation at the end of this file.  Search for =head


$VERSION = '1.57';


use 5.006;

## Module export.
use vars qw(@EXPORT);
@EXPORT = qw(pick Menu);
## Module import.
use Exporter ();
use Config ();
our @ISA = qw(Exporter);
BEGIN {
   if (-e $Config{installprivlib}."/Module/Load/Conditional.pm") {
      $canload = sub {
         require $Config{installprivlib}."/Module/Load/Conditional.pm";
         return Module::Load::Conditional::can_load($_[0]);
      };
   } elsif (-e $Config{installsitelib}."/Module/Load/Conditional.pm") {
      $canload = sub {
         require $Config{installsitelib}."/Module/Load/Conditional.pm";
         return Module::Load::Conditional::can_load($_[0]);
      };
   } elsif (-e $Config{installvendorlib}."/Module/Load/Conditional.pm") {
      $canload = sub {
         require $Config{installvendorlib}."/Module/Load/Conditional.pm";
         return Module::Load::Conditional::can_load($_[0]);
      };
   } else {
      $canload = sub { return 0 };
   }
}

##############################################################
##############################################################
#
#  THIS BLOCK MARKED BY TWO LINES OF POUND SYMBOLS IS FOR
#  SETTINGS NEEDED BY THE MODULE   Net::FullAuto.  IF YOU ARE
#  USING   Term::Menus   OUTSIDE OF   Net::FullAuto,  YOU CAN
#  SAFELY IGNORE THIS SECTION. (That's 'ignore' - not 'remove')
#

BEGIN { ##  Begin  Net::FullAuto  Settings

   #####################################################################
   ####                                                              ###
   #### DEFAULT NAME OF  Net::FullAuto  menu_config_module_file IS:  ###
   ####                                                              ###
   #### ==> fa_menu.pm <==  If you rename the file, you must either  ###
   ####                                                              ###
   #### change the setting of $menu_config_module_file as well, or   ###
   #### set the $fa_menu_config variable in the BEGIN { } block      ###
   #### of the top level script invoking Net::FullAuto. (Advised)    ###
   #### the setting of $menu_config_module_file as well.             ###
   ####                                                              ###
   #####################################################################
                                                                     ###
   our $menu_config_module_file='fa_menu.pm';                        ###
                                                                     ###
   #####################################################################

   #####################################################################
   ####                                                              ###
   #### DEFAULT NAME OF  Net::FullAuto  custom_code_module_file IS:  ###
   ####                                                              ###
   #### ==> fa_code.pm <==  If you rename the file, you must either  ###
   ####                                                              ###
   #### change the setting of $custom_code_module_file as well, or   ###
   #### set the $fa_custom_code variable in the BEGIN { } block      ###
   #### of the top level script invoking Net::FullAuto. (Advised)    ###
   ####                                                              ###
   #####################################################################
                                                                     ###
   our $custom_code_module_file='fa_code.pm';                        ###
                                                                     ###
   #####################################################################

   #####################################################################
   ####                                                              ###
   #### DEFAULT NAME OF Net::FullAuto configuration_module_file IS:  ###
   ####                                                              ###
   #### ==> fa_conf.pm <==  If you rename the file, you must either  ###
   ####                                                              ###
   #### change the setting of $custom_code_module_file as well, or   ###
   #### set the $fa_configuration variable in the BEGIN { } block    ###
   #### of the top level script invoking Net::FullAuto. (Advised)    ###
   ####                                                              ###
   #####################################################################
                                                                     ###
   our $configuration_module_file='fa_conf.pm';                      ###
                                                                     ###
   #####################################################################

   #####################################################################
   ####                                                              ###
   #### DEFAULT NAME OF Net::FullAuto hosts_config_module_file  IS:  ###
   ####                                                              ###
   #### ==> fa_host.pm <==  If you rename the file, you must either  ###
   ####                                                              ###
   #### change the setting of $hosts_module_file as well, or         ###
   #### set the $fa_hosts_config variable in the BEGIN { } block     ###
   #### of the top level script invoking Net::FullAuto. (Advised)    ###
   ####                                                              ###
   #####################################################################
                                                                     ###
   our $hosts_config_module_file='fa_host.pm';                       ###
                                                                     ###
   #####################################################################

   #####################################################################
   ####                                                              ###
   #### DEFAULT NAME OF  Net::FullAuto  maps_config_module_file IS:  ###
   ####                                                              ###
   #### ==> fa_maps.pm <==  If you rename the file, you must change  ###
   ####                                                              ###
   #### change the setting of $maps_config_module_file as well, or   ###
   #### set the $fa_mapping variable in the BEGIN { } block          ###
   #### of the top level script invoking Net::FullAuto. (Advised)    ###
   ####                                                              ###
   #####################################################################
                                                                     ###
   our $maps_config_module_file='fa_maps.pm';                        ###
                                                                     ###
   #####################################################################

   our $fullauto=0;
   if (defined $main::fa_menu_config) {

      if (-1<index $main::fa_menu_config,'/') {
         require $main::fa_menu_config;
         my $mc=substr($main::fa_menu_config,
                (rindex $main::fa_menu_config,'/')+1,-3);
         import $mc;
         $menu_config_module_file=$mc.'.pm';
      } elsif (-1<index caller(2),'FullAuto') {
         require 'Net/FullAuto/Custom/'.$main::fa_menu_config;
         my $mc=substr($main::fa_menu_config,
                (rindex $main::fa_menu_config,'/')+1,-3);
         import $mc;
         $menu_config_module_file=$mc.'.pm';
      } else {
         require $main::fa_menu_config;
         my $mc=substr($main::fa_menu_config,0,-3);
         import $mc;
         $menu_config_module_file=$main::fa_menu_config;
      }
      $fullauto=1
         if -1<index caller(2),'FullAuto';

   } elsif (-1<index caller(2),'FullAuto') {

      if (!$canload->( modules => { 'Net/FullAuto/Custom/'.
            $menu_config_module_file => 0 } )) {
         require 'Net/FullAuto/Distro/'.$menu_config_module_file;
      }
      my $mc=substr($menu_config_module_file,0,-3);
      import $mc;
      $fullauto=1;

   }

   if (defined $main::fa_custom_code) {

      if (-1<index $main::fa_custom_code,'/') {
         require $main::fa_custom_code;
         my $cc=substr($main::fa_custom_code,
                (rindex $main::fa_custom_code,'/')+1,-3);
         import $cc;
         $custom_code_module_file=$cc.'.pm';
      } elsif (-1<index caller(2),'FullAuto') {
         require 'Net/FullAuto/Custom/'.$main::fa_custom_code;
         my $cc=substr($main::fa_custom_code,
                (rindex $main::fa_custom_code,'/')+1,-3);
         import $cc;
         $custom_code_module_file=$cc.'.pm';
      } else {
         require $main::fa_custom_code;
         my $cc=substr($main::fa_custom_code,0,-3);
         import $cc;
         $custom_code_module_file=$main::fa_custom_code;
      }

   } elsif (-1<index caller(2),'FullAuto') {
      if (!$canload->( modules => { 'Net/FullAuto/Custom/'.
            $custom_code_module_file => 0 } )) {
         require 'Net/FullAuto/Distro/'.$custom_code_module_file;
      }
      my $cc=substr($custom_code_module_file,0,-3);
      import $cc;

   }

   if (defined $main::fa_configuration) {

      if (-1<index $main::fa_configuration,'/') {
         require $main::fa_configuration;
         my $cf=substr($main::fa_configuration,
                (rindex $main::fa_configuration,'/')+1,-3);
         import $cf;
         $configuration_module_file=$cf.'.pm';
      } elsif (-1<index caller(2),'FullAuto') {
         require 'Net/FullAuto/Custom/'.$main::fa_configuration;
         my $cf=substr($main::fa_configuration,
                (rindex $main::fa_configuration,'/')+1,-3);
         import $cf;
         $configuration_module_file=$cf.'.pm';
      } else {
         require $main::fa_configuration;
         my $cf=substr($main::fa_configuration,0,-3);
         import $cf;
         $configuration_module_file=$main::fa_configuration;
      }

   } elsif (-1<index caller(2),'FullAuto') {

      if (!$canload->( modules => { 'Net/FullAuto/Custom/'.
            $configuration_module_file => 0 } )) {
         require 'Net/FullAuto/Distro/'.$configuration_module_file;
      }
      my $cf=substr($configuration_module_file,0,-3);
      import $cf;

   }

   if (defined $main::fa_hosts_config) {

      if (-1<index $main::fa_hosts_config,'/') {
         require $main::fa_hosts_config;
         my $hc=substr($main::fa_hosts_config,
                (rindex $main::fa_hosts_config,'/')+1,-3);
         import $hc;
         $hosts_config_module_file=$hc.'.pm';
      } elsif (-1<index caller(2),'FullAuto') {
         require 'Net/FullAuto/Custom/'.$main::fa_hosts_config;
         my $hc=substr($main::fa_hosts_config,
                (rindex $main::fa_hosts_config,'/')+1,-3);
         import $hc;
         $hosts_config_module_file=$hc.'.pm';
      } else {
         require $main::fa_hosts_config;
         my $hc=substr($main::fa_hosts_config,0,-3);
         import $hc;
         $hosts_config_module_file=$main::fa_hosts_config;
      }

   } elsif (-1<index caller(2),'FullAuto') {

      if (!$canload->( modules => { 'Net/FullAuto/Custom/'.
            $hosts_config_module_file => 0 } )) {
         require 'Net/FullAuto/Distro/'.$hosts_config_module_file;
      }
      my $hc=substr($hosts_config_module_file,0,-3);
      import $hc;

   }

   if (defined $main::fa_maps_config) {

      if (-1<index $main::fa_maps_config,'/') {
         require $main::fa_maps_config;
         my $hc=substr($main::fa_maps_config,
                (rindex $main::fa_maps_config,'/')+1,-3);
         import $mp;
         $maps_config_module_file=$mp.'.pm';
      } elsif (-1<index caller(2),'FullAuto') {
         require 'Net/FullAuto/Custom/'.$main::fa_maps_config;
         my $mp=substr($main::fa_maps_config,
                (rindex $main::fa_maps_config,'/')+1,-3);
         import $mp;
         $maps_config_module_file=$mp.'.pm';
      } else {
         require $main::fa_maps_config;
         my $mp=substr($main::fa_maps_config,0,-3);
         import $mp;
         $maps_config_module_file=$main::fa_maps_config;
      }

   } elsif (-1<index caller(2),'FullAuto') {

      if (!$canload->( modules => { 'Net/FullAuto/Custom/'.
            $maps_config_module_file => 0 } )) {
         require 'Net/FullAuto/Distro/'.$maps_config_module_file;
      }
      my $mp=substr($maps_config_module_file,0,-3);
      import $mp;

   }

}

our %email_defaults=();
if (%fa_code::email_defaults) {
   %email_defaults=%fa_code::email_defaults;
}
our %email_addresses=();
if (%fa_code::email_addresses) {
   %email_addresses=%fa_code::email_addresses;
}
our $passwd_file_loc='';
if (defined $fa_code::passwd_file_loc && $fa_code::passwd_file_loc) {
   $passwd_file_loc=$fa_code::passwd_file_loc;
}
our $test=0;
if (defined $fa_code::test && $fa_code::test) {
   $test=$fa_code::test;
}
our $timeout=30;
if (defined $fa_code::timeout && $fa_code::timeout) {
   $timeout=$fa_code::timeout;
}
our $log=0;
if (defined $fa_code::log && $fa_code::log) {
   $log=$fa_code::log;
}
our $tosspass=0;
if (defined $fa_code::tosspass && $fa_code::tosspass) {
   $tosspass=$fa_code::tosspass;
}

##  End  Net::FullAuto  Settings

##############################################################
##############################################################


BEGIN { ##  Begin  Term::Menus

   our $termwidth='';
   our $termheight='';
   our $data_dump_streamer=0;
   if ($canload->( modules => { Term::ReadKey => 0 } )) {
      eval {
         ($termwidth, $termheight) = Term::ReadKey::GetTerminalSize(STDOUT);
      };
      if ($@) {
         $termwidth='';$termheight='';
      }
   } else {
      $termwidth='';$termheight='';
   }
   if ($canload->( modules => { Data::Dump::Streamer => 0 } )) {
      $data_dump_streamer=1;
   }
   our $clearpath='';
   if ($^O ne 'MSWin32' && $^O ne 'MSWin64') {
      if (-e '/usr/bin/clear') {
         $clearpath='/usr/bin/';
      } elsif (-e '/bin/clear') {
         $clearpath='/bin/';
      } elsif (-e '/usr/local/bin/clear') {
         $clearpath='/usr/local/bin/';
      }
   }

}

our %LookUpMenuName=();

our $noclear=1; # set to one to turn off clear for debugging

my $m_flag=0;
my $s_flag=0;
foreach my $dir (@INC) {
   if (!$m_flag && -f "$dir/$menu_config_module_file") {
      $m_flag=1;
      open(FH,"<$dir/$menu_config_module_file");
      my $line='';my %menudups=();
      while ($line=<FH>) {
         if ($line=~/^[ \t]*\%(.*)\s*=/) {
            if (!exists $menudups{$1}) {
               $menudups{$1}='';
            } else {
               my $die="\n       FATAL ERROR! - Duplicate Hash Blocks:"
                      ."\n              ->  \"%$1\" is defined more than once\n"
                      ."              in the $dir/$menu_config_module_file file.\n\n"
                      ."       Hint:  delete or comment-out all duplicates\n\n";
               if ($fullauto) {
                  print $die if !$Net::FullAuto::FA_Core::cron;
                  &Net::FullAuto::FA_Core::handle_error($die,'__cleanup__');
               } else { die $die }
            }
         }
      }
   }
   if (!$s_flag && -f "$dir/$custom_code_module_file") {
      $s_flag=1;
      open(FH,"<$dir/$custom_code_module_file");
      my $line='';my %dups=();
      while ($line=<FH>) {
         if ($line=~/^[ \t]*\%(.*)\s*=/) {
            if (!exists $dups{$1}) {
               $dups{$1}='';
            } else {
               my $die="\n       FATAL ERROR! - Duplicate Hash Blocks:"
                      ."\n              ->  \"%$1\" is defined more "
                      ."than once\n              in the $dir/"
                      ."$custom_code_module_file file.\n\n       Hint:  delete "
                      ."or comment-out all duplicates\n\n";
               if ($fullauto) {
                  print $die if !$Net::FullAuto::FA_Core::cron;
                  &Net::FullAuto::FA_Core::handle_error($die,'__cleanup__');
               } else { die $die }
               #print $die;exit;
            }
         }
      }
   }
}

if ($fullauto) {
   no strict 'refs';
   foreach my $symname (keys %Term::Menus::) {
      if (eval "\\%$symname") {
         my $hashref=eval "\\%$symname";
         HF: foreach my $key (keys %{$hashref}) {
            if (ref ${$hashref}{$key} eq 'HASH') {
               foreach my $ky (keys %{${$hashref}{$key}}) {
                  if (lc($ky) eq 'text') {
                     $LookUpMenuName{$hashref}="$symname";
                     last HF;
                  }
               }
            }
         }
      }
   }
}

{
   use Sys::Hostname;
   our $local_hostname=hostname;
}

my $count=0;
our $blanklines='';
if ($termheight) {
   $count=$termheight;
} else { $count=30 }
while ($count--) { $blanklines.="\n" }
our $parent_menu='';

sub fa_login
{

   my $fa_code='';my $menu_args='';$to='';my $die='';
   my $start_menu_ref='';
   eval {
      ($fa_code,$menu_args,$to,$die)=
         &Net::FullAuto::FA_Core::fa_login(@_);
      $start_menu_ref=eval '$'.substr($menu_config_module_file,0,-3).'::start_menu_ref';
      $to||=0;
      $timeout=$to if $to;
      if ($fa_code) {
         &run_sub($fa_code,$menu_args);
      } elsif (ref $start_menu_ref eq 'HASH') {
         if (!exists $LookUpMenuName{$start_menu_ref}) {
            my $die="\n       FATAL ERROR! - The top level menu,"
                   ." indicated\n              by the "
                   ."\$start_menu_ref variable in\n       "
                   ."       the $menu_config_module_file file, is NOT\n"
                   ."              EXPORTED\n\n       Hint: "
                   ."\@EXPORT = qw( %Menu_1 %Menu_2 ... )\;"
                   ."\n\n\tour \$start_menu_ref=\\%Menu_1\;"
                   ."\n\n       \[ Menu_1 is example - "
                   ."name you choose is optional \]\n";
            &Net::FullAuto::FA_Core::handle_error($die);
         }
         &Menu($start_menu_ref);
      } elsif ($start_menu_ref) {
         my $die="\n       FATAL ERROR! - The top level menu "
                ."block indicated\n              by the "
                ."\$start_menu_ref variable in the\n       "
                ."       $menu_config_module_file file, does not exist as"
                ."\n              a properly constructed and"
                ."\\or named hash\n              block in the"
                ." ".__PACKAGE__.".pm file\n\n       Hint:  "
                ."our \$start_menu_ref=\\%Menu_1\;\n\n       "
                ."\[ Menu_1 is example - name you choose is"
                ." optional \]\n\n       %Menu_1=\(\n"
                ."          Item_1 => { ... },\n        "
                ."...\n       \)\;\n";
         &Net::FullAuto::FA_Core::handle_error($die);
      } else {
         my $die="\n       FATAL ERROR! - The \$start_menu_ref\n"
                ."              variable in the $menu_config_module_file\n"
                ."              file, is not defined or properly"
                ."\n              initialized with the name of "
                ."the\n              menu hash block designated"
                ." for the\n              top level menu.\n\n"
                ."              Hint:  our \$start_menu_ref"
                ."=\\%Menu_1\;\n\n       \[ Menu_1 is example - "
                ."name you choose is optional \]\n\n       "
                ."%Menu_1=\(\n          Item_1 => { ... },\n"
                ."          ...\n       \)\;\n";
         &Net::FullAuto::FA_Core::handle_error($die);
      }
   };
   if ($@) {
      my $cmdlin=52;
      $cmdlin=47 if $fa_code;
      &Net::FullAuto::FA_Core::handle_error($@,"-$cmdlin",'__cleanup__');
   }
   #print "\n==> DONE!!!!!!!!!" if !$Net::FullAuto::FA_Core::cron &&
   #      !$Net::FullAuto::FA_Core::stdio;
   &Net::FullAuto::FA_Core::cleanup(1);

}

sub run_sub
{
   my $fa_code=$_[0];
   my $menu_args= (defined $_[1]) ? $_[1] : '';
   my $subfile=substr($custom_code_module_file,0,-3).'::' if $custom_code_module_file;
   $subfile||='';
   my $return=
      eval "\&$subfile$fa_code\(\@{\$menu_args}\)";
   &Net::FullAuto::FA_Core::handle_error($@,'-1') if $@;
   return $return;
}

sub get_all_hosts
{
   return Net::FullAuto::FA_Core::get_all_hosts(@_);
}

sub Menu
{
#print "MENUCALLER=",(caller)[0]," and ",__PACKAGE__,"\n";<STDIN>;
#print "MENUCALLER=",caller,"\n";<STDIN>;
   my $MenuUnit_hash_ref=$_[0];
   my $picks_from_parent=$_[1];
   my $unattended=0;
   if ($picks_from_parent=~/\](Cron|Batch|Unattended|FullAuto)\[/i) {
      $unattended=1;
      undef $picks_from_parent;
   }
   my $recurse = (defined $_[2]) ? $_[2] : 0;
   my $FullMenu= (defined $_[3]) ? $_[3] : {};
   my $Selected= (defined $_[4]) ? $_[4] : {};
   my $Conveyed= (defined $_[5]) ? $_[5] : {};
   my $SavePick= (defined $_[6]) ? $_[6] : {};
   my $SaveLast= (defined $_[7]) ? $_[7] : {};
   my $SaveNext= (defined $_[8]) ? $_[8] : {};
   my $Persists= (defined $_[9]) ? $_[9] : {};
   my $parent_menu= (defined $_[10]) ? $_[10] : '';
   my $no_wantarray=0;
   if ((defined $_[11] && $_[11]) ||
         ((caller)[0] ne __PACKAGE__ && !wantarray)) {
      $no_wantarray=1;
   }
   if (defined $_[12] && $_[12]) {
      return '','','','','','','','','','','',$_[12];
   }
   my $pmsi_regex=qr/\]p(?:r+evious[-_]*)*m*(?:e+nu[-_]*)
      *c*(?:h+osen[-_]*)*i*(?:t+ems[-_]*)*\[/xi;
   my %Items=();my %negate=();my %result=();
   my %convey=();my %chosen=();my %default=();
   my $picks=[];my $banner='';my %num__=();
   my $display_this_many_items=10;my $die_err='';
   my $master_substituted='';my $convey='';my $error='';
   my $num=0;my @convey=();my $filtered=0;my $sorted='';
   foreach my $key (keys %{$MenuUnit_hash_ref}) {
      if (4<length $key && substr($key,0,4) eq 'Item') {
         $Items{substr($key,5)}=${$MenuUnit_hash_ref}{$key};
      }
   }
   $Persists{unattended}=$unattended if $unattended;

   ############################################
   # Breakdown the MenuUnit into its Components
   ############################################

      # Breakdown Each Item into its Components
      #########################################

   while (++$num) {
      @convey=();
      last unless exists $Items{$num};
      if (exists ${$Items{$num}}{Negate} &&
            (!exists ${$MenuUnit_hash_ref}{Select} ||
            ${$MenuUnit_hash_ref}{Select} eq 'One')) {
         my $die="Can Only Use \"Negate =>\""
                ."\n\t\tElement in ".__PACKAGE__.".pm when the"
                ."\n\t\t\"Select =>\" Element is set to \'Many\'\n\n";
         &Net::FullAuto::FA_Core::handle_error($die) if $fullauto;
         die $die;
      }
      my $con_regex=qr/\]c(o+nvey)*\[/i;
      if (exists ${$Items{$num}}{Convey}) {
         if (ref ${$Items{$num}}{Convey} eq 'ARRAY') {
            foreach my $line (@{${$Items{$num}}{Convey}}) {
               push @convey, $line;
            }
         } elsif (ref ${$Items{$num}}{Convey} eq 'CODE') {
            @convey=${$Items{$num}}{Convey}->();
         } elsif (substr(${$Items{$num}}{Convey},0,1) eq '&') {
            if (defined $picks_from_parent &&
                          !ref $picks_from_parent) {
               my $convey=&transform_pmsi(${$Items{$num}}{Convey},
                          $Conveyed,$pmsi_regex,$picks_from_parent);
               @convey=eval $convey;
            }
         } else {
            push @convey, ${$Items{$num}}{Convey};
         }
         foreach my $item (@convey) {
            my $text=${$Items{$num}}{Text};
            $text=~s/$con_regex/$item/g;
            $text=&transform_pmsi($text,
                  $Conveyed,$pmsi_regex,$picks_from_parent);
            if (-1<index $text,"__Master_${$}__") {
               $text=~
                  s/__Master_${$}__/Local-Host: $local_hostname/sg;
               $master_substituted="Local-Host: $local_hostname";
            }
            if (exists ${$Items{$num}}{Include}) {
               if ($text=~/${$Items{$num}}{Include}/s) {
                  next if exists ${$Items{$num}}{Exclude} &&
                        $text=~/${$Items{$num}}{Exclude}/;
                  push @{$picks}, $text;
               } else { next }
            } elsif (exists ${$Items{$num}}{Exclude} &&
               $text=~/${$Items{$num}}{Exclude}/) {
               next;
            } else { push @{$picks}, $text }

            if (exists ${$Items{$num}}{Convey} &&
                  ${$Items{$num}}{Convey} ne '') {
               $convey{$text}=[$item,${$Items{$num}}{Convey}];
            } elsif (!exists ${$Items{$num}}{Convey}) {
               $convey{$text}=[$item,''];
            }
            $default{$text}=${$Items{$num}}{Default}
               if exists ${$Items{$num}}{Default};
            $negate{$text}=${$Items{$num}}{Negate}
               if exists ${$Items{$num}}{Negate};
            $result{$text}=${$Items{$num}}{Result}
               if exists ${$Items{$num}}{Result};
            $filtered=1 if exists ${$Items{$num}}{Filter};
            $sorted=${$Items{$num}}{Sort}
               if exists ${$Items{$num}}{Sort};
            $chosen{$text}="Item_$num";
         }
      } else {
         my $text=&transform_pmsi(${$Items{$num}}{Text},
                  $Conveyed,$pmsi_regex,$picks_from_parent);
         if (-1<index ${$Items{$num}}{Text},"__Master_${$}__") {
            $text=~
               s/__Master_${$}__/Local-Host: $local_hostname/sg;
            $master_substituted=
                             "Local-Host: $local_hostname";
         }
         if (exists ${$Items{$num}}{Include}) {
            if (${$Items{$num}}{Text}=~/${$Items{$num}}{Include}/) {
               next if exists ${$Items{$num}}{Exclude} &&
                     ${$Items{$num}}{Text}=~/${$Items{$num}}{Exclude}/;

               push @{$picks}, $text;
            } else { next }
         } elsif (exists ${$Items{$num}}{Exclude} &&
            ${$Items{$num}}{Text}=~/${$Items{$num}}{Exclude}/) {
            next;
         } else { push @{$picks}, $text }
         $convey{${$Items{$num}}{Text}}=['',${$Items{$num}}{Convey}]
            if exists ${$Items{$num}}{Convey};
         $default{$text}=${$Items{$num}}{Default}
            if exists ${$Items{$num}}{Default};
         $negate{$text}=${$Items{$num}}{Negate}
            if exists ${$Items{$num}}{Negate};
         $result{$text}=${$Items{$num}}{Result}
            if exists ${$Items{$num}}{Result};
         $filtered=1 if exists ${$Items{$num}}{Filter};
         $sorted=${$Items{$num}}{Sort}
            if exists ${$Items{$num}}{Sort};
         $chosen{$text}="Item_$num";
         $num__{$text}=${$Items{$num}}{__NUM__}
            if exists ${$Items{$num}}{__NUM__};
      } $banner='';
   }


      #########################################
      # End Items Breakdown

   $banner=${$_[0]}{Banner}
      if exists ${$_[0]}{Banner};
   $banner=&transform_pmsi($banner,
      $Conveyed,$pmsi_regex,$picks_from_parent);
   if ($banner && unpack('a1',$banner) eq '&' &&
         defined $picks_from_parent &&
         !ref $picks_from_parent) {
      @banner=eval $banner;
      $banner=join '',@banner;
   }
   $display_this_many_items=${$_[0]}{Display}
      if exists ${$_[0]}{Display};


   ############################################
   # End MenuUnit Breakdown
   ############################################

   my $cl_def=0;
   foreach my $key (keys %{$SaveNext}) {
      if (${$FullMenu}{$key}[5] eq 'ERASE') {
         ${$FullMenu}{$key}[5]='' if !exists ${$SaveLast}{$key};
         $cl_def=1;
         last;
      }
   }
   %default=() if defined ${$FullMenu}{$MenuUnit_hash_ref}[5]
      && !$cl_def;
   my $nm_=(keys %num__)?\%num__:'_ZERO_';
   ${$FullMenu}{$MenuUnit_hash_ref}=[ $MenuUnit_hash_ref,
      \%negate,\%result,\%convey,\%chosen,\%default,$nm_,
      $filtered,$picks ];
   if (exists ${$MenuUnit_hash_ref}{Select} &&
         ${$MenuUnit_hash_ref}{Select} eq 'Many') {
      ($pick,$FullMenu,$Selected,$Conveyed,$SavePick,
              $SaveLast,$SaveNext,$Persists,$parent_menu,$error)=&pick(
                        $picks,$banner,
                        $display_this_many_items,'',
                        $MenuUnit_hash_ref,++$recurse,
                        $picks_from_parent,$parent_menu,
                        $menu_config_module_file,$FullMenu,
                        $Selected,$Conveyed,$SavePick,
                        $SaveLast,$SaveNext,$Persists,
                        \%LookUpMenuName,\@convey,
                        $no_wantarray,$sorted);
      if ($error) {
         if (wantarray && $fullauto) {
            &Net::FullAuto::FA_Core::handle_error($die);
         } else {
            die $error;
         }
      }
      if ($fullauto && $master_substituted) {
         $pick=~s/$master_substituted/__Master_${$}__/sg;
      }
      if ($pick eq ']quit[') {
         return ']quit['
      } elsif ($pick eq '-' || $pick eq '+') {
         return $pick,$FullMenu,$Selected,$Conveyed,
                    $SavePick,$SaveLast,$SaveNext,$Persists;
      } elsif ($pick=~/DONE/) {
         return $pick,$FullMenu,$Selected,$Conveyed,
                       $SavePick,$SaveLast,$SaveNext,$Persists;
      } elsif (ref $pick eq 'ARRAY' && wantarray
            && 1==$recurse) {
         my @choyce=@{$pick};undef @{$pick};undef $pick;
         return @choyce
      } elsif ($pick) { return $pick }
   } else {
      ($pick,$FullMenu,$Selected,$Conveyed,$SavePick,
              $SaveLast,$SaveNext,$Persists,$parent_menu,$error)
              =&pick($picks,$banner,$display_this_many_items,
                       '',$MenuUnit_hash_ref,++$recurse,
                       $picks_from_parent,$parent_menu,
                       $menu_config_module_file,$FullMenu,
                       $Selected,$Conveyed,$SavePick,
                       $SaveLast,$SaveNext,$Persists,
                       \%LookUpMenuName,\@convey,
                       $no_wantarray,$sorted);
#print "WAHT IS ALL=$pick and FULL=$FullMenu and SEL=$Selected and CON=$Conveyed and SAVE=$SavePick and LAST=$SaveLast and NEXT=$SaveNext and PERSISTS=$Persists  and PARENT=$parent_menu and ERROR=$error<==\n";
      if ($error) {
         if (wantarray && $fullauto) {
            &Net::FullAuto::FA_Core::handle_error($die);
#print "RETURNING ERROR=$error\n";
         } else {
            die $error;
         }
      }
      if ($fullauto && $master_substituted) {
         $pick=~s/$master_substituted/__Master_${$}__/sg;
      }
      if ($pick eq ']quit[') {
         return ']quit['
      } elsif ($pick eq '-' || $pick eq '+') {
         if (keys %{${$Selected}{$MenuUnit_hash_ref}}) {
            return '+',$FullMenu,$Selected,$Conveyed,
                       $SavePick,$SaveLast,$SaveNext,$Persists,$error;
         } else {
            return $pick,$FullMenu,$Selected,$Conveyed,
                       $SavePick,$SaveLast,$SaveNext,$Persists,$error;
         }
      } elsif ($pick=~/DONE/) {
         return $pick,$FullMenu,$Selected,$Conveyed,
                       $SavePick,$SaveLast,$SaveNext,$Persists,$error;
      } elsif (ref $pick eq 'ARRAY' && wantarray
            && 1==$recurse) {
         my @choyce=@{$pick};undef @{$pick};undef $pick;
         return @choyce
      } elsif ($pick) { return $pick }
   }

}

sub transform_pmsi
{
   my ($text,$Conveyed,$pmsi_regex,$picks_from_parent)=@_;
   $text=~s/\s?$//s;
   while ($text=~m/($pmsi_regex(?:\{[^}]+\})*)/sg) {
      my $esc_one=$1;
      $esc_one=~s/\]/\\\]/;$esc_one=~s/\[/\\\[/;
      $esc_one=~s/\{/\{\(/;$esc_one=~s/\}/\)\}/;
      while ($esc_one=~/\{/ && $text=~m/$esc_one/) { 
         $text=~s/$esc_one/${$Conveyed}{$1}/se;
      } my $pp=$picks_from_parent;
      $pp="\"$pp\"" if $pp=~/\s/s;
      $text=~s/$esc_one/$pp/s;
   } return $text;
}

sub pick # USAGE: &pick( ref_to_choices_array,
             #  (Optional)       banner_string,
             #  (Optional)       display_this_many_items,
             #  (Optional)       log_file_handle,
             #  ----------
             #  For Use With Sub-Menus
             #  ----------
             #  (Optional)       MenuUnit_hash_ref,
             #  (Optional)       recurse_level,
             #  (Optional)       picks_from_parent,
             #  (Optional)       parent_menu,
             #  (Optional)       menus_cfg_file,
             #  (Optional)       Full_Menu_data_structure,
             #  (Optional)       Selected_data_structure,
             #  (Optional)       Conveyed_data_structure,
             #  (Optional)       SavePick_data_structure,
             #  (Optional)       SaveLast_data_structure,
             #  (Optional)       SaveNext_data_structure,
             #  (Optional)       Persists_data_structure,
             #  (Optional)       LookUpMenuName_data_structure,
             #  (Optional)       convey_item_contents_arrayref_from_menu,
             #  (Optional)       no_wantarray_flag )
{

#print "PICKCALLER=",caller," and Argument 7 =>$_[6]<=\n";sleep 3;

   #  "pick" --> This function presents the user with
   #  with a list of items from which to choose.

   my @pickone=@{$_[0]};
   my $banner=defined $_[1] ? $_[1] : "\n   Please Pick an Item :";
   my $display_this_many_items=defined $_[2] ? $_[2] : 10;
   my $log_handle= (defined $_[3]) ? $_[3] : '';

   # Used Only With Cascasding Menus (Optional)
   my $MenuUnit_hash_ref= (defined $_[4]) ? $_[4] : '';
   my $recurse_level= (defined $_[5]) ? $_[5] : 1;
   my $picks_from_parent= (defined $_[6]) ? $_[6] : '';
   my $parent_menu= (defined $_[7]) ? $_[7] : '';
   my $menu_config_module_file= (defined $_[8]) ? $_[8] : '';
   my $FullMenu= (defined $_[9]) ? $_[9] : {};
   my $Selected= (defined $_[10]) ? $_[10] : {};
   my $Conveyed= (defined $_[11]) ? $_[11] : {};
   my $SavePick= (defined $_[12]) ? $_[12] : {};
   my $SaveLast= (defined $_[13]) ? $_[13] : {};
   my $SaveNext= (defined $_[14]) ? $_[14] : {};
   my $Persists= (defined $_[15]) ? $_[15] : {};
   my $LookUpMenuName= (defined $_[16]) ? $_[16] : {};
   my $Convey_contents= (defined $_[17]) ? $_[17] : [];
   my $no_wantarray= (defined $_[18]) ? $_[18] : 0;
   my $sorted= (defined $_[19]) ? $_[19] : 0;

   my %items=();my %picks=();my %negate=();
   my %exclude=();my %include=();my %default=();
   if ($SavePick && exists ${$SavePick}{$MenuUnit_hash_ref}) {
      %picks=%{${$SavePick}{$MenuUnit_hash_ref}};
   }
   my $num_pick=$#pickone+1;
   my $caller=(caller(1))[3];
   unless ($Persists{unattended}) {
      if ($^O ne 'cygwin') {
         unless ($noclear) {
            if ($^O eq 'MSWin32' || $^O eq 'MSWin64') {
               system("cmd /c cls");
               print "\n";
            } else {
               print `${clearpath}clear`."\n";
            }
         } else { print $blanklines }
      } else { print $blanklines }
   }
   my $numbor=0;                    # Number of Item Selected
   my $return_from_child_menu=0;

   my $choose_num='';
   my $convey='';
   my $menu_output='';
   my $hidedefaults=0;
   my $start=0;

   sub delete_Selected
   {
      my $Selected=$_[2];
      my $SavePick=$_[3];
      my $SaveNext=$_[4];
      my $Persists=$_[5];
      if ($_[1]) {
         my $result=${$Selected}{$_[0]}{$_[1]};
         delete ${$Selected}{$_[0]}{$_[1]};
         delete ${$SavePick}{$_[0]}{$_[1]};
         #delete ${$SaveNext}{$_[0]};
         if ($result) {
            &delete_Selected($result,'',
                $Selected,$SavePick,$SaveNext);
         } delete ${$SaveNext}{$_[0]};
      } else {
         if (keys %{${$Selected}{$_[0]}}) {
            foreach my $key (keys %{${$Selected}{$_[0]}}) {
               delete ${$Selected}{$_[0]}{$key};
               delete ${$SavePick}{$_[0]}{$key};
               delete ${$SaveNext}{$_[0]};
            }
         } else {
            foreach my $key (keys %{${$SavePick}{$_[0]}}) {
               delete ${$SavePick}{$_[0]}{$key};
               delete ${$SaveNext}{$_[0]};
            }
         }
      } delete ${$SaveNext}{$_[0]};
      return $SaveNext;

   }

   sub find_Selected
   {
      my $Selected=$_[2];
      if ($_[1]) {
         my $result=${$Selected}{$_[0]}{$_[1]};
         if (substr($result,0,1) eq '&') {
            return 0;
         } else {
            return &find_Selected($result,'',$Selected);
         }
      } else {
         if (keys %{${$Selected}{$_[0]}}) {
            foreach my $key (keys %{${$Selected}{$_[0]}}) {
               my $result=${$Selected}{$_[0]}{$key};
               return '+' if substr($result,0,1) eq '&';
               my $output=find_Selected($result,'',$Selected);
               return '+' if $output eq '+';
            }
         }
      }
   }

   sub get_subs_from_menu
   {
      my $Selected=$_[0];
      my @subs=();
      foreach my $key (keys %{$Selected}) {
         foreach my $item (keys %{${$Selected}{$key}}) {
            if (substr(${$Selected}{$key}{$item},0,1) eq '&') {
               push @subs, escape_quotes(unpack('x1 a*',${$Selected}{$key}{$item}));
            } elsif (ref ${$Selected}{$key}{$item} eq 'CODE') {
               push @subs, ${$Selected}{$key}{$item};
            } 
         }
      } return @subs;
   }

   my $get_result = sub {

      # $_[0] => $MenuUnit_hash_ref
      # $_[1] => \@pickone
      # $_[2] => $numbor
      # $_[3] => $picks_from_parent

      my $convey='';
      my $send_all=0;my $all_convey='';
      my $FullMenu=$_[4];
      my $Conveyed=$_[5];
      my $Selected=$_[6];
      my $SaveNext=$_[7];
      my $Persists=$_[8];
      my $parent_menu=$_[9];
      my $menu_config_module_file=$_[10];
      my $Convey_contents=$_[11];
      ${$LookUpMenuName}{$_[0]}=${$_[0]}{'Label'}
         unless exists ${$LookUpMenuName}{$_[0]};
      if (exists ${$FullMenu}{$_[0]}[3]{${$_[1]}[$_[2]-1]}) {
         if (exists ${$_[0]}{${$FullMenu}{$_[0]}
                            [4]{${$_[1]}[$_[2]-1]}}{Convey}) {
            $convey=${${$FullMenu}{$_[0]}[3]}
                               {${$_[1]}[$_[2]-1]}[0];
            $convey=~s/\s?$//s;
            if (keys %{${$Selected}{$_[0]}}) {
               my $get_convey='';
               foreach my $item (keys %{${$Selected}{$_[0]}}) {
                  $get_convey.='"'.${${$FullMenu}{$_[0]}[3]}
                               {${$_[1]}[$item-1]}[0].'",'
               } $get_convey.="\"$convey\"";
               $all_convey="[ $get_convey ]";
            }
            $convey='SKIP' if $convey eq '';
         }
         if (exists ${$_[0]}{${$FullMenu}{$_[0]}
               [4]{${$_[1]}[$_[2]-1]}}{Convey}) {
            ${$Conveyed}{${$LookUpMenuName}{$_[0]}}=$convey;
            $parent_menu=${$LookUpMenuName}{$_[0]};
            if (ref ${$_[0]}{${$FullMenu}{$_[0]}
                  [4]{${$_[1]}[$_[2]-1]}}{'Result'} eq 'HASH') {
               if (exists ${$_[0]}{${$FullMenu}{$_[0]}
                     [4]{${$_[1]}[$_[2]-1]}}{'Result'}{'Label'}) {
                  $LookUpMenuName{${$_[0]}{${$FullMenu}{$_[0]}
                     [4]{${$_[1]}[$_[2]-1]}}{'Result'}}=
                     ${$_[0]}{${$FullMenu}{$_[0]}
                     [4]{${$_[1]}[$_[2]-1]}}{'Result'}{'Label'};
                  $parent_menu=$LookUpMenuName{$_[0]};
               } else {
                  my $die="The \"Result1 =>\" Setting".
                          "\n\t\tFound in the Menu Unit -> ".
                          "${$MenuUnit_hash_ref}{'Label'}\n\t\tis a ".
                          "HASH reference to a Menu Unit\,\n\t\t".
                          "that does NOT EXIST or is NOT EXPORTED".
                          "\n\n\tHint: Make sure the Names of all".
                          "\n\t      Menu Hash Blocks in the\n\t".
                          "      $menu_config_module_file file are\n\t".
                          "      listed in the \@EXPORT list\n\t".
                          "      found at the beginning of\n\t".
                          "      the $menu_config_module_file file\n\n\t".
                          "our \@EXPORT = qw( %Menu_1 %Menu_2 ... )\;\n";
                  die $die;
               }
            } elsif (unpack('a1',
                  ${$_[0]}{${$FullMenu}{$_[0]}
                  [4]{${$_[1]}[$_[2]-1]}}{'Result'})
                  ne '&') {
            }
         }
      } elsif ($_[3]) {
         $convey=$_[3];
         ${$Conveyed}{${$_[0]}{'Label'}}=$convey;
      } else {
         $convey=${$_[1]}[$_[2]-1];
         ${$Conveyed}{${$_[0]}{'Label'}}=$convey;
      }
      my $test_item=${$FullMenu}{$_[0]}[2]{${$_[1]}[$_[2]-1]};
      if (exists ${$FullMenu}{$_[0]}[2]{${$_[1]}[$_[2]-1]}) {
         my $ret_regex=qr/\]r(e+turn)*\[/i;
         if ((ref $test_item eq 'HASH' &&
                   exists $test_item->{Item_1})
                   || substr($test_item,0,1) eq '&'
                   || $test_item=~/$ret_regex/
                   || ref $test_item eq 'CODE') {
            my $con_regex=qr/\]c(o+nvey)*\[/i;
            my $sicm_regex=
               qr/\]s(e+lected[-_]*)*i*(t+ems[-_]*)
                  *c*(u+rrent[-_]*)*m*(e+nu[-_]*)*a*(l+l)*\[/xi;
            my $pmsi_regex=qr/\]p(r+evious[-_]*)*m*(e+nu[-_]*)
                  *s*(e+lected[-_]*)*i*(t+ems[-_]*)*\[/xi;
            if (ref $test_item eq 'HASH' &&
                    !exists ${$LookUpMenuName}{$test_item}) {
               if (exists ${$test_item}{'Label'}) {
                  $LookUpMenuName{$test_item}=${$test_item}{'Label'};
               } else {
                  my $die="The \"Result2 =>\" Setting".
                          "\n\t\tFound in the Menu Unit -> ".
                          "${$MenuUnit_hash_ref}{'Label'}\n\t\tis a ".
                          "HASH reference to a Menu Unit\,\n\t\t".
                          "that does NOT EXIST or is NOT EXPORTED".
                          "\n\n\tHint: Make sure the Names of all".
                          "\n\t      Menu Hash Blocks in the\n\t".
                          "      $menu_config_module_file file are\n\t".
                          "      listed in the \@EXPORT list\n\t".
                          "      found at the beginning of\n\t".
                          "      the $menu_config_module_file file\n\n\t".
                          "our \@EXPORT = qw( %Menu_1 %Menu_2 ... )\;\n";
                  die $die;
               }
            }
            if ($test_item=~/$con_regex|$pmsi_regex|$sicm_regex/) {
               my $one='';
               while ($test_item=~m/($sicm_regex)/g) {
                  next if $1 eq $one;
                  $one=$1;
                  $send_all=1 if -1<index lc($one),'a';
                  my $esc_one=$one;
                  $esc_one=~s/\]/\\\]/;$esc_one=~s/\[/\\\[/;
                  if ($convey ne 'SKIP') {
                     if ($send_all) {
                        if (${$MenuUnit_hash_ref}{Select} eq 'Many') {
                           $test_item=~s/\"$esc_one\"/$all_convey/g;
                        } else {
                           my $die="Can Only Use \"All\" (or A)";
                           $die.="\n\t\tQualifier in ".__PACKAGE__;
                           $die.=".pm when the";
                           $die.="\n\t\t\"Select =>\" Element is ";
                           $die.="set to\n\t\t\'Many\' in Menu Block ";
                           $die.='%'.${$LookUpMenuName}{$_[0]}."\n\n";
                           &Net::FullAuto::FA_Core::handle_error($die)
                              if $fullauto;
                           die $die;
                        }
                     } else {
                        $test_item=~s/$esc_one/${$_[1]}[$_[2]-1]/g;
                     }
                  } $test_item=~s/$esc_one/${$_[1]}[$_[2]-1]/g;
               }
               $test_item=&transform_pmsi($test_item,
                       $Conveyed,$pmsi_regex,$picks_from_parent);
               while ($test_item=~m/($con_regex)/g) {
                  next if $1 eq $one;
                  $one=$1;
                  my $esc_one=$one;
                  $esc_one=~s/\]/\\\]/;$esc_one=~s/\[/\\\[/;
                  $test_item=~s/\"$esc_one\"/$Convey_contents/g;
               }
            } elsif (ref $test_item eq 'CODE') {
               my $cd=$test_item;
               if ($data_dump_streamer) {
                  tie *memhand, "TMMemHandle";
                  my $me=\*memhand;
                  print $me &Data::Dump::Streamer::Dump($test_item);
                  $cd=<$me>;
                  my $one='';
                  while ($cd=~m/($sicm_regex)/sg) {
                     next if $1 eq $one;
                     $one=$1;
                     $send_all=1 if -1<index lc($one),'a';
                     my $esc_one=$one;
                     $esc_one=~s/\]/\\\]/;$esc_one=~s/\[/\\\[/;
                     if ($convey ne 'SKIP') {
                        if ($send_all) {
                           if (${$MenuUnit_hash_ref}{Select} eq 'Many') {
                              $cd=~s/\"$esc_one\"/$all_convey/sg;
                           } else {
                              my $die="Can Only Use \"All\" (or A)";
                              $die.="\n\t\tQualifier in ".__PACKAGE__;
                              $die.=".pm when the";
                              $die.="\n\t\t\"Select =>\" Element is ";
                              $die.="set to\n\t\t\'Many\' in Menu Block ";
                              $die.='%'.${$LookUpMenuName}{$_[0]}."\n\n";
                              &Net::FullAuto::FA_Core::handle_error($die)
                                 if $fullauto;
                              die $die;
                           }
                        } else {
                           $cd=~s/$esc_one/${$_[1]}[$_[2]-1]/sg;
                        }
                     } $cd=~s/$esc_one/${$_[1]}[$_[2]-1]/sg;
                  }
                  $cd=&transform_pmsi($cd,
                          $Conveyed,$pmsi_regex,$picks_from_parent);
                  while ($cd=~m/($con_regex)/sg) {
                     next if $1 eq $one;
                     $one=$1;
                     my $esc_one=$one;
                     $esc_one=~s/\]/\\\]/;$esc_one=~s/\[/\\\[/;
                     $cd=~s/\"$esc_one\"/$Convey_contents/sg;
                  }
               }
               eval { $test_item=eval $cd };
               if ($@) {
                  if (unpack('a11',$@) eq 'FATAL ERROR') {
                     if (defined $log_handle &&
                           -1<index $log_handle,'*') {
                        print $log_handle $die;
                        close($log_handle);
                     }
                     die $die;
                  } else {
                     my $die="\n       FATAL ERROR! - The Local "
                            ."System $local_hostname Conveyed\n"
                            ."              the Following "
                            ."Unrecoverable Error Condition :\n\n"
                            ."       $@";
                     if (defined $log_handle &&
                           -1<index $log_handle,'*') {
                        print $log_handle $die;
                        close($log_handle);
                     }
                     if ($parent_menu && wantarray && !$no_wantarray) {
                        return '',
                           $FullMenu,$Selected,$Conveyed,
                           $SavePick,$SaveLast,$SaveNext,
                           $Persists,$parent_menu,$die;
                     } elsif ($fullauto) {
                        &Net::FullAuto::FA_Core::handle_error($die);
                     } else { die $die }
                  }
               }
               $Selected={ key => { item => $test_item } };
               return $FullMenu,$Conveyed,$SaveNext,$Persists,$Selected,$convey,$parent_menu;
            }
            if ($test_item=~/Convey\s*=\>/) {
               if ($convey ne 'SKIP') {
                  $test_item=~s/Convey\s*=\>/$convey/g;
               } else {
                  $test_item=~s/Convey\s*=\>/${$_[1]}[$_[2]-1]/g;
               }
            }
            if ($test_item=~/Text\s*=\>/) {
               $test_item=~s/Text\s*=\>/${$_[1]}[$_[2]-1]/g;
            }
         } else {
            my $die="The \"Result3 =>\" Setting\n              -> "
                   .${$FullMenu}{$_[0]}[2]{${$_[1]}[$_[2]-1]}
                   ."\n              Found in the Menu Unit -> "
                   .$MenuUnit_hash_ref
                   ."\n              is not a Menu Unit\,"
                   ." and Because it Does Not Have"
                   ."\n              an \"&\" as"
                   ." the Lead Character, $0"
                   ."\n              Cannot Determine "
                   ."if it is a Valid SubRoutine.\n\n";
            die $die;
         }
      }
      chomp($_[2]);
      if ($send_all && keys %{${$Selected}{$_[0]}}) {
         foreach my $item (keys %{${$Selected}{$_[0]}}) {
            ${$Selected}{$_[0]}{$item}='';
         }
      } ${$Selected}{$_[0]}{$_[2]}=$test_item;
      if (ref ${$_[0]}{${$FullMenu}{$_[0]}
            [4]{${$_[1]}[$_[2]-1]}}{'Result'} eq 'HASH') {
         if (exists ${$_[0]}{${$FullMenu}{$_[0]}
               [4]{${$_[1]}[$_[2]-1]}}{'Result'}{'Label'}) {
            ${$SaveNext}{$_[0]}=
               ${${$FullMenu}{$_[0]}[2]}
               {${$_[1]}[$_[2]-1]};
         } else {
            my $die="The \"Result4 =>\" Setting".
                   "\n\t\tFound in the Menu Unit -> ".
                   "${$MenuUnit_hash_ref}{'Label'}\n\t\tis a ".
                   "HASH reference to a Menu Unit\,\n\t\t".
                   "that does NOT EXIST or is NOT EXPORTED".
                   "\n\n\tHint: Make sure the Names of all".
                   "\n\t      Menu Hash Blocks in the\n\t".
                   "      $menu_config_module_file file are\n\t".
                   "      listed in the \@EXPORT list\n\t".
                   "      found at the beginning of\n\t".
                   "      the $menu_config_module_file file\n\n\t".
                   "our \@EXPORT = qw( %Menu_1 %Menu_2 ... )\;\n";
            die $die;
         }
      }
      return $FullMenu,$Conveyed,$SaveNext,$Persists,$Selected,$convey,$parent_menu;
   };

   my $sum_menu=0;my $filtered_menu=0;my $defaults_exist=0;
   while (1) {
      if ($num_pick-$start<=$display_this_many_items) {
         $choose_num=$num_pick-$start;
      } else { $choose_num=$display_this_many_items }
      $numbor=$start+$choose_num+1;my $done=0;my $savechk=0;my %pn=();
      my $sorted_flag=0;
      $Persists{$MenuUnit_hash_ref}={} unless exists
         $Persists{$MenuUnit_hash_ref};
      if (!exists $Persists{$MenuUnit_hash_ref}{defaults}) {
         my $it=${[keys %{${$FullMenu}{$MenuUnit_hash_ref}[5]}]}[0];
         my $def=${$FullMenu}{$MenuUnit_hash_ref}[5]{$it};
         if ($def) {
            $def='.*' if $def eq '*';
            foreach my $item (@{[keys %{${$FullMenu}{$MenuUnit_hash_ref}[5]}]}) {
               if ($item=~/$def/) {
                  $Persists{$MenuUnit_hash_ref}{defaults}=1;
               } 
            }
         }
      }
      $Persists{$MenuUnit_hash_ref}{defaults}=0 unless exists
         $Persists{$MenuUnit_hash_ref}{defaults};
      while ($numbor=~/\d+/ &&
            ($numbor<=$start || $start+$choose_num < $numbor)) {
         my $menu_text='';my $pn='';
         $menu_text.=$banner if defined $banner;
         $menu_text.="\n\n";
         my $picknum=$start+1;
         my $numlist=$choose_num;
         my $mark=' ';my $mark_flg=0;my $prev_menu=0;
         while (0 < $numlist) {
#print "NUMBOR=$numbor AND KEYS PICKS=",keys %picks,"\n";
            if (exists $picks{$picknum}) {
               $mark_flg=1;
               if ($return_from_child_menu) {
                  $mark=$picks{$picknum}=$return_from_child_menu;
                  $prev_menu=$picknum;
               } else { $mark=$picks{$picknum} }
               if ($picks{$picknum} ne '+' && $picks{$picknum} ne '-') {
                  $mark_flg=1;$mark='*';
                  if ((exists ${$FullMenu}{$MenuUnit_hash_ref}[2]
                        {$pickone[$picknum-1]}) && (exists
                        ${$FullMenu}{$MenuUnit_hash_ref}[2]
                        {$pickone[$picknum-1]}{Item_1})) {
                     if (exists ${$FullMenu}{$MenuUnit_hash_ref}[3]
                                         {$pickone[$picknum-1]}) {
                        $convey=${${$FullMenu}{$MenuUnit_hash_ref}[3]
                                         {$pickone[$picknum-1]}}[0];
                     } else { $convey=$pickone[$picknum-1] }
                     eval {
                        ($menu_output,$FullMenu,$Selected,$Conveyed,$SavePick,
                           $SaveLast,$SaveNext,$Persists)=&Menu(${$FullMenu}
                           {$MenuUnit_hash_ref}[2]
                           {$pickone[$picknum-1]},$convey,
                           $recurse_level,$FullMenu,
                           $Selected,$Conveyed,$SavePick,
                           $SaveLast,$SaveNext,$Persists,
                           $MenuUnit_hash_ref,$no_wantarray);
                     };
                     die $@ if $@;
                     chomp($menu_output) if !(ref $menu_output);
#print "WHAT IS MENU1=$menu_output\n";
                     if ($menu_output eq '-') {
                        $picks{$picknum}='-';$mark='-';
                     } elsif ($menu_output eq '+') {
                        $picks{$picknum}='+';$mark='+';
                     } elsif ($menu_output eq 'DONE_SUB') {
print "DONE_SUB1\n";
                        return 'DONE_SUB';
                     } elsif ($menu_output eq 'DONE') {
                        if (1==$recurse_level) {
                           my $subfile=substr($custom_code_module_file,0,-3).'::'
                                 if $custom_code_module_file;
                           $subfile||='';
                           foreach my $sub (&get_subs_from_menu($Selected)) {
                              my @resu=();
                              if (ref $sub eq 'code') {
                                 @resu=$sub->();
                                 if (-1<$#resu) {
                  if ($fullauto && defined $Net::FullAuto::FA_Core::plan) {
print "We have a plan23 in TERM-MENUS!!\n";sleep 5;
                  }
                                    if (wantarray && !no_wantarray) {
                                       return @resu;
                                    } else {
                                       return $resu[0];
                                    } return 'DONE_SUB';
                                 }
                              }
                              eval {
                                 unless (defined eval "\@resu=$subfile$sub" ||
                                         defined eval "\@resu=\&main::$sub") {
                                    if ($@) {
                                       my $die='';
                                       if ($fullauto) {
                                          if ($@=~/Undefined subroutine/) {
                                             if (${$FullMenu}{$_[0]}
                                                   [2]{${$_[1]}[$_[2]-1]}) {
                                                $die="The \"Result5 =>\" Setting"
                                                    ."\n\t\t-> " . ${$FullMenu}{$_[0]}
                                                    [2]{${$_[1]}[$_[2]-1]}
                                                    ."\n\t\tFound in the Menu Unit -> "
                                                    ."${$LookUpMenuName}{$_[0]}\n\t\t"
                                                    ."Specifies a Subroutine"
                                                    ." that Does NOT Exist"
                                                    ."\n\t\tin the User Code "
                                                    ."File $custom_code_module_file\n";
                                             } else { $die=$@ }
                                          } else { $die=$@ }
                                          &Net::FullAuto::FA_Core::handle_error($die);
                                       } else { die $@ }
                                    }
                                 }
                              };
                              if ($@) {
                                 if (unpack('a11',$@) eq 'FATAL ERROR') {
                                    if (defined $log_handle &&
                                          -1<index $log_handle,'*') {
                                       print $log_handle $die;
                                       close($log_handle);
                                    }
                                    die $die;
                                 } else {
                                    my $die="\n       FATAL ERROR! - The Local "
                                       ."System $local_hostname Conveyed\n"
                                       ."              the Following "
                                       ."Unrecoverable Error Condition :\n\n"
                                       ."       $@";
                                    if (defined $log_handle &&
                                          -1<index $log_handle,'*') {
                                       print $log_handle $die;
                                       close($log_handle);
                                    }
                                    if ($fullauto) {
                                       &Net::FullAuto::FA_Core::handle_error($die);
                                    } else { die $die }
                                  }
                              } elsif (-1<$#resu) {
                  if ($fullauto && defined $Net::FullAuto::FA_Core::plan) {
print "We have a plan2 in TERM-MENUS!!\n";sleep 5;
                  }
                                 if (wantarray && !no_wantarray) {
                                    return @resu;
                                 } else {
                                    return $resu[0];
                                 }
                              }
                           }
print "DONE_SUB2\n";
 return 'DONE_SUB';
                        } else { return 'DONE' }
                     } elsif ($menu_output) {
#print "WHAT IS MENU3=$menu_output\n";
                        return $menu_output;
                     } else { $picks{$picknum}='+';$mark='+' }
                  } else {
#print "Yepp1\n";
                     $picks{$picknum}='*';
                  }
               }
            } else { $mark=' ' }
            if (!$hidedefaults && ${$FullMenu}{$MenuUnit_hash_ref}[5]
                  {$pickone[$picknum-1]} && (${$FullMenu}
                  {$MenuUnit_hash_ref}[5]{$pickone[$picknum-1]}
                  eq '*' || $pickone[$picknum-1]=~
                  /${$FullMenu}{$MenuUnit_hash_ref}[5]{$pickone[$picknum-1]}/
                  )) {
               $picks{$picknum}='*';$mark='*';$mark_flg=1;
            }
            $pn=$picknum;
#print "WTF=${$FullMenu}{$MenuUnit_hash_ref}[6]{$pickone[$picknum-1]} AND PNnow=$pn\n";
            if (${$FullMenu}{$MenuUnit_hash_ref}[6]{$pickone[$picknum-1]} &&
                  ${$FullMenu}{$MenuUnit_hash_ref}[6]{$pickone[$picknum-1]}
                  ne '_ZERO_') {
               $pn=${$FullMenu}{$MenuUnit_hash_ref}[6]{$pickone[$picknum-1]};
#print "WHAT IS PN=$pn and PM=$parent_menu and MU=$MenuUnit_hash_ref\n";
#print "COME ON=",keys %{${$SavePick}{$MenuUnit_hash_ref}},"\n";
#print "WTFBABY=${${$SavePick}{$MenuUnit_hash_ref}}{19}\n";
               #$mark=${$SavePick}{$parent_menu}{$pn}||' ';
               $mark=${$SavePick}{$MenuUnit_hash_ref}{$pn}||' ';
               $mark_flg=1 unless $mark eq ' ';
               $Persists{$MenuUnit_hash_ref}{defaults}=1
                 if $Persists{$parent_menu}{defaults};
               if (${$FullMenu}{$MenuUnit_hash_ref}[7]) {
                  $filtered_menu=1;
               } else {
                  $sum_menu=1;
               }
            }
            $pn{$pn}=[ $pickone[$picknum-1],$picknum ];
            $menu_text.="   $mark  $pn. \t$pickone[$picknum-1]\n";
            if ($mark eq ' ' || (exists $picks{$picknum} ||
                  exists $picks{$pn})) {
               ${$_[0]}[$pn-1]=$pickone[$picknum-1];
               #$picknum++;
            } $picknum++;
            $numlist--;
         } $hidedefaults=1;
         unless ($Persists{unattended}) {
            if ($^O ne 'cygwin') {
               unless ($noclear) {
                  if ($^O eq 'MSWin32' || $^O eq 'MSWin64') {
                     system("cmd /c cls");
                     print "\n";
                  } else {
                     print `${clearpath}clear`."\n";
                  }
               } else { print $blanklines }
            } else { print $blanklines }
            print $menu_text;my $ch=0;
            if (wantarray && !$no_wantarray &&
                  (exists ${$MenuUnit_hash_ref}{Select} &&
                  ${$MenuUnit_hash_ref}{Select} eq 'Many')) {
               print "\n";
               unless (keys %{${$FullMenu}{$MenuUnit_hash_ref}[1]}) {
                  print "   a.  Select All.";$ch=1;
               }
               if ($mark_flg==1 || $Persists{$MenuUnit_hash_ref}{defaults}) {
                  print "   c.  Clear All.";print "\n" if $ch;
               }
               print "   f.  Finish.\n";
               if ($filtered_menu || $sum_menu) {
                  print "\n   (Type '<' to return to previous Menu)\n";
               }
               if ($Persists{$MenuUnit_hash_ref}{defaults} && !($filtered_menu || $sum_menu)) {
                  print "\n   == Defaults Selections Exist! == (Type '*' to view them)\n";
               }
            } else {
               if ($Persists{$MenuUnit_hash_ref}{defaults}) {
                  print "\n";
                  print "   c.  Clear Default Selection.\n";
                  print "   f.  Finish with Default Selection.\n";
                  if ($filtered_menu || $sum_menu) {
                     print "\n   (Type '<' to return to previous Menu)\n";
                  } else {
                     print "\n   == Default Selection Exists! == (Type '*' to view it)\n";
                  }
               } elsif ($filtered_menu || $sum_menu) {
                  print "\n   (Type '<' to return to previous Menu)\n";
               }
            }
            if ($display_this_many_items<$num_pick) {
               print "\n   $num_pick Total Choices\n",
                     "\n   Press ENTER \(or \"d\"\) to scroll downward\n",
                     "\n   OR \"u\" to scroll upward  \(Type \"quit\" to quit\)\n";
            } else { print"\n   \(Type \"quit\" to quit\)\n" }
            print"\n   PLEASE ENTER A CHOICE: ";
            $numbor=<STDIN>;$pn=$numbor;chomp $pn;
         } elsif ($Persists{$MenuUnit_hash_ref}{defaults}) {
            $numbor='f';
         } elsif (wantarray && !$no_wantarray) {
            my $die="\n       FATAL ERROR! - 'Unattended' mode cannot\n"
                   ."                         be used without Default\n"
                   ."                         Selections being available.";
            return '',$die;
         } else {
            my $die="\n       FATAL ERROR! - 'Unattended' mode cannot\n"
                   ."                         be used without Default\n"
                   ."                         Selections being available.";
            die($die);
         }
         if ($numbor=~/^f$/i && ((wantarray && !$no_wantarray
               && (exists ${$MenuUnit_hash_ref}{Select} &&
               ${$MenuUnit_hash_ref}{Select} eq 'Many')) ||
               $Persists{$MenuUnit_hash_ref}{defaults})) {
            # FINISH
            my $choice='';my @keys=();
            my $chosen='';
            if ($filtered_menu || $sum_menu) {
               $chosen=$parent_menu;
            } else { $chosen=$MenuUnit_hash_ref }
            @keys=keys %picks;
            if (-1==$#keys) {
               if ($Persists{$MenuUnit_hash_ref}{defaults}) {
#print "WHY DO WE THINK DEFAULTS EXIST?\n";
                  if ($filtered_menu || $sum_menu) {
                     $chosen=$parent_menu;
                  }
                  my $it=${[keys %{${$FullMenu}{$chosen}[5]}]}[0];
                  my $def=${$FullMenu}{$chosen}[5]{$it};
                  $def='.*' if $def eq '*';
                  if ($def) {
                     my $cnt=1;
                     foreach my $item (sort @{[keys %{${$FullMenu}{$chosen}[5]}]}) {
                        if ($item=~/$def/) {
#print "XXXXXCNT=$cnt\n";
                           $picks{$cnt}='*';
                           push @keys, $item;
                        } $cnt++
                     }
                  }
               } else {
                  @keys=keys %{${$SavePick}{$parent_menu}};
#print "WHAT ARE THE FLIPPIN KEYS???=@keys<==\n";
                  if (-1==$#keys) {
### DO CONDITIONAL FOR THIS!!!!!!!!!!!!!!!!!
                     if ($^O ne 'cygwin') {
                        unless ($noclear) {
                           if ($^O eq 'MSWin32' || $^O eq 'MSWin64') {
                              system("cmd /c cls");
                              print "\n";
                           } else {
                              print `${clearpath}clear`."\n";
                           }
                        } else { print $blanklines }
                     } else { print $blanklines }
                     print "\n\n       Attention USER! :\n\n       ",
                           "You have selected \"f\" to finish your\n",
                           "       selections, BUT -> You have not actually\n",
                           "       selected anything!\n\n       Do you wish ",
                           "to quit or re-attempt selecting?\n\n       ",
                           "Type \"quit\" to quit or ENTER to continue ... ";
                     $choice=<STDIN>;
                     chomp($choice);
                     next if lc($choice) ne 'quit';
                     return ']quit['
                  } 
               }
            }
            my $ret_regex=qr/\]?r(e+turn)*\[?/i;
            my $return_values=0;
            sub numerically { $a <=> $b }
            #my @sortedpicks=();
#print "WHAT ARE THE KEYS=@keys<==\n";
            #if ($sum_menu || $filtered_menu) {
            #   @sortedpicks=sort numerically keys
            #      %{${$SavePick}{$chosen}};
            #} else {
            #   @sortedpicks=sort numerically keys %picks;
            #}
#print "WHAT ARE THE SORTED KEYS?=@sortedpicks\n";
            my %dupseen=();
            #foreach my $pk (@sortedpicks) {
            foreach my $pk (sort numerically keys %picks) {
#print "PK=$pk\n";
               $return_values=1 if !exists
                  ${$FullMenu}{$chosen}[2]{${$_[0]}[$pk-1]}
                  || !keys
                  %{${$FullMenu}{$chosen}[2]{${$_[0]}[$pk-1]}}
                  || ${$FullMenu}{$chosen}[2]{${$_[0]}[$pk-1]}
                  =~/$ret_regex/i;
               #if ($filtered_menu || $sorted) {
               if (${${$FullMenu}{$parent_menu}[8]}[$pk-1] &&
                     !${$_[0]}[$pk-1]) {
                  my $txt=${${$FullMenu}{$parent_menu}[8]}[$pk-1];
                  if (-1<index $txt,"__Master_${$}__") {
                     $txt=~
                        s/__Master_${$}__/Local-Host: $local_hostname/sg;
                  }
                  unless (exists $dupseen{$txt}) {
                     push @pickd, $txt;
                  } $dupseen{$txt}='';
               } elsif (${$_[0]}[$pk-1]) {
                  my $txt=${$_[0]}[$pk-1];
                  if (-1<index $txt,"__Master_${$}__") {
                     $txt=~
                        s/__Master_${$}__/Local-Host: $local_hostname/sg;
                  }
                  unless (exists $dupseen{$txt}) {
                     push @pickd, $txt;
                  } $dupseen{$txt}='';
               } elsif ($pn{$picknum}) {
                  my $txt=$pn{$picknum}[0];
                  if (-1<index $txt,"__Master_${$}__") {
                     $txt=~
                        s/__Master_${$}__/Local-Host: $local_hostname/sg;
                  }
                  unless (exists $dupseen{$txt}) {
                     push @pickd, $txt;
                  } $dupseen{$txt}='';
               }
            }
#print "RETURNING4 and PICKD=@pickd\n";<STDIN>;
            return \@pickd if $return_values;
#print "DONE2\n";
            return 'DONE';
         } elsif ($numbor=~/^\s*%(.*)/s) {
            my $one=$1||'';
            chomp $one;
            $one=qr/$one/ if $one;
            my @spl=();
            chomp $numbor;
            my $cnt=0;my $ct=0;my @splice=();
            $sort_ed='';
            if ($one) {

            } elsif ($sorted && $sorted eq 'forward') {
               @spl=reverse @pickone;$sort_ed='reverse';
            } else { @spl=sort @pickone;$sort_ed='forward' }
            next if $#spl==-1;
            my %sorts=();
            foreach my $line (@pickone) {
               $cnt++;
               if (exists $pn{$picknum} &&
                     exists ${$FullMenu}{$MenuUnit_hash_ref}[6]
                     {$pn{$picknum}[0]} && ${$FullMenu}
                     {$MenuUnit_hash_ref}[6]{$pn{$picknum}[0]} &&
                     ${$FullMenu}{$MenuUnit_hash_ref}[6]
                     {$pn{$picknum}[0]} && ${$FullMenu}
                     {$MenuUnit_hash_ref}[6]{$pn{$picknum}[0]}
                     ne '_ZERO_') {
                  $sort{$line}=${$FullMenu}{$MenuUnit_hash_ref}[6]{$line};
               } else { $sort{$line}=$cnt }
            } $cnt=0;
            my $chosen='';
            if (!$sorted) {
               $chosen={
                  Label  => ${$MenuUnit_hash_ref}{Label},
                  Select => ${$MenuUnit_hash_ref}{Select},
                  Banner => ${$MenuUnit_hash_ref}{Banner},
               };
               my $cnt=0;
               foreach my $text (@spl) {
                  my $num=$sort{$text};
                  $cnt++;
                  if (exists $picks{$num}) {
                     $chosen->{'Item_'.$cnt}=
                        { Text => $text,Default => '*',__NUM__=>$num };
                  } else {
                     $chosen->{'Item_'.$cnt}=
                        { Text => $text,__NUM__=>$num };
                  }
                  $chosen->{'Item_'.$cnt}{Result}=
                     ${${$MenuUnit_hash_ref}{${${$FullMenu}
                     {$MenuUnit_hash_ref}[4]}{$text}}}{'Result'}
                     if exists ${${$MenuUnit_hash_ref}{${${$FullMenu}
                     {$MenuUnit_hash_ref}[4]}{$text}}}{'Result'};
                  $chosen->{'Item_'.$cnt}{Sort}=$sort_ed;
               } $sorted=$sort_ed;
            } else {
               @pickone=reverse @pickone;
               next;
            }
            $LookUpMenuName{$chose_n}
               =${$chosen}{'Label'};
            %{${$SavePick}{$chosen}}=%picks;
            ${$SaveLast}{$chosen}=$numbor;
            eval {
               ($menu_output,$FullMenu,$Selected,$Conveyed,$SavePick,
                  $SaveLast,$SaveNext,$Persists)=&Menu($chosen,$picks_from_parent,
                  $recurse_level,$FullMenu,
                  $Selected,$Conveyed,$SavePick,
                  $SaveLast,$SaveNext,$Persists,
                  $MenuUnit_hash_ref,$no_wantarray);
            };
            die $@ if $@;
            chomp($menu_output) if !(ref $menu_output);
#print "WHAT IS MENU4=$menu_output\n";
            if ($menu_output eq '-') {
               %picks=%{${$SavePick}{$MenuUnit_hash_ref}};
            } elsif ($menu_output eq '+') {
               %picks=%{${$SavePick}{$MenuUnit_hash_ref}};
            } elsif ($menu_output eq 'DONE_SUB') {
print "DONE_SUB3\n";
               return 'DONE_SUB';
            } elsif ($menu_output eq 'DONE') {
               if (1==$recurse_level) {
                  my $subfile=substr($custom_code_module_file,0,-3).'::'
                        if $custom_code_module_file;
                  $subfile||='';
                  foreach my $sub (&get_subs_from_menu($Selected)) {
                     my @resu=();
                     eval {
                        unless (defined eval "\@resu=$subfile$sub" ||
                                defined eval "\@resu=\&main::$sub") {
                           if ($@) {
                              my $die='';
                              if ($fullauto) {
                                 if ($@=~/Undefined subroutine/) {
                                    if (${$FullMenu}{$_[0]}
                                          [2]{${$_[1]}[$_[2]-1]}) {
                                       $die="The \"Result6 =>\" Setting"
                                           ."\n\t\t-> " . ${$FullMenu}{$_[0]}
                                           [2]{${$_[1]}[$_[2]-1]}
                                           ."\n\t\tFound in the Menu Unit -> "
                                           ."${$LookUpMenuName}{$_[0]}\n\t\t"
                                           ."Specifies a Subroutine"
                                           ." that Does NOT Exist"
                                           ."\n\t\tin the User Code "
                                           ."File $custom_code_module_file\n";
                                     } else { $die=$@ }
                                 } else { $die=$@ }
                                 &Net::FullAuto::FA_Core::handle_error($die);
                              } else { die $@ }
                           }
                        }
                     };
                     if ($@) {
                        if (unpack('a11',$@) eq 'FATAL ERROR') {
                           if (defined $log_handle &&
                                 -1<index $log_handle,'*') {
                              print $log_handle $die;
                              close($log_handle);
                           }
                           die $die;
                        } else {
                           my $die="\n       FATAL ERROR! - The Local "
                              ."System $local_hostname Conveyed\n"
                              ."              the Following "
                              ."Unrecoverable Error Condition :\n\n"
                              ."       $@";
                           if (defined $log_handle &&
                                 -1<index $log_handle,'*') {
                              print $log_handle $die;
                              close($log_handle);
                           }
                           if ($fullauto) {
                              &Net::FullAuto::FA_Core::handle_error($die);
                           } else { die $die }
                        }
                     } elsif (-1<$#resu) {
                        if (wantarray && !no_wantarray) {
                  if ($fullauto && defined $Net::FullAuto::FA_Core::plan) {
print "We have a plan3 in TERM-MENUS!!\n";sleep 5;
                  }
                           return @resu;
                        } else {
                           return $resu[0];
                        }
                     }
                  }
print "DONE_SUB4\n";
 return 'DONE_SUB';
               } else { return 'DONE' }
            } elsif ($menu_output) {
#print "WHAT IS MENU5=$menu_output\n";
               return $menu_output;
            } else { %picks=%{${$SavePick}{$MenuUnit_hash_ref}} }
            #print "DO THE SORT\n";<STDIN>;
         } elsif ($numbor=~/^\*\s*$/s) {
            ## STAR SELECTED
            #if (!exists ${$MenuUnit_hash_ref}{Select} ||
            #      ${$MenuUnit_hash_ref}{Select} eq 'One') {
            #   print "\n   ERROR: Cannot Show Multiple Selected Items\n".
            #         "          When 'Select' is NOT set to 'Many'\n";
            #   sleep 3;next;
            #}
            my @splice=();
            if ($filtered_menu) {
#print "ARE WE FILTERED??\n";
               foreach my $key (keys %{${$SavePick}{$parent_menu}}) {
                  $picks{$key}='*';
               }
               foreach my $key (keys %picks) {
                  if ($parent_menu) {
                     ${${$SavePick}{$parent_menu}}{$key}='*';
                  } else {
                     ${${$SavePick}{$MenuUnit_hash_ref}}{$key}='*';
                  }
               }
            }
            if ($Persists{$MenuUnit_hash_ref}{defaults}) {
               my $it=${[keys %{${$FullMenu}{$MenuUnit_hash_ref}[5]}]}[0];
               $def=${$FullMenu}{$MenuUnit_hash_ref}[5]{$it};
               $def='.*' if $def eq '*';
               if ($def) {
                  my $cnt=1;
                  foreach my $item (sort @{[keys %{${$FullMenu}{$MenuUnit_hash_ref}[5]}]}) {
                     if ($item=~/$def/) {
                        $picks{$cnt}='*';
                     } $cnt++
                  }
               }
            }
            foreach my $pick (sort numerically keys %picks) {
               push @splice,($pick-1)
            }
            foreach $spl (@splice) {
               if ($parent_menu) {
                  push @spl, ${${$FullMenu}{$parent_menu}[8]}[$spl];
               } else {
                  push @spl, ${${$FullMenu}{$MenuUnit_hash_ref}[8]}[$spl];
               }
            }
            my $chosen={
               Label  => ${$MenuUnit_hash_ref}{Label},
               Select => ${$MenuUnit_hash_ref}{Select},
               Banner => ${$MenuUnit_hash_ref}{Banner},
            }; my $cnt=0;
            my $hash_ref=$parent_menu||$MenuUnit_hash_ref;
            foreach my $text (@spl) {
#print "WHAT IS TEXT=$text\n";
               my $num=shift @splice;
               $cnt++;
               $chosen->{'Item_'.$cnt}=
                  { Text => $text,Default => '*',__NUM__=>$num+1 };
               $chosen->{'Item_'.$cnt}{Result}=
                  ${${$MenuUnit_hash_ref}{${${$FullMenu}
                  {$MenuUnit_hash_ref}[4]}{$text}}}{'Result'}
                  if exists ${${$MenuUnit_hash_ref}{${${$FullMenu}
                  {$MenuUnit_hash_ref}[4]}{$text}}}{'Result'};
               $chosen->{'Item_'.$cnt}{Filter}=1;
            }
#print "NUMBOR=$numbor AND KEYS PICKS=",keys %picks,"\n";
            $LookUpMenuName{$chosen}
               =${$chosen}{'Label'};
#print "WHAT THE HELL IS CHOSEN?=$chosen\n";
            %{${$SavePick}{$chosen}}=%picks;
#print "WHAT THE HECK=${${$SavePick}{$chosen}}{19}\n";
            ${$SaveLast}{$chosen}=$numbor;
            $hidedefaults=1;
            eval {
               ($menu_output,$FullMenu,$Selected,$Conveyed,$SavePick,
                  $SaveLast,$SaveNext,$Persists,$ignore1,$ignore2,$ignore3,$die_err)
                  =&Menu($chosen,$picks_from_parent,
                  $recurse_level,$FullMenu,
                  $Selected,$Conveyed,$SavePick,
                  $SaveLast,$SaveNext,$Persists,
                  $MenuUnit_hash_ref,$no_wantarray);
            };
            die $@ if $@;
#print "WHAT IS MENU6=$menu_output\n";
            chomp($menu_output) if !(ref $menu_output);
            if ($menu_output eq '-') {
               %picks=%{${$SavePick}{$MenuUnit_hash_ref}};
            } elsif ($menu_output eq '+') {
               %picks=%{${$SavePick}{$MenuUnit_hash_ref}};
            } elsif ($menu_output eq 'DONE_SUB') {
print "DONE_SUB5\n";
               return 'DONE_SUB';
            } elsif ($menu_output eq 'DONE') {
               if (1==$recurse_level) {
                  my $subfile=substr($custom_code_module_file,0,-3).'::'
                        if $custom_code_module_file;
                  $subfile||='';
                  foreach my $sub (&get_subs_from_menu($Selected)) {
                     my @resu=();
                     eval {
                        unless (defined eval "\@resu=$subfile$sub" ||
                                defined eval "\@resu=\&main::$sub") {
                           if ($@) {
                              my $die='';
                              if ($fullauto) {
                                 if ($@=~/Undefined subroutine/) {
                                    if (${$FullMenu}{$_[0]}
                                          [2]{${$_[1]}[$_[2]-1]}) {
                                       $die="The \"Result7 =>\" Setting"
                                           ."\n\t\t-> " . ${$FullMenu}{$_[0]}
                                           [2]{${$_[1]}[$_[2]-1]}
                                           ."\n\t\tFound in the Menu Unit -> "
                                           ."${$LookUpMenuName}{$_[0]}\n\t\t"
                                           ."Specifies a Subroutine"
                                           ." that Does NOT Exist"
                                           ."\n\t\tin the User Code "
                                           ."File $custom_code_module_file\n";
                                    } else { $die=$@ }
                                 } else { $die=$@ }
                                 &Net::FullAuto::FA_Core::handle_error($die);
                              } else { die $@ }
                           }
                        }
                     };
                     if ($@) {
                        if (unpack('a11',$@) eq 'FATAL ERROR') {
                           if (defined $log_handle &&
                                 -1<index $log_handle,'*') {
                              print $log_handle $die;
                              close($log_handle);
                           }
                           die $die;
                        } else {
                           my $die="\n       FATAL ERROR! - The Local "
                              ."System $local_hostname Conveyed\n"
                              ."              the Following "
                              ."Unrecoverable Error Condition :\n\n"
                              ."       $@";
                           if (defined $log_handle &&
                                 -1<index $log_handle,'*') {
                              print $log_handle $die;
                              close($log_handle);
                           }
                           if ($fullauto) {
                              &Net::FullAuto::FA_Core::handle_error($die);
                           } else { die $die }
                        }
                     } elsif (-1<$#resu) {
                  if ($fullauto && defined $Net::FullAuto::FA_Core::plan) {
print "We have a plan4 in TERM-MENUS!!\n";sleep 5;
                  }
                        if (wantarray && !no_wantarray) {
                           return @resu;
                        } else {
                           return $resu[0];
                        }
                     }
                  }
print "DONE_SUB6\n";
 return 'DONE_SUB';
               } else { return 'DONE' }
            } elsif ($menu_output) {
#print "WHAT IS MENU7=$menu_output\n";
               return $menu_output;
            } else { %picks=%{${$SavePick}{$MenuUnit_hash_ref}} }
         } elsif ($numbor=~/^\s*\/(.+)$/s) {
            ## SLASH SEARCH
            my $one=$1||'';
            chomp $one;
            $one=~s/\*/[\*]/g;
            $one=~s/\+/[\+]/g;
            $one=qr/$one/ if $one;
            my @spl=();
            chomp $numbor;
            my $def='';
            unless (exists $Persists{$MenuUnit_hash_ref}{defaults}) {
               my $it=${[keys %{${$FullMenu}{$MenuUnit_hash_ref}[5]}]}[0];
               $def=${$FullMenu}{$MenuUnit_hash_ref}[5]{$it};
               $def='.*' if $def eq '*';
               if ($def) {
                  my $cnt=1;
                  foreach my $item (sort @{[keys %{${$FullMenu}{$MenuUnit_hash_ref}[5]}]}) {
                     if ($item=~/$def/) {
                        $picks{$cnt}='*';
                     } $cnt++
                  }
               }
            }

            my $cnt=0;my $ct=0;my @splice=();
            foreach my $pik (@pickone) {
               $cnt++;
               if ($pik=~/$one/s) {
                  push @spl, $pik;
                  $splice[$ct++]=$cnt;
               }
            }
            next if $#spl==-1;
            my $chosen={
               Label  => ${$MenuUnit_hash_ref}{Label},
               Select => ${$MenuUnit_hash_ref}{Select},
               Banner => ${$MenuUnit_hash_ref}{Banner},
            }; $cnt=0;
            foreach my $text (@spl) {
               my $num=$splice[$cnt];
               $cnt++;
               if (exists $picks{$num}) {
                  $chosen->{'Item_'.$cnt}=
                     { Text => $text,Default => '*',__NUM__=>$num };
               } elsif ($def && $text=~/$def/) {
                  $chosen->{'Item_'.$cnt}=
                     { Text => $text,Default => '*',__NUM__=>$num };
                  $picks{$num}='*';
               } else {
                  $chosen->{'Item_'.$cnt}=
                     { Text => $text,__NUM__=>$num };
               }
               $chosen->{'Item_'.$cnt}{Result}=
                  ${${$MenuUnit_hash_ref}{${${$FullMenu}
                  {$MenuUnit_hash_ref}[4]}{$text}}}{'Result'}
                  if exists ${${$MenuUnit_hash_ref}{${${$FullMenu}
                  {$MenuUnit_hash_ref}[4]}{$text}}}{'Result'};
               $chosen->{'Item_'.$cnt}{Filter}=1;
            }
            $LookUpMenuName{$chosen}
               =${$chosen}{'Label'};
            %{${$SavePick}{$chosen}}=%picks;
            ${$SaveLast}{$chosen}=$numbor;
            eval {
               ($menu_output,$FullMenu,$Selected,$Conveyed,$SavePick,
                  $SaveLast,$SaveNext,$Persists)=&Menu($chosen,$picks_from_parent,
                  $recurse_level,$FullMenu,
                  $Selected,$Conveyed,$SavePick,
                  $SaveLast,$SaveNext,$Persists,
                  $MenuUnit_hash_ref,$no_wantarray);
            };
            die $@ if $@;
            chomp($menu_output) if !(ref $menu_output);
#print "WHAT IS MENU8=$menu_output\n";
            if ($menu_output eq '-') {
               %picks=%{${$SavePick}{$MenuUnit_hash_ref}};
            } elsif ($menu_output eq '+') {
               %picks=%{${$SavePick}{$MenuUnit_hash_ref}};
            } elsif ($menu_output eq 'DONE_SUB') {
print "DONE_SUB7\n";
               return 'DONE_SUB';
            } elsif ($menu_output eq 'DONE') {
               if (1==$recurse_level) {
                  my $subfile=substr($custom_code_module_file,0,-3).'::'
                        if $custom_code_module_file;
                  $subfile||='';
                  foreach my $sub (&get_subs_from_menu($Selected)) {
                     my @resu=();
                     eval {
                        unless (defined eval "\@resu=$subfile$sub" ||
                                defined eval "\@resu=\&main::$sub") {
                           if ($@) {
                              my $die='';
                              if ($fullauto) {
                                 if ($@=~/Undefined subroutine/) {
                                    if (${$FullMenu}{$_[0]}
                                          [2]{${$_[1]}[$_[2]-1]}) {
                                       $die="The \"Result8 =>\" Setting"
                                           ."\n\t\t-> " . ${$FullMenu}{$_[0]}
                                           [2]{${$_[1]}[$_[2]-1]}
                                           ."\n\t\tFound in the Menu Unit -> "
                                           ."${$LookUpMenuName}{$_[0]}\n\t\t"
                                           ."Specifies a Subroutine"
                                           ." that Does NOT Exist"
                                           ."\n\t\tin the User Code "
                                           ."File $custom_code_module_file\n";
                                    } else { $die=$@ }
                                 } else { $die=$@ }
                                 &Net::FullAuto::FA_Core::handle_error($die);
                              } else { die $@ }
                           }
                        }
                     };
                     if ($@) {
                        if (unpack('a11',$@) eq 'FATAL ERROR') {
                           die $die;
                        } else {
                           my $die="\n       FATAL ERROR! - The Local "
                                  ."System $local_hostname Conveyed\n"
                                  ."              the Following "
                                  ."Unrecoverable Error Condition :\n\n"
                                  ."       $@";
                           if (defined $log_handle &&
                                 -1<index $log_handle,'*') {
                              print $log_handle $die;
                              close($log_handle);
                           }
                           if ($fullauto) {
                              &Net::FullAuto::FA_Core::handle_error($die);
                           } else { die $die }
                        }
                     } elsif (-1<$#resu) {
                  if ($fullauto && defined $Net::FullAuto::FA_Core::plan) {
print "We have a plan5 in TERM-MENUS!!\n";sleep 5;
                  }
                        if (wantarray && !no_wantarray) {
                           return @resu;
                        } else {
                           return $resu[0];
                        }
                     }
                  }
print "DONE_SUB8\n";
 return 'DONE_SUB';
               } else { return 'DONE' }
            } elsif ($menu_output eq '-') {
               $return_from_child_menu='-';
            } elsif ($menu_output eq '+') {
               $return_from_child_menu='+';
            } elsif ($menu_output) {
#print "WHAT IS MENU9=$menu_output\n";
               return $menu_output;
            }
         } elsif ($numbor=~/^\</ && $FullMenu) {
            if ($recurse_level==1) {
               print "\n   WARNING! - You are at the First Menu!",
                     "\n   (Press any key to continue ...) ";<STDIN>;
            } elsif (grep { /\+|\*/ } values %picks) {
               #delete ${$SaveLast}{$MenuUnit_hash_ref};
               #delete ${$SaveNext}{$MenuUnit_hash_ref};
               return '+',
                  $FullMenu,$Selected,$Conveyed,
                  $SavePick,$SaveLast,$SaveNext,
                  $Persists,$parent_menu;
            } else {
               #delete ${$SaveLast}{$MenuUnit_hash_ref};
               #delete ${$SaveNext}{$MenuUnit_hash_ref};
               return '-',
                  $FullMenu,$Selected,$Conveyed,
                  $SavePick,$SaveLast,$SaveNext,
                  $Persists,$parent_menu;
            } last;
         } elsif ($numbor=~/^\>/ && exists
                  ${$SaveNext}{$MenuUnit_hash_ref}) {
            if (exists ${$FullMenu}{$MenuUnit_hash_ref}[3]
                  {$pickone[${$SaveLast}{
                  $MenuUnit_hash_ref}-1]}) {
               $convey=${${$FullMenu}{$MenuUnit_hash_ref}[3]
                  {$pickone[${$SaveLast}{
                  $MenuUnit_hash_ref}-1]}}[0];
            } else {
               $convey=$pickone[${$SaveLast}{
                  $MenuUnit_hash_ref}-1]
            }
            eval {
               ($menu_output,$FullMenu,$Selected,$Conveyed,$SavePick,
                  $SaveLast,$SaveNext,$Persists,$ignore1,$ignore2,$ignore3,$die_err)
                  =&Menu(${$FullMenu}
                  {$MenuUnit_hash_ref}[2]
                  {$pickone[${$SaveLast}{
                  $MenuUnit_hash_ref}-1]},$convey,
                  $recurse_level,$FullMenu,
                  $Selected,$Conveyed,$SavePick,
                  $SaveLast,$SaveNext,$Persists,
                  $MenuUnit_hash_ref,$no_wantarray);
            };
            die $@ if $@;
            chomp($menu_output) if !(ref $menu_output);
#print "WHAT IS MENU10=$menu_output\n";
            if ($menu_output eq 'DONE_SUB') {
print "DONE_SUB9\n";
               return 'DONE_SUB';
            } elsif ($menu_output eq 'DONE') {
               if (1==$recurse_level) {
                  my $subfile=substr($custom_code_module_file,0,-3).'::'
                        if $custom_code_module_file;
                  $subfile||='';
                  foreach my $sub (&get_subs_from_menu($Selected)) {
                     my @resu=();
                     eval {
                        unless (defined eval "\@resu=$subfile$sub" ||
                                defined eval "\@resu=\&main::$sub") {
                           if ($@) {
                              my $die='';
                              if ($fullauto) {
                                 if ($@=~/Undefined subroutine/) {
                                    if (${$FullMenu}{$_[0]}
                                          [2]{${$_[1]}[$_[2]-1]}) {
                                       $die="The \"Result9 =>\" Setting"
                                           ."\n\t\t-> " . ${$FullMenu}{$_[0]}
                                           [2]{${$_[1]}[$_[2]-1]}
                                           ."\n\t\tFound in the Menu Unit -> "
                                           ."${$LookUpMenuName}{$_[0]}\n\t\t"
                                           ."Specifies a Subroutine"
                                           ." that Does NOT Exist"
                                           ."\n\t\tin the User Code "
                                           ."File $custom_code_module_file\n";
                                    } else { $die=$@ }
                                 } else { $die=$@ }
                                 &Net::FullAuto::FA_Core::handle_error($die);
                              } else { die $@ }
                           }
                        }
                     };
                     if ($@) {
                        if (unpack('a11',$@) eq 'FATAL ERROR') {
                           if (defined $log_handle &&
                                 -1<index $log_handle,'*') {
                              print $log_handle $die;
                              close($log_handle);
                           }
                           die $die;
                        } else {
                           my $die="\n       FATAL ERROR! - The Local "
                              ."System $local_hostname Conveyed\n"
                              ."              the Following "
                              ."Unrecoverable Error Condition :\n\n"
                              ."       $@";
                           if (defined $log_handle &&
                                 -1<index $log_handle,'*') {
                              print $log_handle $die;
                              close($log_handle);
                           }
                           if ($fullauto) {
                              &Net::FullAuto::FA_Core::handle_error($die);
                           } else { die $die }
                        }
                     } elsif (-1<$#resu) {
                  if ($fullauto && defined $Net::FullAuto::FA_Core::plan) {
print "We have a plan6 in TERM-MENUS!!\n";sleep 5;
                  }
                        if (wantarray && !no_wantarray) {
                           return @resu;
                        } else {
                           return $resu[0];
                        }
                     }
                  } 
print "DONE_SUB10\n";
return 'DONE_SUB';
               } else { return 'DONE' }
            } elsif ($menu_output eq '-') {
               $return_from_child_menu='-';
            } elsif ($menu_output eq '+') {
               $return_from_child_menu='+';
            } elsif ($menu_output) {
#print "WHAT IS MENU11=$menu_output\n";
               return $menu_output;
            }
         } elsif ($numbor=~/^quit$/i) {
            return ']quit['
         } elsif (!keys %{${$FullMenu}{$MenuUnit_hash_ref}[1]}
                                             && $numbor=~/^a$/i) {
            if (!exists ${$MenuUnit_hash_ref}{Select} ||
                  ${$MenuUnit_hash_ref}{Select} eq 'One') {
               print "\n   ERROR: Cannot Select All Items\n".
                     "          When 'Select' is NOT set to 'Many'\n";
               sleep 3;next;
            }
            if ($sum_menu || $filtered_menu) {
               foreach my $key (keys %{${$FullMenu}{$MenuUnit_hash_ref}[6]}) {
                  ${$SavePick}{$parent_menu}{${$FullMenu}
                     {$MenuUnit_hash_ref}[6]{$key}}='*';
               }
            } else {
               my $ch_num=$num_pick;
               while (1) {
                  $picks{$ch_num--}="a";
                  last if $ch_num==0;
               }
            }
         } elsif ($numbor=~/^c$/i) {
            ## CLEAR ALL CLEARALL
#print "WHAT IS SUM_MENU=$sum_menu and FILTERED_MENU=$filtered_menu\n";sleep 2;
            if ($sum_menu || $filtered_menu) {
               foreach my $key (keys %{${$FullMenu}{$MenuUnit_hash_ref}[6]}) {
                  delete ${$SavePick}{$parent_menu}{${$FullMenu}
                     {$MenuUnit_hash_ref}[6]{$key}};
               }
               foreach my $pick (keys %picks) {
                  if (exists $picks{$pick}) {
                     if ($picks{$pick} eq '*' || $picks{$pick} eq 'a') {
                        delete $picks{$pick};
                        delete $items{$pick};
                        delete ${$Selected}{$MenuUnit_hash_ref}{$pick};
                        delete ${$Selected}{$parent_menu}{$pick};  
                        delete ${$SavePick}{$MenuUnit_hash_ref}{$pick};
                        delete ${$SavePick}{$parent_menu}{$pick};
                     } elsif ($picks{$pick} eq '+') {
                        &delete_Selected($MenuUnit_hash_ref,$pick,
                           $Selected,$SavePick,$SaveNext,$Persists);
                        $SaveNext=$SaveLast;
                        delete $picks{$pick};
                        delete $items{$pick};
                     }
                  }
               } ${$FullMenu}{$parent_menu}[5]='';
               $Persists{$MenuUnit_hash_ref}{defaults}=0;
               $Persists{$parent_menu}{defaults}=0; 
            } else {
               foreach my $pick (keys %picks) {
                  if (exists $picks{$pick}) {
                     if ($picks{$pick} eq '*' || $picks{$pick} eq 'a') {
                        delete $picks{$pick};
                        delete $items{$pick};
                        delete ${$Selected}{$MenuUnit_hash_ref}{$pick};
                     } elsif ($picks{$pick} eq '+') {
                        &delete_Selected($MenuUnit_hash_ref,$pick,
                           $Selected,$SavePick,$SaveNext,$Persists);
                        $SaveNext=$SaveLast;
                        delete $picks{$pick};
                        delete $items{$pick};
                     }
                  }
               } ${$FullMenu}{$MenuUnit_hash_ref}[5]='';
               $Persists{$MenuUnit_hash_ref}{defaults}=0;
            }
         }
         if ($numbor=~/^()$/ || $numbor=~/^\n/ || $numbor=~/^d$/i) {
            if ($display_this_many_items<$num_pick-$start) {
               $start=$start+$display_this_many_items;
            } else { $start=0 }
            $hidedefaults=0;
            $numbor=$start+$choose_num+1;
            last;
         } elsif ($numbor=~/^u$/i) {
            if (0<=$start-$display_this_many_items) {
               $start=$start-$display_this_many_items;
            } else { $start=0 }
            $numbor=$start+$choose_num+1;
            last;
         } chomp $numbor;
         if ($numbor!~/^\d+$/ && !$return_from_child_menu) {
            $numbor=$start+$choose_num+1;
            last;
         } elsif (exists $pn{$numbor}) {
            # NUMBOR CHOSEN
#print "ARE WE HERE and PN=$pn and NUMBOR=$numbor and SUM=$sum_menu\n";sleep 2;%pn=();
#print "ALLLLL=${$FullMenu}{$MenuUnit_hash_ref}[2]{$pn{$numbor}[0]}<==\n";
            my $callertest=__PACKAGE__."::Menu";
            if ($Persists{$MenuUnit_hash_ref}{defaults}) {
               $Persists{$MenuUnit_hash_ref}{defaults}=0;
               $Persists{$parent_menu}{defaults}=0 if $parent_menu;
               foreach my $pick (keys %picks) {
                  if (exists $picks{$pick} && !$picks{$numbor}) {
                     if ($picks{$pick} eq '*' || $picks{$pick} eq 'a') {
                        delete $picks{$pick};
                        delete $items{$pick};
                        delete ${$Selected}{$MenuUnit_hash_ref}{$pick};
                     } elsif ($picks{$pick} eq '+') {
                        &delete_Selected($MenuUnit_hash_ref,$pick,
                           $Selected,$SavePick,$SaveNext,$Persists);
                        $SaveNext=$SaveLast;
                        delete $picks{$pick};
                        delete $items{$pick};
                     }
                  }
               } ${$FullMenu}{$MenuUnit_hash_ref}[5]='';
            }
            if (wantarray && !$no_wantarray &&
                  (exists ${$MenuUnit_hash_ref}{Select} &&
                  ${$MenuUnit_hash_ref}{Select} eq 'Many')) {
#print "WHAT IS PNXXXX=$pn and THIS=$picks{$picknum-1} and keys=",(join "\n",keys %{${$SavePick}{$parent_menu}})," and $numbor and SUMMENU=$sum_menu<==\n";<STDIN>;
               if (exists $picks{$numbor}) {
                  if ($picks{$numbor} eq '*') {
                     delete $picks{$numbor};
                     delete $items{$numbor};
                     delete ${$Selected}{$MenuUnit_hash_ref}{$numbor};
                     delete ${$SavePick}{$parent_menu}{$numbor}
                        if $sum_menu || $filtered_menu;
#print "WHAT IS PNXXXX=$pn and THIS=$picks{$picknum-1} and keys=",(join "\n",keys %{${$SavePick}{$parent_menu}})," and NUMBOR=$numbor and SUMMENU=$sum_menu<==\n";<STDIN>;
                  } else {
                     &delete_Selected($MenuUnit_hash_ref,$numbor,
                         $Selected,$SavePick,$SaveNext,$Persists);
                     $SaveNext=$SaveLast;
                     delete $picks{$numbor};
                     delete $items{$numbor};
                  }
               } elsif (($sum_menu || $filtered_menu) && (exists
                     ${$SavePick}{$parent_menu}{$numbor})) {
#print "ARE WE HERE?22222222\n";
                  if ($Persists{$parent_menu}{defaults}) {
                     $Persists{$parent_menu}{defaults}=0;
                     $Persists{$MenuUnit_hash_ref}{defaults}=0;
                     foreach my $pick (keys %picks) {
                        if (exists $picks{$pick} && !$picks{$numbor}) {
                           if ($picks{$pick} eq '*' || $picks{$pick} eq 'a') {
                              delete $picks{$pick};
                              delete $items{$pick};
                              delete ${$Selected}{$parent_menu}{$pick};
                           } elsif ($picks{$pick} eq '+') {
                              &delete_Selected($parent_menu,$pick,
                                 $Selected,$SavePick,$SaveNext,$Persists);
                              $SaveNext=$SaveLast;
                              delete $picks{$pick};
                              delete $items{$pick};
                           }
                        }
                     } ${$FullMenu}{$MenuUnit_hash_ref}[5]='';
                  }
                  delete ${$Selected}{$MenuUnit_hash_ref}{$numbor};
                  delete $picks{$numbor};
                  delete $items{$numbor};
                  delete ${$SaveNext}{$MenuUnit_hash_ref};
                  delete ${$SavePick}{$parent_menu}{$numbor};
               } else {
                  $items{$numbor}=${$FullMenu}{$MenuUnit_hash_ref}
                                             [4]{$pn{$numbor}[0]};
                  ${$SavePick}{$parent_menu}{$numbor}='*'
                     if $sum_menu || $filtered_menu;
                  my $skip=0;
                  foreach my $key (keys %picks) {
                     if ($picks{$key} ne '-' &&
                           (grep { $items{$numbor} eq $_ }
                           @{$negate{$key}})) {
                        my $warn="\n   WARNING! You Cannot Select ";
                        $warn.="Line $numbor while Line $key is Selected!\n";
                        print "$warn";<STDIN>;
                        $skip=1;
                     } elsif ($picks{$key} eq '-') {
                        delete ${$Selected}{$MenuUnit_hash_ref}{$key};
                        delete $picks{$key};
                        delete ${$SaveNext}{$MenuUnit_hash_ref};
                     }
                  }
                  if ($skip==0) {
                     $picks{$numbor}='*';
                     $negate{$numbor}=
                        ${${$FullMenu}{$MenuUnit_hash_ref}[1]}
                        {$pn{$numbor}[0]};
                     %{${$SavePick}{$MenuUnit_hash_ref}}=%picks;
                     ${$SaveLast}{$MenuUnit_hash_ref}=$numbor;
                  }
               }
               if ($prev_menu && $prev_menu!=$numbor) {
                  &delete_Selected($MenuUnit_hash_ref,$prev_menu,
                     $Selected,$SavePick,$SaveNext,$Persists);
                  delete $picks{$prev_menu};
                  delete $items{$prev_menu};
               }
            } elsif (ref ${$FullMenu}{$MenuUnit_hash_ref}[2]
                         {$pn{$numbor}[0]} eq 'HASH') {
#print "PICKSNUMBER=$numbor<== and keys=",keys %{${$FullMenu}{$MenuUnit_hash_ref}[2]{$pn{$numbor}[0]}},"\n";sleep 2;
               if (exists ${$FullMenu}{$MenuUnit_hash_ref}[2]
                         {$pn{$numbor}[0]}{'Label'}) {
                  chomp($numbor);
                  if (exists $picks{$numbor}) {
                     ${$FullMenu}{$MenuUnit_hash_ref}[5]='ERASE';
                     $hidedefaults=0;
                     $SaveNext=$SaveLast;
                     if ($picks{$numbor} eq '*') {
                        delete $picks{$numbor};
                        delete $items{$numbor};
                        delete ${$Selected}{$MenuUnit_hash_ref}{$numbor};
                     } elsif ($picks{$numbor} ne ' ') {
                        &delete_Selected($MenuUnit_hash_ref,$numbor,
                           $Selected,$SavePick,$SaveNext,$Persists);
                        delete $picks{$numbor};
                        delete $items{$numbor};
                     }
                  }
                  if ($prev_menu && $prev_menu!=$numbor) {
                     ${$FullMenu}{$MenuUnit_hash_ref}[5]='ERASE';
                     $hidedefaults=0;
                     $SaveNext=$SaveLast;
                     &delete_Selected($MenuUnit_hash_ref,$prev_menu,
                        $Selected,$SavePick,$SaveNext,$Persists);
                     delete $picks{$prev_menu};
                     delete $items{$prev_menu};
                  }
                  ($FullMenu,$Conveyed,$SaveNext,$Persists,$Selected,
                     $convey,$parent_menu)
                     =$get_result->($MenuUnit_hash_ref,
                     \@pickone,$pn{$pn}[1],$picks_from_parent,
                     $FullMenu,$Conveyed,$Selected,
                     $SaveNext,$Persists,$parent_menu,$menu_config_module_file,
                     $Convey_contents);
                  $picks{$numbor}='-';
                  %{${$SavePick}{$MenuUnit_hash_ref}}=%picks;
                  ${$SaveLast}{$MenuUnit_hash_ref}=$numbor;
                  eval {
                     ($menu_output,$FullMenu,$Selected,$Conveyed,$SavePick,
                        $SaveLast,$SaveNext,$Persists,$parent_menu)=&Menu(${$FullMenu}
                        {$MenuUnit_hash_ref}[2]
                        {$pn{$numbor}[0]},$convey,
                        $recurse_level,$FullMenu,
                        $Selected,$Conveyed,$SavePick,
                        $SaveLast,$SaveNext,$Persists,
                        $MenuUnit_hash_ref,$no_wantarray);
                  };
                  die $@ if $@;
                  chomp($menu_output) if !(ref $menu_output);
#print "WHAT IS MENU12=$menu_output\n";
                  if ($menu_output eq '-') {
                     $return_from_child_menu='-';
                  } elsif ($menu_output eq '+') {
                     $return_from_child_menu='+';
                  } elsif ($menu_output eq 'DONE_SUB') {
print "DONE_SUB11\n";
                     return 'DONE_SUB';
                  } elsif ($menu_output eq 'DONE' and 1<$recurse_level) {
                     return 'DONE';
                  } elsif ($menu_output) {
                     return $menu_output;
                  } else {
                     my $subfile=substr($custom_code_module_file,0,-3).'::'
                           if $custom_code_module_file;
                     $subfile||='';
                     foreach my $sub (&get_subs_from_menu($Selected)) {
                        my @resu=();
                        eval {
                           unless (defined eval "\@resu=$subfile$sub" ||
                                   defined eval "\@resu=\&main::$sub") {
                              if ($@) {
                                 my $die='';
                                 if ($fullauto) {
                                    if ($@=~/Undefined subroutine/) {
                                       if (${$FullMenu}{$_[0]}
                                             [2]{${$_[1]}[$_[2]-1]}) {
                                          $die="The \"Result10 =>\" Setting"
                                              ."\n\t\t-> " . ${$FullMenu}{$_[0]}
                                              [2]{${$_[1]}[$_[2]-1]}
                                              ."\n\t\tFound in the Menu Unit -> "
                                              ."${$LookUpMenuName}{$_[0]}\n\t\t"
                                              ."Specifies a Subroutine"
                                              ." that Does NOT Exist"
                                              ."\n\t\tin the User Code "
                                              ."File $custom_code_module_file\n";
                                       } else { $die=$@ }
                                    } else { $die=$@ }
                                    &Net::FullAuto::FA_Core::handle_error($die);
                                 } else { die $@ }
                              }
                           }
                        };
                        if ($@) {
                           if (unpack('a11',$@) eq 'FATAL ERROR') {
                              if (defined $log_handle &&
                                    -1<index $log_handle,'*') {
                                 print $log_handle $die;
                                 close($log_handle);
                              }
                              die $die;
                           } else {
                              my $die="\n       FATAL ERROR! - The Local "
                                 ."System $local_hostname Conveyed\n"
                                 ."              the Following "
                                 ."Unrecoverable Error Condition :\n\n"
                                 ."       $@";
                              if (defined $log_handle &&
                                    -1<index $log_handle,'*') {
                                 print $log_handle $die;
                                 close($log_handle);
                              }
                              if ($parent_menu && wantarray && !$no_wantarray) {
                                 return '',
                                    $FullMenu,$Selected,$Conveyed,
                                    $SavePick,$SaveLast,$SaveNext,
                                    $Persists,$parent_menu,$die;
                              } elsif ($fullauto) {
                                 &Net::FullAuto::FA_Core::handle_error($die);
                              } else { die $die }
                           }
                        } elsif (-1<$#resu) {
                  if ($fullauto && defined $Net::FullAuto::FA_Core::plan) {
print "We have a plan7 in TERM-MENUS!!\n";sleep 5;
                  }
                           if (wantarray && !no_wantarray) {
                              return @resu;
                           } else {
                              return $resu[0];
                           }
                        }
                     }
print "DONE_SUB12\n";
 return 'DONE_SUB';
                  }
               } else {
                  my $die="The \"Result11 =>\" Setting".
                          "\n\t\tFound in the Menu Unit -> ".
                          "${$MenuUnit_hash_ref}{'Label'}\n\t\tis a ".
                          "HASH reference to a Menu Unit\,\n\t\t".
                          "that does NOT EXIST or is NOT EXPORTED".
                          "\n\n\tHint: Make sure the Names of all".
                          "\n\t      Menu Hash Blocks in the\n\t".
                          "      $menu_config_module_file file are\n\t".
                          "      listed in the \@EXPORT list\n\t".
                          "      found at the beginning of\n\t".
                          "      the $menu_config_module_file file\n\n\t".
                          "our \@EXPORT = qw( %Menu_1 %Menu_2 ... )\;\n";
                  die $die;
               }
            } elsif ($FullMenu && $caller eq $callertest &&
                  (exists ${$MenuUnit_hash_ref}{Select} &&
                  ${$MenuUnit_hash_ref}{Select} eq 'Many')) {
               chomp($numbor);
               if (exists $picks{$numbor}) {
                  if ($picks{$numbor} eq '*') {
                     delete $picks{$numbor};
                     delete $items{$numbor};
                     delete ${$Selected}{$MenuUnit_hash_ref}{$numbor};
                  } else {
                     &delete_Selected($MenuUnit_hash_ref,$numbor,
                        $Selected,$SavePick,$SaveNext,$Persists);
                     $SaveNext=$SaveLast;
                     delete $picks{$numbor};
                     delete $items{$numbor};
                  } last;
               }
               if (keys %{${$FullMenu}{$MenuUnit_hash_ref}[2]}) {
                  if (substr(${$FullMenu}{$MenuUnit_hash_ref}
                        [2]{$pn{$numbor}[0]},0,1) ne '&') {
                     my $die="The \"Result12 =>\" Setting\n              -> "
                            .${$FullMenu}{$MenuUnit_hash_ref}[2]{$pn{$numbor}[0]}
                            ."\n              Found in the Menu Unit -> "
                            .$MenuUnit_hash_ref
                            ."\n              is not a Menu Unit\,"
                            ." and Because it Does Not Have"
                            ."\n              an \"&\" as"
                            ." the Lead Character, $0"
                            ."\n              Cannot Determine "
                            ."if it is a Valid SubRoutine.\n\n";
                     die $die;
                  }
                  if (${$FullMenu}{$MenuUnit_hash_ref}[2]
                                   {$pn{$numbor}[0]}) { }
                  ($FullMenu,$Conveyed,$SaveNext,$Persists,$Selected,$convey,$parent_menu)
                     =$get_result->($MenuUnit_hash_ref,
                     \@pickone,$pn{$pn}[1],$picks_from_parent,
                     $FullMenu,$Conveyed,$Selected,$SaveNext,
                     $Persists,$parent_menu,$menu_config_module_file,
                     $Convey_contents);
                  ${$SaveLast}{$MenuUnit_hash_ref}=$numbor;
                  my %pick=();
                  $pick{$numbor}='*';
                  %{${$SavePick}{$MenuUnit_hash_ref}}=%pick;
                  my $subfile=substr($custom_code_module_file,0,-3).'::'
                        if $custom_code_module_file;
                  $subfile||='';
                  foreach my $sub (&get_subs_from_menu($Selected)) {
                     my @resu=();
                     eval {
                        unless (defined eval "\@resu=$subfile$sub" ||
                                defined eval "\@resu=\&main::$sub") {
                           if ($@) {
                              my $die='';
                              if ($fullauto) {
                                 if ($@=~/Undefined subroutine/) {
                                    if (${$FullMenu}{$_[0]}
                                          [2]{${$_[1]}[$_[2]-1]}) {
                                       $die="The \"Result13 =>\" Setting"
                                           ."\n\t\t-> " . ${$FullMenu}{$_[0]}
                                           [2]{${$_[1]}[$_[2]-1]}
                                           ."\n\t\tFound in the Menu Unit -> "
                                           ."${$LookUpMenuName}{$_[0]}\n\t\t"
                                           ."Specifies a Subroutine"
                                           ." that Does NOT Exist"
                                           ."\n\t\tin the User Code "
                                           ."File $custom_code_module_file\n";
                                    } else { $die=$@ }
                                 } else { $die=$@ }
                                 &Net::FullAuto::FA_Core::handle_error($die);
                              } else { die $@ }
                           }
                        }
                     };
                     if ($@) {
                        if (unpack('a11',$@) eq 'FATAL ERROR') {
                           die $die;
                        } else {
                           my $die="\n       FATAL ERROR! - The Local "
                                  ."System $local_hostname Conveyed\n"
                                  ."              the Following "
                                  ."Unrecoverable Error Condition :\n\n"
                                  ."       $@";
                           if (defined $log_handle &&
                                -1<index $log_handle,'*') {
                              print $log_handle $die;
                              close($log_handle);
                           }
                           if ($parent_menu && wantarray && !$no_wantarray) {
                              return '',
                                 $FullMenu,$Selected,$Conveyed,
                                 $SavePick,$SaveLast,$SaveNext,
                                 $Persists,$parent_menu,$die;
                           } elsif ($fullauto) {
                              &Net::FullAuto::FA_Core::handle_error($die);
                           } else { die $die }
                        }
                     } else {
                        if (-1<$#resu) {
                  if ($fullauto && defined $Net::FullAuto::FA_Core::plan) {
print "We have a plan8 in TERM-MENUS!!\n";sleep 5;
                  }
                           if (wantarray && !no_wantarray) {
                              return @resu;
                           } else {
                              return $resu[0];
                           }
                        }
                        $done=1;last
                     }
                  }
               } else { $done=1;last }
print "DONE_SUB13\n";
               return 'DONE_SUB';
            } elsif (keys %{${$FullMenu}{$MenuUnit_hash_ref}[2]}) {
               my $rest=${$FullMenu}{$MenuUnit_hash_ref}[2]{$pn{$numbor}[0]};
               if (ref ${$FullMenu}{$MenuUnit_hash_ref}[2]{$pn{$numbor}[0]} eq 'CODE') {
               } elsif (substr(${$FullMenu}{$MenuUnit_hash_ref}
                     [2]{$pn{$numbor}[0]},0,1) ne '&') {
                  my $die="The \"Result14 =>\" Setting\n              -> "
                         .${$FullMenu}{$MenuUnit_hash_ref}[2]{$pn{$numbor}[0]}
                         ."\n              Found in the Menu Unit -> "
                         .$MenuUnit_hash_ref
                         ."\n              is not a Menu Unit\,"
                         ." and Because it Does Not Have"
                         ."\n              an \"&\" as"
                         ." the Lead Character, $0"
                         ."\n              Cannot Determine "
                         ."if it is a Valid SubRoutine.\n\n";
                  die $die;
               }
               if (${$FullMenu}{$MenuUnit_hash_ref}[2]
                                {$pn{$numbor}[0]}) { }
               ($FullMenu,$Conveyed,$SaveNext,$Persists,$Selected,$convey,$parent_menu)
                  =$get_result->($MenuUnit_hash_ref,
                  \@pickone,$pn{$pn}[1],$picks_from_parent,
                  $FullMenu,$Conveyed,$Selected,$SaveNext,
                  $Persists,$parent_menu,$menu_config_module_file,
                  $Convey_contents);
               ${$SaveLast}{$MenuUnit_hash_ref}=$numbor;
               my %pick=();
               $pick{$numbor}='*';
               %{${$SavePick}{$MenuUnit_hash_ref}}=%pick;
               my $subfile=substr($custom_code_module_file,0,-3).'::'
                  if $custom_code_module_file;
               $subfile||='';
               foreach my $sub (&get_subs_from_menu($Selected)) {
                  my @resu=();
                  if (ref $sub eq 'CODE') {
                     @resu=$sub->();
                     if (-1<$#resu) {
                  if ($fullauto && defined $Net::FullAuto::FA_Core::plan) {
print "We have a plan91 in TERM-MENUS!!\n";sleep 5;
                  }
                        if (wantarray && !no_wantarray) {
                           return @resu;
                        } else {
                           return $resu[0];
                        }
                     }
                     $done=1;last
                  }
                  eval {
                     unless (defined eval "\@resu=\&$subfile$sub" ||
                             defined eval "\@resu=\&main::$sub") {
                        if ($@) {
                           my $die='';
                           if ($fullauto) {
                              if ($@=~/Undefined subroutine/) {
                                 if (${$FullMenu}{$_[0]}
                                       [2]{${$_[1]}[$_[2]-1]}) {
                                    $die="The \"Result15 =>\" Setting"
                                        ."\n\t\t-> " . ${$FullMenu}{$_[0]}
                                        [2]{${$_[1]}[$_[2]-1]}
                                        ."\n\t\tFound in the Menu Unit -> "
                                        ."${$LookUpMenuName}{$_[0]}\n\t\t"
                                        ."Specifies a Subroutine"
                                        ." that Does NOT Exist"
                                        ."\n\t\tin the User Code "
                                        ."File $custom_code_module_file\n";
                                  } else { $die=$@ }
                              } else { $die=$@ }
                              &Net::FullAuto::FA_Core::handle_error($die);
                           } else { die $@ }
                        }
                     }
                  };
                  if ($@) {
                     if (unpack('a11',$@) eq 'FATAL ERROR') {
                        die $die;
                     } else {
                        my $die="\n       FATAL ERROR! - The Local "
                               ."System $local_hostname Conveyed\n"
                               ."              the Following "
                               ."Unrecoverable Error Condition :\n\n"
                               ."       $@";
                        if (defined $log_handle &&
                              -1<index $log_handle,'*') {
                           print $log_handle $die;
                           close($log_handle);
                        }
                        if ($parent_menu && wantarray && !$no_wantarray) {
                           return '',
                              $FullMenu,$Selected,$Conveyed,
                              $SavePick,$SaveLast,$SaveNext,
                              $Persists,$parent_menu,$die;
                        } elsif ($fullauto) {
                           &Net::FullAuto::FA_Core::handle_error($die,'-28');
                        } else { die $die }
                     }
                  } else {
                     if (-1<$#resu) {
                  if ($fullauto && defined $Net::FullAuto::FA_Core::plan) {
print "We have a plan9 in TERM-MENUS!!\n";sleep 5;
                  }
                        if (wantarray && !no_wantarray) {
                           return @resu;
                        } else {
                           return $resu[0];
                        }
                     }
                     $done=1;last
                  }
               }
print "DONE_SUB14\n";
 return 'DONE_SUB';
            } else { $done=1 }
            last if !$return_from_child_menu;
         }
      } last if $done;
   }
   if (wantarray && !$no_wantarray &&
         (exists ${$MenuUnit_hash_ref}{Select} &&
         ${$MenuUnit_hash_ref}{Select} eq 'Many')) {
      my @picks=();
      foreach (keys %picks) {
         my $pik=$pickone[$_-1];
         push @picks, $pik;
      } undef @pickone;
      if ($MenuUnit_hash_ref) {
         unless ($Persists{unattended}) {
            if ($^O ne 'cygwin') {
               unless ($noclear) {
                  if ($^O eq 'MSWin32' || $^O eq 'MSWin64') {
                     system("cmd /c cls");
                     print "\n";
                  } else {
                     print `${clearpath}clear`."\n";
                  }
               } else { print $blanklines }
            } else { print $blanklines }
         }
         return \@picks,
                $FullMenu,$Selected,$Conveyed,
                $SavePick,$SaveLast,$SaveNext,
                $Persists,$parent_menu,$error;
      } else {
         return @picks;
      }
   }
   my $pick=$pickone[$numbor-1];
   undef @pickone;
   return $pick,
          $FullMenu,$Selected,$Conveyed,
          $SavePick,$SaveLast,$SaveNext,
          $Persists,$parent_menu,$error;

}

sub escape_quotes {

   my $sub=$_[0];
   return $sub if -1==index $sub,'"';
   my $routine=substr($sub,0,(index $sub,'(')+1);
   my $args=substr($sub,(index $sub,'(')+1,-1);
   $args=~s/[']/!%!'%!%/g;
   $args=~s/^\s*(["]|!%!)//;$args=~s/(["]|%!%)\s*$//;
   my @args=split /(?:["]|%!%)\s*,\s*(?:["]|!%!)/, $args;
   my @newargs=();
   foreach my $arg (@args) {
      $arg=~s/(!%!|%!%)//g;
      if ($arg=~/^[']/) {
         push @newargs, $arg;
      } else {
         $arg=~s/["]/\\"/g;
         push @newargs, '"'.$arg.'"';
      }
   }
   $sub=$routine;
   foreach my $arg (@newargs) {
      $sub.=$arg.",";
   }
   chop $sub;
   $sub.=')';
   return $sub;

}

1;

package TMMemHandle;

use strict;
sub TIEHANDLE {
   my $class = shift;
   bless [], $class;
}

sub PRINT {
   my $self = shift;
   push @$self, join '', @_;
}

sub PRINTF {
   my $self = shift;
   my $fmt = shift;
   push @$self, sprintf $fmt, @_;
}

sub READLINE {
   my $self = shift;
   shift @$self;
}

__END__;


######################## User Documentation ##########################


## To format the following documentation into a more readable format,
## use one of these programs: perldoc; pod2man; pod2html; pod2text.
## For example, to nicely format this documentation for printing, you
## may use pod2man and groff to convert to postscript:
##   pod2man Term/Menus.pm | groff -man -Tps > Term::Menus.ps

=head1 NAME

Term::Menus - Create Powerful Terminal, Console and CMD Enviroment Menus

=head1 SYNOPSIS

C<use Term::Menus;>

see METHODS section below

=head1 DESCRIPTION

Term::Menus allows you to create powerful Terminal, Console and CMD environment
menus. Any perl script used in a Terminal, Console or CMD environment can
now include a menu facility that includes sub-menus, forward and backward
navigation, single or multiple selection capabilities, dynamic item creation
and customized banners. All this power is simple to implement with a straight
forward and very intuitive configuration hash structure that mirrors the actual
menu architechture needed by the application. A separate configuration file is
optional. Term::Menus is cross platform compatible.

Term::Menus is a stand-alone - other CPAN modules are not needed for its
implementation ( so it's *easy* to install! ;-) )

Term::Menus was initially conceived and designed to work seemlessly
with the perl based Network Process Automation Utility Module called
Net::FullAuto (Available in CPAN :-) - however, it is not itself dependant
on other Net::FullAuto components, and will work with *any* perl
script/application.


Reasons to use this module are:

=over 2

=item *

You have a list (or array) of items, and wish to present the user a simple
CMD enviroment menu to pick a single item and return that item as a scalar
(or simple string). Example:

   use Term::Menus;

   my @list=('First Item','Second Item','Third Item');
   my $banner="  Please Pick an Item:";
   my $selection=&pick(\@list,$banner);
   print "SELECTION = $selection\n";

The user sees ==>


   Please Pick an Item:

      1.        First Item
      2.        Second Item
      3.        Third Item

   (Type "quit" to quit)

   PLEASE ENTER A CHOICE:

--< 2 >-<ENTER>----------------------------------

The user sees ==>

   SELECTION = Second Item

=item *

You have a large list of items and need scrolling capability:

   use Term::Menus;

   my @list=`ls -1 /bin`;
   my $banner="   Please Pick an Item:";
   my $selection=&pick(\@list,$banner);
   print "SELECTION = $selection\n";

The user sees ==>

   Please Pick an Item:

      1.        arch
      2.        ash
      3.        awk
      4.        basename
      5.        bash
      6.        cat
      7.        chgrp
      8.        chmod
      9.        chown
      10.       cp

   93 Total Choices

   Press ENTER (or "d") to scroll downward

   OR "u" to scroll upward  (Type "quit" to quit)

   PLEASE ENTER A CHOICE:

--<ENTER>--------------------------------------

   Please Pick an Item:

      11.       cpio
      12.       csh
      13.       cut
      14.       date
      15.       dd
      16.       df
      17.       echo
      18.       ed
      19.       egrep
      20.       env

   93 Total Choices

   Press ENTER (or "d") to scroll downward

   OR "u" to scroll upward  (Type "quit" to quit)

   PLEASE ENTER A CHOICE:

--< 14 >-<ENTER>----------------------------------

The user sees ==>

   SELECTION = date

=item *

You need to select multiple items and return the selected list:

   use Term::Menus;

   my @list=`ls -1 /bin`;
   my %Menu_1=(

      Item_1 => {

         Text    => "/bin Utility - ]Convey[",
         Convey  => [ `ls -1 /bin` ],

      },

      Select => 'Many',
      Banner => "\n   Choose a /bin Utility :"
   );

   my @selections=&Menu(\%Menu_1);
   print "SELECTIONS = @selections\n";

The user sees ==>

   Choose a /bin Utility :

      1.        /bin Utility - arch
      2.        /bin Utility - ash
      3.        /bin Utility - awk
      4.        /bin Utility - basename
      5.        /bin Utility - bash
      6.        /bin Utility - cat
      7.        /bin Utility - chgrp
      8.        /bin Utility - chmod
      9.        /bin Utility - chown
      10.       /bin Utility - cp

   a.  Select All.   c.  Clear All.
   f.  Finish.

   93 Total Choices

   Press ENTER (or "d") to scroll downward

   OR "u" to scroll upward  (Type "quit" to quit)

   PLEASE ENTER A CHOICE:

--< 3 >-<ENTER>----------------------------------

--< 7 >-<ENTER>----------------------------------

The user sees ==>

   Choose a /bin Utility :

      1.        /bin Utility - arch
      2.        /bin Utility - ash
   *  3.        /bin Utility - awk
      4.        /bin Utility - basename
      5.        /bin Utility - bash
      6.        /bin Utility - cat
   *  7.        /bin Utility - chgrp
      8.        /bin Utility - chmod
      9.        /bin Utility - chown
      10.       /bin Utility - cp

   a.  Select All.   c.  Clear All.
   f.  Finish.

   93 Total Choices

   Press ENTER (or "d") to scroll downward

   OR "u" to scroll upward  (Type "quit" to quit)

   PLEASE ENTER A CHOICE:

--< f >-<ENTER>----------------------------------

The user sees ==>

   SELECTIONS = /bin Utility - awk /bin Utility - chgrp


=item *

You need sub-menus:

   use Term::Menus;

   my %Menu_2=(

      Label  => 'Menu_2',
      Item_1 => {

         Text   => "]Previous[ is a ]Convey[ Utility",
         Convey => [ 'Good','Bad' ]
      },

      Select => 'One',
      Banner => "\n   Choose an Answer :"
   );

   my %Menu_1=(

      Label  => 'Menu_1',
      Item_1 => {

         Text   => "/bin/Utility - ]Convey[",
         Convey => [ `ls -1 /bin` ],
         Result => \%Menu_2,

      },

      Select => 'One',
      Banner => "\n   Choose a /bin Utility :"
   );

   my @selections=&Menu(\%Menu_1);
   print "SELECTIONS=@selections\n";

The user sees ==>

   Choose a /bin Utility :

      1.        /bin Utility - arch
      2.        /bin Utility - ash
      3.        /bin Utility - awk
      4.        /bin Utility - basename
      5.        /bin Utility - bash
      6.        /bin Utility - cat
      7.        /bin Utility - chgrp
      8.        /bin Utility - chmod
      9.        /bin Utility - chown
      10.       /bin Utility - cp

   a.  Select All.   c.  Clear All.
   f.  Finish.

   93 Total Choices

   Press ENTER (or "d") to scroll downward

   OR "u" to scroll upward  (Type "quit" to quit)

   PLEASE ENTER A CHOICE:

--< 5 >-<ENTER>----------------------------------

   Choose an Answer :

      1.        bash is a Good Utility
      2.        bash is a Bad Utility

   (Type "quit" to quit)

   PLEASE ENTER A CHOICE:

--< 1 >-<ENTER>----------------------------------

The user sees ==>

   SELECTIONS = bash is a Good Utility

=item *

You want to use a perl subroutine to create the text items or banner:

(Note: READ THE COMMENTS embedded in the Menu_2 sample following.
       The syntax is a bit tricky and MUST be created exactly as
       described - otherwise it will NOT work!)

   package current_package_name; # Qualify subroutine calls with
                                 # &main:: if not using
                                 # a package architechture

   use Term::Menus;

   sub create_items {

      my $previous=shift;
      my @textlines=();
      push @textlines, "$previous is a Good Utility";
      push @textlines, "$previous is a Bad Utility";
      return @testlines;
             ## return value must NOT be an array
             ## not an array reference

   }

   sub create_banner {

      my $previous=shift;
      return "\n   Choose an Answer for $previous :"
             ## return value MUST be a string for banner

   }

   my %Menu_2=(

      Label  => 'Menu_2',
      Item_1 => {

         Text   => "]Convey[",
         Convey => "&current_package_name::create_items(\"]Previous[\")",

                   # IMPORTANT! '&' *must* be used to denote subroutine
                   #            as the first character

                   #      &current_package_name:: qualifier or &main::
                   #      quaifiler MUST be used - otherwise
                   #      Term::Menus cannot locate it

                   #      embedded quote characters must be escaped

                   #      enclosing double quotes MUST be used - this is
                   #      a STRING being passed to Term::Menus that will
                   #      then be internally eval-ed during runtime
                   #      after the macro ]Previous[ is substituted

                   #      other macros and values can be passed as
                   #      arguments as follows:

                   #      (\"]Previous[\",\"AnyString\")

      },

      Select => 'One',
      Banner => "&current_package_name::create_banner(\"]Previous[\")",

                ## or "&main::create_banner(\"]Previous[\")",
                ## if using in top level script (file does NOT
                ## have .pm extension)
   );

   my %Menu_1=(

      Label  => 'Menu_1',
      Item_1 => {

         Text   => "/bin/Utility - ]Convey[",
         Convey => [ `ls -1 /bin` ],
         Result => \%Menu_2,

      },

      Select => 'One',
      Banner => "\n   Choose a /bin Utility :"
   );

   my @selections=&Menu(\%Menu_1);
   print "SELECTIONS=@selections\n";

The user sees ==>

   Choose a /bin Utility :

      1.        /bin Utility - arch
      2.        /bin Utility - ash
      3.        /bin Utility - awk
      4.        /bin Utility - basename
      5.        /bin Utility - bash
      6.        /bin Utility - cat
      7.        /bin Utility - chgrp
      8.        /bin Utility - chmod
      9.        /bin Utility - chown
      10.       /bin Utility - cp

   a.  Select All.   c.  Clear All.
   f.  Finish.

   93 Total Choices

   Press ENTER (or "d") to scroll downward

   OR "u" to scroll upward  (Type "quit" to quit)

   PLEASE ENTER A CHOICE:

--< 5 >-<ENTER>----------------------------------

   Choose an Answer for bash :

      1.        bash is a Good Utility
      2.        bash is a Bad Utility

   (Type "quit" to quit)

   PLEASE ENTER A CHOICE:

--< 1 >-<ENTER>----------------------------------

The user sees ==>

   SELECTIONS = bash is a Good Utility

=back

More examples are in the B<EXAMPLES> section below.

Usage questions should be directed to the Usenet newsgroup
comp.lang.perl.modules.

Contact me, Brian Kelly <Brian.Kelly@fullautosoftware.net>,
if you find any bugs or have suggestions for improvements.

=head2 What To Know Before Using

=over 2

=item *

There are two methods available with Term::Menus - &pick() and &Menu().
C<&Menu()> uses C<&pick()> - you can get the same results using
only
C<&Menu()>. However, if you need to simply pick one item from a single
list - use C<&pick()>. The syntax is simpler, and you'll write less code.
;-)

=item *

You'll need to be running at least Perl version 5.002 to use this
module.  This module does not require any libraries that don't already
come with a standard Perl distribution.

=back

=head1 METHODS

=over 4

=item B<pick> - create a simple menu

    $pick = &pick ($list|\@list|['list',...],[$Banner]);

Where I<$list> is a variable containing a array or list reference.
This argument can also be a escaped array (sending a reference) or
an anonymous array (which also sends a reference).

I<$Banner> is an optional argument sending a customized Banner to
top the simple menu - giving instructions, descriptions, etc.
The default is "Please Pick an Item:"

=item B<Menu> - create a complex Menu

    $pick  = &Menu ($list|\@list|['list',...],[$Banner]);

Where I<$pick> is a variable containing a array or list reference
of the pick or picks.

    @picks = &Menu ($Menu_1|\%Menu_1|{ Label => 'Menu_1' });

Where I<$Menu_1> is a hash reference to the top level Menu
Configuration Hash Structure.

=back

=head2  Menu Configuration Hash Structures

=over 4

These are the building blocks of the overall Menu architecture. Each
hash structure represents a I<menu screen>. A single menu layer, has
only one hash structure defining it. A menu with a single sub-menu
will have two hash structures. The menus connect via the C<Result>
element of an I<Item> - C<Item_1> - hash structure in parent menu
C<%Menu_1>:


   my %Menu_2=(

      Label  => 'Menu_2',
      Item_1 => {

         Text   => "]Previous[ is a ]Convey[ Utility",
         Convey => [ 'Good','Bad' ]
      },

      Select => 'One',
      Banner => "\n   Choose an Answer :"
   );

   my %Menu_1=(

      Label  => 'Menu_1',
      Item_1 => {

         Text   => "/bin/Utility - ]Convey[",
         Convey => [ `ls -1 /bin` ],
         Result => \%Menu_2,

      },

      Select => 'One',
      Banner => "\n   Choose a /bin Utility :"
   );

=back

=head3  Menu Component Elements

Each Menu Configuration Hash Structure consists of elements that define
and control it's behavior, appearance, constitution and purpose. An
element's syntax is as you would expect it to be in perl - a key string
pointing to an assocaited value: C<key =E<gt> value>. The following
items
list supported key names and ther associated value types:

=over 4

=item

B<Display> => 'Integer'

=item

=over 2

=item

The I<Display> key is an I<optional> key that determines the number
of Menu
Items that will be displayed on each screen. This is useful when the items
are multi-lined, or the screen size is bigger or smaller than the default
number utilizes in the most practical fashion. The default number is 10.

   Display => 15,

=back

=item

B<Label> => 'Char String consisting of ASCII Characters'

=item

=over 2

=item

The I<Label> key provides a unique identifier to each Menu Structure.
I<Every Menu Configuration Hash Structure B<must> have a valid and
unique Label element> Otherwise C<&Menu()> will throw an error.

   Label => 'Menu_1',

=back

=item

B<Item_E<lt>intE<gt>> => { Item Configuration Hash
Structure }

=item

=over 2

=item

The I<Item_E<lt>intE<gt>> elements define customized menu items.
There are
essentially two methods for creating menu items: The I<Item_E<lt>intE<gt>>
elements, and the C<]Convey[> macro (described later). The difference being
that the C<]Convey[> macro turns an Item Conguration Hash into an Item
I<Template> -> a B<powerful> way to I<Item>-ize large lists
or quantities
of data that would otherwise be difficult - even impossible - to anticipate
and cope with manually.

   Item_1 => { Text => 'Item 1' },
   Item_2 => { Text => 'Item 2' },

Items created via C<]Convey[> macros have two drawbacks:

=over 2

=item *

They all have the same format.

=item *

They all share the same C<Result> element.

=back

The syntax and usage of I<Item_E<lt>intE<gt>> elements is important
and
extensive enough warrant it's own section. See B<I<Item Configuration Hash
Structures>> below.

=back

=item

B<Select> => 'One' --or-- 'Many'

=item

=over 2

=item

The I<Select> element determines whether this particular menu layer
allows the selection of multiple items - or a single item. The default
is 'One'.

   Select => 'Many',

=back

=item

B<Banner> => 'Char String consisting of ASCII Characters'

=item

=over 2

=item

The I<Banner> element provides a customized descriptive header to the menu.
I<$Banner> is an optional element - giving instructions, descriptions, etc.
The default is "Please Pick an Item:"

   Banner => "The following items are for selection,\n".
             "\tEnjoy the Experience!",

B<NOTE:>   Macros (like  C<]Previous[> )  I<can> be used in Banners!   :-)   ( See Item Configuration Macros below )

=back

=back

=head3 Item Congfiguration Hash Structures

Each Menu Item can have an independant configurtion. Each Menu Configuration
Hash Structure consists of elements that define and control it's behavior,
appearance, constitution and purpose. An element's syntax is as you would
expect it to be in perl - a key string pointing to an assocaited value: key
=> value. The following items list supported key names and ther associated
value types:

=over 4

=item

B<Text> => 'Char String consisting of ASCII Characters'

=item

=over 2

=item

The I<Text> element provides a customized descriptive string for the Item.
It is the text the user will see displayed, describing the selection.

   Text => 'This is Item_1',

=back

=item

B<Convey> => [ List ] --or-- @List --or-- $Scalar --or-- 'ASCII String'

=item

=over 2

=item

The I<Convey> element has a twofold purpose; it provides for the contents
of the C<]Convey[> macro, and defines or contains the string or result that
is passed on to child menus - if any. Use of this configuration element is
I<optional>. If C<Convey> is not a list, then it's value is passed onto child
menus. If C<Convey> I<is> a list, then the Item selected is passed onto the
children - if any. It is important to note, I<when used>, that only the
resulting I<Convey> string - B<I<NOT>> the the Item C<Text> value or string,
is conveyed to child menus. When the C<Convey> element is not used, the
full Item C<Text> value B<is> conveyed to the children - if any. However, the
full contents of the C<Text> element is I<returned> as the I<Result> of the
operation when the user completes all menu activity. See the I<Macro> section
below for more information.

   Convey => [ `ls -1` ] ,

=back

=item

B<Default> => 'Char String' --or-- Perl regular expression - qr/.../

=item

=over 2

=item

The I<Default> element provides a means to pre-select certain elements,
as if the items were selected by the user. This can be done with two
constructs - simple string or pre-compiled regular expression.
Note: The C<Default> element is available only when the C<Select> element
is set to C<'Many'> - C<Select => 'Many',>

   Default => 'base|chown',

   Default => qr/base|chown/i,

The user sees ==>

   Choose a /bin Utility :

      1.        /bin Utility - arch
      2.        /bin Utility - ash
      3.        /bin Utility - awk
   *  4.        /bin Utility - basename
      5.        /bin Utility - bash
      6.        /bin Utility - cat
      7.        /bin Utility - chgrp
      8.        /bin Utility - chmod
   *  9.        /bin Utility - chown
      10.       /bin Utility - cp

   a.  Select All.   c.  Clear All.
   f.  Finish.

   93 Total Choices

   Press ENTER (or "d") to scroll downward

   OR "u" to scroll upward  (Type "quit" to quit)

   PLEASE ENTER A CHOICE:

=back

=item

B<Exclude> => 'Char String' --or-- Perl regular expression - qr/.../

=item

=over 2

=item

The I<Exclude> element provides a means to remove matching elements
from the Menu seen by the user. This element is useful only when the
C<]Convey[> macro is used to populate items. This can be done with two
constructs - simple string or pre-compiled regular expression.

   Exclude => 'base|chown',

   Exclude => qr/base|chown/i,

=back

=item

B<Include> => 'Char String' --or-- Perl regular expression - qr/.../

=item

=over 2

=item

The I<Include> element provides a means to create items filtered from a larger
list of potential items available via the C<]Convey[> macro. This element is
useful only when the C<]Convey[> macro is used to populate items. The
C<Exclude> element can be used in conjunction with C<Include> to further
refine the final list of items used to construct the menu. The C<Include>
element - when used - always takes presidence, and the C<Exclude> will be used
only on the C<Include> filtered results. This element can be used with
two value constructs - simple string or pre-compiled regular expression.

   Include => 'base|chown',

   Include => qr/base|chown/i,

=back

=item

B<Result> => \%Menu_2  --or --  "&any_method()",

=item

=over 2

=item

I<Result> is an I<optional> element that also has two important uses:

=item *

For selecting the child menu next in the chain of operation and conveyance,

   Result => \%Menu_2,

--or--

=item *

For building customized method arguements using C<&Menu()>'s built-in
macros.

=item

   Result => "&any_method($arg1,\"]Selected[\",\"]Previous[\")",

B<NOTE:> I<ALWAYS> be sure to surround the subroutine or method calling
syntax with DOUBLE QUOTES. (You can use single quotes if you don't want
interpolation). Quotes are necessary because you're telling C<&Menu()> -
I<not> Perl - what method you want invoked. C<&Menu()> won't invoke the method
until after all other processing - where Perl will try to invoke it the first
time it encounters the line during runtime - lo----ng before a user gets a
chance to see or do I<anything>. B<BUT> - be sure I<B<NOT>> to use quotes
when assigning a child menu reference to the C<Result> value.

Again, I<Result> is an I<optional> element. The default behavior when
C<Result> is omitted from the Item Configuration element, is for the selection
to be returned to the C<&Menu()>'s calling script/module/app. If the C<Select>
element was set to C<'One'>, then that item is returned regardless of whether
the Perl structure receiving the output is an array or scalar. If there were
multiple selections - i.e., C<Select> is set to C<'Many'> - then, depending
on what structure is set for receiving the output, will determine whether
C<&Menu()> returns a list (i.e. - array), or I<reference> to an array.

=back

=back

=head3 Item Congfiguration Macros

Each Menu Item can utilize a very powerful set of configuration I<Macros>.
These constructs principally act as purveyors of information - from one
menu to another, from one element to another. There are currently three
available Macros:

=over 4

=item

B<]Convey[>

=item

=over 2

=item

C<]Convey[> is used in conjunction with the I<Convey> element (described)
earlier. It's purpose to "convey" or transport or carry a list item associated
with the C<Convey> element - and replace the C<]Convey[> Macro in the C<Text>
element value with that list item. The I<Convey> mechanism utilizing the
C<Convey> Macro is essentially an I<Item multiplier>. The entire contents of
the list associated with the I<Convey> element will be turned into it's own
C<Item> when the menu is displayed.

   use Term::Menus;

   my %Menu_1=(

      Label  => 'Menu_1',
      Item_1 => {

         Text   => "/bin/Utility - ]Convey[",
         Convey => [ `ls -1 /bin` ],
         Result => \%Menu_2,

      },

      Select => 'One',
      Banner => "\n   Choose a /bin Utility :"
   );

   my @selections=&Menu(\%Menu_1);
   print "SELECTIONS=@selections\n";

The user sees ==>

   Choose a /bin Utility :

      1.        /bin Utility - arch
      2.        /bin Utility - ash
      3.        /bin Utility - awk
      4.        /bin Utility - basename
      5.        /bin Utility - bash
      6.        /bin Utility - cat
      7.        /bin Utility - chgrp
      8.        /bin Utility - chmod
      9.        /bin Utility - chown
      10.       /bin Utility - cp

   a.  Select All.   c.  Clear All.
   f.  Finish.

   93 Total Choices

   Press ENTER (or "d") to scroll downward

   OR "u" to scroll upward  (Type "quit" to quit)

   PLEASE ENTER A CHOICE:

B<NOTE:>     C<]C[>  can be used as a shorthand for  C<]Convey[>.

=back

=item

B<]Previous[>

=item

=over 2

=item

C<]Previous[> can be used in child menus. The C<]Previous[> Macro contains
the I<Selection> of the parent menu. Unlike the C<]Convey[> Macro, the
C<]Previous[> Macro can be used in both the C<Text> element value, and the
C<Result> element values (when constructing method calls):

The C<]Previous[> Macro can also be used in the Banner.

   use Term::Menus;

   my %Menu_2=(

      Label  => 'Menu_2',
      Item_1 => {

         Text   => "]Previous[ is a ]Convey[ Utility",
         Convey => [ 'Good','Bad' ]
      },

      Select => 'One',
      Banner => "\n   Choose an Answer :"
   );

   my %Menu_1=(

      Label  => 'Menu_1',
      Item_1 => {

         Text   => "/bin/Utility - ]Convey[",
         Convey => [ `ls -1 /bin` ],
         Result => \%Menu_2,

      },

      Select => 'One',
      Banner => "\n   Choose a /bin Utility :"
   );

   my @selections=&Menu(\%Menu_1);
   print "SELECTIONS=@selections\n";

The user sees ==>

   Choose a /bin Utility :

      1.        /bin Utility - arch
      2.        /bin Utility - ash
      3.        /bin Utility - awk
      4.        /bin Utility - basename
      5.        /bin Utility - bash
      6.        /bin Utility - cat
      7.        /bin Utility - chgrp
      8.        /bin Utility - chmod
      9.        /bin Utility - chown
      10.       /bin Utility - cp

   a.  Select All.   c.  Clear All.
   f.  Finish.

   93 Total Choices

   Press ENTER (or "d") to scroll downward

   OR "u" to scroll upward  (Type "quit" to quit)

   PLEASE ENTER A CHOICE:

--< 5 >-<ENTER>----------------------------------

   Choose an Answer :

      1.        bash is a Good Utility
      2.        bash is a Bad Utility

   (Type "quit" to quit)

   PLEASE ENTER A CHOICE:

--< 1 >-<ENTER>----------------------------------

The user sees ==>

   SELECTIONS = bash is a Good Utility

B<NOTE:>     C<]P[>  can be used as a shorthand for  C<]Previous[>.

=back

=item

B<]Previous[{> <I<Menu_Label>> B<}>

=item

=over 2

=item

C<]Previous[{Menu_Label}> can be used in child menus. The C<]Previous[{Menu_Label}> 
Macro contains the I<Selection> of any preceding menu specified with the C<Menu_Label> 
string. The C<]Previous[{Menu_Label}> follows the same conventions as the C<]Previous[>
Macro - but enables access to the selection of i<any> preceding menu. This is very
useful for Menu trees more than two levels deep.

The C<]Previous[{Menu_Label}> Macro can also be used in the Banner.

   use Term::Menus;

   my %Menu_3=(

      Label  => 'Menu_3',
      Item_1 => {

         Text   => "]Convey[ said ]P[{Menu_1} is a ]Previous[ Utility!",
         Convey => [ 'Bob','Mary' ]
      },

      Select => 'One',
      Banner => "\n   Who commented on ]Previous[{Menu_1}? :"
   );

   my %Menu_2=(

      Label  => 'Menu_2',
      Item_1 => {

         Text   => "]Previous[ is a ]C[ Utility",
         Convey => [ 'Good','Bad' ],
         Result => \%Menu_3,
      },

      Select => 'One',
      Banner => "\n   Is ]P[ Good or Bad? :"
   );

   my %Menu_1=(

      Label  => 'Menu_1',
      Item_1 => {

         Text   => "/bin/Utility - ]Convey[",
         Convey => [ `ls -1 /bin` ],
         Result => \%Menu_2,

      },

      Select => 'One',
      Banner => "\n   Choose a /bin Utility :"
   );

   my @selections=&Menu(\%Menu_1);
   print "SELECTIONS=@selections\n";

The user sees ==>

   Choose a /bin Utility :

      1.        /bin Utility - arch
      2.        /bin Utility - ash
      3.        /bin Utility - awk
      4.        /bin Utility - basename
      5.        /bin Utility - bash
      6.        /bin Utility - cat
      7.        /bin Utility - chgrp
      8.        /bin Utility - chmod
      9.        /bin Utility - chown
      10.       /bin Utility - cp

   PLEASE ENTER A CHOICE:

--< 5 >-<ENTER>----------------------------------

   Is bash Good or Bad? :

      1.        bash is a Good Utility
      2.        bash is a Bad Utility

   (Type "quit" to quit)

   PLEASE ENTER A CHOICE:

--< 1 >-<ENTER>----------------------------------

   Who commented on bash? :

      1.        Bob said bash is a Good Utility!
      2.        Mary said bash is a Good Utility!

   (Type "quit" to quit)

   PLEASE ENTER A CHOICE:

--< 2 >-<ENTER>----------------------------------


The user sees ==>

   SELECTIONS = Mary said bash is a Good Utility!

B<NOTE:>     C<]P[>  can be used as a shorthand for  C<]Previous[>.

C<]P[{Menu_Label}>  can be used as a shorthand for C<]Previous[{Menu_Label}>.

C<]C[> can be used as a shorthand for C<]Convey[>.

=back

=item

B<]Selected[>

=item

=over 2

=item

C<]Selected[> can only be used in a I<terminal> menu. B<(> I<A terminal menu is
the last menu in the chain, or the last menu the user sees. It is the menu that
defines the> C<Result> I<element with a method> C<Result =E<gt> &any_method()>,
I<or does not have a> C<Result> I<element included or defined.> B<)>
C<]Selected[> is used to pass the selection of the I<current> menu to the
C<Result> element method of the current menu:

   use Term::Menus;

   sub selected { print "\n   SELECTED ITEM = $_[0]\n" }

   my %Menu_1=(

      Label  => 'Menu_1',
      Item_1 => {

         Text   => "/bin/Utility - ]Convey[",
         Convey => [ `ls -1 /bin` ],
         Result => "&selected(]Selected[)",

      },

      Select => 'One',
      Banner => "\n   Choose a /bin Utility :"
   );

   my @selections=&Menu(\%Menu_1);
   print "SELECTIONS=@selections\n";

B<NOTE:>     C<]S[>  can be used as a shorthand for  C<]Selected[>.

B<NOTE:>     if you want to return output from the Result subroutine,
             you must include a 'return' statement. So the sub above:

                sub selected { print "\n   SELECTED ITEM = $_[0]\n" }

             Becomes:

                sub selected { print "\n   SELECTED ITEM = $_[0]\n";return $_[0] }

=back

=back

=head1 USAGE and NAVIGATION

Usage of C<&pick()> and/or C<&Menu()> during the runtime of a script in which
one or both are included, is simple and intuitive. Nearly everything the end
user needs in terms of instruction is included on-screen. The
script-writer/developer/programmer can also include whatever instructions s/he
deems necessary and/or helpful in the customizable C<Banner> (as described
above). There is however, one important feature about using C<&Menu()> with
sub-menus that's important to know about.

=head3 Forward  ' B<E<gt>> ' and  Backward  ' B<E<lt>> ' Navigation

When working with more than one C<&Menu()> screen, it's valuable to know how
to navigate back and forth between the different C<&Menu()> levels/layers.  For
example, above was illustrated the output for two layers of menus - a parent
and a child:

=over 4

The user sees ==>

   Choose a /bin Utility :

      1.        /bin Utility - arch
      2.        /bin Utility - ash
      3.        /bin Utility - awk
      4.        /bin Utility - basename
      5.        /bin Utility - bash
      6.        /bin Utility - cat
      7.        /bin Utility - chgrp
      8.        /bin Utility - chmod
      9.        /bin Utility - chown
      10.       /bin Utility - cp

   a.  Select All.   c.  Clear All.
   f.  Finish.

   93 Total Choices

   Press ENTER (or "d") to scroll downward

   OR "u" to scroll upward  (Type "quit" to quit)

   PLEASE ENTER A CHOICE:

--< 5 >-<ENTER>----------------------------------

The user sees ==>

   Choose an Answer :

      1.        bash is a Good Utility
      2.        bash is a Bad Utility

   (Type "quit" to quit)

   PLEASE ENTER A CHOICE:

=back

In the above example, suppose that the user "fat-fingered" his/her
choice, and really didn't want to "bash" bash, but wanted to bash
awk instead. Is restarting the whole script/application now necessary?
Suppose it was a process that had run overnight, and the user is seeing
this menu through fogged glasses from the steam rising out of their
morning coffee? Having to run the whole job again would not be welcome news
for the BOSS. THANKFULLY, navigation makes this situation avoidable.
All the user would have to do is type ' B<E<lt>> ' to go backward to the
previous menu, and ' B<E<gt>> ' to go forward to the next menu (assuming there
is one in each case):

The user sees ==>

   Choose an Answer :

      1.        bash is a Good Utility
      2.        bash is a Bad Utility

   (Type "quit" to quit)

   PLEASE ENTER A CHOICE:

 --<  >  >-<ENTER>-----------------------------

The user sees ==>

   Choose a /bin Utility :

      1.        /bin Utility - arch
      2.        /bin Utility - ash
      3.        /bin Utility - awk
      4.        /bin Utility - basename
   -  5.        /bin Utility - bash
      6.        /bin Utility - cat
      7.        /bin Utility - chgrp
      8.        /bin Utility - chmod
      9.        /bin Utility - chown
      10.       /bin Utility - cp

   a.  Select All.   c.  Clear All.
   f.  Finish.

   93 Total Choices

   Press ENTER (or "d") to scroll downward

   OR "u" to scroll upward  (Type "quit" to quit)

   PLEASE ENTER A CHOICE:

Note in the above example the Dash ' B<-> ' in front of item B<5.> This informs
the user that s/he had previously selected this item. To clear the selection,
the user would simply choose item B<5> again. This effectively deletes the
previous choice and restores the menu for a new selection. If the user was
satisfied with the choice, and was simply double checking thier selection, they
simply repeat the navigation process by typing ' B<E<gt>> ' - then <ENTER>
-
and returning to the child menu they left.

If the child menu was a I<multiple-selection> menu, and the user had made some
selections before navigating back to the parent menu, the user would see a
' B<+> ' rather than a ' B<-> '. This informs the user that selections were
made in the child menu.

   Choose a /bin Utility :

      1.        /bin Utility - arch
      2.        /bin Utility - ash
      3.        /bin Utility - awk
      4.        /bin Utility - basename
   +  5.        /bin Utility - bash
      6.        /bin Utility - cat
      7.        /bin Utility - chgrp
      8.        /bin Utility - chmod
      9.        /bin Utility - chown
      10.       /bin Utility - cp

   a.  Select All.   c.  Clear All.
   f.  Finish.

   93 Total Choices

   Press ENTER (or "d") to scroll downward

   OR "u" to scroll upward  (Type "quit" to quit)

   PLEASE ENTER A CHOICE:

=head3 View Sorted Items ' B<%> '

When working with numerous items in a single menu, it may be desirable to see
the set of choices organized in either descending or reverse acscii order.
Term::Menus provides this feature with the I<Percent> ' B<%> ' key.  Simply
type ' B<%> ' and the items will be sorted in descending ascii order. Type
' B<%> ' again, and you will see the items reverse sorted. Assume that we have
the following menus.

=over 4

The user sees ==>

   Please select all files for immediate transfer:

   *  1.        addr2name.awk has  **NOT**  been transferred
   *  2.        awk.exe has  **NOT**  been transferred
      3.        gawk-3.1.4.exe has  **NOT**  been transferred
   *  4.        gawk.exe has  **NOT**  been transferred
      5.        igawk has  **NOT**  been transferred
      6.        pgawk-3.1.4.exe has  **NOT**  been transferred
      7.        pgawk.exe has  **NOT**  been transferred
   *  8.        822-date has been transferred
      9.        DllPlugInTester.exe has been transferred
   *  10.       ELFDump.exe has been transferred

   a.  Select All.   c.  Clear All.
   f.  Finish.

   929 Total Choices

   Press ENTER (or "d") to scroll downward

   OR "u" to scroll upward  (Type "quit" to quit)

   PLEASE ENTER A CHOICE:

--< % >-<ENTER>----------------------------------

The user sees ==>

   Please select all files for immediate transfer:

   *  8.        822-date has been transferred
      9.        DllPlugInTester.exe has been transferred
   *  10.       ELFDump.exe has been transferred
      11.       GraphicsMagick++-config has been transferred
      12.       GraphicsMagick-config has been transferred
      13.       X11 has been transferred
      14.       [.exe has been transferred
      15.       a2p.exe has been transferred
      16.       aclocal has been transferred
      17.       aclocal-1.4 has been transferred

   a.  Select All.   c.  Clear All.
   f.  Finish.

   929 Total Choices

   Press ENTER (or "d") to scroll downward

   OR "u" to scroll upward  (Type "quit" to quit)

   PLEASE ENTER A CHOICE:

And if we choose to enter ' B<%> ' I<again>

--< % >-<ENTER>----------------------------------

The user sees ==>

   Please select all files for immediate transfer:

      929.      znew has been transferred
      928.      zmore has been transferred
      927.      zless has been transferred
      926.      zipsplit.exe has been transferred
      925.      zipnote.exe has been transferred
      924.      zipinfo has been transferred
      923.      zipgrep has been transferred
      922.      zipcloak.exe has been transferred
      921.      zip.exe has been transferred
      920.      zgrep has been transferred

   a.  Select All.   c.  Clear All.
   f.  Finish.

   929 Total Choices

   Press ENTER (or "d") to scroll downward

   OR "u" to scroll upward  (Type "quit" to quit)

   PLEASE ENTER A CHOICE:

This submenu of selections works just like any other menu. The user can
deselect an item, clear all items, re-choose all items, etc. The choices made
here are preserved when-or-if the user navigates back to the original (parent)
menu. In other words, if Item 1. is deselected in the sorted menu, Item 1.
will also be deselected in the parent menu above.

=back

=head3 View Summary of Selected Items ' B<*> '

When working with numerous items in a single menu, it is desirable to see the
set of choices made before leaving the menu and committing to a non-returnable
forward (perhaps even critical) process. Term::Menus provides this feature
with the I<Star> ' B<*> ' key. Assume we have the following menu with 93 Total
Choices. Assume further that we have selected items 1,3,9 & 11. Note that we
cannot see Item 11 on the first screen since this menu is configured to show
only 10 Items at a time.

=over 4

The user sees ==>

   Choose a /bin Utility :

   *  1.        /bin Utility - arch
      2.        /bin Utility - ash
   *  3.        /bin Utility - awk
      4.        /bin Utility - basename
      5.        /bin Utility - bash
      6.        /bin Utility - cat
      7.        /bin Utility - chgrp
      8.        /bin Utility - chmod
   *  9.        /bin Utility - chown
      10.       /bin Utility - cp

   a.  Select All.   c.  Clear All.
   f.  Finish.

   93 Total Choices

   Press ENTER (or "d") to scroll downward

   OR "u" to scroll upward  (Type "quit" to quit)

   PLEASE ENTER A CHOICE:

--< * >-<ENTER>----------------------------------

The user sees ==>

   Choose a /bin Utility :

   *  1.        /bin Utility - arch
   *  3.        /bin Utility - awk
   *  9.        /bin Utility - chown
   *  11.       /bin Utility - cpio

   (Type "quit" to quit)

   PLEASE ENTER A CHOICE:

This submenu of selections works just like any other menu. The user can
deselect an item, clear all items, re-choose all items, etc. The choices made
here are preserved when-or-if the user navigates back to the original (parent)
menu. In other words, if Item 1. is deselected in the summary menu, Item 1.
will also be deselected in the parent menu above.

=back

=head1 EXAMPLES

=head1 AUTHOR

Brian M. Kelly <Brian.Kelly@fullautosoftware.net>

=head1 COPYRIGHT

Copyright (C) 2000, 2001, 2002, 2003, 2004,
              2005, 2006, 2007, 2008
by Brian M. Kelly.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License.
(http://www.opensource.org/licenses/gpl-license.php).


#!/usr/bin/perl

### OPEN SOURCE LICENSE - GNU AFFERO PUBLIC LICENSE Version 3.0 #######
#
#    Net::FullAuto Demonstration GUI
#    Copyright (C) 2000-2015  Brian M. Kelly
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but **WITHOUT ANY WARRANTY**; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public
#    License along with this program.  If not, see:
#    <http://www.gnu.org/licenses/agpl.html>.
#
#######################################################################

use Wx::Perl::Packager;
use Wx;
chdir "$ENV{PAR_TEMP}/inc" if -e "$ENV{PAR_TEMP}/inc";

our $VERSION = '0.01';

use 5.010;
use strict;
use warnings;
use Wx qw(:everything :id :misc :panel);
use Wx::Event qw(EVT_BUTTON EVT_TREE_SEL_CHANGED EVT_MENU EVT_CLOSE
                 EVT_MEDIA_LOADED EVT_MEDIA_PLAY EVT_ACTIVATE
                 EVT_NOTEBOOK_PAGE_CHANGED EVT_MEDIA_STATECHANGED
                 EVT_DROP_FILES EVT_FILEPICKER_CHANGED EVT_TEXT
                 EVT_PAINT);

use Wx::Media;
use Wx::WebView;
use Wx::DND;
use wxPerl::Constructors;
use File::Copy qw(copy);
use Cwd;

# create the WxApplication
my $app = Wx::SimpleApp->new;
my $frame = Wx::Frame->new(undef, -1,
		           'FullAuto© Automates EVERYTHING Demonstration',
                           wxDefaultPosition,[ 800, 600 ]);
SplitterWindow($frame);
$frame->Show;
$app->MainLoop;

# Example specific code
sub SplitterWindow {

   my ( $self ) = @_;

   my $splitterWindow = Wx::SplitterWindow->new($self, -1);
   #get our logo
   Wx::InitAllImageHandlers();

   # create menu bar
   my $bar  = Wx::MenuBar->new;
   my $file = Wx::Menu->new;
   my $help = Wx::Menu->new;
   my $edit = Wx::Menu->new;

   $file->Append( wxID_EXIT, '' );

   $help->Append( wxID_ABOUT, '' );

   $edit->Append( wxID_COPY,  '' );
   $edit->Append( wxID_FIND,  '' );
   my $find_again = $edit->Append( -1, "Find Again\tF3" );

   $bar->Append( $file, "&File" );
   #$bar->Append( $edit, "&Edit" );
   $bar->Append( $help, "&Help" );

   $self->SetMenuBar( $bar );
   $self->{menu_count} = $self->GetMenuBar->GetMenuCount;

   my $logo = Wx::Bitmap->new("fullautogreenbannerpower.png",
                              wxBITMAP_TYPE_PNG );
   my $banner = Wx::BannerWindow->new($splitterWindow);
   $banner->SetBitmap( $logo );
   $banner->Show(1);
	
   my $rightWindows = Wx::SplitterWindow->new($splitterWindow, -1);
   $rightWindows->Show(1);

   my $righttop = Wx::Notebook->new($rightWindows,
     wxNO_FULL_REPAINT_ON_RESIZE|wxCLIP_CHILDREN);

   $righttop->Show(1);

   my $media = Wx::MediaCtrl->new($righttop, -1, '', [-1,-1], [-1,-1], 0 );
   $media->LoadFile("C:\\Users\\Public\\Videos\\Sample Videos\\Wildlife.wmv");

   $media->Show( 1 );
   $media->ShowPlayerControls;
   $righttop->{media}=$media;
   EVT_MEDIA_STATECHANGED($righttop, $media,\&main::on_media_loaded);

   my $webpanel = Wx::Panel->new($righttop, wxID_ANY);

   my $aws_url='https://portal.aws.amazon.com/gp/aws/developer/'.
               'registration/index.html';
   $webpanel->{defaulturl}=$aws_url;
   my $html = Wx::WebView::New($webpanel, wxID_ANY, $webpanel->{defaulturl});
   $html->{defaulturl}=$aws_url;
   $webpanel->{webview}=$html;

   my $dfbrow  = Wx::Button->new($webpanel, wxID_ANY, 'Go to Default Browser');
   my $btnurl  = Wx::Button->new($webpanel, wxID_ANY, 'Load URL');
   my $btnback = Wx::Button->new($webpanel, wxID_ANY, 'Back');
   my $btnforw = Wx::Button->new($webpanel, wxID_ANY, 'Forward');
   my $btnhist = Wx::Button->new($webpanel, wxID_ANY, 'History');

   my $buttonsizer = Wx::BoxSizer->new(wxHORIZONTAL);
   $buttonsizer->Add($dfbrow,  0, wxLEFT|wxRIGHT, 0);
   $buttonsizer->Add($btnurl,  0, wxLEFT|wxRIGHT, 0);
   $buttonsizer->Add($btnback, 0, wxLEFT|wxRIGHT, 0);
   $buttonsizer->Add($btnforw, 0, wxLEFT|wxRIGHT, 0);
   $buttonsizer->Add($btnhist, 0, wxLEFT|wxRIGHT, 0);

   EVT_BUTTON($webpanel, $dfbrow,  sub { shift->main::GoToDefBrowser( @_ ); });
   EVT_BUTTON($webpanel, $btnurl,  sub { shift->main::OnBtnURL( @_ ); });
   EVT_BUTTON($webpanel, $btnback, sub { shift->main::OnBtnBack( @_ ); });
   EVT_BUTTON($webpanel, $btnforw, sub { shift->main::OnBtnForward( @_ ); });
   EVT_BUTTON($webpanel, $btnhist, sub { shift->main::OnBtnHistory( @_ ); });

   my $msizer = Wx::BoxSizer->new( wxVERTICAL );
   $msizer->Add($html, 1, wxEXPAND|wxALL, 0);
   $msizer->Add($buttonsizer, 0, wxEXPAND|wxALL, 0);

   $webpanel->SetSizer( $msizer );
   $webpanel->Layout;
   $webpanel->Refresh;

   $self->{media}=$media;

   $righttop->AddPage( $media, "Presentation", 1 );
   $righttop->AddPage( $webpanel, "Amazon Web Services", 0 );

   $righttop->Show(1);

   my $rightbottom = Wx::Panel->new($rightWindows);
   my $notready  = Wx::Bitmap->new("notready.jpg",
                                 wxBITMAP_TYPE_JPEG );
   my $presshere = Wx::Bitmap->new("presshere.jpg",
                                 wxBITMAP_TYPE_JPEG );
   my $steel = Wx::Bitmap->new("Scratched_Steel_Texture_by_AaronDesign.jpg",
                                 wxBITMAP_TYPE_JPEG);
   $rightbottom->{steel}=$steel;
   EVT_PAINT($rightbottom,\&on_paint);
   my $statbm = Wx::StaticBitmap->new($rightbottom,-1,$notready,[440,110]);
   $rightbottom->{statbm}=$statbm;
   $rightbottom->{notready}=$notready;
   $rightbottom->{presshere}=$presshere;
   $rightbottom->{righttop}=$righttop;
   $rightbottom->{html}=$html;
   $rightbottom->DragAcceptFiles(1);
   #$rightbottom->SetBackgroundColour(Wx::Colour->new(192,192,192));
   my $fp1 = Wx::FilePickerCtrl->new( $rightbottom, -1, "",
                "Find and Select AWS Key File -> yourkeyfile.pem",
                "PEM files (*.pem)|*.pem|All files|*.*",
                [30, 20], [400,-1],wxFLP_USE_TEXTCTRL);
   $fp1->Show(1);
   $rightbottom->{fp1}=$fp1;
   EVT_FILEPICKER_CHANGED( $rightbottom, $fp1, \&on_change );

   my $fp2 = Wx::FilePickerCtrl->new( $rightbottom, -1, "",
                "Find and Select AWS Credentials file -> credentials.csv",
                "CSV files (*.csv)|*.csv|All files|*.*",
                [30, 50], [400,-1],wxFLP_USE_TEXTCTRL);
   $fp2->Show(1);
   $rightbottom->{fp2}=$fp2;
   EVT_FILEPICKER_CHANGED( $rightbottom, $fp2, \&on_change );

   my $button1=wxPerl::Button->new(
      $rightbottom,
      'Launch + Get Key File',
      id        => -1,
      position  => [440,20],
      size      => [176,-1],
      style     => 0,
      validator => Wx::wxDefaultValidator(),
      name      => 'key',
   );
   $rightbottom->{key}=$fp1;
   EVT_BUTTON( $rightbottom, $button1, \&main::OnClick_button1 );

   my $button2=wxPerl::Button->new(
      $rightbottom,
      'Get New AWS Credentials File',
      id        => -1,
      position  => [440,50],
      size      => [176,-1],
      style     => 0,
      validator => Wx::wxDefaultValidator(),
      name      => 'credentials',
   );
   $rightbottom->{credentials}=$fp2;
   EVT_BUTTON( $rightbottom, $button2, \&main::OnClick_button2 );

   my $button3=wxPerl::Button->new(
      $rightbottom,
      'Get IP Address of Instance',
      id        => -1,
      position  => [440,80],
      size      => [176,-1],
      style     => 0,
      validator => Wx::wxDefaultValidator(),
      name      => 'ip',
   );
   EVT_BUTTON( $rightbottom, $button3, \&main::OnClick_button3 );

   my $ipbox=wxPerl::TextCtrl->new(
      $rightbottom,
      '',
      id        => -1,
      position  => [330,81],
      size      => [100,-1],
      style     => 0,
      validator => Wx::wxDefaultValidator(),
      name      => 'ipbox',
   );
   $rightbottom->{ipbox}=$ipbox;
   EVT_TEXT( $rightbottom, $ipbox, \&on_change );

   my $bmp = Wx::Bitmap->new("fakey.png",
                         wxBITMAP_TYPE_PNG );

   my $bb=Wx::BitmapButton->new($rightbottom,-1,$bmp,[555,110]);
   $bb->Enable(0);

   my $eng = Wx::Bitmap->new("engineroom.jpg",
                         wxBITMAP_TYPE_JPEG );
   my $er=Wx::BitmapButton->new($rightbottom,-1,$eng,[30,90]);
   $er->Enable(1);
   #my $statictext1=Wx::StaticText->new( $rightbottom, -1,
   #               'Amazon Credentials File',
   #               [452,106], [-1, -1]);
   #my $statictext2=Wx::StaticText->new( $rightbottom, -1,
   #               'Amazon Key File',
   #               [452,76], [-1, -1]);
   $rightbottom->{bb}=$bb;
   $rightbottom->{bmp}=$bmp;
   $rightbottom->Show(1);
   my $gif=Wx::Animation->new();
   # Scrolling Gif Generator
   # http://www.ottoschellekens.nl/downloads/downloads.html
   $gif->LoadFile("standup.gif",wxANIMATION_TYPE_GIF);
   my $newAni=Wx::AnimationCtrl->new(
         $rightbottom,-1, $gif, [118,120], [-1,-1], 0 );
   $newAni->Play();
   EVT_BUTTON( $rightbottom, $bb, \&fullauto_button);
   EVT_BUTTON( $rightbottom, $er, \&enginerm_button);
   EVT_DROP_FILES( $rightbottom, \&main::on_drop );

   $splitterWindow->SetMinimumPaneSize(5);

   $rightWindows->SplitHorizontally($righttop,$rightbottom,350);
   $splitterWindow->SplitVertically($banner,$rightWindows,142);

   EVT_CLOSE( $self, \&on_close );
   EVT_MENU( $self, wxID_ABOUT, \&on_about );
   EVT_MENU( $self, wxID_EXIT, sub { $self->Close } );
   EVT_MENU( $self, wxID_COPY, \&on_copy );
   EVT_MENU( $self, wxID_FIND, \&on_find );
   EVT_MENU( $self, $find_again, \&on_find_again );

   $self->SetIcon(Wx::Icon->new("FA.ico",wxBITMAP_TYPE_ICO));
   $self->Show;

}

sub on_paint {

    my $self = shift;
    my $dc = Wx::PaintDC->new( $self );

    $dc->DrawBitmap( $self->{steel},0,0,0);

}

sub fullauto_button {

   my ($self, $event) =@_;
   # http://proton-ce.sourceforge.net/rc/wxwidgets \
   # /docs/html/wx/wx_processfunctions.html
   my $key=$self->{key}->GetPath();
   $key=~s/^.*\/(.*)$/$1/;
   Wx::ExecuteCommand("puttykey $key",wxEXEC_SYNC);
   my $path=$ENV{HOMEDRIVE}.$ENV{HOMEPATH};
   if (exists $ENV{PAR_TEMP} && (-e "$ENV{PAR_TEMP}/inc")) {
      copy "$path/fullauto.ppk", "$ENV{PAR_TEMP}/inc";
   } else {
      copy "$path/fullauto.ppk", cwd();
   }
   unlink "$path/fullauto.ppk";
   my $text=$self->{ipbox}->GetLineText(0);
   Wx::ExecuteCommand("runputty fullauto.ppk $text",wxEXEC_ASYNC);

}

sub enginerm_button {

   my ($self, $event) =@_;
   Wx::Shell("perl -v"); 

}

sub on_change {

   my ($self, $event) =@_;
   my $text=$self->{ipbox}->GetLineText(0);
   my $key='';my $cred='';
   if ($text=~/\d+\.\d+\.\d+\.\d+/ &&
         ($cred=$self->{credentials}->GetPath()) &&
         ($key=$self->{key}->GetPath())) {
      if (exists $ENV{PAR_TEMP} && (-e "$ENV{PAR_TEMP}/inc")) {
         copy $cred, "$ENV{PAR_TEMP}/inc";
         copy $key,  "$ENV{PAR_TEMP}/inc";
print "PAR=$ENV{PAR_TEMP}/inc\n";
      } else {
         copy $cred, cwd();
         copy $key, cwd();
      }
      $self->{statbm}->SetBitmap($self->{presshere});
      $self->{bb}->SetBitmap($self->{bmp});
      $self->{bb}->Enable(1);
   } elsif ($text=$self->{key}->GetPath()) {
      $self->{statbm}->SetBitmap($self->{notready});
      $self->{bb}->Enable(0);
   }
}

sub OnClick_button1 {

   my ($self, $event) =@_;
   $self->{righttop}->ChangeSelection(1);
   $self->{html}->LoadURL($self->{html}->{defaulturl});
   #print "BUTTON ONE WAS PRESSED\n";

}

sub OnClick_button2 {

   my ($self, $event) =@_;
   $self->{righttop}->ChangeSelection(1);
   $self->{html}->LoadURL('https://console.aws.amazon.com/iam/#users');
   #print "BUTTON TWO WAS PRESSED\n";

}

sub OnClick_button3 {

   my ($self, $event) =@_;
   $self->{righttop}->ChangeSelection(1);
   $self->{html}->LoadURL('https://console.aws.amazon.com/ec2');
   #print "BUTTON THREE WAS PRESSED\n";

}

sub on_drop {

    my( $self, $wxDropFilesEvent ) = @_;
    my @files = $wxDropFilesEvent->GetFiles;
    if ($files[0]=~/csv$/) {
       $self->{credentials}->SetPath($files[0]);
    } elsif ($files[0]=~/pem$/) {
       $self->{key}->SetPath($files[0]);
    }
}

sub on_media_loaded {

    my( $self, $event ) = @_;
    #Wx::LogMessage( 'Media loaded, start playback' );
    unless (exists $self->{done}) {
       #$self->{media}->Seek(9000,0);
       $self->{media}->Play;
       $self->{media}->Pause;
       $self->{media}->Seek(0,0);
       $self->{done}=1;
    }
}

sub GoToDefBrowser {

   my ( $self ) = @_;
   my $url=$self->{webview}->GetCurrentURL();
   Wx::LaunchDefaultBrowser($url,wxBROWSER_NEW_WINDOW);

   return;

}

sub OnBtnURL {
    my ($self, $event) = @_;

    my $url=$self->{webview}->GetCurrentURL();
    my $dialog = Wx::TextEntryDialog->new
        ( $self, "Enter a URL to load", "Enter a URL to load",
        $url );
    my $res = $dialog->ShowModal;
    my $rvalue =  $dialog->GetValue;
    $dialog->Destroy;
    return if $res == wxID_CANCEL;
    $self->{defaulturl} = $rvalue;
    $self->{webview}->LoadURL( $rvalue );
}

sub OnBtnBack {
    my ($self, $event) = @_;
    $self->{webview}->GoBack if $self->{webview}->CanGoBack;
}

sub OnBtnForward {
    my ($self, $event) = @_;
    $self->{webview}->GoForward if $self->{webview}->CanGoForward;
}

sub OnBtnHistory {
    my ($self, $event) = @_;
    my @past = $self->{webview}->GetBackwardHistory;
    my @future = $self->{webview}->GetForwardHistory;

    my $ptext = '<h3>Backward History</h3><br>';
    $ptext .= $_->GetTitle . ' : ' .  $_->GetUrl . '<br>' for ( @past );
    $ptext .= '<h3>Forward History</h3><br>';
    $ptext .= $_->GetTitle . ' : ' .  $_->GetUrl . '<br>' for ( @future );
    $ptext .= '</font>';

    $self->{webview}->SelectAll;
    $self->{webview}->DeleteSelection;

    $self->{webview}->SetPage($ptext, 'http://localhost:54321/');
}

sub on_find {

   my( $self ) = @_;
   $self->get_search_term;
   $self->search;

   return;
}

sub on_find_again {

   my( $self ) = @_;
   if (not $self->search_term) {
       $self->get_search_term;
   }
   $self->search;

   return;
}

sub get_search_term {

   my ($self) = @_;

   my $search_term = $self->search_term || '';
   my $dialog = Wx::TextEntryDialog->new( $self, "",
                "Search term", $search_term );
   if ($dialog->ShowModal == wxID_CANCEL) {
       $dialog->Destroy;
       return;
   }
   $search_term = $dialog->GetValue;
   $self->search_term($search_term);
   $dialog->Destroy;
   return;
}

sub search {

   my ($self) = @_;

   my $search_term = $self->search_term;
   return if not $search_term;

   my $code = $self->{source};
   my ($from, $to) = $code->GetSelection;
   my $last = $code->isa( 'Wx::TextCtrl' ) ? $code->GetLastPosition()
            : $code->GetLength();
   my $str  = $code->isa( 'Wx::TextCtrl' ) ? $code->GetRange(0, $last) 
            : $code->GetTextRange(0, $last);
   my $pos = index($str, $search_term, $from+1);
   if (-1 == $pos) {
       $pos = index($str, $search_term);
   }
   if (-1 == $pos) {
       return; # not found
   }

   $code->SetSelection($pos, $pos+length($search_term));

   return;
}

sub on_close {

   my( $self, $event ) = @_;

   Wx::Log::SetActiveTarget( $self->{old_log} );
   $event->Skip;
}

sub on_about {

   my( $self ) = @_;
   use Wx qw(wxOK wxCENTRE wxVERSION_STRING);

   my $info = Wx::AboutDialogInfo->new;

   $info->SetName( "FullAuto Demonstration" );
   $info->SetVersion( '0.01' );
   $info->SetDescription( 'FullAuto Automates EVERYTHING Demonstration' );
   $info->SetCopyright(
      "(c) 2001-2014 Brian Kelly <Brian.Kelly\@FullAutoSoftware.net>" );
   $info->SetWebSite(
      'http://www.FullAutoSoftware.net', 'The FullAuto web site' );
   $info->AddDeveloper( 'Brian Kelly <Brian.Kelly@FullAutoSoftware.net>' );
   $info->SetIcon(Wx::Icon->new("fagreen.ico",wxBITMAP_TYPE_ICO));

   Wx::AboutBox( $info );

}

# TODO: disallow copy when not the code is in focus
# or copy the text from the log window too.
sub on_copy {
print "ONCOPY\n";
   my( $self ) = @_;

   my $code = $self->{source};
   my ($from, $to) = $code->GetSelection;
   my $str = $code->isa( 'Wx::TextCtrl' ) ? $code->GetRange($from, $to)
                                           : $code->GetTextRange($from, $to);
   if (wxTheClipboard->Open()) {
       wxTheClipboard->SetData( Wx::TextDataObject->new($str) );
       wxTheClipboard->Close();
   }

   return;
}

1;

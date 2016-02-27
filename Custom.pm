package Slim::Utils::OS::Custom;

use strict;
use warnings;
use Config;
use File::Spec::Functions qw(:ALL);
use FindBin qw($Bin);
use base qw(Slim::Utils::OS);

use constant MAX_LOGSIZE => 1024*1024*1; # maximum log size: 1 MB




sub name {
	return 'piCore';
}

sub initDetails {
	my $class = shift;

	$class->{osDetails}->{'os'} = 'piCore';
	$class->{osDetails}->{osName} = $Config{'osname'} || 'piCore';
	$class->{osDetails}->{uid}    = getpwuid($>);
	$class->{osDetails}->{osArch} = $Config{'myarchname'};

	return $class->{osDetails};
}

sub canDBHighMem {
	my $class = shift;
    
	require File::Slurp;
        
	if ( my $meminfo = File::Slurp::read_file('/proc/meminfo') ) {
		if ( $meminfo =~ /MemTotal:\s+(\d+) (\S+)/sig ) {
			my ($value, $unit) = ($1, $2);
                                
		# some 1GB systems grab RAM for the video adapter - enable dbhighmem if > 900MB installed
			if ( ($unit =~ /KB/i && $value > 900_000) || ($unit =~ /MB/i && $value > 900) ) {
				return 1;
			}
		}
	}
	return 0;
}

sub initSearchPath {
	my $class = shift;

	$class->SUPER::initSearchPath();

	my @paths = (split(/:/, ($ENV{'PATH'} || '/sbin:/usr/sbin:/bin:/usr/bin')), qw(/usr/bin /usr/local/bin /usr/libexec /sw/bin /usr/sbin /opt/bin));
	
	Slim::Utils::Misc::addFindBinPaths(@paths);
}

=head2 dirsFor( $dir )

Return OS Specific directories.

Argument $dir is a string to indicate which of the server directories we
need information for.

=cut

sub dirsFor {
	my ($class, $dir) = @_;

	my @dirs = $class->SUPER::dirsFor($dir);
	
	# some defaults
	if ($dir =~ /^(?:strings|revision|convert|types|repositories)$/) {

		push @dirs, $Bin;

	} elsif ($dir eq 'log') {

		push @dirs, $::logdir || catdir($Bin, 'Logs');

	} elsif ($dir eq 'cache') {

		push @dirs, $::cachedir || catdir($Bin, 'Cache');

	} elsif ($dir =~ /^(?:music|playlists)$/) {

		push @dirs, '';

	# we don't want these values to return a(nother) value
	} elsif ($dir =~ /^(?:libpath|mysql-language)$/) {

	} elsif ($dir eq 'prefs' && $::prefsdir) {
		
		push @dirs, $::prefsdir;
		
    } elsif ($dir eq 'updates') {
	    
		my $updateDir = '/tmp/slimupdate';

        mkdir $updateDir unless -d $updateDir;
        	
		@dirs = $updateDir;
                        
	} else {

		push @dirs, catdir($Bin, $dir);
	}
	return wantarray() ? @dirs : $dirs[0];
}

sub canAutoUpdate { 1 }
sub runningFromSource { 0 }
sub installerExtension { 'tgz' }
sub installerOS { 'nocpan' }

sub getUpdateParams {
	Slim::Web::Pages->addPageFunction("html/docs/picore-update.html",\&picoreupdate);

	return {
		cb => sub {
			my ($file) = @_;
			$file =~ /(\d\.\d\.\d).*?(\d{5,})/;
			$::newVersion = Slim::Utils::Strings::string('PICORE_UPDATE_AVAILABLE', "$1 - $2", $file );
		}
	};

}                                                                                               

sub picoreupdate {
	 my ($client, $params) = @_;

# user pressed the "runUpdate" button:
	if ( $params->{'runUpdate'} ) {
	# it's time to run the update!
	 mkdir '/tmp/test' unless -d '/tmp/test';
	}

	# here's how you define a variable accessible in the web skin:
	$params->{'versionString'} = 'new Version';   ## Need to add code to show the new version.
		
	 return Slim::Web::HTTP::filltemplatefile('html/docs/picore-update.html', $params);    ##This needs show a different page.
}


sub logRotate
{
    my $class   = shift;
	my $dir     = shift || Slim::Utils::OSDetect::dirsFor('log');
        
	# only keep small log files (1MB) because they are in RAM
	Slim::Utils::OS->logRotate($dir, MAX_LOGSIZE);
}       

sub ignoredItems {
	return (
		'bin'	=> '/',
		'dev'	=> '/',
		'etc'	=> '/',
		'opt'	=> '/',
		'etc'	=> '/',
		'init'	=> '/',
		'root'	=> '/',
		'sbin'	=> '/',
		'tmp'	=> '/',
		'var'	=> '/',
		'lib'	=> '/',
		'run'	=> '/',
		'sys'	=> '/',
		'usr'	=> '/',
		'lost+found'=> 1,
	);
}

1;


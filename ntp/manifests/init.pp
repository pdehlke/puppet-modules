#
# ntp module
# ntp/manifests/init.pp - Classes for configuring NTP
#
# Copyright (C) 2007 David Schmitt <david@schmitt.edv-bus.at>
# Copyright 2008, admin(at)immerda.ch
# Copyright 2008, Puzzle ITC GmbH
# Marcel Härry haerry+puppet(at)puzzle.ch
# Simon Josi josi+puppet(at)puzzle.ch
#
# This program is free software; you can redistribute 
# it and/or modify it under the terms of the GNU 
# General Public License version 3 as published by 
# the Free Software Foundation.
#

class ntp {
    case $kernel {
        linux: {
            case $operatingsystem {
                debian: { include ntp::debian }
                gentoo: { include ntp::gentoo }
                default: { include ntp::linux }
            }
        }
        openbsd: { include ntp::openbsd }
		SunOS: { include ntp::solaris }
        default: { fail("no classes for this kernel yet defined!") }
    }    

}

class ntp::base {

	package { ntp:
	    ensure => installed,
		provider => $operatingsystem ? {
	  	  solaris => pkg,
		  default => undef
		},
		before => File["/etc/ntp.conf"],

	}

	file { "/etc/ntp.conf":
		name => $operatingsystem ? {
		  solaris => "/etc/inet/ntp.conf",
		  default => "/etc/ntp.conf"
		},
		content => template("ntp/ntp.conf"),
		require => Package[ntp],
	}

    service{ntpd:
		name => $operatingsystem ? {
			suse => "ntp",
			debian => "ntp",
			ubuntu => "ntp",
			solaris => "ntp",
			default => "ntpd",
		},
        ensure => running,
        subscribe => [ File["/etc/ntp.conf"] ],
    }
	
}

class ntp::solaris inherits ntp::base {
    Service[ntp]{
        enable => true,
    }
}
class ntp::linux inherits ntp::base {
    Service[ntpd]{
        enable => true,
    }
}
class ntp::gentoo inherits ntp::linux {
    Package[ntp]{
        category => 'net-misc',
    }
}

class ntp::debian inherits ntp::linux {
    case $lsbdistcodename {
        'sarge': { 
            Package[ntp]{
                name => 'ntp-server', 
            }
        }
    }
    Service['ntpd']{
        name => 'ntp',
    }
}

class ntp::openbsd inherits ntp::base {
    Service[ntpd]{
        restart => "kill -HUP `ps ax | grep ntpd | head -n 1 | awk '{ print $1 }'`",
        stop => "kill `ps ax | grep ntpd | head -n 1 | awk '{ print $1 }'`",
        start => '/usr/sbin/ntpd',
        hasstatus => false,
    }
}

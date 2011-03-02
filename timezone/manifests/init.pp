class timezone::solaris::utc {
  file { "/etc/default/init":
	ensure => present,
	source => "puppet:///modules/timezone/init";
  }
}
class timezone::ubuntu {
    package { "tzdata":
        ensure => installed
    }
}

class timezone::ubuntu::utc inherits timezone::ubuntu {
    file { "/etc/localtime":
        require => Package["tzdata"],
        source => "file:///usr/share/zoneinfo/UTC",
    }
}

class timezone::arizona inherits timezone::ubuntu {
    file { "/etc/localtime":
        require => Package["tzdata"],
        source => "file:///usr/share/zoneinfo/US/Arizona",
    }
}

class timezone::central inherits timezone::ubuntu {
    file { "/etc/localtime":
        require => Package["tzdata"],
        source => "file:///usr/share/zoneinfo/US/Central",
    }
}

class timezone::ubuntu::eastern inherits timezone::ubuntu {
    file { "/etc/localtime":
        require => Package["tzdata"],
        source => "file:///usr/share/zoneinfo/US/Eastern"
    }
}

class timezone::ubuntu::pacific inherits timezone::ubuntu {
    file { "/etc/localtime":
        require => Package["tzdata"],
        source => "file:///usr/share/zoneinfo/US/Pacific"
    }
}

class timezone::ubuntu::mountain inherits timezone::ubuntu {
    file { "/etc/localtime":
        require => Package["tzdata"],
        source =>
             "file:///usr/share/zoneinfo/US/Mountain"
    }
}

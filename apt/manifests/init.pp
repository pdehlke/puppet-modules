class apt::apt {
    exec {
        "apt-get_update":
            command => "/usr/bin/apt-get -q update",
            refreshonly => true;
    }
}

define apt::key() {
    include apt::apt
    file {
        "/etc/apt/$name.key":
            source => "puppet:///modules/apt/$name.key",
            notify => Exec["import apt key $name"];
    }
    exec { 
        "import apt key $name":
            command => "/usr/bin/apt-key add /etc/apt/$name.key",
            refreshonly => true,
            before => Exec["apt-get_update"],
            require => File["/etc/apt/$name.key"],
            notify => Exec["apt-get_update"];
    }
}

define apt::sources_list($content) {
    include apt::apt
    file {
        "/etc/apt/sources.list.d/${name}.list":
            ensure => present,
            content => $content,
            before => Exec["apt-get_update"],
            notify => Exec["apt-get_update"];
    }
}

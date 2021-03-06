#stage { [apt, hadoop-base, hadoop-main, users]:}                                                               
#Stage[apt] -> Stage[users] -> Stage[hadoop-base] -> Stage[hadoop-main]-> Stage[main]     

class hadoop::apt {
  class {"apt::apt": stage => apt}
    apt::sources_list { 
        "cloudera":
            content => "deb http://archive.cloudera.com/debian/ lucid-cdh3 contrib";
        "canonical":
            content => "deb http://archive.canonical.com/ lucid partner";
    }

    apt::key {
        "cloudera":
    }
}

class hadoop::base {
    package {
        "hadoop-0.20":
            ensure => latest,
            require => Package["sun-java6-bin"];
        "sun-java6-bin":
            ensure => latest,
            require  => File["/var/cache/debconf/sun-java6.seeds"],
            responsefile => "/var/cache/debconf/sun-java6.seeds";
    }

    file {
        "/var/cache/debconf/sun-java6.seeds":
            ensure => present,
            source => "puppet:///modules/hadoop/sun-java6.seeds";

        "/etc/default/hadoop-0.20":
            ensure => present,
            source => "puppet:///modules/hadoop/hadoop-0.20.default",
            owner => 'root', group => 'root', mode => 644,
            require => Package["hadoop-0.20"];

        "/etc/hadoop-0.20/conf.puppet":
            ensure => directory,
            owner => 'hdfs', group => 'hadoop', mode => 644,
            require => Package["hadoop-0.20"];


		"/usr/lib/hadoop-0.20/bin/hadoop-config.sh":
            ensure => present,
            source => "puppet:///modules/hadoop/hadoop-config.sh",
            owner => 'root', group => 'root', mode => 644,
            require => Package["hadoop-0.20"];

        "/etc/hadoop-0.20/conf.puppet/hdfs-site.xml":
            content => template("hadoop/hdfs-site.xml.erb"),
            owner => 'hdfs', group => 'hadoop', mode => 644,
            require => File["/etc/hadoop-0.20/conf.puppet"];


        "/var/lib/hadoop-0.20/dfs":
            ensure => directory,
            owner => 'hdfs', group => 'hadoop', mode => 644,
            require => Package["hadoop-0.20"]; 

        "/var/log/hadoop-0.20":
            ensure => directory,
            owner => 'hdfs', group => 'hadoop', mode => 775,
            require => Package["hadoop-0.20"]; 

    }

    exec {
        "/usr/sbin/update-alternatives --install /etc/hadoop-0.20/conf hadoop-0.20-conf /etc/hadoop-0.20/conf.puppet 15":
            refreshonly => true,
            require => [Package["hadoop-0.20"],
                        File["/etc/hadoop-0.20/conf.puppet"]],
            subscribe => File["/etc/hadoop-0.20/conf.puppet"];
    }
}

class hadoop::worker {
    package {
        [ "hadoop-0.20-tasktracker", "hadoop-0.20-datanode" ]:
            ensure => latest;
    }
    file {
        "/var/lib/hadoop-0.20/dfs/data":
            ensure => directory,
            owner => 'hdfs', group => 'hadoop', mode => 644;
    }
    File <<| tag == 'hadoop-core-site' |>>
    File <<| tag == 'hadoop-mapred-site' |>>
    service {
        ["hadoop-0.20-tasktracker", "hadoop-0.20-datanode"]:
            hasstatus => true,
            ensure => running,
            enable => true,
            subscribe => [File["hadoop-core-site"],
                          File["hadoop-mapred-site"],
                          File["/etc/hadoop-0.20/conf.puppet/hdfs-site.xml"]],
            require => [Package["hadoop-0.20-tasktracker"],
                        Package["hadoop-0.20-datanode"],
                        File["hadoop-core-site"],
                        File["hadoop-mapred-site"]];
    }
}

class hadoop::jobtracker {
    package {
        [ "hadoop-0.20-jobtracker" ]:
            ensure => latest,
            require => Package["hadoop-0.20"];
    }
    @@file {
        "hadoop-mapred-site":
            path => "/etc/hadoop-0.20/conf.puppet/mapred-site.xml",
            content => template("hadoop/mapred-site.xml.erb"),
			ensure => present,
            owner => 'mapred', group => 'hadoop', mode => 644,
			tag => "hadoop-mapred-site";
    }
    File <<| tag == 'hadoop-core-site' |>>
    File <<| tag == 'hadoop-mapred-site' |>>
    service {
        "hadoop-0.20-jobtracker":
            hasstatus => true,
            ensure => running,
            enable => true,
            subscribe => [File["hadoop-core-site"],
                          File["hadoop-mapred-site"],
                          File["/etc/hadoop-0.20/conf.puppet/hdfs-site.xml"]],
            require => [Package["hadoop-0.20-jobtracker"],
                        File["hadoop-core-site"],
                        File["hadoop-mapred-site"]];
    }
}

class hadoop::namenode {
    package {
        [ "hadoop-0.20-namenode" ]:
            ensure => latest;
    }
    file {
        "/var/lib/hadoop-0.20/dfs/name":
            ensure => directory,
            owner => 'hdfs', group => 'hadoop', mode => 644;
    }
    @@file {
        "hadoop-core-site":
            path => "/etc/hadoop-0.20/conf.puppet/core-site.xml",
            content => template("hadoop/core-site.xml.erb"),
			ensure => present,
            owner => 'hdfs', group => 'hadoop', mode => 644,
			tag => "hadoop-core-site";
    }
    File <<| tag == 'hadoop-core-site' |>>
    exec {
        "format-dfs":
            command => "/bin/su hdfs -c 'yes Y | /usr/bin/hadoop --config /etc/hadoop-0.20/conf.puppet namenode -format'",
            refreshonly => true,
            subscribe => File["/var/lib/hadoop-0.20/dfs/name"],
            require => File["/var/lib/hadoop-0.20/dfs/name"],
            creates => "/var/lib/hadoop-0.20/dfs/name/image";
    }
    service {
        "hadoop-0.20-namenode":
            hasstatus => true,
            ensure => running,
            enable => true,
            subscribe => [File["hadoop-core-site"],
                          File["/etc/hadoop-0.20/conf.puppet/hdfs-site.xml"]],
            require => [File["hadoop-core-site"],
                        Package["hadoop-0.20-namenode"],
                        Exec["format-dfs"]];
    }
}

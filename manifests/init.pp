class asterisk {
  case $::operatingsystem {
    'CentOS': {
      $libdir='/usr/lib64'
    }
    'Debian','Ubuntu': {
      $libdir='/usr/lib'
    }
  }

#	include sngrep
	include asterisk::install
	mc_conf::hotlist {
		'/etc/asterisk': ;
		'/home/record': ;
		'/var/lib/asterisk': ;
	}
	include fail2ban::asterisk
	file {"/var/log/asterisk":
		ensure	=> directory,
		mode	=> '0750',
	} ->
	file {"/var/log/asterisk/old":
		ensure	=> directory,
		mode	=> '0750',
	} ->
	file {"/etc/logrotate.d/asterisk":
		ensure	=> file,
		source	=> 'puppet:///modules/asterisk/logrotate.d/asterisk',
		mode	=> '0644',
	}
}


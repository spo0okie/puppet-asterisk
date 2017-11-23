class asterisk {
	include sngrep
	include asterisk::install
	mc_conf::hotlist {
		'/etc/asterisk': ;
		'/home/record': ;
		'/var/lib/asterisk': ;
	}
	include fail2ban::asterisk
	file {"/etc/logrotate.d/asterisk":
		ensure	=> file,
		source	=> 'puppet:///modules/asterisk/logrotate.d/asterisk',
		mode	=> '0644',
	}
}


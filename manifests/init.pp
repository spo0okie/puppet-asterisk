class asterisk {
	include sngrep
	include asterisk::install
	mc_conf::hotlist {
		'/etc/asterisk': ;
		'/var/lib/asterisk': ;
	}
	include fail2ban::asterisk
}


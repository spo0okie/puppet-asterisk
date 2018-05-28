class asterisk::voipmonitor {
	$tmpdir='/tmp/ast.voipmon_inst'
	$guidir='/var/www/voipmonitor_gui'
	include asterisk
	include asterisk::snappy_install
	include mysql_server
	class {'php': version=>'56'} ->
	#сlass {'apache::mod::php': package_name => 'php56'}
	file {"$tmpdir":
		ensure=>directory
	} ->
	file {"$tmpdir/voipmon.tar.gz":
		ensure	=> file,
		source	=> 'puppet:///modules/asterisk/voipmonitor-19.2-src.tar.gz',
	} ->
	file {"$tmpdir/gui.tar.gz":
		ensure	=> file,
		source	=> 'puppet:///modules/asterisk/voipmonitor-gui-16.24-SVN.56.tar.gz',
	} ->
	file {"$guidir":
		ensure	=> directory,
		owner	=> 'apache',
		mode	=> '0755',
	} ->
	file {"/var/spool/voipmonitor/":
		ensure	=> directory,
		owner	=> 'apache',
		mode	=> '0777',
	} ->
	file {"/etc/rsyslog.d/voipmonitor.conf":
		ensure	=> file,
		source	=> 'puppet:///modules/asterisk/rsyslog.d/voipmonitor.conf',
		mode => '0644',
		notify => Service['rsyslog']
	} ->
	package {
		'unixODBC-devel':		ensure => installed;
		'libcurl-devel':		ensure => installed;
		'json-c-devel':			ensure => installed;
		'rrdtool-devel':		ensure => installed;
		'glib2-devel':			ensure => installed;
		'urw-fonts':			ensure => installed;
		'librsvg2':				ensure => installed;
	} ->
	exec {'install_voipmonitor':
		command	=> 'tar -zxvf ./voipmon.tar.gz && cd voipmonitor*src && ./configure --libdir=/usr/lib64 && make && make install',
		cwd		=> $tmpdir,
		unless	=> 'which voipmonitor',
		path	=> '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin',
		require => Package['kernel-devel'],
	} ->
	exec {'install_voipmonitor_conf':
		command => 'echo tst && cd voipmonitor*src && cp config/voipmonitor.conf /etc/',
		cwd		=> $tmpdir,
		unless	=> 'test -f /etc/voipmonitor.conf',
		path	=> '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin'
	} -> 
	exec {'install_voipmonitor_svc':
		command => 'echo tst && cd voipmonitor*src && cp config/init.d/voipmonitor /etc/init.d/ &&  chmod 750 /etc/init.d/voipmonitor && chkconfig --add voipmonitor',
		cwd		=> $tmpdir,
		unless	=> 'test -x /etc/init.d/voipmonitor',
		path	=> '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin'
	} ->
	exec {'install_voipmonitor_gui':
		command => "tar -zxvf ./gui.tar.gz && cd voipmonitor-gui-* && cp -r . $guidir && chown -R apache $guidir",
		cwd		=> $tmpdir,
		unless	=> "test -f $guidir/cdr.php",
		path	=> '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin'
	} ->
	exec {'install_voipmonitor_db':
		command => 'echo "create database voipmonitor" | mysql',
		cwd		=> $tmpdir,
		unless	=> 'echo "show databases" | mysql | grep voipmonitor',
		notify	=> Service['voipmonitor'],
		path	=> '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin'
	} ->
	exec {'install_ioncube':
		command => 'wget --no-continue http://voipmonitor.org/ioncube/x86_64/ioncube_loader_lin_5.6.so -O /opt/remi/php56/root/usr/lib64/php/modules/ioncube_loader_lin_5.6.so',
		cwd		=> $tmpdir,
		unless	=> 'test -f /opt/remi/php56/root/usr/lib64/php/modules/ioncube_loader_lin_5.6.so',
		notify	=> Service['httpd'],
		path	=> '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin'
	} ->
	exec {'install_ioncube_conf':
		command => 'echo "zend_extension = /opt/remi/php56/root/usr/lib64/php/modules/ioncube_loader_lin_5.6.so" > /opt/remi/php56/root/etc/php.d/ioncube.ini',
		cwd		=> $tmpdir,
		unless	=> 'test -f /opt/remi/php56/root/etc/php.d/ioncube.ini',
		notify	=> Service['httpd'],
		path	=> '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin'
	} ->
	service {'voipmonitor':
		enable => true,
		ensure => running
	} -> 
	apache::vhost {'voipmonitor':
		servername => "$::fqdn",
		port		=> '2080',
		docroot		=> $guidir,
	} 
	file {"/usr/local/etc/voipmonitor/":
		ensure	=> directory,
		owner	=> 'root',
		mode	=> '0777',
	} ->
	file {"/usr/local/etc/voipmonitor/voipmon.cdr.trim.sh":
		ensure	=> file,
		source	=> 'puppet:///modules/asterisk/voipmon.cdr.trim.sh',
		mode => '0755',
	}


}


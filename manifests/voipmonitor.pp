class asterisk::voipmonitor {
	$tmpdir='/tmp/ast.voipmon_inst'
	$guidir='/var/www/voipmonitor_gui'
	include asterisk
	#include asterisk::snappy_install
	include mysql_client
	#class {'php': version=>'56'} ->
	#сlass {'apache::mod::php': package_name => 'php56'}
	file {"$tmpdir":
		ensure=>directory
	} ->
	file {"$tmpdir/voipmon.tar.gz":
		ensure	=> file,
		source	=> 'puppet:///modules/asterisk/voipmonitor-27.8-src.tar.gz',
	} ->
	file {"$tmpdir/gui.tar.gz":
		ensure	=> file,
		source	=> 'puppet:///modules/asterisk/voipmonitor-gui-24.62-SVN.71.tar.gz',
	} ->
	file {"$guidir":
		ensure	=> directory,
		owner	=> $::apache::params::user,
		mode	=> '0755',
	} ->
	file {"/var/spool/voipmonitor/":
		ensure	=> directory,
		owner	=> $::apache::params::user,
		mode	=> '0777',
	} ->
	file {"/etc/rsyslog.d/voipmonitor.conf":
		ensure	=> file,
		source	=> 'puppet:///modules/asterisk/rsyslog.d/voipmonitor.conf',
		mode => '0644',
		notify => Service['rsyslog']
	} ->
	package {
		[
			'unixodbc-dev',
			'libcurl4-nss-dev',
			'libcurl4-openssl-dev',
			'libcurl4-gnutls-dev',
			'libjson-c-dev',
			'librrd-dev',
			'libglib2.0-dev',
			'fonts-urw-base35',
			'librsvg2-2',
			'libsnappy-dev',
		]:
		ensure => installed;
	} ->
	exec {'install_voipmonitor':
		command	=> 'tar -zxvf ./voipmon.tar.gz && cd voipmonitor*src && ./configure --libdir=/usr/lib64 && make && make install',
		cwd		=> $tmpdir,
		unless	=> 'which voipmonitor',
		path	=> '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin',
		timeout => 1800,
		require => Package[$common::packages::kernel_devel],
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
		command => "tar -zxvf ./gui.tar.gz && cd voipmonitor-gui-* && cp -r . $guidir && chown -R ${apache::param::user} $guidir",
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
		command => 'wget --no-continue http://voipmonitor.org/ioncube/x86_64/ioncube_loader_lin_7.3.so -O /usr/lib/php/20180731/ioncube_loader_lin_7.3.so',
		cwd		=> $tmpdir,
		unless	=> 'test -f /usr/lib/php/20180731/ioncube_loader_lin_7.3.so',
		notify	=> Service[$apache::service_name],
		path	=> '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin'
	} ->
	exec {'install_ioncube_conf':
		command => 'echo "zend_extension = /usr/lib/php/20180731/ioncube_loader_lin_7.3.so" > /etc/php/7.3/mods-available/ioncube.ini',
		cwd		=> $tmpdir,
		unless	=> 'test -f /etc/php/7.3/mods-available/ioncube.ini',
		notify	=> Service[$apache::service_name],
		path	=> '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin'
	} ->
	exec {'install_ioncube_conf_apache':
		command => 'ln -s /etc/php/7.3/mods-available/ioncube.ini /etc/php/7.3/apache2/conf.d/01-ioncube.ini',
		cwd		=> $tmpdir,
		unless	=> 'test -f /etc/php/7.3/apache2/conf.d/01-ioncube.ini',
		notify	=> Service[$apache::service_name],
		path	=> '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin'
	} ->
	exec {'install_ioncube_conf_cli':
		command => 'ln -s /etc/php/7.3/mods-available/ioncube.ini /etc/php/7.3/cli/conf.d/01-ioncube.ini',
		cwd		=> $tmpdir,
		unless	=> 'test -f /etc/php/7.3/cli/conf.d/01-ioncube.ini',
		notify	=> Service[$apache::service_name],
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


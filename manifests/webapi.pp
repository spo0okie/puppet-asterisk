class asterisk::webapi {
	file {'/var/www/ast-webapi/':
		ensure	=> directory,
		source	=> 'puppet:///modules/asterisk/webapi',
		recurse	=> true,
	} ->
	file {'/var/spool/asterisk/outgoing/':
		ensure	=> directory,
		mode	=> '0777',
	} ->
	apache::vhost { "asterisk_webapi":
		port			=> '80',
		servername		=> "${::fqdn}",
		docroot			=> '/var/www/ast-webapi/',
		docroot_owner	=> 'apache',
		docroot_group	=> 'apache',
		docroot_mode	=> '0770',
		directoryindex	=> 'api2.php',
		rewrites	=> [
			{
				comment     => 'Everything to router pattern',
				rewrite_cond => ['%{REQUEST_FILENAME} !-f','%{REQUEST_FILENAME} !-d'],
				rewrite_rule => ['.* /api2.php [L]'],
			}
		]
	}->
	mc_conf::hotlist {
		'/var/www/ast-webapi/': ;
    }

}


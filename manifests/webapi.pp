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
		port			=> '8082',
		servername		=> "${::fqdn}",
		docroot			=> '/var/www/ast-webapi/',
		docroot_owner	=> $::apache::params::user,
		docroot_group	=> $::apache::params::group,
		docroot_mode	=> '0770',
		directoryindex	=> 'api2.php',
		rewrites	=> [
			{
				comment     => 'Everything to router pattern',
				rewrite_cond => ['%{REQUEST_FILENAME} !-f','%{REQUEST_FILENAME} !-d'],
				rewrite_rule => ['.* /api2.php [L]'],
			}
		],
		headers     =>  [
			'set Access-Control-Allow-Origin "*"'
		],
	}->
	mc_conf::hotlist {
		'/var/www/ast-webapi/': ;
    }

}


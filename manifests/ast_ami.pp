class asterisk::ast_ami {
	file {'/usr/local/etc/ast-ami/':
		ensure	=> directory,
		source	=> 'puppet:///modules/asterisk/ast-ami',
		recurse	=> true,
	} ->
	cron {'ast ami translation service checker':
		command =>  '/usr/local/etc/ast-ami/svc.watch_svc.php',
		user    =>  root,
	} ->
	mc_conf::hotlist {
		'/usr/local/etc/ast-ami/': ;
    }

}


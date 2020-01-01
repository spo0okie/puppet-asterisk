class asterisk::install {
	#подключаем модуль установки dahdi. 
	#более того, надо указать require Exec['install_dahdi']
	#чтобы убедиться что все встало
	include asterisk::dahdi
	include sox
	#версия поставляемого астериска
	$version='11.25.1'

	#временная папка в которой будем работать
	$tmpdir='/tmp/ast.ast_inst'

	#папка исходников куда все распакуется
	$srcdir="$tmpdir/asterisk-$version"

	package {['sqlite','sqlite-devel','libogg','spandsp','libvorbis','spandsp-devel','libsrtp','libsrtp-devel','libogg-devel','libvorbis-devel']:ensure => installed;} ->
	file {$tmpdir:
		require=>Exec['install_dahdi'],
		ensure=>directory
	} ->
	file {"$tmpdir/asterisk.tar.gz":
		ensure	=> file,
		source	=> 'puppet:///modules/asterisk/asterisk-11-current.tar.gz',
	} ->
	exec {'asterisk_extract':
		command	=> "tar -zxvf ./asterisk.tar.gz",
		cwd		=> $tmpdir,
		onlyif	=> "which ${asterisk::dahdi::checkfile}",							#устанавливаем астериск только после dahdi
		unless	=> "test -f $srcdir/.version && grep $version $srcdir/.version",	#распаковываем только если уже нет файла с версией и он указывает на правильную версию
		path	=> '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin'
	} ->
	exec {'asterisk_install':
		command	=> "$srcdir/configure --libdir=/usr/lib64 && make menuselect.makeopts && menuselect/menuselect --enable res_srtp --enable res_fax --enable app_meetme --enable chan_ooh323 && make clean && make && make install",
		cwd		=> $srcdir,
		onlyif	=> "which ${asterisk::dahdi::checkfile}",		#устанавливаем астериск только после dahdi
		unless	=> 'which asterisk > /dev/null && test -f /usr/lib64/asterisk/modules/res_srtp.so',
		timeout	=> 1800,
		path	=> '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin'
	} ->
	exec {'asterisk_service':
		command => "cat contrib/init.d/rc.redhat.asterisk|sed 's/__ASTERISK_SBIN_DIR__/\\/usr\\/sbin/g' > /etc/init.d/asterisk && chmod 777 /etc/init.d/asterisk && chkconfig --add asterisk",
		cwd		=> "$srcdir",
		onlyif	=> 'which asterisk',
		unless	=> 'ls /etc/init.d/asterisk',
		path	=> '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin'
	} ->
	service {'asterisk':
		ensure	=> running,
		enable	=> true
	}
}


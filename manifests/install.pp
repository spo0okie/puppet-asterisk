class asterisk::install {
	#подключаем модуль установки dahdi. 
	#более того, надо указать require Exec['install_dahdi']
	#чтобы убедиться что все встало
	include asterisk::dahdi

	#версия поставляемого астериска
	$version='11.25.1'

	#временная папка в которой будем работать
	$tmpdir='/tmp/ast.ast_inst'

	#папка исходников куда все распакуется
	$srcdir="$tmpdir/asterisk-$version"

	case $::operatingsystem {
		'OpenSuSE': {
			package {
				'libxml2-2':		ensure => installed;
				'sqlite3':			ensure => installed;
				'sqlite3-devel':	ensure => installed;
				'libogg0':			ensure => installed;	#for voipmonitor
				'libspandsp2':		ensure => installed;	#need for fax support
				'libvorbis0':		ensure => installed;	#for voipmonitor
			}
		}
		default: {
			package {
				'libxml2':			ensure => installed;
				'sqlite':			ensure => installed;
				'sqlite-devel':		ensure => installed;
				'libogg':			ensure => installed;	#for voipmonitor
				'spandsp':			ensure => installed;	#need for fax support
				'libvorbis':		ensure => installed;	#for voipmonitor
			}
		}
	} ->
	package {
		'libxml2-devel':	ensure => installed;
		'spandsp-devel':	ensure => installed;
		'libsrtp':			ensure => installed;
		'libsrtp-devel':	ensure => installed;
		'libogg-devel':		ensure => installed;	#for voipmonitor
		'libvorbis-devel':	ensure => installed;	#for voipmonitor
	} ->
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
##		WARNING!!! вот это вот специфично именно для редхата. надо пофиксить для дебиана и опенсусе
		command => "cat contrib/init.d/rc.redhat.asterisk|sed 's/__ASTERISK_SBIN_DIR__/\/usr\/sbin/g' > /etc/init.d/asterisk && chmod 777 /etc/init.d/asterisk && chkconfig --add asterisk",
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


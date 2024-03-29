class asterisk::install {
	#подключаем модуль установки dahdi. 
	#более того, надо указать require Exec['install_dahdi']
	#чтобы убедиться что все встало
	include asterisk::dahdi
	include sox
	#версия поставляемого астериска
	$version='13.31.0-rc1'
	#мажорная версия
	$version_maj='13'
	#$version='11.25.1'

	#временная папка в которой будем работать
	$tmpdir='/tmp/ast.ast_inst'

	#папка исходников куда все распакуется
	$srcdir="$tmpdir/asterisk-$version"

	case $::operatingsystem {
		'CentOS': {
			case $::operatingsystemmajrelease {
				'6','7': {
					$package_list=['sqlite','sqlite-devel','libogg','spandsp','libvorbis','spandsp-devel','libsrtp','libsrtp-devel','libogg-devel','libvorbis-devel','libuuid-devel','jansson-devel'];
					package{$package_list: 
						ensure=>installed,
						require=>Exec['install_dahdi']
					}
				}
				'8': {
					#для CentOS 8 пришлось подключать репу http://repo.okay.com.mx/centos/8/x86_64/release/okay-release-1-3.el8.noarch.rpm
					include repos::okay
					$package_list=['sqlite','sqlite-devel','libogg','spandsp','libvorbis','spandsp-devel','libsrtp','libsrtp-devel','libogg-devel','libvorbis-devel','libuuid-devel','jansson-devel'];
					package{$package_list: ensure =>installed,
						require=>Package['okay-release'],
						require=>Exec['install_dahdi']
					}
				}
			}
		}
		'Debian','Ubuntu': {
			$package_list=['sqlite3','libsqlite3-dev','libogg0','libspandsp2','libvorbis0a','libspandsp-dev','libsrtp2-1','libsrtp2-dev','libogg-dev','libvorbis-dev','uuid-dev','libjansson-dev'];
			package{$package_list: ensure =>installed, require=>Package['dahdi']}
		}
	} ->

	file {$tmpdir:
		ensure=>directory
	} ->
	file {"$tmpdir/asterisk.tar.gz":
		ensure	=> file,
		source	=> "puppet:///modules/asterisk/asterisk-${version}.tar.gz",
		
	} ->
	exec {'asterisk_extract':
		require => Exec['clean_asterisk_sources'],
		command	=> "tar -zxvf ./asterisk.tar.gz",
		cwd		=> $tmpdir,
		onlyif	=> "which ${asterisk::dahdi::checkfile}",							#устанавливаем астериск только после dahdi
		unless	=> "test -f $srcdir/.version && grep $version $srcdir/.version",	#распаковываем только если уже нет файла с версией и он указывает на правильную версию
		path	=> '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin'
	} ->
	exec {'asterisk_install':
		command	=> "$srcdir/configure --libdir=${asterisk::libdir} --prefix=/ && make menuselect.makeopts && menuselect/menuselect --enable res_srtp --enable res_fax --enable app_meetme --enable chan_ooh323 --disable-asteriskssl && make clean && make && make install",
		require	=> Package[$pakage_list],
		cwd		=> $srcdir,
		onlyif	=> "which ${asterisk::dahdi::checkfile}",							#устанавливаем астериск только после dahdi
		unless	=> "which asterisk > /dev/null && test -f ${asterisk::libdir}/asterisk/modules/res_phoneprov.so && test -f ${asterisk::libdir}/asterisk/modules/app_meetme.so && asterisk -V|grep $version && asterisk -V|grep spoo",
		timeout	=> 1800,
		path	=> '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin',
		notify	=> Service['asterisk'],
	} ->
	case $::operatingsystem {
		'CentOS': {
			case $::operatingsystemmajrelease {
				'6','7': {
					exec {'asterisk_service':
						command => "cat contrib/init.d/rc.redhat.asterisk|sed 's/__ASTERISK_SBIN_DIR__/\\/usr\\/sbin/g' > /etc/init.d/asterisk && chmod 777 /etc/init.d/asterisk && chkconfig --add asterisk",
						cwd		=> "$srcdir",
						onlyif	=> 'which asterisk',
						unless	=> 'ls /etc/init.d/asterisk',
						path	=> '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin'
					}
				}
				'8': {
					file {'/etc/systemd/system/asterisk.service': source=>'puppet:///modules/asterisk/asterisk.service'}
					 #если по юнитфайлу есть изменения - говорим systemd перечитать его
					exec {'asterisk_unitfile_reload':
						command		=> 'systemctl daemon-reload',
						subscribe	=> File['/etc/systemd/system/asterisk.service'],
						refreshonly	=> true,
						path		=> '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin'
					}
				}
			}
		}
		'Debian','Ubuntu': {
			file {'/etc/systemd/system/asterisk.service': source=>'puppet:///modules/asterisk/asterisk.service'}
			#если по юнитфайлу есть изменения - говорим systemd перечитать его
			exec {'asterisk_unitfile_reload':
				command		=> 'systemctl daemon-reload',
				subscribe	=> File['/etc/systemd/system/asterisk.service'],
				refreshonly	=> true,
				path		=> '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin'
			}
		}
	} ->
	service {'asterisk':
		ensure	=> running,
		enable	=> true
	}
	exec {'clean_asterisk_sources':
		command		=> "rm -rf $srcdir",
		subscribe	=> File["$tmpdir/asterisk.tar.gz"],
		refreshonly	=> true,
		path		=> '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin'
	}
}


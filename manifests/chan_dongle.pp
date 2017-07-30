#класс установки модуля chan_dongle для астериска
#добавлять его нужно по делу, а не в каждую установку,
#поскольку этот модуль официально не поддерживается и просто
#народное творчество
#нужен для поддержки usb свистков

class asterisk::chan_dongle {
	$tmpdir='/tmp/ast.dongle_inst'
	file {$tmpdir:
		ensure=>directory
	} ->
	file {"$tmpdir/dongle.zip":
		ensure	=> file,
		source	=> 'puppet:///modules/asterisk/chan_dongle-asterisk11.zip',
	} ->
	exec {'install_chan_dongle':
		command	=> 'unzip -o ./dongle.zip && cd asterisk-chan-dongle* && aclocal && autoconf && automake -a || DESTDIR="/usr/lib64/asterisk/modules" ./configure  && make && make install',
		cwd		=> $tmpdir,
		unless	=> 'test -f /usr/lib64/asterisk/modules/chan_dongle.so',
		path	=> '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin',
		require => Package['unzip'],
	}
}


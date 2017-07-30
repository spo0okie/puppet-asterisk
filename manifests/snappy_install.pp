class asterisk::snappy_install {
	$tmpdir='/tmp/ast.snappy_inst'
	file {$tmpdir:
		ensure=>directory
	} ->
	file {"$tmpdir/snappy.zip":
		ensure	=> file,
		source	=> 'puppet:///modules/asterisk/snappy.zip',
	} ->
	exec {'install_snappy':
		command	=> 'unzip -o ./snappy.zip && cd snappy* && ./autogen.sh && ./configure --libdir=/usr/lib64 && make && cp ./README.md README && make install',
		cwd		=> $tmpdir,
		unless	=> 'test -f /usr/lib64/libsnappy.so',
		path	=> '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin',
		require => Package['kernel-devel'],
	}
}


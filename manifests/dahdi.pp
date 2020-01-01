class asterisk::dahdi {
	$tmpdir='/tmp/ast.dahdi_inst'
	#файл, наличие которого указывает на наличие dahdi в системе
	$checkfile='dahdi_hardware'
	file {$tmpdir:
		ensure=>directory
	} ->
	file {"$tmpdir/dahdi.tar.gz":
		ensure	=> file,
		source	=> 'puppet:///modules/asterisk/dahdi-linux-complete-current.tar.gz',
	} ->
	exec {'install_kernel_sources':
		command	=> "yum install kernel-devel -y",
		cwd		=> $tmpdir,
		unless	=> "which $checkfile",
		path	=> '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin',
		require => Package['kernel-devel'],
	} ->
	exec {'install_dahdi':
		command	=> 'tar -zxvf ./dahdi.tar.gz && cd dahdi* && make && make install',
		cwd		=> $tmpdir,
		unless	=> "which $checkfile",
		path	=> '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin',
		require => Package['kernel-devel'],
	}
}


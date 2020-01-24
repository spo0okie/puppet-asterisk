class asterisk::dahdi {
	$tmpdir='/tmp/ast.dahdi_inst'
	#файл, наличие которого указывает на наличие dahdi в системе
	$checkfile='dahdi_hardware'
	case $::operatingsystem {
		'CentOS': {
			case $::operatingsystemmajrelease {
				'6','7': {
					exec {'install_kernel_sources':
					command	=> "yum install kernel-devel -y",
					cwd		=> $tmpdir,
					unless	=> "which $checkfile",
					path	=> '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin',
					require => Package['kernel-devel'],
					}
					$dahdi_ver='2.11.1'
				}
				'8': {
					$dahdi_ver='3.1.0'
				}
			}
		}
	}
	file {$tmpdir:
		ensure=>directory
	} ->
	file {"$tmpdir/dahdi.tar.gz":
		ensure	=> file,
		source	=> "puppet:///modules/asterisk/dahdi-linux-complete-${dahdi_ver}.tar.gz",
	} ->
	exec {'install_dahdi':
		command	=> "tar -zxvf ./dahdi.tar.gz && cd dahdi-linux-complete-${dahdi_ver}+${dahdi_ver}/tools && make all && make install",
		cwd		=> $tmpdir,
		unless	=> "which $checkfile",
		path	=> '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin',
		require => Package['kernel-devel'],
	}
}


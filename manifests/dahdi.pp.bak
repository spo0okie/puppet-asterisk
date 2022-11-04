class asterisk::dahdi {
	$tmpdir='/tmp/ast.dahdi_inst'
	#файл, наличие которого указывает на наличие dahdi в системе
	$checkfile='dahdi_hardware'
	#в зависимости от операционной системы мы ставим разные версии dahdi разными сборочными строками?
	#почему разные и по разному? потомучто все было зашибись по старому на версиях 6 и 7 были проблемы на 8й, в связи с чем изменения
	#
	case $::operatingsystem {
		'CentOS': {
			case $::operatingsystemmajrelease {
				'6','7': {
					exec {'install_kernel_sources':
						command	=> "yum install kernel-devel -y",
						cwd		=> $tmpdir,
						unless	=> "which $checkfile",
						path	=> '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin',
						require => Package[$::common::kernel_devel],
					}
					$dahdi_ver='2.11.1'
					$buildcmd="tar -zxvf ./dahdi.tar.gz && cd dahdi-linux-complete-${dahdi_ver}+${dahdi_ver} && make && make install"
				}
				'8': {
					$dahdi_ver='3.1.0'
					$buildcmd="tar -zxvf ./dahdi.tar.gz && cd dahdi-linux-complete-${dahdi_ver}+${dahdi_ver} && make all && make install"
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
				command	=> $buildcmd,
				cwd		=> $tmpdir,
				unless	=> "which $checkfile",
				path	=> '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin',
				require => Package[$::common::kernel_devel],
			}			
		}
		'Debian','Ubuntu': {
			package {['dahdi','dahdi-linux','dahdi-source']:
				ensure => installed,
			} 
		}
	}
}


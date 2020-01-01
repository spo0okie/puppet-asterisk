class asterisk::sounds {
	#загружает русские звуковые файлы
	file {"/var/lib/asterisk/sounds":
		ensure	=> directory,
		source	=> 'puppet:///modules/asterisk/sounds',
		recurse	=> true,
		require => Service['asterisk'],
	}
}


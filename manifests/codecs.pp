class asterisk::codecs {
	file {"${asterisk::libdir}/asterisk/modules/codec_g729.so":
		ensure	=> file,
		source	=> "puppet:///modules/asterisk/codecs/codec_g729-ast${asterisk::install::version_maj}0-gcc4-glibc-x86_64-core2.so",
		mode	=> '0555',
		require	=> Service['asterisk'],
	}
	file {"${asterisk::libdir}/asterisk/modules/codec_g723.so":
		ensure	=> file,
		source	=> "puppet:///modules/asterisk/codecs/codec_g723-ast${asterisk::install::version_maj}0-gcc4-glibc-x86_64-core2.so",
		mode	=> '0555',
		require	=> Service['asterisk'],
	}
}


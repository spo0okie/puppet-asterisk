class asterisk::codecs {
	file {"/usr/lib64/asterisk/modules/codec_g729.so":
		ensure	=> file,
		source	=> 'puppet:///modules/asterisk/codecs/codec_g729-ast110-gcc4-glibc-x86_64-core2.so',
		mode	=> '0555',
		require	=> Service['asterisk'],
	}
	file {"/usr/lib64/asterisk/modules/codec_g723.so":
		ensure	=> file,
		source	=> 'puppet:///modules/asterisk/codecs/codec_g723-ast110-gcc4-glibc-x86_64-core2.so',
		mode	=> '0555',
		require	=> Service['asterisk'],
	}
}


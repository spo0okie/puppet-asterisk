class asterisk::mcedit {
	file {"/usr/share/mc/syntax/asterisk.syntax":
		ensure	=> file,
		source	=> 'puppet:///modules/asterisk/mcedit/asterisk.syntax',
		mode	=> '0644',
	} ->
  file_line { "mcedit_asterisk_syntax_mask":
		path => '/etc/mc/Syntax',
		line => 'file ..\*\\.(conf)$ Config\sFile',
    after => 'include syntax.syntax\n\n'
	} ->
  file_line { "mcedit_asterisk_syntax_mask":
		path => '/etc/mc/Syntax',
		line => 'include asterisk.syntax',
    after => 'file ..\*\\.(conf)$ Config\sFile'
	}
}

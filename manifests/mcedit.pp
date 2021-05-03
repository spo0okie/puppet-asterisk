class asterisk::mcedit {
  case $::operatingsystem {
    'CentOS': {
       $syntaxConfig='/etc/mc/Syntax'
    }
    'Debian','Ubuntu': {
       $syntaxConfig='/usr/share/mc/syntax/Syntax'
    }
  }
  #тут у нас судя по man mcedit (https://www.systutorials.com/docs/linux/man/1-mcedit/) должно быть
  #вторым параметром экранированный regexp конфига астериска
  #допустим он выглядит так: /etc/asterisk/.*.conf$, тогда:
  $fileRegexLine='file /etc/asterisk/\.\*\.(conf)$ Config\sFile'
  file {"/usr/share/mc/syntax/asterisk.syntax":
    ensure	=> file,
    source	=> 'puppet:///modules/asterisk/mcedit/asterisk.syntax',
    mode	=> '0644',
  } ->
  file_line { "mcedit_asterisk_syntax_mask":
    path => $syntaxConfig,
    line => $fileRegexLine,
    after => 'include syntax.syntax'
  } ->
  file_line { "mcedit_asterisk_syntax_include":
    path => $syntaxConfig,
    line => 'include asterisk.syntax',
    after => '^file /etc/asterisk/'
  }
}

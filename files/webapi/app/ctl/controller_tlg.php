<?php

//конечная цель всего вот этого /opt/telegram.sh/telegram -c 1571486886 "test from srv-sms"


/*
 * Класс работы с tlg
 */
class controller_tlg {
	private $telegram_path;
	const MSG_BIN_NOT_FOUND='BINARY_NOT_FOUND';
	const MSG_EXEC_ERR='EXECUTION_ERROR';
	const MSG_NO_TEXT='NO_MESSAGE_GIVEN';
	const MSG_NO_ADDR='NO_SEND_ADDR_GIVEN';
	const MSG_OK='OK';
	
	public function __construct(){
		$this->telegram_path='/opt/telegram.sh/telegram';
	}
	
	/*
	 * выполняет комманду telegram с переданными параметрами
	 * @var string $params параметры вызова gammu
	 */
	private function run($params){
		setlocale('LC_ALL','ru_RU.UTF-8');
		$out=null;
		if (!strlen($this->telegram_path)) return controller_tlg::MSG_BIN_NOT_FOUND;
		if (exec('export LANG=ru_RU.UTF-8 && '.$this->telegram_path.' '.$params,$out)===false) return controller_tlg::MSG_EXEC_ERR;
		if (!isset($out[0])) return controller_tlg::MSG_EXEC_ERR.': '.implode('|',$out);
		//if (strpos(implode("\n",$out),'Written message with ID')===false) return controller_tlg::MSG_EXEC_ERR.': '.implode('|',$out);
		return controller_tlg::MSG_OK.': '.implode('|',$out);
	}
	
	/*
	 * @var $text тест для отправки в формате UTF8
	 * @var $addr номер телефона для отправки СМС
	 */
	private function send($text,$addr){
		if (!strlen($text)) return controller_tlg::MSG_NO_TEXT;
		if (!strlen($addr)) return controller_tlg::MSG_NO_ADDR;
		$params='-c '.$addr.' "'.addslashes($text).'"';
		//TEXT 89193393655 -unicode -text "$text" -autolen ${#text}
		error_log($params);
		return $this->run($params);
	}




	/*
	 * отправляет СМС беря адрес и текст из URL
	 */
	public function action_send() {
		$addr=router::getRoute(3, 'addr');
		$text=router::getRoute(4, 'text');
		echo $this->send($text, $addr);
		exit();
	}
}
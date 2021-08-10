<?php

//конечная цель всего вот этого> echo "проверка" | gammu sendsms TEXT +79193393655 -unicode


/*
 * Класс работы с смс
 */
class controller_sms {
	private $gammu_path;
	const MSG_BIN_NOT_FOUND='BINARY_NOT_FOUND';
	const MSG_EXEC_ERR='EXECUTION_ERROR';
	const MSG_NO_TEXT='NO_MESSAGE_GIVEN';
	const MSG_NO_ADDR='NO_SEND_ADDR_GIVEN';
	const MSG_OK='OK';
	
	public function __construct(){
		exec('which gammu-smsd-inject',$out);
		$this->gammu_path=isset($out[0])?$out[0]:false;
	}
	
	/*
	 * выполняет комманду gammu с переданными параметрами
	 * @var string $params параметры вызова gammu
	 */
	private function run($params){
		setlocale(LC_ALL,'ru_RU.UTF-8');
		$out=null;
		if (!strlen($this->gammu_path)) return controller_sms::MSG_BIN_NOT_FOUND;
		if (exec('export LANG=ru_RU.UTF-8 && '.$this->gammu_path.' '.$params,$out)===false) return controller_sms::MSG_EXEC_ERR;
		if (!isset($out[0])) return controller_sms::MSG_EXEC_ERR.': '.implode('|',$out);
		if (strpos($out[0],'OK, ссылка на сообщение=')===false) return controller_sms::MSG_EXEC_ERR.': '.implode('|',$out);
		return controller_sms::MSG_OK.': '.implode('|',$out);
	}
	
	/*
	 * @var $text тест для отправки в формате UTF8
	 * @var $addr номер телефона для отправки СМС
	 */
	private function send($text,$addr){
		if (!strlen($text)) return controller_sms::MSG_NO_TEXT;
		if (!strlen($addr)) return controller_sms::MSG_NO_ADDR;
		$phone=$this->get_phone();
		$params='--config /etc/gammu-smsd-'.$phone.' TEXT '.$addr.' -text "'.addslashes($text).'" -unicode -autolen '.strlen($text);
		//TEXT 89193393655 -unicode -text "$text" -autolen ${#text}
		error_log($params);
		return $this->run($params);
	}



	private function get_phone() {
		$db=mysqli_connect('localhost','smsd','smsdPa55wd','gammu_smsd');
		mysqli_query($db,'use gammu_smsd');
		$req_obj=mysqli_query($db,'select ID from phones order by ID;');
		$phones=array();
		while (is_array($row=mysqli_fetch_assoc($req_obj))) {
			$phones[]=$row['ID'];
		}
		$req_obj=mysqli_query($db,'select id from phone_use order by id;');
		$row=mysqli_fetch_assoc($req_obj);
		$phone= ($row['id']+1) % count($phones);
		mysqli_query($db,'delete from phone_use;');
		$q='insert into phone_use values('.$phone.',"");';
		error_log($q);
		mysqli_query($db,$q);
		error_log( mysqli_error($db));
		return $phones[$phone];
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
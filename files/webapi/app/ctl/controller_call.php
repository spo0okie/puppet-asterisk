<?php
/*
 * Класс инициации исходящих звонков в астериске
 */

class controller_call {
	const tmp_folder='/tmp';
	const spool_folder='/var/spool/asterisk/outgoing';
	const MSG_OK='OK';
	const MSG_ERR_WRITE='CANT_WRITE_TO_FILE';
	const MSG_ERR_OPEN='CANT_OPEN_FILE';
	const MSG_ERR_COPY='ERROR_COPYING_FILE';
	const MSG_NO_FROM='NO_CALLER_SET';
	const MSG_NO_TO='NO_CALLEE_SET';
	
	/*
	 * Формирует текст call-файла для астериска
	 */
	static public function callFileText($from,$to){
		return 	"Channel: Local/$from@org1_phones\n".
				"Callerid: Вызов $to<$to>\n".
				"WaitTime:15\n\n".
				"Account: 1\n".
				"Context: org1_phones\n".
				"Extension: $to\n".
				"Priority: 1\n";
	}
	
	/*
	 * Формирует имя временного файла
	 */
	static public function tmpCallFileName(){
		return (string)(time()).'_'.(string)(rand(1000,9999)).'.call';
	}
	
	/*
	 * Инициирует исходящий звонок посредством формирования временного файла и копирования в спул астериска
	 */
	static public function initiateCall($from,$to){
		$tmpfile=controller_call::tmp_folder.'/'.controller_call::tmpCallFileName();
		if ($f=fopen($tmpfile,'w')) {
			if (fwrite($f,controller_call::callFileText($from, $to))) {
				fclose($f);
				$dummy=[];
				$ret=null;
				$cmd="mv $tmpfile ".controller_call::spool_folder."/";
				exec($cmd,$dummy,$ret);
				return $ret?(controller_call::MSG_ERR_COPY):controller_call::MSG_OK;
			} else return controller_call::MSG_ERR_WRITE;
		} else return controller_call::MSG_ERR_OPEN;
	}
	
	public function action_initiate(){
		$from=router::getRoute(3, 'from');
		$to=  router::getRoute(4, 'to');
		if   (is_null($from))	echo controller_call::MSG_NO_FROM;
		elseif (is_null($to))	echo controller_call::MSG_NO_TO;
		else echo controller_call::initiateCall($from, $to);
	}

	public function action_event(){
		$body = file_get_contents('php://input');
		error_log(print_r($body,true));
	}
	
}

?>
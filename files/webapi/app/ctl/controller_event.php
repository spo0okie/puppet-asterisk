<?php
/*
 * Класс регистрации событий от ВАТС интерсвязи
 */


class controller_event {
	const tmp_folder='/tmp';

	//ошибки распарсивания JSON данных
	const EMPTY_BODY='ERR: Got empty POST body';
	const JSON_ERROR='ERR: JSON format error';
	const JSON_NO_PARAMS='ERR: JSON block contain no PARAMS branch';
	const PARAMS_NO_CALLID='ERR: PARAMS block contain no call_id';
	const PARAMS_NO_SRC='ERR: PARAMS block contain no src_phone';
	const PARAMS_NO_DST='ERR: PARAMS block contain no dst_phone';
	const PARAMS_NO_LOCAL='ERR: PARAMS block contain no real_local_number';
	const PARAMS_NO_DATE='ERR: PARAMS block contain no event_date';
	const PARAMS_NO_EVENT='ERR: PARAMS block contain no event_name';
	const PARAMS_UNKNOWN_EVENT='ERR: PARAMS block contain unknown event_name';

	const ERR_UNKNOWN_CLIENT='ERR: Unknown client phone';
	const ERR_ORACLE_ERR='ERR: Error pushing data to Oracle';

	const TEST_OK='OK: test OK';

	//определения типов JSON событий
	const EVT_CALL_START='start.call';      //начало вызова - с внешнего на внешний
	const EVT_TALK_START='start.talk';      //начало разговора - свнешнего с внутренним
	const EVT_CALL_LOCAL='local.in.call';   //вызов на внутренний
	const EVT_CALL_END='end.call';          //конец вызова
	const EVT_VM_START='vm.record.start';     //начало записи сообщения
	const EVT_VM_END='vm.record.end';     //начало записи сообщения

	//успешная отправка сообщения
	const OK_OK='OK: all ok';

	private $server=null;
	private $instance=null;
	private $user=null;
	private $password=null;
	private $oci;
	private $body;

	/**
	 * Выход с логированием ошибки
	 * @param $status текст ошибки
	 */
	private static function halt($status) {
		error_log($status);
		die($status);
	}

	/**
	 * Сравнение телефонов
	 * @param string $callerid текстовя строка определителя номера
	 * @param mixed $phone объект с которым идет сравнение (массив или строка) например [7,351,2050130]
	 * @return bool
	 */
	private static function phone_compare($callerid,$phone){
		if (is_array($phone)) { //сравнение с разными вариантами написания телефона
			if (!count($phone)) return false; //если передан пустой массив, то точно не совпало
			for ($i=0;$i<count($phone);$i++) {
				$teststring=implode('',array_slice($phone,$i)); //собираем тестовую строку из токенов телефонного номера
				//error_log($teststring);
				if (static::phone_compare($callerid,$teststring)) return true;
			}
			return false;
		} else { //сравнение строк
			return (strcmp($callerid,$phone)==0);
		}

	}

	private function connect() {
		$this->oci = oci_connect($this->user,$this->password,$this->server.'/'.$this->instance);
	}

	private function disconnect() {
		oci_close($this->oci);
	}

		
	private function sendData($data) {
		date_default_timezone_set('Asia/Yekaterinburg');
		/*
		 * 4. Принимать следующие события входящего вызова:
		 *      New - приём входящего вызова (до автоинформирования)
		 *      Ring - распределение входящего вызова на рабочее место диспетчеру
		 *      Answ - ответ диспетчера на входящий свызов
		 *      Cancel - вызов сброшен диспетчером
		 *      Drop - вызов сброшен абонентом
		 *      Post??? - голосовая почта (абонент наговорил голосовое сообщение) - где ??? - секунды, на которых началось голосовое сообщение
		 * */

        /**
         * -- сохранить входящий вызов в очереди вызовов (функция без commit, commit делается внешне)
         * -- aon - телефон звонящего абонента
         * -- serv_ph - номер телефона/службы, на который звонит абонент
         * -- in_ph - внутренний номер телефона, если есть
         * -- dt - дата и время поступающего события
         * -- typ - тип события (соединено, сброшено оператором, сброшено абонентом)
         * -- snd_f - звуковой файл
         * -- ndx - уникальный номер события в глобальном поле событий
         * -- ctype - тип вызова: CALL - голосовой вызов, RECORD - запись для прослушивания
         * -- d - если подразделение уже определено, то подставляется без определения по номерам входящих телефонов
         * -- rid - номер заявки, которая уже оформлена для данного входящего
         * procedure calls_queue(
         *      aon varchar2,
         *      serv_ph_ varchar2,
         *      inph varchar2,
         *      dt date,
         *      typ varchar2,
         *      snd_f varchar2,
         *      ndx number default null,
         *      ctype_ varchar2 default 'CALL',
         *      d number default null,
         *      req_id number default null
         * ) is
         */
		$oci_command = "begin ".
			"ics.services.calls_queue(".
			"'".$data['src']."',".
			"'".$data['orgphone']."',".
			"'".$data['dst']."',".
			//"to_date('". date('d.m.Y H:i:s')."','dd.mm.yyyy hh24:mi:ss'),".     //вариант, когда дату передаем в явном виде
			"sysdate,".                                                           //вариант, когда дату записывает сам оракл
			"'".$data['state']."',".
            "'".$data['monitor']."'";
		if (isset($data['ndx']) && !empty($data['ndx']))
            $oci_command .= ",".$data['ndx'];

		$oci_command .=");"." end;";

		$stid = oci_parse($this->oci, $oci_command);
		error_log("Data sent to Oracle: ".$oci_command);
		if (!oci_execute($stid)) static::halt(static::ERR_ORACLE_ERR);
	}

	/*
	{
		"type": "call_event", 
		"params": {
			"src_phone": "79193393655",
			"dst_phone": "73512250698", 
			"event_date": "2019-02-13 22:56:53.685954", 
			"call_id": "120a0a1e7473036e24ed0cc44d1dd970", 
			"event_name":
				start.call          //начало вызова - с внешнего на внешний
			    local.in.call       //вызов на внутренний
				end.call            //конец вызова
			"direction": "1"
		}
	}

	{
		"type": "call_event", 
		"params": {
			"real_local_number": "105", 
			"event_date": "2019-02-13 22:56:53.724717", 
			"call_id": "120a0a1e7473036e24ed0cc44d1dd970", 
			"event_name": "local.in.call"
			"src_phone": "79193393655", 
			"dst_phone": "73512250698", 
		}
	}
	*/


	/**
	 * Тут мы должны на основании JSON евента свформировать запись для БД
	 * @param $params - блок параметров полученный в JSON
	 * @return array - массив данных в соотв. с API для оракл
	 * @throws Exception - выбрасывает ошибку обработки
	 */
	private function form_data($params) {

		switch ($params->event_name) {


			case static::EVT_CALL_START:
				return [
					'src'=>$params->src_phone,
					'orgphone'=>$params->dst_phone,
					'dst'=>'',
					'state'=>'New',
                    'monitor'=>$params->call_id,
					'ndx'=>isset($params->evt_id)?$params->evt_id:''
				];
				break;
			case static::EVT_CALL_END:
				return [
					'src'=>$params->src_phone,
					'orgphone'=>$params->dst_phone,
					'dst'=>isset($params->real_local_number)?$params->real_local_number:'',
					'state'=>'Drop',
					'monitor'=>$params->call_id,
                    'ndx'=>isset($params->evt_id)?$params->evt_id:''
				];
				break;
			case static::EVT_TALK_START:
				//в случае внутреннего вызова обязательно должен быть внетренний
				if (!isset($params->real_local_number))
					throw new Exception(static::PARAMS_NO_LOCAL);
				return [
					'src'=>$params->src_phone,
					'orgphone'=>$params->dst_phone,
					'dst'=>$params->real_local_number,
					'state'=>'Answ',
					'monitor'=>$params->call_id,
                    'ndx'=>isset($params->evt_id)?$params->evt_id:''
				];
				break;
			case static::EVT_CALL_LOCAL:
				//в случае внутреннего вызова обязательно должен быть внетренний
				if (!isset($params->real_local_number))
					throw new Exception(static::PARAMS_NO_LOCAL);
				return [
					'src'=>$params->src_phone,
					'orgphone'=>$params->dst_phone,
					'dst'=>$params->real_local_number,
					'state'=>'Ring',
					'monitor'=>$params->call_id,
                    'ndx'=>isset($params->evt_id)?$params->evt_id:''
				];
				break;

			case static::EVT_VM_START:
				//начало записи голосового сообщения
				break;


			case static::EVT_VM_END:
				break;

			default:
				//выбрасываем исключение, неизвестное событие
				throw new Exception(static::PARAMS_NO_EVENT.' "'.$params->event_name.'"');
				break;
		}
		return null;
	}

	private function load_connection(&$data) {
		//подгружаем список клиентов
		include "conf_db_list.php";
		//error_log(print_r($conf_db_list,true));
		foreach ($conf_db_list as $db)
			foreach ($db['org_phones'] as $org_phone) if (static::phone_compare($data['orgphone'],$org_phone))
			//if (array_search($data['orgphone'],$db['org_phones']))
			{
				$this->server=$db['server'];
				$this->instance=$db['instance'];
				$this->user=$db['user'];
				$this->password=$db['passwd'];
				$data['orgphone']=$org_phone[1].$org_phone[2];
				return;
			}
		static::halt(static::ERR_UNKNOWN_CLIENT.' ['.$data['orgphone'].'] //'.$this->body);
	}

	public function action_push(){
		$body = file_get_contents('php://input');
		$this->body=$body;
		$err_suffx=' //'.$body;
		if (!strlen($body)) static::halt(static::EMPTY_BODY.$err_suffx);
		$json=json_decode($body);
		if (is_null($json)) static::halt(static::JSON_ERROR.$err_suffx);
		if (!isset($json->params)) static::halt(static::JSON_NO_PARAMS.$err_suffx);
		if (isset($json->event_name)) $json->params->event_name=$json->event_name;
		if (!isset($json->params->call_id)) static::halt(static::PARAMS_NO_CALLID.$err_suffx);
		if (!isset($json->params->event_name)) static::halt(static::PARAMS_NO_EVENT.$err_suffx);
		if (!isset($json->params->src_phone)) static::halt(static::PARAMS_NO_SRC.$err_suffx);
		if (!isset($json->params->dst_phone)) static::halt(static::PARAMS_NO_DST.$err_suffx);
		//if (!isset($json->params->event_date)) die(static::PARAMS_NO_DATE);

		//обрезаем код страны
		if (strlen($json->params->src_phone)==11) $json->params->src_phone=substr($json->params->src_phone,1);
		if (strlen($json->params->dst_phone)==11) $json->params->dst_phone=substr($json->params->dst_phone,1);

		//формируем данные для оракла
		try {
			$data=$this->form_data($json->params);
		} catch (Exception $e) {
			static::halt($e->getMessage().$err_suffx);
		}

		//ищем в какой оракл затолкать
		$this->load_connection($data);

		//соединяемся
		$this->connect();
		error_log(print_r($data,true));
		//толкаем
		$this->sendData($data);
		//выкл
		$this->disconnect();
		die (static::OK_OK);
	}


	/**
	 * Проверка связи
	 */
	public function action_test(){
		die(static::TEST_OK);
	}

}

?>
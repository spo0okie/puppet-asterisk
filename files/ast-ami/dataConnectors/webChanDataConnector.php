<?php
/**
 * class webChanDataConnector
 * url: https://github.com/spo0okie/ast-ami/wiki/webChanDataConnector
 * User: spookie
 * Date: 07.03.2020
 * Time: 19:52
 */

require_once(dirname(__FILE__) . DIRECTORY_SEPARATOR . '/webDataConnector.php');

class webChanDataConnector extends webDataConnector  {
	private $p='webChanDataCon: '; //log prefix
	//private $lastMsgTime=null;

	public function __construct($conParams=null) {
		if (!isset($conParams['weburl_chan'])) {
			msg($this->p.'Initialization error: Incorrect connection parameters given!');
			return NULL;
		}
		$this->url=	$conParams['weburl_chan'];
		$this->p='webChanDataCon('.$this->url.'): ';
		msg($this->p.'Initialized');
	}

	public function sendData($data) {
		if (isset($data['Privilege'])) unset($data['Privilege']);
		$json_data=json_encode($data,JSON_FORCE_OBJECT);

		msg($this->p.'Sending data:' . $json_data);

		/* //synchronous
		$options = [
			'http' => [
				'header'  => "Content-type: application/json\r\n",
				'method'  => 'POST',
				'content' => $json_data,
			]
		];

		$context  = stream_context_create($options);
		$result = file_get_contents('http://'.$this->url.'/push', false, $context);
		msg($this->p.'Data sent:' . $result);
		*/

		if (strtoupper(substr(PHP_OS, 0, 3)) === 'WIN') {
			$devNull='NUL';
		} else {
			$devNull='/dev/null';
		}

		exec('curl --silent -X POST -d \''.$json_data.'\' http://'.$this->url.'/push  -o /var/log/asterisk/ast-ami-curl.log > '.$devNull.' 2> '.$devNull.' &');
		//exec('curl --silent -X POST -d \''.$json_data.'\' http://'.$this->url.'/push -o c:\\wamp\\logs\\ast-ami-curl.log &');
	}

	public function getType() {return 'webChan';}
}

<?php

function file_force_download($file,$type='application/octet-stream') {
	if (file_exists($file)) {
		// сбрасываем буфер вывода PHP, чтобы избежать переполнения памяти выделенной под скрипт
		// если этого не сделать файл будет читаться в память полностью!
		if (ob_get_level()) {
			ob_end_clean();
		}
		// заставляем браузер показать окно сохранения файла
		header('Content-Description: File Transfer');
		header('Content-Type: '.$type);
		header('Content-Disposition: attachment; filename=' . basename($file));
		header('Content-Transfer-Encoding: binary');
		header('Expires: 0');
		header('Cache-Control: must-revalidate');
		header('Pragma: public');
		header('Content-Length: ' . filesize($file));
		// читаем файл и отправляем его пользователю
		readfile($file);
		exit;
	}
}
$org='Soveren';
$recfolder='/home/record';
$error='UNKNOWN';
switch ($_GET['f']) {
	case 'get_record':
		if (!isset($_GET['name']))		$error='NO_FILE_GIVEN';
		else {
			$fname=$_GET['name'];
			$fdate=explode('-',$fname)[0];
			$file=$recfolder.'/'.$org.'/'.$fdate.'/'.$fname.'.mp3';
			if (file_exists($file)) {
				file_force_download($file);
			} else 						$error='NO_FILE_FOUND:'.$file;
		}
		break;
	
	case 'call_out':
		$tmpfile='/tmp/callfile.call';
		if (!isset($_GET['from']))		$error='NO_CALLER_SET';
		elseif (!isset($_GET['to'])) 	$error='NO_CALLEE_SET';
		else {
			$from=$_GET['from'];
			$phone=$_GET['to'];
			//фикс поскольку со стороны оракла приходили такие запросы
			if (substr($phone,-1)=='%') $phone=substr($phone,0,-1); 
			$text=	"Channel: Local/$from@org1_phones\n".
					"Callerid: Вызов $phone<$phone>\n".
					"WaitTime:15\n\n".
					"Account: 1\n".
					"Context: org1_phones\n".
					"Extension: $phone\n".
					//"Set: outall=1\n".
					"Priority: 1\n";
			if ($f=fopen($tmpfile,'w')){
				if (fwrite($f,$text)) {
					fclose($f);
					$dummy=array();
					$ret=NULL;
					exec("cp $tmpfile /var/spool/asterisk/outgoing/",$dummy,$ret);
					$error=$ret?'ERROR_COPYING_FILE':'OK';
				} else $error='CANT_WRITE_TO_FILE';
			} else $error='CANT_OPEN_FILE';
		}
		break;
	
	default:
		echo 'UNKNOWN_METHOD';
}
echo $error."\n";



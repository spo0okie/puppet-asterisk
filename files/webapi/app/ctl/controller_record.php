<?php
/*
 * контроллер для записей звонков
 */
class controller_record{
	const rec_folder='/home/record';
	const MSG_NO_FILE_GIVEN='NO_FILENAME_GIVEN';
	const MSG_NO_FILE_FOUND='NO_FILE_FOUND';
	
	static public function force_download($file,$type='application/octet-stream') {
		if (file_exists($file)) {
			// сбрасываем буфер вывода PHP, чтобы избежать переполнения памяти выделенной под скрипт
			// если этого не сделать файл будет читаться в память полностью!
			if (ob_get_level())	ob_end_clean();
			
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

	public function action_get(){
		$org=router::getRoute(3, 'org', 'org1');
		$name=router::getRoute(4, 'name');
		if (is_null($name)) {
			echo controller_record::MSG_NO_FILE_GIVEN;
			return;
		}
		
		$file=	controller_record::rec_folder.'/'.
				$org.'/'.
				(explode('-',$name)[0]).'/'.
				$name.'.mp3';
		
		if (file_exists($file)) {
			controller_record::force_download($file);
		} else {
			echo controller_record::MSG_NO_FILE_FOUND;
		}
	}
}

?>
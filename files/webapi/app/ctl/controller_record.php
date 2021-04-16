<?php
/*
 * контроллер для записей звонков
 */



class controller_record{
	const rec_folder='/home/record';
	const MSG_NO_FILE_GIVEN='NO_FILENAME_GIVEN';
    const MSG_NO_FILE_FOUND='NO_FILE_FOUND';
    const MSG_HASH_ERR='HASH_FAIL';
	const MSG_DOWNLOAD_ERR='IS74API_DOWNLOAD_ERROR';
	
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

    static function get_org_folders($root){
        $orgs=[];
        $handler=opendir($root);
        while (false !== ($item=readdir($handler))) {
            if (
                is_dir($root.'/'.$item)
                and
                !in_array($item,['.','..','lost+found'])
            ) {
                $orgs[]=$item;
                if (is_array($down_orgs=static::get_org_folders($root.'/'.$item)))
                    foreach ($down_orgs as $down_org) $orgs[]=$item.'/'.$down_org;
            }
        }
        closedir($handler);
        return $orgs;
    }

    static function get_listfiles(){
        $files=[];

        foreach (static::get_org_folders(controller_record::rec_folder) as $folder) {
            $tokens=explode('/',$folder);
            if (is_array($tokens) and count($tokens))
                $org=$tokens[0];
            else
                $org=$folder;
            $handler=opendir(controller_record::rec_folder.'/'.$folder);
            while (false !== ($item=readdir($handler))) {
                if (
                    !is_dir(controller_record::rec_folder.'/'.$folder.'/'.$item)
                and
                    (strlen($item)>4)
                and
                    substr($item,strlen($item)-4)==='.mp3'
                ) {
                    $files[]=$org.'/'.substr($item,0,strlen($item)-4);
                    if (count($files)>99) {
                        closedir($handler);
                        return $files;
                    }
                }

            }
            closedir($handler);
        }
        return $files;
    }

    public function action_get(){
		include "conf_db_list.php";
        /* @var $remote_api_url string */
        /* @var $recovery_node string */

        $org=router::getRoute(3, 'org', 'org1');
		$name=router::getRoute(4, 'name');
		if (is_null($name)) {
			echo controller_record::MSG_NO_FILE_GIVEN;
			return;
		}
		


		if (isset($conf_db_list[$org]) && isset($conf_db_list[$org]['token'])) {
			$file=	controller_record::rec_folder.'/'.$org.'/'.$name.'.mp3';
			$token=$conf_db_list[$org]['token'];
			$cmd="/usr/bin/curl -X GET '$remote_api_url/record/$name' -H 'Authorization: Bearer $token' -o $file";
			error_log($cmd);
			exec ($cmd);
			//return;
		} else {
			$file=	controller_record::rec_folder.'/'.
			$org.'/'.
			(explode('-',$name)[0]).'/'.
			$name.'.mp3';
			$file=str_replace(' ','+',$file);
		}


        //Если файл есть то скачиваем его
		if (file_exists($file)) {
			controller_record::force_download($file);
		} else { //Если файла нет то
            if (
                (!isset($_GET['no_recovery']) or !$_GET['no_recovery']) //если не запрещено восстановление
            and
                (isset ($recovery_node)) //если определена резервная нода
            ){
                header("HTTP/1.1 301 Moved Permanently");
                header("Location: $recovery_node/record/get/$org/$name?no_recovery=1");
                exit();
            } else
			    echo controller_record::MSG_NO_FILE_FOUND;
		}
	}

	function action_getfiles() {
	    echo implode("\n",static::get_listfiles());
    }

    public function action_del(){
        include "conf_db_list.php";
        /* @var $remote_api_url string */
        /* @var $recovery_node string */

        $org=router::getRoute(3, 'org', 'org1');
        $name=router::getRoute(4, 'name');
        $hash=router::getRoute(5, 'hash');

        if (is_null($name)) {
            echo controller_record::MSG_NO_FILE_GIVEN;
            return;
        }

        if (is_null($hash)) {
            echo controller_record::MSG_HASH_ERR;
            return;
        }

        $file=	controller_record::rec_folder.'/'.
            $org.'/'.
            (explode('-',$name)[0]).'/'.
            $name.'.mp3';
        $file=str_replace(' ','+',$file);



        //Если файл есть то скачиваем его
        if (file_exists($file)) {
            $test_hash=hash_file('md5',$file);
            if ($hash!==$test_hash) {
                echo controller_record::MSG_HASH_ERR;
                return;
            }
            unlink($file);
            echo "OK";
        } else { //Если файла нет то
            echo controller_record::MSG_NO_FILE_FOUND;
            error_log($file);
        }
    }
}

?>
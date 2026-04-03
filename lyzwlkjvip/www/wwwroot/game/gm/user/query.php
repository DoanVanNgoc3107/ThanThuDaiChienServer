<?php
include 'config.php';
if ($_SESSION['lasttime'] == '') {
    $_SESSION['lasttime'] = time();
} else {
    if (time() - $_SESSION['lasttime'] < 1) {
        exit('Nhập quá nhanh, vui lòng chờ một chút!'); 
    } else {
        $_SESSION['lasttime'] = time();
    }
}

if ($_POST) {
    /*
     "1" => array (
  "user" =>"admin",
  "pswd" =>"admin",
  "zoneid"=>1,
  "srv_name"=>"game.dev.1",
  "name"=>"Khu 1 (A Trạch Source)",
  "url"=>"http://127.0.0.1:39081",
  "hidde"=>false
 )
 
    */
    $quid      =  trim(poststr('qu'));
    $qu        =  $quarr[$quid];
    $uid       =  trim(poststr('uid'));
    $url       =  $qu['url'];
    $srv_name  =  $qu['srv_name'];
    $adm_user  =  $qu['user'];
    $adm_pswd  =  $qu['pswd'];
    
    $cookie    =  loginGetCookie($url,$adm_user,$adm_pswd);
    
    
    $pwd = trim(poststr('pwd'));
    
    
    // Xử lý tham số
    
    
        
        $time = time();
        
    // Xử lý tham số  
    
    if ($quid >= 1) {
        if ($uid != '') {
            if ($_POST['type']) {
                $type = trim($_POST['type']);
                $pswd = trim($_POST['pswd']);
                if ($pwd == '') {
                    exit('');
                }
                $vipfile = 'Q32838727-' . $quid . '.json';
                $fp = fopen($vipfile, "a+");
                if (filesize($vipfile) > 0) {
                    $str = fread($fp, filesize($vipfile));
                    fclose($fp);
                    $vipjson = json_decode($str, true);
                    if ($vipjson == null) {
                        $vipjson = array();
                    }
                } else {
                    $vipjson = array();
                }
                if (!$vipjson[$uid]) {
                    exit('Mã thẻ đã hết hạn, bạn không có quyền quản trị.');
                } elseif ($vipjson[$uid]['pwd'] != $pwd) {
                    exit('Mật khẩu người dùng thiết lập không khớp.');
                }
                if ($vipjson[$uid]['quid'] != $quid) {
                    exit('Người dùng đã thiết lập không khớp với khu vực (server) hiện tại.');
                }
                $viplevel = intval($vipjson[$uid]['level']);
                switch ($type) {
                    case 'charge':
                
                        $chargetype = trim(poststr('chargetype'));
                        $chargenum = trim(poststr('chargenum'));
                        if ($chargetype == '') {
                                exit('ID nạp tiền không hợp lệ');
                            }
                            $find = false;
                            $file = fopen("../charge.txt", "r");
                            while (!feof($file)) {
                                $line = fgets($file);
                                $txts = explode(';', $line);
                                if ($txts[0] == $chargetype) {
                                    $find = true;
                                }
                            }
                            fclose($file);
                            if ($find == false) {
                                exit('ID nạp tiền không hợp lệ');
                            }
                            $chargenum = trim(poststr('chargenum'));
                            if ($chargenum == '' || $chargenum < 0 || $chargenum > 999999999) {
                                exit('Số lượng gửi không hợp lệ (1-999999999)');
                            }
                        
                             $result = sendMail($url,$uid,$cookie,$chargetype,$chargenum,$srv_name);
                             
                             exit('Nạp tiền thành công, vui lòng nhận trong thư!');
               
                    break;
                    
                    case 'charge1':
                
                        $chargetype1 = trim(poststr('chargetype1'));
                        $chargenum1 = trim(poststr('chargenum1'));
                        if ($chargetype1 == '') {
                                exit('ID nạp tiền không hợp lệ');
                            }
                            $find = false;
                            $file = fopen("../charge1.txt", "r");
                            while (!feof($file)) {
                                $line = fgets($file);
                                $txts = explode(';', $line);
                                if ($txts[0] == $chargetype1) {
                                    $find = true;
                                }
                            }
                            fclose($file);
                            if ($find == false) {
                                exit('ID nạp tiền không hợp lệ');
                            }
                            $chargenum1 = trim(poststr('chargenum1'));
                            if ($chargenum1 == '' || $chargenum1 < 0 || $chargenum1 > 1) {
                                exit('Số lượng gửi không hợp lệ (1-1)');
                            }
                        
                             $result = sendMail($url,$uid,$cookie,$chargetype1,$chargenum1,$srv_name);
                             
                             exit('Gửi thành công, vui lòng nhận trong thư!');
               
                    break;
                    
                    case 'charge2':
                
                        $chargetype2 = trim(poststr('chargetype2'));
                        $chargenum2 = trim(poststr('chargenum2'));
                        if ($chargetype2 == '') {
                                exit('ID nạp tiền không hợp lệ');
                            }
                            $find = false;
                            $file = fopen("../charge2.txt", "r");
                            while (!feof($file)) {
                                $line = fgets($file);
                                $txts = explode(';', $line);
                                if ($txts[0] == $chargetype2) {
                                    $find = true;
                                }
                            }
                            fclose($file);
                            if ($find == false) {
                                exit('ID nạp tiền không hợp lệ');
                            }
                            $chargenum2 = trim(poststr('chargenum2'));
                            if ($chargenum2 == '' || $chargenum2 < 0 || $chargenum2 > 9999) {
                                exit('Số lượng gửi không hợp lệ (1-9999)');
                            }
                        
                             $result = sendMail($url,$uid,$cookie,$chargetype2,$chargenum2,$srv_name);
                             
                             exit('Gửi thành công, vui lòng nhận trong thư!');
               
                    break;
                    
                    case 'charge3':
                
                        $chargetype3 = trim(poststr('chargetype3'));
                        $chargenum3 = trim(poststr('chargenum3'));
                        if ($chargetype3 == '') {
                                exit('ID nạp tiền không hợp lệ');
                            }
                            $find = false;
                            $file = fopen("../charge3.txt", "r");
                            while (!feof($file)) {
                                $line = fgets($file);
                                $txts = explode(';', $line);
                                if ($txts[0] == $chargetype3) {
                                    $find = true;
                                }
                            }
                            fclose($file);
                            if ($find == false) {
                                exit('ID nạp tiền không hợp lệ');
                            }
                            $chargenum3 = trim(poststr('chargenum3'));
                            if ($chargenum3 == '' || $chargenum3 < 0 || $chargenum3 > 999999) {
                                exit('Số lượng gửi không hợp lệ (1-999999)');
                            }
                        
                             $result = sendMail($url,$uid,$cookie,$chargetype3,$chargenum3,$srv_name);
                             
                             exit('Gửi thành công, vui lòng nhận trong thư!');
               
                    break;
                    
                    case 'charge4':
                
                        $chargetype4 = trim(poststr('chargetype4'));
                        $chargenum4 = trim(poststr('chargenum4'));
                        if ($chargetype4 == '') {
                                exit('ID nạp tiền không hợp lệ');
                            }
                            $find = false;
                            $file = fopen("../charge4.txt", "r");
                            while (!feof($file)) {
                                $line = fgets($file);
                                $txts = explode(';', $line);
                                if ($txts[0] == $chargetype4) {
                                    $find = true;
                                }
                            }
                            fclose($file);
                            if ($find == false) {
                                exit('ID nạp tiền không hợp lệ');
                            }
                            $chargenum4 = trim(poststr('chargenum4'));
                            if ($chargenum4 == '' || $chargenum4 < 0 || $chargenum4 > 999) {
                                exit('Số lượng gửi không hợp lệ (1-999)');
                            }
                        
                             $result = sendMail($url,$uid,$cookie,$chargetype4,$chargenum4,$srv_name);
                             
                             exit('Gửi thành công, vui lòng nhận trong thư!');
               
                    break;
                    
                    case 'charge5':
                
                        $chargetype5 = trim(poststr('chargetype5'));
                        $chargenum5 = trim(poststr('chargenum5'));
                        if ($chargetype5 == '') {
                                exit('ID nạp tiền không hợp lệ');
                            }
                            $find = false;
                            $file = fopen("../charge5.txt", "r");
                            while (!feof($file)) {
                                $line = fgets($file);
                                $txts = explode(';', $line);
                                if ($txts[0] == $chargetype5) {
                                    $find = true;
                                }
                            }
                            fclose($file);
                            if ($find == false) {
                                exit('ID nạp tiền không hợp lệ');
                            }
                            $chargenum5 = trim(poststr('chargenum5'));
                            if ($chargenum5 == '' || $chargenum5 < 0 || $chargenum5 > 1) {
                                exit('Số lượng gửi không hợp lệ (1-1)');
                            }
                        
                             $result = sendMail($url,$uid,$cookie,$chargetype5,$chargenum5,$srv_name);
                             
                             exit('Gửi thành công, vui lòng nhận trong thư!');
               
                    break;
                    
                    case 'daoju':
                    
                    
                            
                        if ($viplevel < 1) {
                            exit('Không đủ quyền hạn VIP');
                        }
                            $mailid = trim(poststr('item'));
                            if ($mailid == '') {
                                exit('Lỗi ID vật phẩm');
                            }
                            $find = false;
                            $file = fopen("../item.txt", "r");
                            while (!feof($file)) {
                                $line = fgets($file);
                                $txts = explode('|', $line);
                                if ($txts[0] == $mailid) {
                                    $find = true;
                                }
                            }
                            fclose($file);
                            if ($find == false) {
                                exit('ID vật phẩm không tồn tại');
                            }
                            $mailnum = trim(poststr('num'));
                            if ($mailnum == '' || $mailnum < 0 || $mailnum > 9999) {
                                exit('Số lượng gửi không hợp lệ');
                            }
                           // Chống F12 (sửa code phía client)
                        $mailid = trim(poststr('item'));
                            if ($mailid == '') {
                                exit('Lỗi ID vật phẩm');
                            }
                            $find = false;
                            $file = fopen("../xmitem.txt", "r");
                            while (!feof($file)) {
                                $line = fgets($file);
                                $txts = explode(';', $line);
                                if ($txts[0] == $mailid) {
                                    $find = true;
                                }
                            }
                            fclose($file);
                            if ($find == false) {
                                exit('ID vật phẩm không tồn tại');
                            }
                            $mailnum = trim(poststr('num'));
                            if ($mailnum == '' || $mailnum < 0 || $mailnum > 9999) {
                                exit('Số lượng gửi quá lớn, không được phép đâu nha!');
                            }
                        // Chống F12
                            $item = trim($_POST['item']);
                            $itemnum = trim($_POST['num']);
                            $title =  trim($_POST['title']);
                            $content = trim($_POST['content']);
                            
                            
                            sendMail($url,$uid,$cookie,$item,$itemnum,$srv_name,$title,$content);
                             
                             
                             exit('Gửi thành công!');
                    break;
                    default:
                        exit('Hệ thống bất thường, vui lòng thử lại!');
                    break;
                }
            } else {
                exit('Định bắt gói tin hả!');
            }
        } else {
            exit('Tên nhân vật không đúng');
        }
    } else {
        exit('Lỗi ID khu vực (Server)');
    }
} else {
    exit('Yêu cầu không hợp lệ! Vui lòng tự trọng.');
}
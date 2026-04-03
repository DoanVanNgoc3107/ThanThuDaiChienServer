<?php
$t = time ();
?>
<!DOCTYPE html>
<html>   
<?php 
include_once 'head.php';
include_once './user/config.php';;
?>    
 
<body>
 <div class="container">
   <br>
   <div class="row">
     <div class="container-fluid">
  <div class="modal-dialog">
    <div class="modal-content">
      <ul class="breadcrumb">				
				<li>
					 <b>口袋新世纪-GM授权后台</b>
				</li>				
			</ul>
      <div class="modal-body">
   <div class="form-horizontal" role="form">						
                <div class="form-group">
                    <div class="col-sm-10">
					<h4>信息填写</h4>
                        <input type="password" id="checknum" name="checknum" class="form-control" maxlength="16" value="" placeholder="输入GM校验码" required>
                    </div>
                </div>
				<div class="form-group">
                    <div class="col-sm-10">
                        <select id="qu" name="qu" class="form-control selectpicker" data-size="5" required>
                            <?php
						
						foreach($quarr as $key=>$value){
							if($value['hidde']!=true){
								echo '<option value="'.$key.'">'.$value['name'].'</option>';
						}
						}
							
						?>
                        </select>
                    </div>
                </div>
				<div class="form-group">
                    <div class="col-sm-10">
                        <input type="text" id="uid" name="uid" class="form-control" value="" placeholder="请输入角色ID" required>
			
                    </div>
                </div>
				
				<div class="form-group">
                    <div class="col-sm-10">
					<h4>充值系统</h4>
                      		
                    </div>
                </div>
				
				<div class="form-group">
                    <div class="col-sm-10">
                        <select id="chargetype" name="chargetype" class="selectpicker show-tick form-control" data-live-search="true" data-size="10" title="请选择物品">
                         <?php
    $file = fopen("charge.txt", "r");
    while(!feof($file))
    {
      $line=fgets($file);
      $txts=explode(';',$line);
      echo '<option value="'.$txts[0].'" title="'.$txts[1].'">'.$txts[1].'</option>';
    }
    fclose($file);
    ?>							
                        </select>
                    </div>
                </div>
                <div class="form-group">
                    <div class="col-sm-10">					    
                        <input type="text" id="chargenum" name="chargenum" class="form-control" min="0" max="9999" value="" placeholder="数量" required>
                    </div>
                </div>
                <div class="form-group">
                    <div class="col-sm-10 ">
						<button type="submit" class="btn btn-danger btn-block" onclick="chargebtn()">充值</button>						
                    </div>					
                </div>
              
                <div class="form-group">
                    <div class="col-sm-10">
                        <select id="mailid" name="mailid" class="selectpicker show-tick form-control" data-live-search="true" data-size="10" title="请选择物品">
                         <?php
    $file = fopen("xmitem.txt", "r");
    while(!feof($file))
    {
      $line=fgets($file);
      $txts=explode(';',$line);
      echo '<option value="'.$txts[0].'" title="'.$txts[1].'">'.$txts[1].'</option>';
    }
    fclose($file);
    ?>							
                        </select>
                    </div>
                </div>
				
				<div class="form-group">
                    <div class="col-sm-10">					    
                        <input type="text" id="mailnum" name="mailnum" class="form-control" min="0" max="9999" value="" placeholder="数量" required>
                    </div>
                </div>
                
              
               			
                <div class="form-group">
                    <div class="col-sm-10 ">						
					<button type="submit" class="btn btn-primary btn-block" onclick="send_mail()">邮件发送</button> 
					<!--
					<button type="submit" class="btn btn-primary btn-block" onclick="send_allmail()">全服邮件</button> 
					 -->          
                    </div>					
                </div> 	
				
				<div class="form-group">
                    <div class="col-sm-10">
					<h4>授权系统</h4>			
                        <input type="text" id="pwd" name="pwd" class="form-control" value="" placeholder="请输入授权密码" required>
                    </div>
                </div>
                <div class="form-group">
                    <div class="col-sm-10">						
						<button type="submit" class="btn btn-primary" onclick="shouquanbtn()">无限元宝</button>                                            
                        <button type="submit" class="btn btn-primary" onclick="shouquanbtn1()">物品后台</button> 
                        <button type="submit" class="btn btn-primary" onclick="unshouquan()">取消权限</button>
						<button type="submit" class="btn btn-primary" onclick="editpwdbtn()">修改密码</button> 						
                    </div>					
                </div> 		
            </div>
			
      </div>
	 
    </div>
	
  </div>
     </div>
   </div>
 </div>
 <script src="js/msg.js?v=<?php echo $t;?>"></script>
</body>
</html>
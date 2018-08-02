<?php

date_default_timezone_set('Europe/London');
$filename="MNLIST.txt";
$datefile="";
$allowed_status=array("NEW_START_REQUIRED","ENABLED","WATCHDOG_EXPIRED");

function read_mnlist($filename) {
 global $datefile;
 // Open the file
 if (file_exists($filename)) {
   #$datefile=date ("F d Y H:i:s.", filemtime($filename));
   $datefile=filemtime($filename);
   $MNLIST=array();
   $fp = @fopen($filename, 'r');
   // Add each line to an array
   if ($fp) {
     $database = @fread($fp, filesize($filename));
     if ($database !==false) {
       $MNLIST = explode("\n",$database);
       return $MNLIST;
     } else {
	return FALSE;
     }
   } else {
    return FALSE;
   }
 } else {
    return FALSE;
 }
}

function json_validate($string)
{
	// decode the JSON data
	$result = json_decode($string,true);
	
    //switch and check possible JSON errors
    switch (json_last_error()) {
    	case JSON_ERROR_NONE:
      	$error = ''; // JSON is valid // No error has occurred
         break;
      case JSON_ERROR_DEPTH:
      	$error = 'The maximum stack depth has been exceeded.';
         break;
      case JSON_ERROR_STATE_MISMATCH:
      	$error = 'Invalid or malformed JSON.';
         break;
	   case JSON_ERROR_CTRL_CHAR:
	   	$error = 'Control character error, possibly incorrectly encoded.';
	   	break;
		case JSON_ERROR_SYNTAX:
      	$error = 'Syntax error, malformed JSON.';
      	break;
      // PHP >= 5.3.3
      case JSON_ERROR_UTF8:
	   	$error = 'Malformed UTF-8 characters, possibly incorrectly encoded.';
      	break;
      // PHP >= 5.5.0
	   case JSON_ERROR_RECURSION:
	   	$error = 'One or more recursive references in the value to be encoded.';
      	break;
      // PHP >= 5.5.0
      case JSON_ERROR_INF_OR_NAN:
      	$error = 'One or more NAN or INF values in the value to be encoded.';
      	break;
      case JSON_ERROR_UNSUPPORTED_TYPE:
	   	$error = 'A value of a type that cannot be encoded was given.';
         break;
      default:
      	$error = 'Unknown JSON error occured.';
      	break;
    }

    if ($error !== '') {
    	// throw the Exception or exit // or whatever :)
      throw new Exception($error);
    }

    // everything is OK
    return $result;
}



//Init MN List Array
$MN_LIST=read_mnlist($filename);
if ($MN_LIST !== FALSE) {
	$ip_ijson_list=array();
	$ip_list=array();
	//echo "MN list OK\n";
	
//Read Request on $argV
   if (!empty($argv[1])) {
	  	  try {
	  	  		//print_r($argv);
	  	  		$ip_json_list=json_validate($argv[1]);
	  	  		
	  	  } catch (Exception $e) {
	  	  	  echo 'Error while reading the json file : ', $e->getMessage(), "\n";
	  	  	  exit(1);
	  	  }
	  	  
		  foreach ($ip_json_list as $MN_ID=>$IP) {
		  	  if(filter_var($IP, FILTER_VALIDATE_IP)) {
		  	  	$MN_ID=filter_var($MN_ID, FILTER_SANITIZE_STRING);
		    	$ip_list[$MN_ID] = (string)$IP;
		  	  } else {
		  	  	 //debug 
		  	  	 $ip_list[$MN_ID] = "NA";
		  	  }
		  	}
	  } else {
	  	 echo 'usage : php ./mnrank.php \'{"mn1":"192.168.0.1","mn2":"192.168.0.2"}\'', "\n"; 
	  	  exit(0);
	  }
 
   //ip_list contain now array ("MN-NAME"=>"IP.IP.IP.IP" | "NA")) 
 
   // running through the MN list for information 
   
  $MN_TOTAL=array();
  $MN_ENABLE=array();
  $MN_UNHEALTHY=array();
  $MN_UNHEALTHY_STATUS=array();
  $POS=0;
    
  $MNIP_ARRAY=array();
  
  //Building general statistics
  foreach ($MN_LIST as $KEY=>$LINE) {
	// Init Temp value
   $MNIP_STATUS="";
   $MNIP_LASTSEEN="";
   $MNIP_ACTIVESEC="";
   $MNIP_LASTPAYMENT="";
   $MNIP_LASTPAID_BLOCK="";
  	
    //removing consecutive space
    $clean_LINE = preg_replace('!\s+!', ' ', TRIM($LINE));
    //don't process empty line
    if ($clean_LINE<>"") {
	$tmp=explode(' ',$clean_LINE);
	//check we have all our fields
	if (count($tmp)==9) {
 		$MN_TOTAL[]=$tmp;
		$MN_STATUS=$tmp[1];
		//remove the ":" at the end of the TXID
		$TXID=substr($tmp[0], 0, -1);
		// Define each fields
		$MN_LASTSEEN=$tmp[4];
		$MN_ACTIVESEC=$tmp[5];
		$MN_LASTPAYMENT=$tmp[6];
		$MN_LASTPAID_BLOCK=$tmp[7];
		// remove port to get IP only
		$TMP_IP=explode(':',$tmp[8]);
		$MN_IP=$TMP_IP[0];
		//store MNIP_INFO if match out IP
		if (in_array($MN_IP, $ip_list)) {
			//echo "Found IP : $MN_IP\n";
			$MN_ID_EXIST=array_search ($MN_IP, $ip_list);
			$MN_ID= $MN_ID_EXIST ? $MN_ID_EXIST : "LOST_IP";
			$MNIP_ARRAY[$MN_ID]["MN_IP"]=$MN_IP;
			$MNIP_ARRAY[$MN_ID]["MN_STATUS"]=in_array($MN_STATUS, $allowed_status) ? $MN_STATUS : "NA";
  			$MNIP_ARRAY[$MN_ID]["MN_LASTSEEN"]=$MN_LASTSEEN;
  			$MNIP_ARRAY[$MN_ID]["MN_ACTIVESEC"]=$MN_ACTIVESEC;
  			$MNIP_ARRAY[$MN_ID]["MN_LASTPAYMENT"]=$MN_LASTPAYMENT;
  			$MNIP_ARRAY[$MN_ID]["MN_LASTPAID_BLOCK"]=$MN_LASTPAID_BLOCK;
		} else {
			//echo "-$MN_IP- not in our list\n";
		}
		// if MN is "ENABLED" we calculate last Payment in second
		if ($MN_STATUS=="ENABLED") {
			$POS++;
			$TIME=0;
			//This node never get any payment so we take since how long it is active
			if ($MN_LASTPAYMENT==0) {
			  $TIME=$MN_ACTIVESEC;
			} else {
			  // we Calculate number of sec since last payment
			  $MN_PAYMENT_SEC=time()-$MN_LASTPAYMENT;
			  // if MN has been desactivate since last payment we take number of seconds it is active
			  if ($MN_PAYMENT_SEC>=$MN_ACTIVESEC) {
				$TIME=$MN_ACTIVESEC;
			  // else we take number of seconds since last payement
			  } else {
				$TIME=$MN_PAYMENT_SEC;
			  }
			}
			$tmp[0]=$TXID;
			$tmp[8]=$MN_IP;
			$tmp[9]=$TIME;
			$MN_ENABLE[$POS]=$tmp;
		// If MN is not "ENABLED" we just take counter for each MN status
		} else {
			if (array_key_exists($MN_STATUS,$MN_UNHEALTHY_STATUS)) {
				$MN_UNHEALTHY_STATUS[$MN_STATUS]++;
			} else {
				$MN_UNHEALTHY_STATUS[$MN_STATUS]=1;
			}
			$tmp[0]=$TXID;
			$tmp[8]=$MN_IP;
			$MN_UNHEALTHY[]=$tmp;
		}
	}
     }
  }
  
  array_multisort( array_column($MN_ENABLE,9), SORT_DESC, $MN_ENABLE );
  $POS_IP=array_column($MN_ENABLE,8);
  $POS_TXID=array_column($MN_ENABLE,0);

  $TOTAL_ENABLE=count($MN_ENABLE);
  $TOTAL_UNHEALTHY=count($MN_UNHEALTHY);
  $TOTAL_MN=count($MN_TOTAL);

  //building Json Answer
  $json_answer=array();
  $json_answer[]=array("update"=>$datefile);

  $json_answer[]=array("masternodes"=>array("total"=>$TOTAL_MN,"enabled"=>$TOTAL_ENABLE,"unhealthy"=>$TOTAL_UNHEALTHY));
  $json_answer[]=array("unhealthy"=>$MN_UNHEALTHY_STATUS);

 // var_dump($MNIP_ARRAY);
  $MN_STATS=array();
  
  foreach ($ip_list as $MN_ID=>$MNIP) {
  		 $MN_ID=filter_var($MN_ID, FILTER_SANITIZE_STRING);
		 //echo "processing $MNIP...\n";
		 $DATA=$MNIP_ARRAY[$MN_ID];
		  if (filter_var($MNIP, FILTER_VALIDATE_IP)) {
				$Position = array_search($MNIP, $POS_IP);
				if ($Position !==false) {
						$MN_STATS[$MN_ID]=array("ip"=>$MNIP,"pos"=>$Position,"result"=>"success","message"=>"ok","status"=>$DATA["MN_STATUS"],"lastseen"=>$DATA["MN_LASTSEEN"],"lastpayment"=>$DATA["MN_LASTPAYMENT"]);
				} else {
						$MN_STATS[$MN_ID]=array("ip"=>$MNIP,"pos"=>-1,"result"=>"warning","message"=>"Masternode not enabled","status"=>$DATA["MN_STATUS"],"lastseen"=>$DATA["MN_LASTSEEN"],"lastpayment"=>$DATA["MN_LASTPAYMENT"]);
				}
		  // Invalid IP
		  } else {
			$Position=-1;
			$MN_STATS[$MN_ID]=array("ip"=>"NA","pos"=>-1,"result"=>"warning","message"=>"You need to enter an IPV4 address","status"=>"","lastseen"=>"0");
		  }
	}
	$json_answer[]=array("stats"=>$MN_STATS);

// MNLIST Not loaded  
} else {
  $json_answer[]=array("stats"=>array("pos"=>-1,"result"=>"critical","message"=>"Error while reading the database","status"=>"","lastseen"=>0));
}

print_r(json_encode($json_answer));

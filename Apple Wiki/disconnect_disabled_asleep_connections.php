#!/usr/bin/php
<?php

// The disconection threshold sets the idle time threshold for disconnections.
// Any connection that has been idle for a time greater than this will be disconnected.
// This is in seconds, so for one hour, set it to 3600, 24 hours, set it to 86400, etc.

$disconnection_threshold = 86400;

// The disconnection message sets the message that users will be sent when being disocnnected.
// Leave it empty to not send a message.

$disconnection_message = "";

// The disconnection time sets the amount of time users will be given before being disconnected.
// Leave it at 0 to disconnect immediately.

$disconnection_time = 0;

// The report_disconnection_details flag sets whether this script reports the details of disconnected sessions
// when finished. You probably want to set this to 0 if you're scheduling the script.

$report_disconnection_details = 1;


// You shouldn't need to customise anything below this line.


$output_array = array();
$return_var = 0;
$connected_users_command = "serveradmin command afp:command = getConnectedUsers";

exec( $connected_users_command, &$output_array, $return_var );

if ($return_var != 0) {
  die ("Problem executing $connected_users_command, return status was: $return_var\n");
} else {

  // pop the timestamp off the end of the array and clean it up in case we want to use it for another similar script.
  $timestamp = array_pop($output_array);
  $timestamp = str_replace('afp:timeStamp = ', '', $timestamp);
  $timestamp = str_replace('"', '', $timestamp);

  // shift the AFP service state off the beginning of the array and clean it up.
  $afp_state = array_shift($output_array);
  $afp_state = str_replace('afp:state = ', '', $afp_state);
  $afp_state = str_replace('"', '', $afp_state);

  if ($afp_state != "RUNNING") {
    die ("AFP Service is not currently running. No connections to disconnect...");
  }

  // clean up output array by removing the prefix
  $output_array = str_replace('afp:usersArray:_array_index:', '' , $output_array);

  $connections = array();
  
  foreach ( $output_array as $line ) {
    $index = preg_replace('/:.*/', '', $line);
    $attribute = preg_replace('/.*:(\w+)\ =.*/', '$1', $line);
    $value = preg_replace('/.*=\ /', '', $line);
    $connections[$index][$attribute] = $value;
  }

  $disabled_asleep_connections = array();

  foreach ( $connections as $connection ) {
    // Connection state '6' means disabled/asleep.
    if ( $connection['state'] == '6' ) {
      $disabled_asleep_connections[] = $connection;
    }
  }

  $sessions_to_be_disconnected = array();

  foreach ($disabled_asleep_connections as $connection) {
    if ( $connection['lastUseElapsedTime'] > $disconnection_threshold ) {
      $sessions_to_be_disconnected[] = $connection;
    }
  }
  
  if ( ! count($sessions_to_be_disconnected) > 0 ) {
   die ("No sessions to disconnect\n"); 
  }

  $disconnect_command = 'afp:command = disconnectUsers' . "\n";
  $disconnect_command .= 'afp:message = "' . $disconnection_message . '"' . "\n";
  $disconnect_command .= 'afp:minutes = ' . $disconnection_time . "\n";

  $session_index = 0;
  
  foreach ($sessions_to_be_disconnected as $session) {
    $session_id = $session['sessionID'];
    $disconnect_command .= 'afp:sessionIDsArray:_array_index:' . $session_index . ' = ' . $session_id . "\n"; 
    $session_index += 1;
  }
  
  $filename = '/tmp/afp_disconnect_command.txt';
  
  if ( ! $handle = fopen($filename, 'w+') ) {
    die ("Unable to get handle for file ($filename)\n");
  }
  
  if ( fwrite($handle, $disconnect_command) === FALSE ) {
    die ("Cannot write to file ($filename)\n");
  }
  
  fclose($handle);	
  $disconnect_users_command = "/usr/sbin/serveradmin command < $filename";
  $output_array = array();
  $return_var = 0;
  exec ($disconnect_users_command, &$output_array, $return_var );
  
  if ($return_var != 0) {
    die ("Problem executing $disconnect_users_command, return status was: $return_var\n");
  } else {
    
    if ( $report_disconnection_details == 1 ) {
      print 'Disconnected ' . count($sessions_to_be_disconnected) . " session(s):\n\n";
      foreach ($sessions_to_be_disconnected as $session) {
        print 'Disconnected User: ' . $session['name'] . ' from IP: ' . $session['ipAddress'] . "\n";
      }
    }
  }
}
?>
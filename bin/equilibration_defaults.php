#!/usr/local/bin/php
<?php
{};

$request = json_decode( file_get_contents( "php://stdin" ) );
$result  = (object)[];

function error_exit( $msg ) {
    global $result;
    $result->_error = $msg;
    echo json_encode( $result );
    exit;
}

if ( $request === NULL ) {
    error_exit( "Invalid JSON input provided" );
}

## find step4_

$ifile = __DIR__ . "/../results/users/$request->_logon/$request->_project/charmm-gui/namd/step4_equilibration.inp";

## get state

require "common.php";
$cgstate = new cgrun_state();

if ( file_exists( $ifile ) ) {
    $result->{"sparams-min_steps"}   = intval( `grep -Pi '^minimize ' $ifile  | awk '{ print \$2 }'` );
    $result->{"sparams-run_steps"}   = intval( `grep -Pi '^run ' $ifile  | awk '{ print \$2 }'` );
    $result->{"sparams-dcdfreq"}     = intval( `grep -Pi '^dcdfreq ' $ifile  | awk '{ print \$2 }'` );
    $result->{"sparams-description"} = isset( $cgstate->state->description ) ? $cgstate->state->description : "";
    $result->{"sparams-temperature"} = floatval( `grep -Pi '^set temp ' $ifile | awk '{ print \$3 }'` );
} else {
    $result->error = "$ifile does not exist";
}   

$result->_status = "load_defaults received ok json";
echo json_encode( $result );
exit;



#!/usr/local/bin/php
<?php
{};

$request = json_decode( file_get_contents( "php://stdin" ) );
$result  = (object)[];

function defaults_error_exit( $msg ) {
    global $result;
    $result->_error = $msg;
    echo json_encode( $result );
    exit;
}

if ( $request === NULL ) {
    defaults_error_exit( "Invalid JSON input provided" );
}

## find step5_

$ifile = __DIR__ . "/../results/users/$request->_logon/$request->_project/charmm-gui/namd/step5_production.inp";

## get state

require "common.php";
$cgstate = new cgrun_state();

if ( file_exists( $ifile ) ) {
    $result->{"sparams-numsteps"}    = intval( `grep -Pi '^numsteps ' $ifile  | awk '{ print \$2 }'` );
    $result->{"sparams-run_steps"}   = intval( `grep -Pi '^run ' $ifile  | awk '{ print \$2 }'` );
    $result->{"sparams-dcdfreq"}     = intval( `grep -Pi '^dcdfreq ' $ifile  | awk '{ print \$2 }'` );
    $result->{"sparams-temperature"} = floatval( `grep -Pi '^set temp ' $ifile | awk '{ print \$3 }'` );
    $result->{"sparams-description"} = isset( $cgstate->state->description ) ? $cgstate->state->description : "";
    $result->{"sparams-lastoutput"}  = isset( $cgstate->state->lastoutput ) ? $cgstate->state->lastoutput : "?";
} else {
    $result->error = "$ifile does not exist";
}   

$result->_status = "load_defaults received ok json";
echo json_encode( $result );
exit;



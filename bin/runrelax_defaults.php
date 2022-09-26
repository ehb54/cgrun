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

## find step4_

$ifile = __DIR__ . "/../results/users/$request->_logon/$request->_project/charmm-gui/namd/step4_equilibration.inp";

## get state

require "common.php";
$cgstate = new cgrun_state();

if ( file_exists( $ifile ) ) {
    $result->{"sparams-dcdfreq"}     = intval( `grep -Pi '^dcdfreq ' $ifile  | awk '{ print \$2 }'` );
    $result->{"sparams-description"} = isset( $cgstate->state->description ) ? $cgstate->state->description : "";
    $result->{"sparams-runjobs"}     = isset( $cgstate->state->solmin_minimization_steps ) ? count( $cgstate->state->solmin_minimization_steps ) : 0;
    if ( isset( $cgstate->state->solmin_minimization_steps ) ) {
        for ( $i = 0; $i < count( $cgstate->state->solmin_minimization_steps ); ++$i ) {
            $result->{"sparams-runjobs-min_steps-$i"} = intval( $cgstate->state->solmin_minimization_steps[$i] );
        }
    }
} else {
    $result->error = "$ifile does not exist";
}   

$result->_status = "load_defaults received ok json";
echo json_encode( $result );
exit;



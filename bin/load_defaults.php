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

if ( $request->_filedata ) {
    $filelines = explode( "\n", $request->_filedata );
    $result->textfield = sprintf( "file found with %d rows", count( $filelines ) );
} else {
    $result->textfield = "no file found";
}

$result->_status = "load_defaults received ok json";
echo json_encode( $result );
exit;



#!/usr/local/bin/php
<?php

$self = __FILE__;

if ( count( $argv ) != 2 ) {
    echo '{"error":"$self requires a JSON input object"}';
    exit;
}

$json_input = $argv[1];

$input = json_decode( $json_input );

if ( !$input ) {
    echo '{"error":"$self - invalid JSON."}';
    exit;
}

$output = (object)[];

include "genapp.php";

$genapp = new GenApp( $input, $output );

$genapp->udpmessagebox('{"text":"udp messagebox"}' );
$genapp->tcpmessagebox('{"text":"tcp messagebox"}' );
$genapp->tcpmessage('{"_textarea":"tcp message\n"}' );
$genapp->udpmessage('{"_textarea":"udp message\n"}' );
$genapp->tcpmessage( [ "_textarea" => `ls -lR` ] );

## log results to textarea

# $output->{'_textarea'} = "JSON output from executable:\n" . json_encode( $output, JSON_PRETTY_PRINT ) . "\n";
$output->{'_textarea'} .= "JSON input from executable:\n"  . json_encode( $input, JSON_PRETTY_PRINT )  . "\n";

echo json_encode( $output );
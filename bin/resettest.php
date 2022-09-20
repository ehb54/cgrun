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

## process inputs here to produce output

$namd = (object)[];

$gpu_util  = 75;
$mem_util  = 80;
$mem_total = 10000;
$mem_free  = 500;
$mem_used  = 850;

if ( !isset( $namd->gpustats ) ) {
    $namd->gpustats = (Object)[];
    $namd->gpustats->max_gpu_util  = $gpu_util;
    $namd->gpustats->max_mem_util  = $mem_util;
    $namd->gpustats->min_mem_free  = $mem_free;
    $namd->gpustats->max_mem_used  = $mem_used;
}

$namd->gpustats->gpu_util  = $gpu_util;
$namd->gpustats->mem_util  = $mem_util;
$namd->gpustats->mem_total = $mem_total;
$namd->gpustats->mem_free  = $mem_free;
$namd->gpustats->mem_used  = $mem_used;

if ( $namd->gpustats->max_gpu_util < $gpu_util ) {
    $namd->gpustats->max_gpu_util = $gpu_util;
}

if ( $namd->gpustats->max_mem_util < $mem_util ) {
    $namd->gpustats->max_mem_util = $mem_util;
}

if ( $namd->gpustats->min_mem_free > $mem_free ) {
    $namd->gpustats->min_mem_free = $mem_free;
}

if ( $namd->gpustats->max_mem_used > $mem_used ) {
    $namd->gpustats->max_mem_used = $mem_used;
}


$namd->gpustats->msg =
    sprintf(
#        "<table border=\"2px\">"
        "<table>"
        . "<tr>"
        . "<th style=\"padding-right:5px;padding-left:5px;\"></th>"
        . "<th style=\"padding-right:5px;padding-left:5px;\">Last</th>"
        . "<th style=\"padding-right:5px;padding-left:5px;\">Max</th>"
        . "</tr>"
        . "<tr>"
        . "<th>GPU %%</th>"
        . "<td style=\"text-align:center\">%d</td>"
        . "<td style=\"text-align:center\">%d</td>"
        . "<tr>"
        . "<th>Memory Used %%</th>"
        . "<td style=\"text-align:center\">%d</td>"
        . "<td style=\"text-align:center\">%d</td>"
        . "<tr>"
        . "<th>Memory Used MB</th>"
        . "<td style=\"text-align:center\">%d</td>"
        . "<td style=\"text-align:center\">%d</td>"
        . "<tr>"
        . "</table>"

        #"GPU Utilization: %d% [Max %d%]<br>"
        #. "Memory Utilization: %d% [Max %d%]<br>"
        #. "Memory Used: %d [Max %d]<br>"
        #. "Memory Free: %d [Min %d]<br>"

        , $namd->gpustats->gpu_util
        , $namd->gpustats->max_gpu_util

        , $namd->gpustats->mem_util
        , $namd->gpustats->max_mem_util

        , $namd->gpustats->mem_used
        , $namd->gpustats->max_mem_used

        #, $namd->gpustats->mem_free
        #, $namd->gpustats->min_mem_free
    );


## log results to textarea

$output->gpustats = $namd->gpustats->msg;
$output->result   = "test result";
$output->fileout  = "not/really/a/file";

$output->{'_textarea'} = "JSON output from executable:\n" . json_encode( $output, JSON_PRETTY_PRINT ) . "\n";
$output->{'_textarea'} .= "JSON input from executable:\n"  . json_encode( $input, JSON_PRETTY_PRINT )  . "\n";

echo json_encode( $output );

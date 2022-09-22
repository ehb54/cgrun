<?php
{};

class cgrun_state {
    private $statefile;

    public $state;
    public $errors;

    function __construct() {
        $this->statefile = "state.json";
        $this->errors    = "";
        if ( file_exists( $this->statefile ) ) {
            $this->state = json_decode( file_get_contents( $this->statefile ) );
        } else {
            $this->state = (object)[];
        }
    }

    public function save() {
        try {
            if ( false === file_put_contents( $this->statefile, json_encode( $this->state ) ) ) {
                $this->errors .= "Error storing $this->statefile";
                return false;
            }
            chmod( $this->statefile, 0660 );
            return true;
        } catch ( Exception $e ) {
            $this->errors .= "Error storing $this->statefile";
            return false;
        }
    }

    public function init() {
        $this->state = (object)[];
        return $this->save();
    }
        
    public function dump( $msg = false ) {
        return ( $msg ? "$msg:\n" : "" ) . json_encode( $this->state, JSON_PRETTY_PRINT ) . "\n";
    }
}

## test

/*
$cgstate = new cgrun_state();

echo $cgstate->dump( "initial state" );

$cgstate->state->xyz = "hi";

echo $cgstate->dump( "after set xyz" );

$cgstate->save();

*/

#!/usr/bin/python2
import json, sys, StringIO, socket, time, subprocess
from genapp import genapp

if __name__=='__main__':

	argv_io_string = StringIO.StringIO(sys.argv[1])
	json_variables = json.load(argv_io_string)
        ga = genapp( json_variables )
        
	output = {} 

        ga.udpmessage( { "_message" : { "icon": "toast.png", "text" : "udp message\n" } } ) 
        ga.udpmessagebox( { "text" : "udp messagebox", "icon" : "skull.png"  } ) 
        ga.tcpmessage( { "_message" : { "icon": "toast.png", "text" : "tcp message\n" } } ) 
        ga.tcpmessagebox( { "text" : "tcp messagebox", "icon" : "information.png" } ) 
        ga.tcpmessage( { "_textarea" : subprocess.check_output( ['ls','-lR'] ) } )

        time.sleep( 3 )
        
        output[ 'result' ] = "message sent 3 seconds ago"

        output['_textarea'] = "JSON output from executable:\n" + json.dumps( output, indent=4 ) + "\n\n";
        output['_textarea'] += "JSON input to executable:\n" + json.dumps( json_variables, indent=4 ) + "\n";

	print json.dumps(output)
		

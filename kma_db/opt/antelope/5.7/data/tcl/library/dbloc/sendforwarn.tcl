# This file should contain all of the proc's which relate to the 
# "Save" operation and windows
# Edited by Gilbert 2010.01.17

# creates a save button for the buttonbar
proc sendforwarn_button {parent} {
    global ::Save ::State ::Define

    return [Buttonmenu $parent.#auto \
	-text Send_for_warn \
	-command sendforwarn \
    ]
}

proc sendforwarn {args} { 
    global ::State ::Define ::Prefor2
    global ::Db ::Tdb ::Ebs

    set file [open send_for_warning.txt a+]

    set dborigin [dblookup $Tdb 0 origin 0 0]

    if { [dbquery $dborigin dbRECORD_COUNT] < 1 } {
        return 0
    }

    set evid [dbgetv $dborigin 0 0 evid]
    set orid [dbgetv $dborigin 0 0 orid]

    set selorid $Prefor2($evid)

    if { $selorid < 0  } {
        tkdialog .warning Warning "can't select orid in DB" ok
        return 0
    }

    set db [dbsubset $dborigin "orid == $selorid"]

    loop i 0 [dbquery $db dbRECORD_COUNT] {
        set evid [dbgetv $db 0 $i evid]
 	set orid [dbgetv $db 0 $i orid]
        set lat  [dbgetv $db 0 $i lat]
	set lon [dbgetv $db 0 $i lon]
        set time [dbgetv $db 0 $i time] 
	set depth [dbgetv $db 0 $i depth]
	set ml [dbgetv $db 0 $i ml]
    }

#######################

    set dborigerr [dblookup $Tdb 0 origerr 0 0]
    set db [dbsubset $dborigerr "orid == $selorid"]
    
    loop i 0 [dbquery $db dbRECORD_COUNT] {
	set smajax [dbgetv $db 0 $i smajax]
	set sminax [dbgetv $db 0 $i sminax]
	set strike [dbgetv $db 0 $i strike]
	set sdepth [dbgetv $db 0 $i sdepth]
    }

#######################
    
    set dbnetmag [dblookup $Tdb 0 netmag 0 0]
    set db [dbsubset $dbnetmag "orid == $selorid"]
    set db [dbsubset $db "magtype == 'ml'"]

    loop i 0 [dbquery $db dbRECORD_COUNT] {
	set uncertainty [dbgetv $db 0 $i uncertainty]
    }

    if { [dbquery $db dbRECORD_COUNT] < 1 } {
        return 0
    }

    puts $file "$evid $orid $lat $lon $time $depth $ml $smajax $sminax $strike $sdepth $uncertainty"
   
    set ltime [expr $time + 32400.0]
    set now1 [exec epoch -l +%E now]
    set now2 [expr $now1 + 32400.0]

    set origintime [exec epoch -l +%Y%m%d%H%M%S.%s $ltime]
    set nowtime [exec epoch -l +%Y%m%d%H%M%S.%s $now2]

    set formatStr_f {1000%8d%8d%-10.3f%-10.3f%-10.2f%10.2f%-20.20s%-20.20s}
    set formatStr_t {1200%8d%8d%10.4f%10.4f%10.2f%10.2f%10.2f%10.2f%10.2f%10.2f%10.2f%20.20s%20.20s%10s}
	
    foreach con_server [array names Ebs] {

	set port_index $Ebs($con_server)

	if { $port_index != ""} {

        	set port_num [lindex $port_index 0]
        	set index [lindex $port_index 1]
		set dmCode [lindex $port_index 2]

		puts $file "connet server : $con_server  port : $port_num packet type : $index"
		
    		set serverchannel [socket $con_server $port_num]
    		fconfigure $serverchannel -buffering line

		if { $index == 1 } {
    			puts $serverchannel [format $formatStr_f $evid $orid $lat $lon $depth $ml $origintime $nowtime]
    			puts $file [format $formatStr_f $evid $orid $lat $lon $depth $ml $origintime $nowtime]
    			after 200
    			puts $serverchannel [format $formatStr_s $evid $orid $ml]
    			puts $file [format $formatStr_s $evid $orid $ml]
		}
		if { $index == 3 } {
    			puts -nonewline $serverchannel [format $formatStr_t $evid $orid $lat $lon $depth $ml $smajax $sminax $strike $sdepth $uncertainty $origintime $nowtime $dmCode]
    			puts $file [format $formatStr_t $evid $orid $lat $lon $depth $ml $smajax $sminax $strike $sdepth $uncertainty $origintime $nowtime $dmCode "\n"]
		}
    		close $serverchannel

    		after 100
	}
    }
    close $file

    tkdialog .warning Message "All send the Earthquake information evid:$evid orid:$orid dmCode:$dmCode to EBS server" ok

    exec /home/rt/knsn/bin/new_arrival.sh $orid >> /home/rt/knsn/logs/new_arrival.log &

#    set startTime [clock seconds]
#    puts "client socket : [fconfigure $serverchannel -sockname]"
#    puts "peer  socket : [fconfigure $serverchannel -peername]"
#    puts [wirte $serverchannel]
#    set ssend[cclient 203.247.79.113 9321]
}

proc thinking {args} { 
    global AfterId
    if [info exists AfterId] {
	after cancel $AfterId
    }
    busy release .
    if { $args != "" }  {
	errlog report "busy" [lindex $args 0]
    } else { 
	errlog report "busy" "waiting for operation to complete"
    }
    busy hold . -cursor watch
    global Define
    set AfterId [after [expr $Define(max_busy)*1000] { 
	if {[busy status .]} {
	    waiting "*** busy cleared automatically after $Define(max_busy) seconds ***" 
	}
    }]
}

proc waiting {args} {
    global AfterId
    after cancel $AfterId
    busy release .
    if { [grab current] != "" } { 
	grab release [grab current]
    }
    if { $args != "" }  {
	errlog report "" [lindex $args 0]
    }
}


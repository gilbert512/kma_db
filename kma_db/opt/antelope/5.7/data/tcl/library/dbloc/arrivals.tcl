
# This file should contain all of the proc's which relate to the 
# "Arrivals" operation and windows

# dispatches all arrivals operations
proc arrivals {args} { 
    global ::Arrivals ::State ::Define 

    # errlog complain arrivals $args
    set cmd [lindex $args 0]
    switch $cmd {
	init		{ create_arrivals_display }
	reap		-
	stations	-
	get_arids_used  -
	get_records_used {return [$Arrivals(display) $cmd]}
	Arrivals	-
	records 	-
	flag		-
	forget		-
	origin  	-
	event  		-
	select_all	-
	select_orid	-
	set_source	-
	map		-
	draw_arrivals	-
	range  		-
	default 	{ eval $Arrivals(display) $args }
    }
}

#  default		{ tkerror "bad message: arrivals $args" }
proc create_arrivals_display {} { 
    global ::Tdb ::Arrivals ::Define
    set Arrivals(display) .arrivals
    ArrivalDisplay $Arrivals(display) \
	-xmode time \
	-ymode order \
	-db $Tdb
    blt::table . \
	.arrivals 5,0	-columnspan $Define(maxcol) -fill both 
}

proc dbpick {args} { 
    global State
    # errlog complain dbpick $args
    if { "$State(arrival_records)" != "" } {
        # first argument is always 'arrival'
	set cmd [lindex $args 1] 
	set record [lindex $args 2]
	global Tdb
	switch $cmd { 
	    time	{ arrivals arrival_moved $record }
	    phase	{ arrivals arrival_changed_phase $record }
	    deltime { arrivals arrival_changed_measurements $record }
	    add     { set db [dblookup $Tdb 0 arrival 0 0]
		      set n [dbquery $db dbRECORD_COUNT]
		      arrivals arrival_added $record }
	    delete  { arrivals arrival_deleted $record }
	}
    }
}

# $Id$ 

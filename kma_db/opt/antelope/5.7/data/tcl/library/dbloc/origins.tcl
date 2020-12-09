
# This file should contain all of the proc's which relate to the 
# "Origins" operation and windows

# creates an origins button for the buttonbar
proc origins_button {parent} {
    return [Buttonmenu $parent.#auto \
	-text Origins \
	-command origins 
    ]
}

# dispatches all origins operations
proc origins {args} { 
    global ::Origins ::State ::Define

    set cmd [lindex $args 0]
    switch $cmd {
	init		{create_origins_display}
	update		-
	keepers 	-
	savers	 	-
	recalcs		-
	reassocs	-
	reassoc_records	-
	deletions	-
	flag		-
	redisplay_origin -
	set_evid  {eval $Origins(display) $args}
	show_residuals  {eval $Origins(display) $args}
	forget		{return [$Origins(display) $args] }
	default		{ tkerror "bad message: origins $args" }
    }
}

# creates the configuration/control window for origins operation
proc create_origins_display {} {
    global ::Origins ::State ::Define ::Db
    global ::Tdb

# put this window on main screen
    set w .o
    frame $w
    set Origins(display) $w.origins
    OriginDisplay $Origins(display) \
	-height	$Define(origins_height) \
	-width $Define(origins_width) \
	-display $Define(origin_info) \
	-font Fixedwidth \
	-db $Tdb
 
#     origins update

    blt::table $w \
	$w.origins 0,0	-columnspan $Define(maxcol) -fill x 

    blt::table . \
	$w 	10,0 -columnspan $Define(maxcol) -fill x
     
}

# $Id$ 



# creates a locate button for the buttonbar
proc map_button {parent} {
    global ::Database
    return [Buttonmenu $parent.#auto \
	-text Map \
	-command map \
	-menus "trial $Database"
    ]
}

# dispatches all map operations
proc map {args} { 
    global ::Map ::State ::Define
    global ::Db ::Tdb

    set cmd [lindex $args 0]
    switch $cmd {
	init	{}
	summon	{map_controls summon}
	dismiss {map_controls dismiss}
	Controls {map_controls summon}
	trial { display_map $Tdb .trial_map }
	Map -
	default	{ display_map $Db .database_map } 
    }
}

proc display_map {db w} {
    set name [dbquery $db dbDATABASE_NAME]
    send2dbloc bkg dbloc_map $name
}



# $Id$ 

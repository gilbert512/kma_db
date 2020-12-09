

# creates a database button for the buttonbar
proc database_button {parent} {
    global Database User
    return [Buttonmenu $parent.#auto \
	-text Database \
	-command database \
	-menus "Trial $Database $User(reference_db)"
    ]
}

proc database {args} { 
    global Trial Database
    switch -- $args { 
	init	    {}
	Trial	    	-
	Database    	{send2dbloc bkg dbe $Trial } 
	default		{send2dbloc bkg dbe $args } 
    }
}


# $Id$ 

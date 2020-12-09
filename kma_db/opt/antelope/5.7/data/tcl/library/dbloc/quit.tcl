proc quit_without_saving {} { 

    global Tdb
    set orids {}
    set keepers [origins keepers]
    foreach i $keepers {
	lappend orids [dbgetv $Tdb origin $i orid]
    }
    global Database
# ignore license expiring messages
    set problems [exec dbloc_verify $Database $orids 2>/dev/null]
    if { $problems != "" } { 
	set result [tk_dialog .abort {Danger} {This will leave a corrupt database} warning 1 Quit {Don't Quit}]
	if { $result == 1 } { 
	    return 
	}
    }

    catch "send2dbloc quit"
    after 1000
    destroy . 
}

proc quit {} {

    if { [save Save] } { 
	return 
    }

    catch "send2dbloc quit"
    after 1000
    destroy . 
}

# $Id$ 


# This should bring up the main window with a few buttons 
proc add_menu_command {pf menu db record} {
    global ::User
    if { [info exists User($pf)] } { 
	set table [dbquery $db dbTABLE_FILENAME]
	foreach command $User($pf) {
	    set i [string wordend $command 0]
	    set label [string range $command 0 [expr $i-1]]
	    set command [string range $command [expr $i+1] end]
	    $menu add command -label $label -command "exec $command $table $record"
	}
    }
}

proc main {} {

    global Program
    wm title . $Program
    wm iconname . $Program

    global ::Define

    menubar .menubar
    buttonbar .buttonbar


}

# $Id$ 

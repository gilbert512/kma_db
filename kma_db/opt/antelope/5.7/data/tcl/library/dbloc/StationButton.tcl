

proc StationButton {this dbsite sta record} { 
	global ::Define ::Sta_label
	menubutton $this \
	    -menu $this.m \
	    -font LabelFixed \
	    -relief raised \
	    -padx 5 -pady 0 -borderwidth 0 -highlightthickness 0 \
	    -textvariable Sta_label($sta)
	set menu $this.m
	menu $menu \
	    -disabledforeground blue -font Menu -tearoff 0

	foreach tag $Define(site_info) { 
	    set info [lindex [dbgetr $dbsite 1 $record 1 $tag] 0]
	    $menu add command -label "$info" -state disabled
	}

	$menu add command \
	    -label "Use this station" \
	    -command "arrivals select_sta $sta use"
	$menu add command \
	    -label "Calculate residuals only" \
	    -command "arrivals select_sta $sta residuals"
	$menu add command \
	    -label "Ignore this station" \
	    -command "arrivals select_sta $sta ignore"

	add_menu_command station_menu_items $menu $dbsite $record
}
    
proc move_canvas_window { canvas w x y } {
    global ::Id
    if { [info exists Id($w)] } { 
	$canvas delete $Id($w)
    }
    set Id($w) [$canvas create window $x $y -window $w -anchor w]
}

# $Id$ 

 
# This file should contain all of the proc's which relate to the 
# "Locate" operation and windows

# creates a locate button for the buttonbar
proc locate_button {parent} {
    global Locate State Define
    set w [Buttonmenu $parent.#auto \
	-text Locate \
	-command locate \
	-menus ""
    ]
    lappend Locate(buttons) $w
    return $w
}

# dispatches all locate operations
proc locate {args} { 
    global Locate State Define
    set cmd [lindex $args 0]
    switch $cmd {
	init	{ set Locate(buttons) ""
		 create_locate_controls}
	Locate	{ run_locate 1 }
	fix_depth { fix_depth }
	set_startloc_menu { set_startloc_menu }
	unset_key_entry  unset_key_entry
	default { eval $args } 
    }
}

proc magnitude_button {parent} {
    global Magnitude State Define User
    set w [Buttonmenu $parent.#auto \
	-text Magnitudes \
	-command magnitudes \
	-menus ""
    ]
    if { [llength $User(magnitude_calculators) ] > 1 } { 
	foreach mag $User(magnitude_calculators) { 
	    # errlog report Magnitude "$w add checkbutton -label $mag -variable Magnitude($mag)"
	    $w add checkbutton -label $mag -variable Magnitude($mag)
	    set Magnitude($mag) 1
	}
    } elseif { [llength $User(magnitude_calculators) ] == 1 } { 
	foreach mag $User(magnitude_calculators) { 
	    set Magnitude($mag) 1
	}
    }
    lappend Magnitude(buttons) $w
    return $w
}

proc undone_magnitudes {} {
    global Arrivals
    set orid [$Arrivals(display) get Orid] 
    return $orid
}

# dispatches all magnitude operations
proc magnitudes {args} { 
    global Arrivals Magnitude State Define
    set cmd [lindex $args 0]
    switch $cmd {
	Magnitudes	{ eval run_magnitudes [undone_magnitudes] }
	default { eval $args } 
    }
}

proc unset_key_entry {} {
    global Locate
    set Locate(key_entry) 0
}

proc run_locate {flag} {
    global Locate
    thinking "$Locate(location_program): trying to locate event..."
    if { ! [make_location_input $flag] } {
	send2dbloc $Locate(location_program)
    } else { 
	waiting
    }
}

proc fix_depth {} {
    global Locate
    set Locate(fix_depth) y
    run_locate 1
    set Locate(fix_depth) n
}

proc set_startloc_menu {} {
    global Db Locate
    set stations [lsort [arrivals stations]]
    $Locate(startmenu) delete 0 last
    foreach sta $stations { 
	$Locate(startmenu) add command \
	    -label $sta \
	    -command "start_at_sta $sta ; run_locate 0"
    }
    start_at_sta [lindex $stations 0] 
}

proc start_at_prefor {} { 
    global Db Tdb Locate
    if { $Locate(use_starting_location) == "n" } { 
	$Locate(use_starting_location_button) invoke
    }
    set Locate(key_entry) 0
    set orid [arrivals get Orid]
    if { $orid < 1 } { 
	return -1
    }
    set db [dblookup $Tdb 0 origin orid $orid]
    if { [lindex $db 3] < 0 } {
	return -1 
    }
    set evid [dbgetv $db 0 [lindex $db 3] evid]
    if { $evid < 1 } { 
	return -1
    }
    set dbevent [dblookup $Db 0 event evid $evid]
    if { [lindex $dbevent 3] < 0 } {
	return -1 
    }
    set prefor [dbgetv $dbevent 0 [lindex $dbevent 3] prefor]
    if { $prefor < 1 } { 
	return -1
    }

    set prefor2 prefor

    set db [dblookup $Tdb 0 origin orid $prefor]
    if { [lindex $db 3] < 0 } {
	return -1 
    }
    set Locate(origin_time) [dbgetv $db 0 [lindex $db 3] time]
    set Locate(latitude) [dbgetv $db 0 [lindex $db 3] lat]
    set Locate(longitude) [dbgetv $db 0 [lindex $db 3] lon]
    if { $Locate(fix_depth) != "y" } {
	set Locate(depth) [dbgetv $db 0 [lindex $db 3] depth]
    }
    return 0 
}

proc start_at_orid {orid} { 
    global Tdb Locate
    if { $Locate(use_starting_location) == "n" } { 
	$Locate(use_starting_location_button) invoke
    }
    set Locate(key_entry) 0
    set db [dblookup $Tdb 0 origin orid $orid]
    set Locate(origin_time) [dbgetv $db 0 [lindex $db 3] time]
    set Locate(latitude) [dbgetv $db 0 [lindex $db 3] lat]
    set Locate(longitude) [dbgetv $db 0 [lindex $db 3] lon]
    if { $Locate(fix_depth) != "y" } {
	set Locate(depth) [dbgetv $db 0 [lindex $db 3] depth]
    }
}

proc start_at_sta {sta} {
    global Db Locate User
    set db [dblookup $Db 0 site sta $sta]
    if { [lindex $db 3] >= 0 } { 
	set Locate(origin_time) 0
	set Locate(latitude) [dbgetv $db 0 [lindex $db 3] lat]
	set Locate(longitude) [dbgetv $db 0 [lindex $db 3] lon]
	set Locate(key_entry) 0
	if { $Locate(fix_depth) != "y" } {
	    set Locate(depth) $User(starting_depth)
	}
    }
}

proc make_location_input {flag} {
    global Locate State Define 

    set arids [arrivals get_arids_used]
    set evid -1
    set arrivals [arrivals reap]
    if { $flag && ! $Locate(key_entry) && $Locate(use_starting_location) } {
	if { [start_at_prefor] } { 
	    set sta [lindex $arrivals 1]
	    start_at_sta $sta
	}
    }
    if { [clength $arrivals] } {
	set Locate(first_arrival_time) [lindex $arrivals 3]
	set file [open $Locate(location_program).pf w]
	puts $file "output_file     $Locate(location_output)"
	puts $file "travel_time_model       $Locate(travel_time_model)"
	puts $file "maximum_iterations      $Locate(maximum_iterations)"
	puts $file "initial_latitude        $Locate(latitude)"
	puts $file "initial_longitude       $Locate(longitude)"
	puts $file "initial_depth           $Locate(depth)"
	puts $file "fix_depth       	    $Locate(fix_depth)"
	puts $file "author                  $Locate(author)"
	puts $file "arrival_table           &Tbl{"
	puts -nonewline $file $arrivals
	puts $file "}"
	set program $Locate(location_program)

	if { [catch ${program}_pf error] } {
	    errlog complain Locate "${program}_pf $error"
	} else {
	    puts $file $error
	}
	close $file
	return 0 
    } else { 
	errlog complain Locate "No arrivals to locate"
	return 1
    }
}

proc calculate_magnitudes {orid database} {
    global User Magnitude Define
    foreach program $User(magnitude_calculators) {
	if { $program != "" } {
	    set cmd "$program $database $orid"
	    # errlog report Magnitude ": $cmd"
	    puts stderr ": $cmd"
	    set logfile [file tail [lindex $program 0]].magnitude
	    if { [catch {eval exec $cmd >& $logfile} result] } { 
		errlog complain {$program} $result
	    }
	    # errlog report Magnitude ": $cmd finished"
	}
    }
    origins redisplay_origin $orid
}

proc run_magnitudes {orid} { 
    global User
    global Trial
    global Define
    global Magnitude
    global Tdb 
    global Locate
    set db [dblookup $Tdb 0 origin orid $orid]
    if { [lindex $db 3] >= 0 } { 
	set auth [dbgetv $db 0 [lindex $db 3] auth]
	set auth [lindex $auth 0]
	# errlog report Magnitude "auth=$auth Locate(author)=$Locate(author) direct=$User(allow_direct_magnitude_calculations)"
	if { $auth == $Locate(author) } { 
	    # errlog report Magnitude "calculate_magnitudes $orid $Trial #1"
	    calculate_magnitudes $orid $Trial
	} elseif { ! $User(allow_direct_magnitude_calculations) } {
	    errlog complain Magnitude "no magnitude calculated: allow_direct_magnitude_calculations is not in dbloc2.pf"
	} elseif { ! [lcontain $User(override_previous_magnitude_authors) $auth]} {
	    errlog complain Magnitude "no magnitude calculated: author $auth is not allowed to be recalculated in dbloc2.pf"
	} else { 
	    global Database
	    # errlog report Magnitude "calculate_magnitudes $orid $Database #2"
	    calculate_magnitudes $orid $Database
	}
    }
}

proc location_solution: {args} { 
    global located
    global Trial
    global User
    global Define
    set located 1 
    waiting
    switch -glob $args { 
    *new* { 
	errlog report Locate "found solution"
	set orid [lpop args]
	if { $User(run_magnitudes_automatically) } { 
	    run_magnitudes $orid
	}
	origins update
	origins show_residuals $orid
	}
    default { 
	regsub "no_solution :" $args "" args
	errlog complain Locate $args
	}
    }
}

proc set_model_options { w program } {
    global Locate
    $w configure -options $Locate($program)
}

proc run_locate_configure {} {
    global Locate
    set program $Locate(location_program)
    if { [catch "${program}_options" error] } {
	errlog complain locsat "no options for $program? $error"
    }
}

proc Use_starting_location {w} {
    global Locate Color
    set m $Locate(startmenu)
    set n [$m index end]
    if { $n == "none" } { set n 0 }
    if { $Locate(use_starting_location) } { 
	$w config -text "Starting location:" 
	loop i 0 $n { 
	    $m entryconfigure $i -state normal
	}

	foreach widget $Locate(location_widgets) { 
	    # catch {$widget config -state normal}
	    catch {$widget config -fg $Color(foreground)}
	    catch {$widget config -activeforeground $Color(activeForeground) }
	}
    } else { 
	$w config -text "program will estimate starting location" 
	loop i 0 $n { 
	    $m entryconfigure $i -state disabled
	}
	foreach widget $Locate(location_widgets) { 
	    # catch {$widget config -state disabled}
	    catch {$widget config -fg $Color(disabledForeground)}
	    catch {$widget config -activeforeground $Color(disabledForeground)}
	}

    }
}


# creates the configuration/control window for locate operation
proc create_locate_controls {} {
    global Locate State Define User
    set w .locate
    frame .locate

    set Locate(location_output) location_output
    set Locate(maximum_iterations) 40
    set Locate(origin_time) 0
    set Locate(latitude) 0.0
    set Locate(longitude) 0.0
    set Locate(depth) $User(starting_depth)
    set Locate(use_starting_location) n
    set Locate(fix_depth) n
    set Locate(author) $User(Institution):[id user]
    foreach i $User(location_programs) {
	set p [lindex $i 0] 
	set models [lrange $i 1 end]
	lappend programs $p
	set Locate($p) $models
    }
    set program [lindex $programs 0]
    set Locate(location_program) $program
    set Locate(travel_time_model) $Locate($program)

    button $w.configure \
	-padx 0 -pady 0 -borderwidth 1 -highlightthickness 0 \
	-text options \
	-command run_locate_configure
 
    global ::Color
    label $w.label \
	-text Locate \
	-background $Color(disabledForeground)

    scale $w.iterations \
	-label "Maximum Iterations" \
	-width 10 \
	-length 150 \
	-orient horizontal \
	-to 80 \
	-command "set Locate(maximum_iterations)" \
	-background $Color(background)
    $w.iterations set $Locate(maximum_iterations)

 
    checkbutton $w.initial_location \
	-variable Locate(use_starting_location) \
	-selectcolor $Color(disabledForeground) \
	-indicator 0 \
	-offvalue n \
	-onvalue y \
	-command "Use_starting_location $w.initial_location" 
    $w.initial_location select
    set Locate(use_starting_location_button) $w.initial_location

    menubutton $w.sta \
	-menu $w.sta.menu \
	-text "Station" \
	-relief raised \
	-padx 0 -pady 0 -borderwidth 1 -highlightthickness 0 
    menu $w.sta.menu -tearoff no
    set Locate(startmenu) $w.sta.menu
 
    label $w.l_latitude -text "Latitude" 
    entry $w.latitude \
	-textvariable Locate(latitude) \
	-width 8 \
	-relief ridge \
	-exportselection yes
    bind $w.latitude <Key> {set Locate(key_entry) 1}
 
    label $w.l_longitude -text Longitude 
    entry $w.longitude \
	-textvariable Locate(longitude) \
	-width 8 \
	-relief ridge \
	-exportselection yes
    bind $w.longitude <Key> {set Locate(key_entry) 1}

    set Locate(location_widgets) [concat $w.sta $w.sta.menu \
				 $w.l_longitude $w.longitude \
				 $w.l_latitude $w.latitude]
    Use_starting_location $w.initial_location

    menubutton $w.depth \
	-menu $w.depth.menu \
	-text Depth \
	-relief raised \
	-padx 0 -pady 0 -borderwidth 1 -highlightthickness 0 
    menu $w.depth.menu -tearoff no
 
    foreach depth $User(depth_list) {
        $w.depth.menu add command \
	    -label $depth \
	    -command "set Locate(depth) $depth ; run_locate 0 "
    }

    entry $w.depth_entry \
	-textvariable Locate(depth) \
	-width 5 \
	-relief ridge \
	-exportselection yes
 
    set hull [SelectorButton $w.model \
	-options $Locate($program) \
	-variable Locate(travel_time_model) ]
    set Locate(travel_time_model) [lindex $Locate($program) 0]
 
    SelectorButton $w.program \
	-options $programs \
	-command "set_model_options $hull" \
	-variable Locate(location_program)

    checkbutton $w.fixdepth \
	-variable Locate(fix_depth) \
	-text "Fix Depth" \
	-offvalue n \
	-onvalue y
 
    button $w.results \
	-padx 0 -pady 0 -borderwidth 1 -highlightthickness 0 \
	-text "View results" \
	-command "view_file -end $Locate(location_output)" 
 
    menubutton $w.magnitude_results \
	-menu $w.magnitude_results.menu \
	-padx 0 -pady 0 -borderwidth 1 -highlightthickness 0 \
	-text "View magnitude results" 
    menu $w.magnitude_results.menu -tearoff no
    foreach program $User(magnitude_calculators) {
	if {$program != ""} {
	    set logfile [lindex $program 0].magnitude
	    $w.magnitude_results.menu add command \
		-label $program \
		-command "view_file -end $logfile" 
	}
    }

    set col 0
    blt::table $w \
	$w.label	1,$col -fill both -rowspan 2 \
	$w.program	1,[incr col] \
	$w.configure    2,$col \
	$w.model	1,[incr col] \
	$w.sta 	        2,[incr col] \
	$w.initial_location 1,$col -columnspan 5 -fill x \
	$w.l_latitude 	2,[incr col] \
	$w.latitude 	2,[incr col] \
	$w.l_longitude 	2,[incr col] \
	$w.longitude 	2,[incr col] \
	$w.depth 	1,[incr col] \
	$w.depth_entry 	1,[incr col] \
	$w.fixdepth 	1,[incr col] \
	$w.iterations 	1,[incr col] -rowspan 2\
	$w.results 	1,[incr col] \
	$w.magnitude_results 	2,$col

    blt::table . \
	$w 14,0 -columnspan $Define(maxcol) -fill x
}


# $Id$ 

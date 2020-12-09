
# This file should contain all of the proc's which relate to the 
# "Associate" operation and windows

proc associate_button {parent} {
    global ::Associate
    set w [Buttonmenu $parent.#auto \
	-text Associate \
	-command associate \
	-menus "Controls large_residuals unusual_phases"
    ]
    lappend Associate(buttons) $w
    return $w
}

# dispatches all associate operations
proc associate {args} { 
    global ::Associate ::State ::Define

    set cmd [lindex $args 0]
    switch $cmd {
	init	{
		set Associate(buttons) ""
		create_associate_controls
		}
	summon	{summon .associate_controls }
	dismiss {dismiss .associate_controls }
	Controls {summon .associate_controls }
	large_residuals {
		set records [arrivals get_records_used] 
		if { [llength $records] } {
		    set evid -1
		    eval send2dbloc assoc $evid [expr 2*$State(P_residual_max)] [expr 2*$State(S_residual_max)] @[rules] $records
		    thinking "trying to associate with catalogs using large residuals..."
		} else {
		    errlog complain associate "No arrivals to associate"
		}
	    }

	unusual_phases {
		set records [arrivals get_records_used] 
		if { [llength $records] } {
		    set evid -1
		    set save $State(assoc_phases)
		    eval send2dbloc assoc $evid $State(P_residual_max) $State(S_residual_max) @[rules] $records
		    set State(assoc_phases) $save
		    thinking "trying to associate with catalogs using unusual phases..."
		} else {
		    errlog complain associate "No arrivals to associate"
		}
	    }

	Associate {
		set records [arrivals get_records_used] 
		if { [llength $records] } {
		    set evid -1
		    eval send2dbloc assoc $evid $State(P_residual_max) $State(S_residual_max) @[rules] $records
		    thinking "trying to associate with catalogs ..."
		} else {
		    errlog complain associate "No arrivals to associate"
		}
	    }

	default	{
		errlog complain associate "bad command '$args'"
	    }
    }
}

proc dbloc_assoc {n args} { 
    global ::associated
    set associated 1
    waiting
    if { $n > 0 } {
	errlog report associate "$n origins associated"
	origins update
    } else { 
	errlog report associate "no origins associated"
    }
}

proc rules {} {
    global ::State
    set rules ""
    if {$State(assoc_first) } {
	lappend rules first
    }
    if {$State(assoc_best) } {
	lappend rules best
    }
    lappend rules $State(assoc_phases)
    if {$State(assoc_all) } {
	lappend rules arids=all
    }
    return [join $rules ,]
}

# creates the configuration/control window for associate operation
proc create_associate_controls {} {
    global ::Associate ::State ::Define ::User
    set w .associate_controls
    dbloc_window $w

    label $w.l_presidual \
	-text "Maximum P Residual"
    entry $w.presidual \
	-textvariable State(P_residual_max) \
	-relief sunken \
	-width 5

    label $w.l_sresidual \
	-text "Maximum S Residual"
    entry $w.sresidual \
	-textvariable State(S_residual_max) \
	-relief sunken \
	-width 5

    checkbutton $w.first \
	-anchor w \
	-text "Keep only first qualifying phase for each arrival" \
	-variable State(assoc_first)

    checkbutton $w.best \
	-anchor w \
	-text "Show only best matching origin" \
	-variable State(assoc_best)

    checkbutton $w.all \
	-anchor w \
	-text "Require match to all arrivals" \
	-variable State(assoc_all)

    radiobutton $w.ps \
	-anchor w \
	-text "Standard P, S phases" \
	-variable State(assoc_phases) \
	-value PS

    radiobutton $w.p \
	-anchor w \
	-text "P phases only" \
	-variable State(assoc_phases) \
	-value P

    radiobutton $w.s \
	-anchor w \
	-text "S phases only" \
	-variable State(assoc_phases) \
	-value S

    radiobutton $w.ps+ \
	-anchor w \
	-text "All P, S phases" \
	-variable State(assoc_phases) \
	-value PS+

    blt::table $w \
	$w.l_presidual  1,0 -anchor w -fill x \
	$w.presidual  	1,1 -anchor w -fill x \
	$w.l_sresidual  2,0 -anchor w -fill x \
	$w.sresidual  	2,1 -anchor w -fill x \
	$w.first 	3,0 -anchor w -fill x -columnspan 2 \
	$w.best 	4,0 -anchor w -fill x -columnspan 2 \
	$w.all 		5,0 -anchor w -fill x -columnspan 2 \
	$w.ps 		1,2 -anchor w -fill x \
	$w.p 		2,2 -anchor w -fill x \
	$w.s 		3,2 -anchor w -fill x \
	$w.ps+ 		4,2 -anchor w -fill x 

    dismiss .associate_controls 
}

# $Id$ 

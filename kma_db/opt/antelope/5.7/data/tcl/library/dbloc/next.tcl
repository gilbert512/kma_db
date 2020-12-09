
# This file should contain all of the proc's which relate to the 
# "Next" operation and windows

# creates a next button for the buttonbar
proc next_button {parent} {
    global ::Next ::State ::Define
    set w [Buttonmenu $parent.#auto \
	-text Next \
	-command next 
    ]
    $w add checkbutton \
	-label "associate after next" \
	-variable State(auto_associate)
    $w add checkbutton \
	-label "locate after next" \
	-variable State(auto_locate)
    lappend Next(buttons) $w
    return $w
}

# dispatches all next operations
proc next {args} { 
    global ::Next 
    global ::State 
    global ::Define

    set cmd [lindex $args 0]
    switch $cmd {
	init	{
		set Next(buttons) ""
		create_next_top .next_top_controls
		}
	summon	{summon .next_controls}
	dismiss {dismiss next_controls}
	Controls {summon .next_controls}
	regroup { regroup }
	previous { prev_group }
	from_unassoc { from_unassoc }
	after_assoc { after_assoc } 
	group_from_arrival { group_from_arrival [lindex $args 1] }
	group_from { group_from [lindex $args 1] }
	Next	{
		waveforms new_event
		switch $State(next_default) {
		0	next_group
		}
	    }
	set_range { 
	    eval setup_next [lrange $args 1 end]
	}
	default		{ tkerror "bad message: next $args" }
    }
}

proc from_unassoc {} {
     global ::Tdb ::State
     foreach i [origins keepers] {
        set keep([dbgetv $Tdb origin $i orid]) 1
     }

     foreach i [arrivals get arrival_records] {
	set at [dbgetv $Tdb arrival $i arid time]
	set time([lindex $at 0]) [lindex $at 1]
     }

     set dbassoc [dblookup $Tdb 0 assoc 0 0]
     set nassoc [dbquery $dbassoc dbRECORD_COUNT]
     loop i 0 $nassoc {
	set arid [dbgetv $dbassoc 0 $i arid]
	if { $arid > 0 } {
	    set orid [dbgetv $dbassoc 0 $i orid]
	    if { [info exists keep($orid)] } { 
		set assoc($arid) 1
	    }
	}
     }

     set mintime [str2epoch $State(current_start_time)]
     foreach arid [array names time] {
	if { ! [info exists assoc($arid)] } {
	    set mintime [min $mintime $time($arid)]
	}
     }
     group_from $mintime
}

proc after_assoc {} {
     global ::Tdb ::State
     foreach i [origins keepers] {
        set keep([dbgetv $Tdb origin $i orid]) 1
     }

     foreach i [arrivals get arrival_records] {
	set at [dbgetv $Tdb arrival $i arid time]
	set time([lindex $at 0]) [lindex $at 1]
     }

     set dbassoc [dblookup $Tdb 0 assoc 0 0]
     set nassoc [dbquery $dbassoc dbRECORD_COUNT]
     set maxtime [str2epoch $State(current_start_time)]
     loop i 0 $nassoc {
	set arid [dbgetv $dbassoc 0 $i arid]
	if { $arid > 0 } {
	    set orid [dbgetv $dbassoc 0 $i orid]
	    if { [info exists keep($orid)] } { 
		set maxtime [max $time($arid) $maxtime]
	    }
	}
     }
     group_from [expr $maxtime+.01]
}

proc after_next {} {
# called by arrivals after the "records" command is executed
    global ::Next ::State ::Define
    locate set_startloc_menu 
    origins update
    waveforms update
    if { $State(auto_associate) } {
	associate Associate
    }
    if { $State(auto_locate) } {
	locate Locate
    }
    waiting
}

proc push_window_stack {strtime} {
    global ::State
    lappend State(time_window_stack) $strtime
}

proc group_from_arrival { record } { 
    global ::Db
    set time [expr [dbgetv $Db arrival $record time]-.1]
    group_from $time
}

proc group_from {time} {
    global ::Next ::State
    set strtime [strtime $time]
    group_arrivals_by_time $strtime
    push_window_stack $strtime
    set State(stack_pointer) [llength $State(time_window_stack)]
}


# finds next group of arrivals after current time window
proc next_group {} {
    global ::Next ::State
    group_arrivals_by_time $State(next_start_time) 
    push_window_stack $State(next_start_time)
    set State(stack_pointer) [llength $State(time_window_stack)]
}

proc prev_group {} {
    global ::Next ::State
    if { [llength $State(time_window_stack)] == $State(stack_pointer)} {
	set n [incr State(stack_pointer) -2]
    } else {
	set n [incr State(stack_pointer) -1]
    }
    if { $n < 0 } { 
	errlog complain next "no previous time grouping"
	incr State(stack_pointer)
	return
    }
    group_arrivals_by_time [lindex $State(time_window_stack) $n] 
}

proc group_from_listbox {args} {
    group_arrivals_by_time $args
}

proc group_arrivals_by_time {strtime} {
    global ::Next ::State ::Define
    if { [save Save] } {
	return
    }
    thinking "grouping from $strtime with window of $State(time_window)"
    origins forget
    arrivals forget
    send2dbloc group [str2epoch $strtime] $State(time_window) $State(unassociated)
}

proc regroup {} { 
    global ::State
    group_arrivals_by_time $State(current_start_time)
}

proc go_to {} { 
    global ::Db ::Next
    set id $Next(idtype)
    if { $Next(id) < 1 } { return } 
    set cmd {}
    switch $id {
	arid	{ 
	    set db [dblookup $Db 0 arrival 0 0]
	    set i [dbfind $db -1 0 arid==$Next(id)]
	}
	evid	{ 
	    set db [dblookup $Db 0 event 0 0]
	    set i [dbfind $db -1 0 evid==$Next(id)]
	    if { $i >= 0 } { 
		set orid [dbgetv $db 0 $i prefor]
		set db [dblookup $Db 0 origin 0 0]
		set i [dbfind $db -1 0 orid==$orid]
		set cmd "origins update ; origins show_residuals $orid"
	    }
	}
	orid	{ 
	    set db [dblookup $Db 0 origin 0 0]
	    set i [dbfind $db -1 0 orid==$Next(id)]
	    if { $i >= 0 } { 
		set orid $Next(id)
		set cmd "origins update ; origins show_residuals $orid"
	    }
	}
    }
    if { $i < 0 } { 
	errlog complain find "Can't find $id $Next(id)"
    } else {
	# set_next [dbgetv $db 0 $i time]
	group_from [dbgetv $db 0 $i time]
	global State
	set State(pending) $cmd
    }
}

proc set_time_window { w } { 
    global ::State
    set State(time_window) $w
}

proc fix_scroll_day { s } { 
    global ::Next
    set s [max $s 0]
    set s [min $s [expr $Next(day_range)-1]]
    set Next(day) $s
    set_scroll_day
    }

proc fix_scroll_minute { s } { 
    global ::Next
    set s [max $s 0]
    set s [min $s $Next(minute_range)]  
    set Next(minute) $s
    set_scroll_minute
    }

proc t2day {t} {
    global ::Next
    set x [int ($t-$Next(first_day))/(3600*24)]
    return $x 
    }

proc t2minute {t} {
    global ::Next
    set x [int ($t-$Next(first_day)-$Next(day)*3600*24)/60]
    return $x 
    }

proc set_next { x } {
    global ::State
    set s [strtime $x]
    set State(next_start_time) $s
}

proc set_next_from_scrolls {} { 
    global ::Next 
    set x [expr $Next(first_day) + $Next(day) * 3600 * 24 + $Next(minute) * 60 ]
    set_next $x
    }
 

proc set_scroll_day {} {
    global ::Next
    $Next(scroll_day) set $Next(day_range) 1 $Next(day) $Next(day)
    set_next_from_scrolls
    }

proc set_scroll_minute {} {
    global ::Next
    $Next(scroll_minute) set $Next(minute_range) 1 $Next(minute) $Next(minute)
    set_next_from_scrolls
    }
    
proc set_scrolls {args} {
	global ::State
	set epoch [str2epoch $State(next_start_time)]
	fix_scroll_day [t2day $epoch]
	fix_scroll_minute [t2minute $epoch]
    }

proc setup_next {min_time max_time group_min group_max } {
    global ::Next ::State
    set State(first_arrival) $min_time
    set State(last_arrival) $max_time
    set State(current_start_time) [strydtime [expr $group_min-.1]]
    set Next(first_day) [epoch [yearday $min_time]]
    set Next(first_date) [strdate $Next(first_day)]
    set Next(last_day) [epoch [yearday $max_time]]
    set Next(last_date) [strdate $Next(last_day)]
    set Next(day_range) [expr int(($Next(last_day) - $Next(first_day))/(24*3600) + 1)]
    set_scrolls
    set_next [expr $group_max+1]
}


proc create_next_top {w} {
    global ::Next ::State ::Define

    frame $w

    set Next(minute_range) [expr 24*60]
    set Next(first_day) 0
    set Next(first_date) ""
    set Next(last_day) 0
    set Next(last_date) ""
    set Next(day) 0
    set Next(minute) 0
    set Next(day_range) 1

# group by time_window
    label $w.next_start_time_label \
	-text "Next group from "

    entry $w.next_start_time \
	-textvariable State(next_start_time) \
	-relief sunken \
	-width 26

    # Time scroll bars
    scrollbar $w.sday \
        -orient horizontal \
        -command fix_scroll_day \
        -width 10
    label $w.day0 -textvariable Next(first_date) 
    label $w.day1 -textvariable Next(last_date) 

    set Next(scroll_day) $w.sday

    scrollbar $w.sminute \
        -orient horizontal \
        -command fix_scroll_minute \
        -width 10

    set Next(scroll_minute) $w.sminute

    setup_next $State(first_arrival) \
		$State(last_arrival) \
		[str2epoch $State(current_start_time)] \
		[expr [str2epoch $State(next_start_time)]-1]

    checkbutton $w.unassociated \
	-text "unassociated only" \
	-variable State(unassociated)

# Go to a particular id

    set Next(id) ""

    SelectorButton $w.go_to \
	-options {evid orid arid} \
	-variable Next(idtype) 
    $w.go_to choose orid

    label $w.evid_label \
	-text "#" 

    entry $w.evid_orid \
	-textvariable Next(id) \
	-relief sunken \
	-width 5
    bind $w.evid_orid <Return> go_to

    button $w.find \
	-padx 0 -pady 0 -borderwidth 1 -highlightthickness 0 \
	-text Find \
	-command go_to

    set f $w.fg
    frame $f

    button $f.next \
	-padx 2 -pady 0 -borderwidth 1 -highlightthickness 0 \
	-text Next \
	-command "next Next"
    button $f.from_unassoc \
	-padx 2 -pady 0 -borderwidth 1 -highlightthickness 0 \
	-text "From first unassoc" \
	-command from_unassoc
    button $f.after_assoc \
	-padx 2 -pady 0 -borderwidth 1 -highlightthickness 0 \
	-text "After last assoc" \
	-command after_assoc
    button $f.previous \
	-padx 2 -pady 0 -borderwidth 1 -highlightthickness 0 \
	-text Previous \
	-command "next previous"
    button $f.regroup \
	-padx 2 -pady 0 -borderwidth 1 -highlightthickness 0 \
	-text Regroup \
	-command "next regroup"

    pack $f.next $f.previous $f.regroup $f.from_unassoc $f.after_assoc -side left

    global ::Color
    label $w.time_window_label -text Time-window 
    scale $w.time_window \
        -width 10 \
        -length 200 \
        -sliderlength 8 \
        -orient horizontal \
        -to 2000 \
        -command set_time_window \
        -background $Color(background)
    $w.time_window set $State(time_window)

    blt::table $w \
	    $w.day0		     1,0 -anchor w \
	    $w.next_start_time_label 1,2 -anchor center \
	    $w.next_start_time	     1,3 -anchor center \
	    $w.unassociated	     1,4 -anchor e \
	    $w.day1		     1,24 -anchor e \
	    $w.sday		     2,0 -columnspan 25 -fill x \
	    $w.sminute	     	     3,0 -columnspan 25 -fill x \
	    $f			     5,0 -anchor w -columnspan 4 \
	    $w.time_window_label     5,4 -anchor w \
	    $w.time_window	     5,5 -anchor w -columnspan 3 \
	    $w.go_to 		     5,8 \
	    $w.evid_label  	     5,9 -anchor w \
	    $w.evid_orid   	     5,10 -anchor w \
	    $w.find 		     5,11 


    blt::table . \
	$w 	1,0 -columnspan $Define(maxcol) -fill x

}


# $Id$ 

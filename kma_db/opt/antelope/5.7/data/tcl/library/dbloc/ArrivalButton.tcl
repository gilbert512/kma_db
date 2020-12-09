package require Itcl
package require Itk
namespace import -force itcl::*
namespace import -force itk::*

bind ButtonMenu <2> { 
    tkButtonmenuDown %W
}

bind ButtonMenu <ButtonRelease-2> {
    tkButtonmenu2Up %W
}

proc tkButtonmenu2Up w {
    global ::tk::Priv
    set p [winfo parent $w]
    if {[string equal $w $::tk::Priv(buttonWindow)]} {
	set ::tk::Priv(buttonWindow) ""
	$w configure -relief $::tk::Priv(relief)
	if {[string equal $w $::tk::Priv(window)] \
		&& [string compare [$w cget -state] "disabled"]} {
	    uplevel #0 [list $p mouse_residuals]
	}
    }
}

class ArrivalButton {

    inherit Buttonmenu

    constructor {args} {
       global ::Arrival 
       global ::Slowness 
       global ::Azimuth 
       global ::Define

	set w $itk_interior
	set parent [winfo parent $w]
	# $w configure -highlightthickness 2

	eval itk_initialize $args

	set iphase [dbgetv $db 0 $record iphase]
	set azimuth [dbgetv $db 0 $record azimuth]
	set arid [dbgetv $db 0 $record arid]
	
	if { $azimuth > 0 } { 
	    set font Azimuth
	} else { 
	    set font Arid
	}

	$menu configure -disabledforeground blue -font Menu

	foreach i $Define(arrival_info) { 
	    set info [lindex [dbgetr $db $timeflag $record 1 $i] 0]
	    $menu add command -label "$i: $info" -state disabled
	}

	$menu add command \
	    -label "Show this waveform" \
	    -command "waveforms show_arrival $record"

	$menu add command \
	    -label "Assume source location" \
	    -command "arrivals set_source arid $arid"

	$menu add command \
	    -label "Show waveforms assuming this as source" \
	    -command "waveforms assume_source $record"

	$menu add command \
	    -label "Regroup from here" \
	    -command "next group_from_arrival $record"

	if { $azimuth < 0 } { 

	    $menu add radiobutton \
		-label "Use this arrival" \
		-variable Arrival($w) \
		-value 1 \
		-command "$this raise"
	    $menu add radiobutton \
		-label "Calculate residuals only" \
		-variable Arrival($w) \
		-value 0 \
		-command "$this sink"
	    $menu add radiobutton \
		-label "Ignore this arrival" \
		-variable Arrival($w) \
		-value -1 \
		-command "$this grayout"
	    set Arrival($w) 1

	} else {

	    $menu add command \
		-label "Use this arrival" \
		-command "$this use"
	    $menu add command \
		-label "Calculate residuals only" \
		-command "$this residuals"
	    $menu add command \
		-label "Ignore this arrival" \
		-command "$this ignore"


	    $menu add separator

	    $menu add radiobutton \
		-label Use \
		-variable Arrival($w) \
		-value 1
	    $menu add radiobutton \
		-label "Calculate residual only" \
		-variable Arrival($w) \
		-value 0
	    $menu add radiobutton \
		-label "Ignore this arrival time" \
		-variable Arrival($w) \
		-value -1
	    set Arrival($w) 1

	    $menu add command \
		-label Azimuth \
		-state disabled

	    foreach i $Define(azimuth_info) { 
		set info [lindex [dbgetr $db $timeflag $record 1 $i] 0]
		$menu add command -label "$i: $info" -state disabled
	    }

	    $menu add radiobutton \
		-label "Use this azimuth" \
		-variable Azimuth($w) \
		-value 1
	    $menu add radiobutton \
		-label "Calculate residual only" \
		-variable Azimuth($w) \
		-value 0
	    $menu add radiobutton \
		-label "Ignore this azimuth" \
		-variable Azimuth($w) \
		-value -1
	    set Azimuth($w) 1

	    set slow [dbgetv $db 0 $record slow]
	    if { $slow > 0 } { 
		$menu add command \
		    -label Slowness \
		    -state disabled

		foreach i $Define(slowness_info) { 
		    set info [lindex [dbgetr $db $timeflag $record 1 $i] 0]
		    $menu add command -label "$i: $info" -state disabled
		}
	    
		$menu add radiobutton \
		    -label "Use this slowness" \
		    -variable Slowness($w) \
		    -value 1
		$menu add radiobutton \
		    -label "Calculate residual only" \
		    -variable Slowness($w) \
		    -value 0
		$menu add radiobutton \
		    -label "Ignore this slowness" \
		    -variable Slowness($w) \
		    -value -1
		set Slowness($w) 1
	    }

	}
	add_menu_command arrival_menu_items $menu $db $record
	$this configure -text $iphase -command "$this cycle" -font $font
	$this adjust_look
	$menu configure -font Menu

	set relief [$itk_interior cget -relief]
	$itk_interior configure -relief raised
    }

    destructor {
	global ::Arrival
	global ::Slowness
	global ::Azimuth
	global ::Arrival_button
	catch "unset Arrival($w)"
	catch "unset Slowness($w)"
	catch "unset Azimuth($w)"
	catch "unset Arrival_button($id)"
    }

    method used {} {
	global ::Arrival
	return [expr $Arrival($w) >= 0] 
    }

    method change_phase {} { 
	set iphase [dbgetv $db 0 $record iphase]
	$this configure -text $iphase 
    }
    
    method update_measurements {} { 
       global ::Define
	set j 0
	foreach i $Define(arrival_info) { 
	    set info [lindex [dbgetr $db $timeflag $record 1 $i] 0]
	    $menu entryconfigure $j -label "$i: $info" 
	    incr j
	}
    }

    method reap {} { 
	global ::Arrival
	global ::Slowness
	global ::Azimuth
	if { $Arrival($w) < 0 } { return "" }
	set line [dbgetv $db 0 $record arid sta iphase time deltim ]
	set timedef [expr ($Arrival($w)==1)?"d":"n"]
	append line " " $timedef " "

	if { [info exists Azimuth($w)] } { 
	    set azdef [expr ($Azimuth($w)==1)?"d":"n"]
	} else { 
	    set azdef n
	}
	append line [dbgetv $db 0 $record azimuth delaz] " " $azdef " "

	if { [info exists Slowness($w)] } { 
	    set slodef [expr ($Slowness($w)==1)?"d":"n"]
	} else { 
	    set slodef n
	}
	append line [dbgetv $db 0 $record slow delslo] " " $slodef

	return "$line\n"
    }

    method config {config} {}

    method widget {} { return $w } 
    method menu {} { return $menu } 

    method mark_associated {} {
	$w configure -relief flat
    }

    method flag {} {
	$w configure -background red -activebackground red
    }

    method unflag {} {
	global ::Color
	$w configure -background $Color(background) -activebackground $Color(activeBackground)
    }

    method unmark {} {
	$w configure -relief raised
    }

    method raise {} { 
	global ::Define
	$w configure -foreground $Define(used_color) -activeforeground $Define(used_color)
    }

    method sink {} { 
	global ::Define
	$w configure -foreground $Define(partial_color) -activeforeground $Define(partial_color)
    }

    method grayout {} { 
	global ::Define
	$w configure -foreground $Define(ignored_color) -activeforeground $Define(ignored_color)
    }

    method cycle {args} {
       global ::Arrival 

	switch -- $Arrival($w) {
	    1  {$this ignore}
	    0	-
	    -1	{$this use}
	}
    }

    method use {} { 
       global ::Arrival 
       global ::Slowness 
       global ::Azimuth 
	set Arrival($w) 1
	if { [info exists Azimuth($w)] } { 
	    set Azimuth($w) 1
	}
	if { [info exists Slowness($w)] } { 
	    set Slowness($w) 1
	}
	$this adjust_look
    }

    method mouse_residuals {} { 
	global ::Arrival
	if { $Arrival($w) } { 
	    $this residuals
	} else { 
	    $this ignore 
	}
    }

    method residuals {} { 
       global ::Arrival 
       global ::Slowness 
       global ::Azimuth 
	set Arrival($w) 0
	if { [info exists Azimuth($w)] } { 
	    set Azimuth($w) 0
	}
	if { [info exists Slowness($w)] } { 
	    set Slowness($w) 0
	}
	$this adjust_look
    }

    method ignore {} { 
       global ::Arrival 
       global ::Slowness 
       global ::Azimuth 
	set Arrival($w) -1
	if { [info exists Azimuth($w)] } { 
	    set Azimuth($w) -1
	}
	if { [info exists Slowness($w)] } { 
	    set Slowness($w) -1
	}
	$this adjust_look
    }

    method adjust_look {} {
       global ::Arrival 
       global ::Slowness 
       global ::Azimuth 
	if { $Arrival($w) == -1
	    && ( [info exists Slowness($w)] ? ($Slowness($w) == -1) : 1)
	    && ( [info exists Azimuth($w)] ? ($Azimuth($w) == -1) : 1)
	    } { $this grayout 
	} elseif { $Arrival($w) <= 0
	    || ( [info exists Slowness($w)] && $Slowness($w) <= 0 )
	    || ( [info exists Azimuth($w)] && $Azimuth($w) <= 0 ) 
	    } { $this sink 
	} else { $this raise } 
    }

    method move_to {x y} {
	global ::Arrival_button
	set xpos $x
	set ypos $y
	if { [info exists id] && "$id" != "" } {
	    unset Arrival_button($id)  
	    $parent delete $id 
	}
	set id [$parent create window $xpos $ypos -window $w]
	set Arrival_button($id) $this
    }

    public variable record
    public variable db
    public variable ypos
    public variable xpos
    public variable timeflag 1
    public variable id 

    protected variable w
    public variable parent
    protected variable Deg2Rad 0.017453278

}


# $Id$ 

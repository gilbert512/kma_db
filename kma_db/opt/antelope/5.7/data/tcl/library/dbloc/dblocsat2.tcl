#!/bin/sh
# This comment extends to the next line for tcl \
exec dbwish $0 $*

proc dblocsat2_options {} {
    set w .dblocsat2

    if { [winfo exists $w] } { 
	wm deiconify $w
	blt::winop raise $w
	return
    } 

    toplevel $w
    wm title $w "Pf dblocsat2"
    wm iconname $w "Pf dblocsat2"
    global dblocsat2

    if { ! [info exists dblocsat2(Already-Initialized)] } {
	dblocsat2_default
    }


    scale $w.confidence_level \
	-label "Confidence level" \
	-from 0.00 -to 1.00 \
	-resolution 0.01 \
	-orient horizontal \
	-variable dblocsat2(confidence_level)


    scale $w.damping_factor \
	-label "Damping factor" \
	-from -3.0 -to 0.0 \
	-resolution 0.1 \
	-orient horizontal \
	-variable dblocsat2(damping_factor)


    scale $w.est_std_error \
	-label "Est std error" \
	-from 1.0 -to 5.0 \
	-resolution 0.1 \
	-orient horizontal \
	-variable dblocsat2(est_std_error)


    scale $w.degrees_of_freedom \
	-label "Degrees of freedom" \
	-from 1 -to 10 \
	-resolution 1 \
	-orient horizontal \
	-variable dblocsat2(degrees_of_freedom)


    global ::Color
    label $w.default_Uncertainty \
	-text "Default Uncertainty" \
	-bg $Color(disabledForeground) 

    scale $w.default_deltim \
	-label "arrival" \
	-from 0.00 -to 1.00 \
	-resolution 0.01 \
	-orient horizontal \
	-variable dblocsat2(default_deltim)


    scale $w.default_delaz \
	-label "azimuth" \
	-from 0.00 -to 20.00 \
	-resolution 0.01 \
	-orient horizontal \
	-variable dblocsat2(default_delaz)


    scale $w.default_delslo \
	-label "slowness" \
	-from 0.00 -to .1 \
	-resolution 0.01 \
	-orient horizontal \
	-variable dblocsat2(default_delslo)


    button $w.default -text Default -command "dblocsat2_default" 
    button $w.dismiss -text Dismiss -command "wm withdraw $w" -bg red -fg white

    set col 0
    set row 0
    blt::table $w \
	$w.confidence_level [incr row],$col -fill x -anchor w \
	$w.damping_factor [incr row],$col -fill x -anchor w \
	$w.est_std_error [incr row],$col -fill x -anchor w \
	$w.degrees_of_freedom [incr row],$col -fill x -anchor w \
	$w.default_Uncertainty [incr row],$col -fill x -anchor w \
	$w.default_deltim [incr row],$col -fill x -anchor w \
	$w.default_delaz [incr row],$col -fill x -anchor w \
	$w.default_delslo [incr row],$col -fill x -anchor w \
	$w.default	20,0 -fill x \
	$w.dismiss	20,1 -cspan 10 -fill x

}

proc dblocsat2_pf {} {
    global dblocsat2


    if { ! [info exists dblocsat2(Already-Initialized)] } {
	dblocsat2_default
    }
    global Locate
    if { $Locate(use_starting_location) } {
	append pf "use_starting_location	y\n"
    } else { 
	append pf "use_starting_location	n\n"
    }

    append pf "confidence_level	$dblocsat2(confidence_level)\n"
    append pf "damping_factor	$dblocsat2(damping_factor)\n"
    append pf "est_std_error	$dblocsat2(est_std_error)\n"
    append pf "degrees_of_freedom	$dblocsat2(degrees_of_freedom)\n"
    append pf "default_deltim	$dblocsat2(default_deltim)\n"
    append pf "default_delaz	$dblocsat2(default_delaz)\n"
    append pf "default_delslo	$dblocsat2(default_delslo)\n"
    append pf "verbose y	y\n"

    return $pf
}

proc dblocsat2_default {} {
    global dblocsat2

    set dblocsat2(confidence_level) 0.9
    set dblocsat2(damping_factor) -1.0
    set dblocsat2(est_std_error) 2.4
    set dblocsat2(degrees_of_freedom) 8
    set dblocsat2(default_deltim) 0.1
    set dblocsat2(default_delaz) 10.0
    set dblocsat2(default_delslo) 0.01
    set dblocsat2(Already-Initialized) 1

}

# $Id$ 

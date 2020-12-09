#!/bin/sh
# This comment extends to the next line for tcl \
exec dbwish $0 $*

proc dbgrassoc2_options {} {
    set w .dbgrassoc2

    if { [winfo exists $w] } { 
	wm deiconify $w
	blt::winop raise $w
	return
    } 

    toplevel $w
    wm title $w "Pf dbgrassoc2"
    wm iconname $w "Pf dbgrassoc2"
    global dbgrassoc2

    if { ! [info exists dbgrassoc2(Already-Initialized)] } {
	dbgrassoc2_default
    }

    message $w.msg -text "No options currently" 
    button $w.default -text Default -command "dbgrassoc2_default" 
    button $w.dismiss -text Dismiss -command "wm withdraw $w" -bg red -fg white

    set col 0
    set row 0
    blt::table $w \
	$w.msg		19,0 -fill x \
	$w.dismiss	20,1 -cspan 10 -fill x

}

proc dbgrassoc2_pf {} {
    global dbgrassoc2
    if { ! [info exists dbgrassoc2(Already-Initialized)] } {
	dbgrassoc2_default
    }
    set pf {}
    return $pf
}

proc dbgrassoc2_default {} {
    global dbgrassoc2
}

# $Id$ 

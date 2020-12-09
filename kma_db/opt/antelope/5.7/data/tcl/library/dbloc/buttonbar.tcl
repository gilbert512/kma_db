
# This should put the standard button bar along the bottom

proc buttonbar w {
    global Define

    frame $w
    set parent [winfo parent $w]
    blt::table $parent \
	$w $Define(button_row),0 -columnspan $Define(maxcol) -anchor w -fill x

    listbox $w.error  \
	-relief ridge \
	-yscroll "$w.escroll set" \
	-width 50 \
	-height 1
    scrollbar $w.escroll -command "$w.error yview"
    errlog configure -window $w.error

    # button $w.quit \
	-text Quit \
	-command quit \
	-fg white \
	-bg red \
	-activebackground red
	
    set col 0
    blt::table $w \
	$w.error		    0,0 -columnspan $Define(maxcol) -anchor w -fill x \
	$w.escroll		    0,$Define(maxcol) -fill y \
	\
	[next_button $w] 	    1,$col       -anchor center -fill x \
	[locate_button $w]          1,[incr col] -anchor center -fill x 
    global User
    if { [info exists User(run_magnitudes_automatically) ] && $User(run_magnitudes_automatically) != "yes" } { 
	set User(run_magnitudes_automatically) no
	blt::table $w \
	    [magnitude_button $w]	    1,[incr col] -anchor center -fill x 
    } else { 
	set User(run_magnitudes_automatically) yes
    }
    blt::table $w \
	[associate_button $w]       1,[incr col] -anchor center -fill x \
	[save_button $w] 	    1,[incr col] -anchor center -fill x \
	[waveforms_button $w]       1,[incr col] -anchor center -fill x \
	[map_button $w] 	    1,[incr col] -anchor center -fill x \
	[database_button $w]        1,[incr col] -anchor center -fill x \
	[sendforwarn_button $w]     1,[incr col] -anchor center -fill x 
	# $w.quit		    1,$Define(maxcol) -anchor center -fill x

}

# $Id$ 

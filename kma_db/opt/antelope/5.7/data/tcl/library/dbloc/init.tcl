
proc dbloc_init {} {
    global Define Trial

    old_tk
    option add *Menubutton.Pad 0
    option add *Menubutton.Padx 0
    option add *Menubutton.Pady 0
    option add *Menubutton.BorderWidth 0

    discover_colors
    error_reporter errlog 
    errlog configure -log $Define(Work_dir)/logger
    errlog commence

    if { ! [catch "glob $Trial.*" old] } { 
	foreach file $old { 
	    ftruncate $file 0
	}
    }

    next init
    origins init
    locate init
    associate init
    save init

    arrivals init
    waveforms init
    map init
    database init

    global ::State
    next group_from [str2epoch $State(current_start_time)]
}

proc discover_colors {} { 
# The only way to find the default colors is to make up widget and ask it.

    menubutton .mb

    global Color 
    set Color(foreground) [lindex [.mb config -foreground] 4]
    set Color(background) [lindex [.mb config -background] 4]
    set Color(activeBackground) [lindex [.mb config -activebackground] 4]
    set Color(disabledForeground) [lindex [.mb config -disabledforeground] 4]
    destroy .mb

}
# $Id$ 

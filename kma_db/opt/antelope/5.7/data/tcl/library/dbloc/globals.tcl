
#  This is the forlorn attempt to declare all the globals 
#  in one central file, in hopes of not being overwhelmed with them.
#
#  The need for global variables is the biggest problem in tcl/tk.

proc global_setup {} {

    global ::argv ::argv0 ::argc 
    global ::Database ::Db

    if { $argc == 3 && [lindex $argv 0] == "-p" } { 
	set Pfname [lindex $argv 1]
	set Database [lindex $argv 2]
    } elseif { $argc == 1 } {
	set Pfname dbloc2
	set Database [lindex $argv 0]
    } else {
	puts stderr "Usage: $argv0 \[-p pf\] database"  
	exit 1
    }

    set Db [dbopen $Database r+]

    global ::Program 		# application name
    set Program dbloc2 

    global ::Version 		# version code
    set Version 1.1

    global ::Date 		# version date
    set Date "\$Date$"
    regsub -all \\$ $Date "" Date
    regsub "Date: " $Date "" Date

    global ::tcl_precision
    set tcl_precision 17

# initialize all other global variables
    global ::Pf 			# array for parameters 
    global ::Define ::Statefile

    pfload Pf $Pfname
    if { $Pfname != "dbloc2.pf" } { 
	puts stderr "using parameter file $Pfname"
    }

    set Define(Width) [winfo screenwidth .]
    set Define(Height) [winfo screenheight .]

    if { ! [info exists Define(vertical_span)] } { 
	set Define(vertical_span) .9
    }
    if { ! [info exists Define(horizontal_span)] } { 
	set Define(horizontal_span) .9
    }

    if { ! [info exists Define(vertical_max)] } { 
	set Define(vertical_max) 100000
    }
    if { ! [info exists Define(horizontal_max)] } { 
	set Define(horizontal_max) 100000
    }

    set height [expr int($Define(Height) * $Define(vertical_span))] 
    # puts stderr "height is $height Define(height) = $Define(Height) span=$Define(vertical_span)"
    if { $height > $Define(vertical_max) } {
	set height $Define(vertical_max)
    }

    pfgetarr fonts [pfget $Pfname fonts]
    foreach font [array names fonts] {
        eval font create $font $fonts($font)
    }
    option add *Font Plain
    option add Menu*Font Menu

    set Define(arrivals_height) [expr int(.5*$height)]
    set Define(origins_height) [expr int(.2*$height)]

    set width [expr int($Define(Width) * $Define(horizontal_span))]
    # puts stderr "width is $width Define(width) = $Define(Width) span=$Define(horizontal_span)"
    if { $width > $Define(horizontal_max) } {
	set width $Define(horizontal_max)
    }
    set Define(origins_width) $width
    set Define(arrivals_width) $width

    set Statefile $Define(Work_dir)/state.pf
    load_state

    global ::Tdb ::Trial
    set Trial $Define(Work_dir)/$Define(Temporary_db)
    set Tdb [dbopen $Trial r+]
    }


# $Id$ 

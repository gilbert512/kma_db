
# What are some of the things that would be nice in an error reporting facility?
#  a history
#  the ability to place the error in multiple locations
#  the ability to bring up a new toplevel window/dialog
package require Itcl
package require Itk
namespace import -force itcl::*
namespace import -force itk::*

class error_reporter {
# this should serve as a central error reporter

    constructor {args} {
	eval configure $args
    }

    method widget {} { return $w } 

    method commence {} { 
	set message "\n\n[strtime [clock seconds]] dbloc commencing"    
	foreach i $logs {
	    set LOG [open $i a+]
	    puts $LOG $message
	    close $LOG
	}
    }

    method report {src msg} {
	set message "[strtime [clock seconds]] $src: $msg"    
	foreach i $logs {
	    set LOG [open $i a+]
	    puts $LOG $message
	    close $LOG
	}
	foreach w $windows {
	    set n [$w size]
	    if { $n > $retain } { 
		$w delete 0 [expr $retain-$n]
	    }
	    $w insert end "$src: $msg"
	    $w yview end
	}
    }

    method complain {src msg} {
	$this report $src $msg
	update
	if { $audible_bell } { bell } 
	if { $visual_bell } {
	    foreach w $windows {
		$w configure -bg red
	    }
	    update
	    after 1000
	    global ::Color
	    foreach w $windows {
		$w configure -bg $Color(background)
	    }
	}

    }

    method clear {} {
        foreach w $windows {
            $w configure -text ""
        }
    }

    method dialog {title src msg args} {
	report $src $msg
	return [eval tkdialog [unique_window .] \"$title\" \"$msg\" $args]
    }

    method add_log { w } {
	lappend logs $w
	set logs [lrmdups $logs]
    }

    method delete_log {w} {
	ldelete logs $w
    }

    method add_window { w } {
	lappend windows $w
	set windows [lrmdups $windows]
    }

    method delete_window {w} {
	ldelete windows $w
    }

    method view_log {} {
	if { $logs != "" } {
	    view_file -end [lindex $logs 0]
	} else {
	    $this complain logger "No log file to display"
	}
    }

    public variable log {} { 
	$this add_log $log
	set log ""
    }

    public variable window {} { 
	$this add_window $window
	set window ""
    }

    public variable audible_bell 1
    public variable visual_bell 1
    public variable retain 25

    common logs {} 
    common windows {}
}

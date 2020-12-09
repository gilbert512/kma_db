package require Itcl
package require Itk
namespace import -force itcl::*
namespace import -force itk::*

class ResultButton {
    inherit itk::Widget

    constructor {args} {
	global ::State ::Result

	itk_component add cb { 
	    button $itk_interior.cb \
        	-padx 0 -pady 0 -borderwidth 0 -highlightthickness 0
	}

        eval itk_initialize $args

	if { [lsearch -exact $State(old_orids) $orid] >= 0 } {
	    $itk_component(cb) config \
		-textvariable Result($record) \
		-width 7 \
		-command "$this toggle"
	    $this result
	} else {
	    $itk_component(cb) config \
		-textvariable Result($record) \
		-width 7 \
		-command "$this toggle"
	    $this no
	}
	pack $itk_component(cb)
    }

    public method toggle {} {
	global ::Result
	switch $Result($record) {
	    Send	{ $this no }
	    No	{ $this result }
#	    Reassoc     { $this chop } 
#	    Chop        { $this result } 
#	    Save	{ $this drop }
#	    Drop	{ $this save }
	}
    }

#    public method chop {} {
#	global ::Result ::State
#	global ::Color
#	set Result($record) Chop
#	$itk_component(cb) config -background $Color(disabledForeground) \
#	    -activebackground $Color(disabledForeground) 
#    }
#
#    public method reassoc {} {
#	global ::Result ::State
#	global ::Color
#	set Result($record) Reassoc
#	$itk_component(cb) config -background $Color(disabledForeground) \
#	    -activebackground $Color(disabledForeground) 
#    }

    public method retain {} {
	global ::Result ::State
	global ::Color

	if { "$Result($record)" == "No" } { 
	    $this result
	} elseif { "$Result($record)" == "Send" } { 
	    $this no
	}
    }

    public method result {} {
	global ::Result ::State
	global ::Color

	set Result($record) Send
	$itk_component(cb) config -background $Color(background) \
	    -activebackground $Color(activeBackground) 
    }

#    public method save {} {
#	global ::Result ::State
#	global ::Color
#
#	set Result($record) Save
#	$itk_component(cb) config -background $Color(disabledForeground) \
##		-activebackground $Color(disabledForeground) 
#    }

    public method no {} {
	global ::Result 
	global ::State 
	global ::Prefor
	global ::Prefor2
	global ::Color

	set Result($record) No

	$itk_component(cb) config -background $Color(disabledForeground) \
	    -activebackground $Color(disabledForeground) 

	if { [info exists Prefor2($evid)] && $Prefor2($evid) == $orid } { 
	    set Prefor2($evid) -1
	}
    }

#    public method drop {} {
#	global ::Result 
#	global ::State 
#	global ::Prefor
#	global ::Color
#
#	set Result($record) Drop
#	$itk_component(cb) config -background $Color(background) \
#	    -activebackground $Color(activeBackground) 
#	if { [info exists Prefor($evid)] && $Prefor($evid) == $orid } { 
#	    set Prefor($evid) -1
#	}
#    }

    public variable record
    public variable orid
    public variable evid

}


# $Id$ 

package require Itcl
package require Itk
namespace import -force itcl::*
namespace import -force itk::*

class KeepButton {
    inherit itk::Widget

    constructor {args} {
	global ::State ::Keep

	itk_component add cb { 
	    button $itk_interior.cb \
        	-padx 0 -pady 0 -borderwidth 0 -highlightthickness 0
	}

        eval itk_initialize $args

	if { [lsearch -exact $State(old_orids) $orid] >= 0 } {
	    $itk_component(cb) config \
		-textvariable Keep($record) \
		-width 7 \
		-command "$this toggle"
	    $this keep
	} else {
	    $itk_component(cb) config \
		-textvariable Keep($record) \
		-width 7 \
		-command "$this toggle"
	    $this drop
	}
	pack $itk_component(cb)
    }

    public method toggle {} {
	global ::Keep
	switch $Keep($record) {
	    Keep	{ $this delete }
	    Delete	{ $this reassoc }
	    Reassoc     { $this chop } 
	    Chop        { $this keep } 
	    Save	{ $this drop }
	    Drop	{ $this save }
	}
    }

    public method chop {} {
	global ::Keep ::State
	global ::Color
	set Keep($record) Chop
	$itk_component(cb) config -background $Color(disabledForeground) \
	    -activebackground $Color(disabledForeground) 
    }

    public method reassoc {} {
	global ::Keep ::State
	global ::Color
	set Keep($record) Reassoc
	$itk_component(cb) config -background $Color(disabledForeground) \
	    -activebackground $Color(disabledForeground) 
    }

    public method retain {} {
	global ::Keep ::State
	global ::Color

	if { "$Keep($record)" == "Delete" } { 
	    $this keep
	    # set Keep($record) Keep
	} elseif { "$Keep($record)" == "Drop" } { 
	    $this save
	    # set Keep($record) Save
	}
    }

    public method keep {} {
	global ::Keep ::State
	global ::Color

	set Keep($record) Keep
	$itk_component(cb) config -background $Color(background) \
	    -activebackground $Color(activeBackground) 
    }

    public method save {} {
	global ::Keep ::State
	global ::Color

	set Keep($record) Save
	$itk_component(cb) config -background $Color(disabledForeground) \
		-activebackground $Color(disabledForeground) 
    }

    public method delete {} {
	global ::Keep 
	global ::State 
	global ::Prefor
	global ::Color

	set Keep($record) Delete
	$itk_component(cb) config -background $Color(disabledForeground) \
	    -activebackground $Color(disabledForeground) 

	if { [info exists Prefor($evid)] && $Prefor($evid) == $orid } { 
	    set Prefor($evid) -1
	}
    }

    public method drop {} {
	global ::Keep 
	global ::State 
	global ::Prefor
	global ::Color

	set Keep($record) Drop
	$itk_component(cb) config -background $Color(background) \
	    -activebackground $Color(activeBackground) 
	if { [info exists Prefor($evid)] && $Prefor($evid) == $orid } { 
	    set Prefor($evid) -1
	}
    }

    public variable record
    public variable orid
    public variable evid

}


# $Id$ 

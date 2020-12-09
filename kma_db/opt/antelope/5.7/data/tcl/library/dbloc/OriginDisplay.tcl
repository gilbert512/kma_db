package require Itcl
package require Itk
package require BLT

namespace import -force itcl::*
namespace import -force itk::*

#  This widget should display a set of origins
option add *ScrolledBlt.height	  400 widgetDefault
option add *ScrolledBlt.width	  600 widgetDefault
option add *ScrolledBlt.scrollregion {0 0 1000 200} widgetDefault

proc option_menu {w var command options} {
    regsub \\(.*\\) $var {} g
    global $g
    menubutton $w -textvariable $var -menu $w.m \
	-padx 0 -pady 0 -borderwidth 0 -highlightthickness 0
    menu $w.m
    foreach option $options { 
	$w.m add command -label $option -command "$command $var $option"
    }
    set default [lindex $options 0]
    eval set $var $default
    return $w
}


class ScrolledBlt {
    inherit itk::Widget

    constructor {args} {

	global ::Color

	itk_component add bar {
	    frame $itk_interior.bar
	}

	itk_component add label { 
	    label $itk_interior.bar.label \
		-text Origins: \
		-width 20 \
		-bg $Color(disabledForeground)
	}

	global ::Origins

	itk_component add reviewed { 
	    radiobutton $itk_interior.bar.reviewed \
		-padx 5 -pady 0 -borderwidth 2 -highlightthickness 0 \
		-text "Mark reviewed  " \
		-variable Origins(reviewed) \
		-value 1 \
		-bg $Color(disabledForeground)
	}

	itk_component add asis { 
	    radiobutton $itk_interior.bar.asis \
		-padx 5 -pady 0 -borderwidth 2 -highlightthickness 0 \
		-text "Leave as-is  " \
		-variable Origins(reviewed) \
		-value 2 \
		-bg $Color(disabledForeground)
	}

	itk_component add notReviewed { 
	    radiobutton $itk_interior.bar.notReviewed \
		-padx 5 -pady 0 -borderwidth 2 -highlightthickness 0 \
		-text "Mark NOT reviewed  " \
		-variable Origins(reviewed) \
		-value 3 \
		-bg $Color(disabledForeground)
	}
	set Origins(reviewed) 1

	itk_component add filler { 
	    label $itk_interior.bar.filler \
		-text " " \
		-bg $Color(disabledForeground)
	}


	pack $itk_interior.bar.label $itk_interior.bar.reviewed $itk_interior.bar.asis $itk_interior.bar.notReviewed -side left -fill x
	pack $itk_interior.bar.filler -side left -expand yes -fill x 

	itk_component add vertical_scrollbar { 
	    scrollbar $itk_interior.sv \
		-command "$itk_interior.c yview" \
		-width 10 \
		-relief sunken
	}

	itk_component add horizontal_scrollbar { 
	    scrollbar $itk_interior.sh \
		-orient horizontal \
		-command "$itk_interior.c xview" \
		-width 10 \
		-relief sunken
	}

	itk_component add canvas { 
	    canvas $itk_interior.c \
		-height 400 \
		-width  600 \
		-xscrollcommand "$itk_interior.sh set" \
		-yscrollcommand "$itk_interior.sv set" 
	} {
	    keep -width -height 
	}

	pack $itk_interior.bar -side top -fill x
	pack $itk_interior.sh -side bottom -fill x
	pack $itk_interior.sv -side right -fill y
	pack $itk_interior.c -expand yes -fill both 

	itk_component add spreadsheet { 
	    frame $itk_interior.c.f 
	}

	$itk_component(canvas) create window 0 0 -window $itk_component(spreadsheet) -anchor nw
	eval itk_initialize $args
    }

    method create { type row col args } {
	set child [unique_window $itk_component(spreadsheet)]
	eval $type $child $args
	eval blt::table $itk_component(spreadsheet) $child $row,$col -fill x -anchor nw
	return $child
    }

    method clear {} {
	foreach i [winfo children $itk_component(spreadsheet)] {
	    destroy $i
	}
    }

}

proc set_etype {var newvalue} { 
    global Etype
    set db $Etype(db)
    regsub .*\\( $var {} record
    regsub \\) $record {} record
    set original [dbgetv $db 0 $record etype]
    if { "$newvalue" != "Unset" && "$newvalue" != "$original" } { 
	dbputv $db 0 $record etype $newvalue
	eval set $var $newvalue
	set orid [dbgetv $db 0 $record orid]
	global State
	if { [lsearch -exact $State(old_orids) $orid] >= 0 } {
	    global Db
	    set db2 [dblookup $Db 0 origin orid $orid]
	    if { [lindex $db2 3] >= 0 } { 
		set lddate [dbgetv $db2 0 [lindex $db2 3] lddate]
		dbputv $db2 0 [lindex $db2 3] etype $newvalue lddate $lddate
	    }
	}
    } else { 
	eval set $var $original
    }
}

class OriginDisplay {
    inherit ScrolledBlt

    constructor {args} {
	for {set i 0} {$i < [llength $args]} { incr i} { 
	    set name [lindex $args $i]
	    incr i 
	    set value [lindex $args $i]
	    itk_initialize $name $value
	}
    }

    method clear {} {
	global ::Keep
	catch "unset Keep"
	global ::Prefor
	catch "unset Prefor"
	global ::Prefor2
        catch "unset Prefor2"

	ScrolledBlt::clear

	catch "unset Row"
	catch "unset Mb"
	catch "unset Widget"
	catch "unset Column"
	set last_record 0
	set row 0 
	set column 1
	$this create label $row $column -text orid -font LabelFixed
	set Column(orid) $column
	incr column
	$this create label $row $column -text Keep -font LabelFixed
	set Column(keep) $column
	incr column
	$this create label $row $column -text Prefor -font LabelFixed
	set Column(prefor) $column
	incr column
	$this create label $row $column -text Etype -font LabelFixed
	set Column(etype) $column
	incr column
	foreach i $display {
	    $this create label $row $column -text $i  -font LabelFixed
	    set Column($i) $column
	    incr column
	}
# Ryoo	
	$this create label $row $column -text Sending -font LabelFixed
        set Column(prefor2) $column

	set highlighted ""
	set flagged ""
    }

    method savers {} {
	global ::Keep
	set savers ""
	if { [info exists Keep] } { 
	    foreach i [array names Keep] {
		if { $Keep($i) == "Save" } {
		    lappend savers $i 
		    }
	    }
	}
	return $savers
    }

    method keepers {} {
	global ::Keep
	set keepers ""
	if { [info exists Keep] } { 
	    foreach i [array names Keep] {
		if { $Keep($i) == "Save" 
		    || $Keep($i) == "Chop" 
		    || $Keep($i) == "Reassoc" 
		    || $Keep($i) == "Keep" } { 
		    lappend keepers $i 
		    }
	    }
	}
	return $keepers
    }

    method recalcs {} {
	global ::Keep
	set recalcs ""
	if { [info exists Keep] } { 
	    foreach i [array names Keep] {
		if { $Keep($i) == "Chop" } { 
		    lappend recalcs [dbgetv $dborigin 0 $i orid]
		}
	    }
	}
	return $recalcs
    }

    method reassoc_records {} {
	global ::Keep
	set reassoc_records ""
	if { [info exists Keep] } { 
	    foreach i [array names Keep] {
		if { $Keep($i) == "Reassoc" } { 
		    lappend reassoc_records $i
		}
	    }
	}
	return $reassoc_records
    }

    method reassocs {} {
	global ::Keep
	set reassocs ""
	if { [info exists Keep] } { 
	    foreach i [array names Keep] {
		if { $Keep($i) == "Reassoc" } { 
		    lappend reassocs [dbgetv $dborigin 0 $i orid]
		}
	    }
	}
	return $reassocs
    }

    method deletions {} {
	global ::Keep
	set deletions ""
	if { [info exists Keep] } { 
	    foreach i [array names Keep] {
		if { $Keep($i) == "Delete" } { 
		    lappend deletions [dbgetv $dborigin 0 $i orid]
		    }
	    }
	}
	return $deletions
    }

# This should remove a particular row and orid from the display
    method remove { record row orid } {
	global ::Keep ::Trial
	if { $Keep($record) == "Save" } {
	    errlog complain origins "Origin $orid is marked to be kept"
	} else {
	    unset Keep($record)
	    loop i 1 $max_column { 
		blt::table forget $Widget($row,$i)
	    }
	    send2dbloc bkg dbloc_delorids $Trial $orid
	    arrivals config -Orid -1
	}
	after 2000 show_conflicting_events
    }

    method prefor {evid} {
	return $prefor($evid)
    }

    method prefor2 {evid} {
        return $prefor2($evid)
    }

    method set_old_evid {orid evid} {
	global Db
	set db [dblookup $Db 0 origin orid $orid]
	set record [lindex $db 3]
	if {$record >= 0} { 
	    set old_evid [dbgetv $db $record evid]
	    if { [catch {dbputv $db $record evid $evid} error] } {
		errlog complain origins "Failed writing new evid $evid to origin $orid row: $error"
	    } else {
		set db [dblookup $Db 0 event evid $old_evid]
		set record [lindex $db 3]
		if {$record >= 0} { 
		    set old_prefor [dbgetv $db $record prefor]
		    if { $prefor == $orid } {
			if { [catch {dbputv $db $record prefor -1} error] } {
			    errlog complain origins "Failed writing new evid $evid to origin $orid row: $error"
			}
		    }
		} else { 
		    errlog complain origins "Can't find event $evid in original database"
		}
	    }

	} else { 
	    errlog complain origins "Can't find origin $orid in original database"
	}

    }

    method set_netmag_evid { orid evid } { 
	# errlog report set_netmag_evid "set_netmag_evid orid=$orid evid=$evid"
	set n [dbquery $dbnetmag dbRECORD_COUNT] 
	# errlog report set_netmag_evid "$n records in netmag table"
	loop i 0 $n { 
	    # set dbnetmag [lreplace $dbnetmag 3 3 $i]
	    set this_orid [dbgetv $dbnetmag 0 $i orid]
	    if { $orid == $this_orid } { 
		if { [catch { dbputv $dbnetmag 0 $i evid $evid } error] } {
		    errlog complain set_netmag_evid "Failed writing new evid $evid to netmag record $i for orid $orid row: $error"
		}
	    }
	}
	# errlog report set_netmag_evid "leaving set_netmag_evid"
    }

    method set_evid {record orid evid} {
	global ::Prefor
	global ::Prefor2
	global Db
	global State
	if { $evid == 0 } {
	    set evid [dbnextid $Db evid]
	}
	dbputv $dborigin 0 $record evid $evid
	set_netmag_evid $orid $evid
	# errlog report set_evid "orid=$orid evid=$evid Row(\$orid)=$Row($orid)   Column(evid)=$Column(evid)"
	if { $evid == -1 } {
	    $Widget($Row($orid),$Column(evid)) config -text ""
	} else {
	    $Widget($Row($orid),$Column(evid)) config -text $evid
	}
	$Widget($Row($orid),$Column(prefor)) config -variable Prefor($evid) 
	if { [info exists Prefor(-1)] && $Prefor(-1) == $orid } { 
	    set Prefor($evid) $orid 
	}
#ryoo
	$Widget($Row($orid),$Column(prefor2)) config -variable Prefor2($evid) 
	if { [info exists Prefor2(-1)] && $Prefor2(-1) == $orid } {
            set Prefor2($evid) $orid
        }

	if { [lsearch -exact $State(old_orids) $orid] >= 0 } {
	    set_old_evid $orid $evid
	}
	# errlog report set_evid "calling show_conflicting_events"
	show_conflicting_events 
	# errlog report set_evid "returned from show_conflicting_events"
    }

    method lookup_magnitude {orid magtype} {
	set magnitude ""
	# errlog report lookup_magnitude "looking in trial database for orid=$orid magtype='$magtype'"
	set nrecords [dbquery $dbnetmag dbRECORD_COUNT]
	# errlog report lookup_magnitude "$nrecords records in netmag table"
	loop i 0 $nrecords {
	    set this_orid [dbgetv $dbnetmag 0 $i orid]
	    # errlog report lookup_magnitude "orid #$i is $this_orid"
	    if { $this_orid == $orid } {
		set this_magtype [dbgetv $dbnetmag 0 $i magtype ]
		# errlog report lookup_magnitude "magtype #$i is $this_magtype"
		if { $this_magtype == $magtype } { 
		    set this_magnitude [dbgetv $dbnetmag 0 $i magnitude ]
		    # errlog report lookup_magnitude "returning magnitude #$i is $this_magnitude"
		    return $this_magnitude
		}
	    }
	}
	# errlog report lookup_magnitude "no luck -- returning {} for magnitude for orid $orid magtype $magtype"
	return "" 
    }

    method get_origin_display {orid fieldname} {
	global ::origin_info_table 
	set field ""
	if [info exists origin_info_table($fieldname)] {
	    set tablename $origin_info_table($fieldname)
	} else { 
	    set tablename origin
	}
	# errlog report get_origin_display "orid=$orid fieldname=$fieldname tablename=$tablename"
	if {$tablename == "netmag" }  { 
	    set field [lookup_magnitude $orid $fieldname]
	    # errlog report get_origin_display "dblooked up $fieldname in netmag: $field"
	} else { 
	    set db [dblookup $dborigin 0 $tablename $fieldname 0]
	    # errlog report get_origin_display "dblooked up $fieldname in $tablename: $db"
	    if { [lindex $db 2] >= 0 } {
		if {$tablename == "origin" } { 
		    set field [lindex [dbgetr $db $timeflag [lindex $dborigin 3] 1 $fieldname] 0]
		    # errlog report get_origin_display "dbgetr $fieldname in origin: $field"
		} elseif {$tablename == "origerr"} {
		    set matchrecord [lindex [dblookup $dborigerr 0 0 orid $orid] 3]
		    if {$matchrecord >= 0} {
			# errlog report get_origin_display "about to dbgetr $fieldname in record #$matchrecord of origerr"
			set field [lindex [dbgetr $db $timeflag $matchrecord 1 $fieldname] 0]
			# errlog report get_origin_display "dbgetr $fieldname in origerr: '$field'"
		    }
		}
	    } else { 
		errlog complain origin_panel "Can't find field $fieldname in $tablename: should $fieldname be in origin_info_table in dbloc2.pf?"
	    }
	    # eliminate year from any time field displays
	    regsub {/[12][0-9][0-9][0-9]  } $field " " field 
	}
	return $field 
    }

    method redisplay_origin {orid} {
	if {[info exists Row($orid)]} {
	    set row $Row($orid)
	    set db [dblookup $dborigin 0 origin orid $orid]
	    set record [lindex $db 3]
	    set bad 0 
	    foreach fieldname $display {
		# errlog notify redisplay_origin "looking up $fieldname"
		set field [get_origin_display $orid $fieldname]
		$Widget($row,$Column($fieldname)) config -text $field
	    }
	}
    }

    method show_residuals {orid} {
	# errlog report show_residuals "origins-show_residuals orid=$orid"
	if [ info exists Mb($orid) ] {
	    $this highlight $Mb($orid)
	    thinking "rearranging arrivals to show residuals for $orid"
	    arrivals set_source orid $orid
	    locate unset_key_entry
	    waiting
	    waveforms update
	} else { 
	    errlog complain show_residuals "no menubutton for $orid : $::errorInfo !!!"
	    # errlog complain show_residuals "[traceback]"
	}
	# errlog report show_residuals "returning from origins-show_residuals orid=$orid"
    }
	   

    method flag {args} {
	global ::Color
	foreach orid $flagged {
	    $Widget($Row($orid),$Column(evid)) config -bg $Color(background) 
	}
	set flagged $args
	foreach orid $args {
	    $Widget($Row($orid),$Column(evid)) config -bg red 
	}
    }

    method set_evid_menu {menu record orid} {
	$menu delete 0 last
	set n [dbquery $dborigin dbRECORD_COUNT]
	set done(-1) 1
	loop i 0 $n {
	    set evid [dbgetv $dborigin 0 $i evid]
	    if { ! [info exists done($evid)] } {
		set done($evid) 1
		$menu add command -command "origins set_evid $record $orid $evid" -label $evid
		}
	}
	$menu add command -command "origins set_evid $record $orid -1" -label unset
	$menu add command -command "origins set_evid $record $orid 0" -label new
    }

    method add_origin {record} {
	global ::State
        if { [dbquery $dborigin dbRECORD_COUNT] <= $record } {
            return 
        }

	set row [expr $record+10]
	set column 1

	set orid [dbgetv $dborigin 0 $record orid]
	if { $orid < 1 } { return } 

	set evid [dbgetv $dborigin 0 $record evid]
	set gregion [lindex [dbgetr $dborigin $timeflag $record 1 gregion(lat,lon)] 0]

	set dborigin [lreplace $dborigin 3 3 $record]
	set mb [$this create menubutton $row $column -text $orid ] 
	set Widget($row,$column) $mb
	set Row($orid) $row
	set Mb($orid) $mb
	incr column

	$mb configure -relief raised -menu $mb.menu -font Orid
	menu $mb.menu \
	    -disabledforeground blue -font Plain -tearoff no
	$mb.menu add command -label $gregion -state disabled
	$mb.menu add command -label "Show residuals" -command "$this show_residuals $orid"
	$mb.menu add command -label "Start at" -command "locate start_at_orid $orid ; run_locate 0"
	if { [lsearch -exact $State(old_orids) $orid] < 0 } {
	    $mb.menu add command -label "Remove" -command "$this remove $record $row $orid"
	}
	$mb.menu add cascade -label "Set evid" -menu $mb.menu.evids 
	menu $mb.menu.evids \
	    -postcommand "$this set_evid_menu $mb.menu.evids $record $orid"
	# $mb.menu add command -label "Add comment" -command "add_origin_comment $orid"
	add_menu_command origin_menu_items $mb.menu $dborigin $record

	global ::Keep
	set keepbutton [$this create KeepButton $row $column -record $record -orid $orid -evid $evid]
	set Widget($row,$column) $keepbutton
	incr column

	global ::Prefor
	set rb [$this create radiobutton $row $column \
		-padx 5 -pady 0 -borderwidth 2 -highlightthickness 0 \
		-variable Prefor($evid) -value $orid]
	set Widget($row,$column) $rb
	# set keepbutton ScrolledBlt::[namespace tail $keepbutton]
	$rb config -command "$keepbutton retain"
	incr column

	global ::Etype
	set mb2 [unique_window $itk_component(spreadsheet)]

	global ::User 
	set Etype(db) $dborigin
	option_menu $mb2 Etype($record) set_etype "- $User(etype)"
	set_etype Etype($record) Unset
	blt::table $itk_component(spreadsheet) $mb2 $row,$column -fill x -anchor nw
	set Widget($row,$column) $mb2
	incr column

	foreach fieldname $display {
	    # errlog report add_record "adding field '$fieldname'"
	    set field [get_origin_display $orid $fieldname]
	    set Widget($row,$column) [$this create label $row $column -text $field -font Fixedwidth]
	    set Widget($row,$fieldname) $Widget($row,$column)
	    incr column
	}
#	set max_column $column

	global ::Prefor2
        set rb2 [$this create radiobutton $row $column \
                -padx 5 -pady 0 -borderwidth 2 -highlightthickness 0 \
                -variable Prefor2($evid) -value $orid]
        set Widget($row,$column) $rb2
        # set keepbutton ScrolledBlt::[namespace tail $keepbutton]
#        $rb2 config -command "$resultbutton retain"
        incr column

	set max_column $column
    }

    method eval {args} {
	::eval $args
    }

    method forget {} {
	dbtruncate $dborigin 0
	dbtruncate $dborigerr 0
	dbtruncate $dbassoc 0
	dbtruncate $dbremark 0 
	dbtruncate $dbnetmag 0 
	$this clear 
    }

    method highlight { button } { 
	global ::Define
	global ::Color
	if { $highlighted != "" } { 
	    $highlighted config -bg $Color(background) -activebackground $Color(activeBackground)
	}
	$button config -bg $Define(ok_residual_color) -activebackground $Define(ok_residual_color)
	set highlighted $button
    }

    method update {} {
	# errlog report origin_update "inside OriginDisplay update"
	set n [dbquery $dborigin dbRECORD_COUNT]
	if { $n < $last_record } {
	    # errlog report origin_update "$n < $last_record"
	    $this clear
	} else { 
	    # errlog report origin_update "$n >= $last_record"
	    loop i $last_record $n { 
		$this add_origin $i
	    }
	}
	set last_record $n
	# errlog report origin_update "assign_evids: $n origins"
	assign_evids
	# errlog report origin_update "assign_evids: [traceback]"

# It seems to be impossible to get the requested height of the 
# frame inside the canvas here.  update idletasks causes the 
# whole application to freeze, and winfo reqheight $frame gives
# bogus small answers.  Hence the calculation.

	set w $itk_component(spreadsheet)
	blt::table arrange $w
	set height [winfo reqheight $w]
	set width  [winfo reqwidth  $w]
	set width  [expr $width+30]
	# set height [expr $n*21 + 21]

	set c $itk_component(canvas) 
	set cheight [winfo height $c]
	set cwidth  [winfo width  $c]

	set xscroll [expr max($cwidth, $width)]
	set yscroll [expr max($cheight, $height)]
	$c configure -scrollregion "0 0 $xscroll $yscroll"

	if { $cheight < $height } { 
	    set offscreen [expr ($height-$cheight)*1.0/$height]
	    after 1000
	    $c yview moveto $offscreen
	} else {
	    $c yview moveto 0
	}
	# errlog report origin_update "done with calculations, returning"
	# puts stderr [traceback]
    }

    public variable db {0 -102 -102 -102} {
	set dborigin [dblookup $db 0 origin 0 0]
	set dborigerr [dblookup $db 0 origerr 0 0]
	set dbassoc [dblookup $db 0 assoc 0 0]
	set dbremark [dblookup $db 0 remark 0 0]
	set dbnetmag [dblookup $db 0 netmag 0 0]
    }

    public variable timeflag 1

    public variable display {evid lat lon time depth dtype nass ndef mb algorithm auth sdobs lddate}

    protected variable Mb
    protected variable Row
    protected variable Widget
    protected variable Column
    protected variable dborigin
    protected variable dborigerr
    protected variable dbremark
    protected variable dbassoc
    protected variable dbnetmag
    protected variable last_record 0 
    protected variable highlighted ""
    protected variable max_column
    protected variable flagged ""
}

proc event {args} { 
# this is just a dummy routine to ignore the event message that is send by dbloc_group
}


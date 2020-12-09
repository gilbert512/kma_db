
# This file should contain all of the proc's which relate to the 
# "Waveforms" operation and windows

# creates a waveforms button for the buttonbar
proc waveforms_button {parent} {
    return [Buttonmenu $parent.#auto \
	-text Waveforms \
	-command waveforms \
	-menus "dismiss"
    ]
}

# dispatches all waveforms operations
proc waveforms {args} { 
    global Waveforms State Define 

    set cmd [lindex $args 0]
    if { ! [info exists Waveforms(dbpick)] } {
	if { $cmd == "init" } {
	    create_waveforms_display 
	} 
	return 
    }
#
#   make sure record count is up to date
    global Db
    set dbarr [dblookup $Db 0 arrival 0 0]
    dbquery $dbarr dbRECORD_COUNT

    switch $cmd {
	Waveforms	{ summon_waveforms }
	summon		{ summon_waveforms } 
	dismiss		{ dismiss_waveforms }
	new_event	{ set Waveforms(first) 1 }
	show_arrival	{ show_arrival [lindex $args 1] } 
	assume_source	{ assume_source [lindex $args 1] } 
	update		{ if { $Waveforms(synchronize) } { 
			    summon_waveforms
			    }
			}
	default		{ tkerror "bad message: waveforms $args" }
    }
}

proc show_arrival { record } {
    global Db User Run

    start_dbpick
    set tsc [dbgetv $Db arrival $record time sta chan]
    set time [expr [lindex $tsc 0] - $User(dbpick_waveform_lead_time)]
    set twin [expr 2*$User(dbpick_waveform_lead_time)]
    set sta [lindex $tsc 1]
    set chan [lindex $tsc 2]
    send2dbpick "sw off pal off sc $sta ts $time tw $twin sw on"
    dbpick_qwm deiconify 
    dbpick_qwm raise 
}

proc assume_source { record } {
    global Db User Run Waveforms Define

    start_dbpick
    thinking "bringing up waveforms"
    if { ! [ info exists Waveforms(fakedb)] } {
	set fakedb [dbopen $Define(Work_dir)/fake r+]
	set fakedb [dblookup $fakedb 0 origin 0 0]
	set Waveforms(fakedb) $fakedb
    } else {
	set fakedb $Waveforms(fakedb)
    }
    set tsc [dbgetv $Db arrival $record time sta chan]
    set time [lindex $tsc 0] 
    set sta [lindex $tsc 1]
    set chan [lindex $tsc 2]

    set dbarrival [dblookup $Db 0 arrival 0 0]
    set dbsite [dblookup $Db 0 site 0 0]
    set dbarrival [lreplace $dbarrival 3 3 $record]
    set matches [dbmatches $dbarrival $dbsite arrival2site]
    set srecord [lindex $matches 0]
    set lat [dbgetv $dbsite 0 $srecord lat]
    set lon [dbgetv $dbsite 0 $srecord lon]

    dbtruncate $fakedb 0
    dbaddv $fakedb origin lat $lat lon $lon depth 0 time $time ndef 0 nass 0 orid 1024

    set time [expr $time-$User(dbpick_waveform_lead_time)]
    send2dbpick "sw off soa off oe $Define(Work_dir)/fake se 1024 rec pal on soa off ts $time tw $User(dbpick_time_window) cw $Waveforms(first) $Waveforms(nchan) sw on"
    dbpick_qwm deiconify 
    dbpick_qwm raise 
    waiting
}

proc synchronize_waveforms {} {
    global Waveforms Tdb User Trial State
    thinking "bringing up waveforms"
    set cmd "sw off"
    set orid [arrivals get Orid]
    if { $orid > 0 } { 
	errlog report waveforms "displaying orid #$orid"
	set db [dblookup $Tdb 0 origin orid $orid]
	set time [dbgetv $db 0 [lindex $db 3] time] 
    } else {
	set records [arrivals get_records_used]
	if { [llength $records] } {
	    set first [lindex $records 0]
	    set time [dbgetv $Tdb arrival $first time]
	} else { 
	    set time [str2epoch $State(current_start_time)]
	}
    }
    set time [expr $time-$User(dbpick_waveform_lead_time)]
    append cmd " ts $time tw $User(dbpick_time_window)"
    
    if { $orid > 0 } {
	append cmd " oe $Trial se $orid rec"
	if {  [arrivals get xmode] == "predicted" } {
	    append cmd " pal on"
	} else { 
	    append cmd " pal off"
	}
	append cmd [_predict]
    } else { 
	append cmd " soa off"
    }
    global Define
    if { $Define(dbpick_revert_to_default) } { 
	set Waveforms(channels) [lindex $Define(dbpick_options_order) 0] 
    }
    append cmd [channels]
    append cmd " cw $Waveforms(first) $Waveforms(nchan) sw on"
    send2dbpick $cmd
    waiting
}

proc dbpick_qwm {cmd} {
    global Waveforms Define
    if { $Waveforms(dbpick) == "" } {
        # It may take a while for dbpick to get started
	if { ! [file exists $Define(Work_dir)/dbpick_window] } {
	    return
	}
	set Waveforms(dbpick) [exec cat $Define(Work_dir)/dbpick_window]
	}
    if { $Waveforms(dbpick) != "" } { 
	errlog report qwm "qwm $Waveforms(dbpick)"
	qwm $cmd $Waveforms(dbpick) 
    }
}

proc send2dbpick {cmd} {
    catch {send -async dbloc_dbpick $cmd}
}

proc start_dbpick {} {
    global Run
    if { ! $Run(dbpick) } { 
	errlog report "" "starting dbpick -- be patient, this may take a while"
	send2dbloc start dbpick
	after 5000
	set Run(dbpick) 1 
	waiting
    }
}

proc summon_waveforms {} {
    global Waveforms Run

    start_dbpick
    dbpick_qwm deiconify 
    dbpick_qwm raise 
    synchronize_waveforms
}

proc dismiss_waveforms {} {
    global Waveforms
    dbpick_qwm iconify 
}

proc _predict {} { 
    global Waveforms
    if { $Waveforms(predicted) } { 
	return " soa on sp P,S"
    } else {
	return " soa off"
    }
}
proc predicted_arrivals {} {
    send2dbpick [_predict]
}

proc get_selected {} { 
    global Db Tdb
    set selected ""
    foreach i [arrivals get_records_used] { 
	set sc [dbgetv $Db arrival $i sta chan]
	set arid [dbgetv $Db arrival $i arid]
	set sc [ translit " " : $sc ]
	set stachan($arid) $sc
	lappend selected $sc
    }
    return [join $selected ,]
}

proc channels {args} {
    global Waveforms User
    global dbpick_channel_options
    switch $Waveforms(channels) { 
	Selected	{  set chans " sc [get_selected] dw" }
	Detections	{  set chans " swd sd on sa off" ; set Waveforms(det) 1 ; set Waveforms(arr) 0 } 
	Arrivals	{  set chans " swa sd off sa on" ; set Waveforms(det) 0 ; set Waveforms(arr) 1 } 
	Arrivals+Detections	{  set chans " swda sd on sa on" ; set Waveforms(det) 1 ; set Waveforms(arr) 1 } 
	default		{ if { [info exists dbpick_channel_options($Waveforms(channels))] } { 
				set chans " $dbpick_channel_options($Waveforms(channels)) dw"
			} else { 
			    set chans " sc *:* dw" 
			}
	}
    } 
    return $chans
}

proc setchannels {args} { 
    global User Waveforms
    set cmd "sw off"
    append cmd [channels]
    append cmd " cw $Waveforms(first) $Waveforms(nchan) sw on"
    send2dbpick $cmd
    dbpick_qwm deiconify 
    dbpick_qwm raise 
}

proc fix_nearfar {} {
    global Waveforms
    set w $Waveforms(frame)
    if { $Waveforms(first) == 1 } { 
	$w.closer configure -state disabled
    } else {
	$w.closer configure -state normal
    }
    if { $Waveforms(first)+$Waveforms(nchan) >= $Waveforms(max) } { 
	$w.further configure -state disabled
    } else {
	$w.further configure -state normal
    }
    send2dbpick "cw $Waveforms(first) $Waveforms(nchan)"
}

proc closer {} { 
    global Waveforms
    set Waveforms(first) [max 1 [expr $Waveforms(first)-$Waveforms(nchan)]]
    fix_nearfar
}

proc further {} { 
    global Waveforms
    set Waveforms(first) [min [expr $Waveforms(max)-$Waveforms(nchan)] \
		   [expr $Waveforms(first)+$Waveforms(nchan)]]
    fix_nearfar
}


proc create_waveforms_display {} { 
    global Tdb Waveforms Define User

    set w .wf
    frame $w
    set Waveforms(frame) $w

    set Waveforms(dbpick) ""

    global ::Color
    label $w.label -text "Waveforms" -bg $Color(disabledForeground)

    button $w.summon \
	-padx 0 -pady 0 -borderwidth 1 -highlightthickness 0 \
	-text "Show waveforms" \
	-command  "waveforms summon"
    button $w.dismiss \
	-padx 0 -pady 0 -borderwidth 1 -highlightthickness 0 \
	-text "Hide waveforms" \
	-command  "waveforms dismiss"

    global dbpick_channel_options
    SelectorButton $w.channels \
	-options "$Define(dbpick_options_order)" \
	-text channels -side right \
	-variable Waveforms(channels) 
    set Waveforms(channels) [lindex $Define(dbpick_options_order) 0] 
    $w.channels config -command setchannels

    set Waveforms(arr) 1
    checkbutton $w.arr \
	-text "Arrivals" \
	-variable Waveforms(arr) \
	-command {if {$Waveforms(arr)} {send2dbpick {sa on}} {send2dbpick {sa off}}}

    set Waveforms(det) 1
    checkbutton $w.det \
	-text "Detections" \
	-variable Waveforms(det) \
	-command {if {$Waveforms(det)} {send2dbpick {sd on}} {send2dbpick {sd off}}}

    set Waveforms(predicted) 1
    checkbutton $w.predicted \
	-text "Predicted" \
	-variable Waveforms(predicted) \
	-command predicted_arrivals

    set Waveforms(synchronize) 0
    checkbutton $w.synchronize \
	-text Synchronize \
	-variable Waveforms(synchronize) 

    set Waveforms(first) 1
    set db [dblookup $Tdb 0 sitechan 0 0]
    set Waveforms(max) [dbquery $db dbRECORD_COUNT]
    set Waveforms(nchan) $User(dbpick_max_channels)

    label $w.window \
	-text "Channels"

    button $w.closer \
	-padx 0 -pady 0 -borderwidth 1 -highlightthickness 0 \
	-text "Closer" \
	-command closer \
	-state disabled 

    label $w.lfirst \
	-text "First"

    entry $w.first \
	-width 3 \
	-textvariable Waveforms(first)
    bind $w.first <Return> fix_nearfar

    label $w.lnchan \
	-text "#"

    entry $w.nchan \
	-width 3 \
	-textvariable Waveforms(nchan)
    bind $w.first <Return> fix_nearfar
	
    button $w.further \
	-padx 0 -pady 0 -borderwidth 1 -highlightthickness 0 \
	-text Further \
	-command further 

    set col -1
    blt::table $w \
	$w.label 	    0,[incr col] -rowspan 2 -fill both \
	$w.arr 	            1,[incr col] -fill x \
	$w.det 	            1,[incr col] -fill x \
	$w.predicted 	    1,[incr col] -fill x \
	$w.synchronize 	    1,[incr col] -fill x \
	$w.closer 	    1,[incr col] \
	$w.window 	    0,$col \
	$w.first  	    1,[incr col] \
	$w.lfirst  	    0,$col \
	$w.nchan  	    1,[incr col] \
	$w.lnchan  	    0,$col \
	$w.further 	    1,[incr col] \
	$w.channels 	    1,[incr col] -fill x \
	$w.summon 	    1,[incr col] -fill x \
	$w.dismiss    	    1,[incr col] -fill x 

    blt::table . \
	$w 15,0	-columnspan $Define(maxcol) -fill x  -anchor w
    }

# $Id$ 

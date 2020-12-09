
class ArrivalDisplay { 
    inherit itk::Widget 

    constructor {args} {
	global ::Arrivals ::State ::Define 

        global ::tcl_precision
        set tcl_precision 17

	set w $itk_interior
	set csta $itk_interior.sta
	itk_component add sta { 
	    canvas $itk_interior.sta \
		-width $sta_width \
		-height $Define(arrivals_height)
	}

	set carr $itk_interior.arr
	itk_component add arr { 
	    canvas $itk_interior.arr \
		-xscrollcommand "$itk_interior.sh set" \
		-yscrollcommand "$itk_interior.sv set" \
		-width $Define(arrivals_width) \
		-height $Define(arrivals_height)
	}

	itk_component add vertical { 
	    scrollbar $itk_interior.sv \
		-command "$this yview " \
		-width 10 \
		-relief sunken
	}

	itk_component add horizontal { 
	    scrollbar $itk_interior.sh \
		-orient horizontal \
		-command "$carr xview" \
		-width 10 \
		-relief sunken
	}

	bind $carr <ButtonPress-1> "$this band_create %x %y"
	bind $carr <B1-Motion> "$this band %x %y"
	bind $carr <ButtonRelease-1> "$this bandselect"

	bind $carr <Shift-ButtonPress-1> "$this zoom_create %x %y"
	bind $carr <Shift-B1-Motion> "$this zoom_show %x %y"
	bind $carr <Shift-ButtonRelease-1> "$this zoom_set"
 
	global ::Color

	itk_component add start_time { 
	    label $itk_interior.start_time \
		-anchor w \
		-textvariable State(current_start_time)
	}

	itk_component add xmode { 
	    SelectorButton $itk_interior.xmode \
		-side left \
		-options {time predicted order} \
		-command "mode_switch xmode"
	}

	itk_component add ymode { 
	    SelectorButton $itk_interior.ymode \
		-side left \
		-options {order distance} \
		-command "mode_switch ymode"
	}

	itk_component add select_all { 
	    button $itk_interior.select_all \
		-padx 2 -pady 0 -borderwidth 1 -highlightthickness 0 \
		-text "Select All" \
		-command "arrivals select_all use"
	}

	itk_component add ignore_all { 
	    button $itk_interior.ignore_all \
		-padx 2 -pady 0 -borderwidth 1 -highlightthickness 0 \
		-text "Ignore All" \
		-command "arrivals select_all ignore"
	}

	itk_component add zoomout { 
	    button $itk_interior.zoomout \
		-padx 2 -pady 0 -borderwidth 1 -highlightthickness 0 \
		-text "Zoom out" \
		-command "$this zoom_out"
	}

	itk_component add unzoom { 
	    button $itk_interior.unzoom \
		-padx 2 -pady 0 -borderwidth 1 -highlightthickness 0 \
		-text "Original zoom" \
		-command "$this unzoom"
	}

	itk_component add ignore_associated { 
	    button $itk_interior.ignore_associated \
		-padx 2 -pady 0 -borderwidth 1 -highlightthickness 0 \
		-text "Ignore associated" \
		-command "$this ignore_associated"
	}

	itk_component add mark_associated { 
	    button $itk_interior.mark_associated \
		-padx 2 -pady 0 -borderwidth 1 -highlightthickness 0 \
		-text "Mark associated" \
		-command "$this mark_associated"
	}

	itk_component add unmark { 
	    button $itk_interior.unmark \
		-padx 2 -pady 0 -borderwidth 1 -highlightthickness 0 \
		-text "Unmark" \
		-command "$this select_all unmark"
	}

	itk_component add map { 
	    button $itk_interior.map \
		-padx 2 -pady 0 -borderwidth 1 -highlightthickness 0 \
		-text "Show Map with reporting stations" \
		-command "arrivals map"
	}

	set col 2
	blt::table $itk_interior \
	    $itk_interior.start_time		  1,0 -columnspan 4 -fill x -anchor w \
	    $itk_interior.sta 2,0 -fill y -columnspan 2 -pady 5 \
	    $itk_interior.arr 2,2 -fill both -columnspan [expr $Define(maxcol)-3]\
	    $itk_interior.sv 2,$Define(maxcol) -fill y \
	 \
	    $itk_interior.ymode 3,0	     -anchor w \
	    $itk_interior.xmode 3,1	     -anchor w \
	    $itk_interior.sh    3,2	     -fill x  -columnspan [expr $Define(maxcol)-3] \
	 \
	    $itk_interior.select_all	    4,[incr col] -anchor w \
	    $itk_interior.ignore_all	    4,[incr col] -anchor w \
	    $itk_interior.ignore_associated 4,[incr col] -anchor w \
	    $itk_interior.mark_associated   4,[incr col] -anchor w \
	    $itk_interior.unmark	    4,[incr col] -anchor w \
	    $itk_interior.zoomout	    4,[incr col] -anchor w \
	    $itk_interior.unzoom	    4,[incr col] -anchor w \
	    $itk_interior.map		    4,[incr col] -anchor w

	global ::Arrival
	global ::Azimuth
	global ::Slowness
	# trace variable Arrival w set_visual
	# trace variable Azimuth w set_visual
	# trace variable Slowness w set_visual

# initialize Arrows to be an array
	set Arrows(0) 0
	unset Arrows(0)
	set ResidualTimes(0) 0
	unset ResidualTimes(0)
	eval itk_initialize $args
    }

    method config {args} {
	eval itk_initialize $args
    }

    method get {name} { return [set $name] }

    method band_create { x y } {
	set x_anchor [$carr canvasx $x]
	set y_anchor [$carr canvasy $y]
	set mouse_mode band
	$carr create rectangle $x_anchor $y_anchor $x_anchor $y_anchor -tags band 
    }

    method band { x y } {
	set x [$carr canvasx $x]
	set y [$carr canvasy $y]
	switch $mouse_mode { 
	band {$carr coords band $x_anchor $y_anchor $x $y}
	zoom {$carr coords band $x_anchor $Ymin $x $Ymax}
	}
    }

    method bandselect {} { 
	global ::Arrival_button
	set enclosed [eval $carr find enclosed  [$carr coords band]] 
	foreach i $enclosed { 
	    catch { $Arrival_button($i) use } 
	}
	$carr delete band
    }

    method zoom_create { x y } {
	set x_anchor [$carr canvasx $x]
	set mouse_mode zoom
	$carr create rectangle $x_anchor $Ymin $x_anchor $Ymax -tags band -fill yellow
	$carr lower band
    }

    method zoom_show { x y } {
	set x [$carr canvasx $x]
	$carr coords band $x_anchor $Ymin $x $Ymax
    }

    method zoom_set {} { 
	global ::Define
	set coords [$carr coords band] 
	$carr delete band
	set x0 [lindex $coords 0]
	set x1 [lindex $coords 2]
	set scale [expr $Define(arrivals_width)/($x1-$x0)]
	zoom $x0 $scale
    }

    method zoom { x0 scale } { 
	set ids [$carr find all] 
	$carr scale all 0 0 $scale 1
	set tscale [expr $tscale*$scale]
	set Xmin [expr $scale*$Xmin]
	set Xmax [expr $scale*$Xmax]
	$carr configure \
	    -scrollregion "$Xmin $Ymin $Xmax $Ymax"
	set x0 [expr $x0*$scale]
	set xscroll [expr ($x0-$Xmin)/($Xmax-$Xmin)]
	$carr xview moveto $xscroll
	show_scale $Tmin $Tmax $Ymin $Ymax [expr $tscale/$tscale_orig]
	show_residuals
    }

    method zoom_out {} { 
	 set x0 [$carr canvasx 0]
	 zoom $x0 .6
    }

    method unzoom {} {
	set scale [expr $tscale_orig/$tscale]
	zoom [expr $Xmin_orig/$scale] $scale
    }


    method yview { args } { 
	eval $csta yview $args
	eval $carr yview $args
    }

    method predict { record } { 
	set dbarrival [lreplace $dbarrival 3 3 $record]
	set matches [dbmatches $dbarrival $dbsite arrival2site]
	set record [lindex $matches 0]
	set dbsite [lreplace $dbsite 3 3 $record]
	dbputv $db compute dbSCRATCH site $dbsite
	dbputv $db compute dbSCRATCH arrival $dbarrival
	set otime [dbgetv $db compute dbSCRATCH origin.time]

	set time [dbeval $dbcompute parrival()]
	if { $time < $otime } {
	    errlog complain arrivals "Can't compute predicted arrivals: check the log file"
	    set time [dbgetv $dbarrival 0 $record time]
	}
	return $time
    }

    method set_xmode { mode } {
	set xmode $mode 
	$itk_component(xmode) setopt $mode
    }

    method set_source {type id} {
	setup_source $type $id
	set_xmode predicted
	if { [winfo exists $w] } {
	    $this display 
	}
    }

    method setup_source { type id } {
	switch $type { 
	    arid    {
		set record $Record($id)
		set dbarrival [lreplace $dbarrival 3 3 $record]
		set time [dbgetv $dbarrival 0 $record time]
		set matches [dbmatches $dbarrival $dbsite arrival2site]
		if { [llength $matches] > 0 } {
		    set record [lindex $matches 0]
		    set lat [dbgetv $dbsite 0 $record lat]
		    set lon [dbgetv $dbsite 0 $record lon]
		    set dborigin [dblookup $db 0 origin 0 dbSCRATCH]
		    dbputv $db origin dbSCRATCH time $time lat $lat lon $lon depth 0
		    dbputv $db compute dbSCRATCH origin $dborigin
		} else {
		    set sta [dbgetv $dbarrival 0 $record sta]
		    errlog complain arrivals "can't find $sta in site table!!"
		    after 2000
		    set t [strdate $time]
		    set arid [dbgetv $dbarrival 0 $record arid]
		    errlog complain arrivals "Quitting because $sta is not found in site table (on $t for arid #$arid)"
		    after 2000
		    puts stderr "\n** Quitting because $sta is not found in site table (on $t for arid #$arid) **"

		    set nsite [dbquery $dbsite dbRECORD_COUNT]
		    if { $nsite < 3 } {
			global ::Tdb
			set name [dbquery $Tdb dbDATABASE_NAME]
			puts stderr "Only $nsite records in $name.site"
		    }
		    quit
		    set lat -999
		}
	    }
	    orid    {
		set dborigin [dblookup $db 0 origin orid $id]
		set record [lindex $dborigin 3]
		set Orid [dbgetv $dborigin 0 $record orid]
		select_orid $Orid use
		set lat [dbgetv $dborigin 0 $record lat]
		set lon [dbgetv $dborigin 0 $record lon]
		set time [dbgetv $dborigin 0 $record time]
		dbputv $db compute dbSCRATCH origin $dborigin
	    }
	}
	if { $lat != -999 } {
	    set source_lat $lat
	    set source_lon $lon
	    set source_time $time
	    $this sort_arrival_records $lat $lon
	}
    }

    method sort_arrival_records { lat lon } {
	global ::Distance
	global ::Define
	global ::Sta_label
	catch "unset Distance"
	catch "unset Sta"
	global ::Iphase
	catch "unset Iphase"
	set max_distance 0
	foreach i $arrival_records {
	    set dbarrival [lreplace $dbarrival 3 3 $i]
	    set sta [dbgetv $dbarrival 0 $i sta]
	    set Iphase($i) [dbgetv $dbarrival 0 $i iphase]
	    set Sta($i) $sta
	    if { ! [info exists Lat($sta)] } {
		set matches [dbmatches $dbarrival $dbsite arrival2site]
		if { "$matches" != "" } {
		    set record [lindex $matches 0]
		    set Site($sta) $record
		    set Lat($sta) [dbgetv $dbsite 0 $record lat]
		    set Lon($sta) [dbgetv $dbsite 0 $record lon]
		} else { 
		    set nsite [dbquery $dbsite dbRECORD_COUNT]
		    set badsta [dbgetv $dbarrival 0 $i sta]
		    set badtime [dbgetv $dbarrival 0 $i time]
		    set badiphase [dbgetv $dbarrival 0 $i iphase]
		    errlog complain arrivals "Can't find station $sta in site table!! Please fix this and restart" 
		    errlog complain arrivals "badsta=$badsta badtime=$badtime badiphase=$badiphase" 
		    errlog complain arrivals "nsite=$nsite dbsite = $dbsite"
		    errlog complain arrivals "dbarrival = $dbarrival"
		    errlog complain arrivals "matches = '$matches'"
		    after 1000
		    set matches [dbmatches $dbarrival $dbsite arrival2site]
		    errlog complain arrivals "2nd matches = '$matches'"
		    if { "$matches" != "" } {
			set record [lindex $matches 0]
			set Site($sta) $record
			set Lat($sta) [dbgetv $dbsite 0 $record lat]
			set Lon($sta) [dbgetv $dbsite 0 $record lon]
		    } else { 
			set Site($sta) -505
			set Lat($sta) 0
			set Lon($sta) 0
			tk_dialog .abort "$sta missing" "Can't find station $sta in site table!! Please fix this and restart" warning 0 Ok 
		    }
		}
	    }

	    if { $Site($sta) >= 0 } { 
		set Distance($i) [lindex [dbdist $lat $lon $Lat($sta) $Lon($sta)] 0 ]
		set Sta_label($sta) [format  "%-6s %6.3f" $sta $Distance($i)]
		set max_distance [max $max_distance $Distance($i)]
	    } else { 
		set Distance($i) 0
		set Sta_label($sta) [format  "%-6s %s" $sta ???]
		errlog complain arrivals "Can't find station $sta (arrival #$i) in site table"
	    }
	}
	set arrival_records [lsort -command by_distance $arrival_records]
	catch "unset Yorder"
	set Ysta_cnt 0
	if { $max_distance > 0 } {
	    set dscale [expr ($Define(arrivals_height)-$sta_height)/$max_distance]
	} else { 
	    set dscale 1
	}
    }

    method map {} {
	global ::Trial
	if { $Orid > 0 } {
	    send2dbloc bkg dbloc_map $Trial $Orid
	} else {
	    send2dbloc bkg dbloc_map $Trial 
	}
    }

    method xpos { record } { 
	set sta [dbgetv $dbarrival 0 $record sta]
	set time [dbgetv $dbarrival 0 $record time]
	switch $xmode {
	    time    { set x [expr ($time-$t0)] }
	    predicted { 
		set x [expr ($time-[$this predict $record])] 
	    }
	    order    - 
	    default { if { [info exists Xorder($record)] } {
			set x $Xorder($record) 
		    } else {
			if { ! [info exists Xsta_cnt($sta)] } { 
			    set Xsta_cnt($sta) -1
			}
			set x [expr [incr Xsta_cnt($sta)]*$arrival_width] 
			set Xorder($record) $x
		    }
	    }
	}
	return $x
    }
    
    method ypos { record } { 
	global ::Distance
	set sta [dbgetv $dbarrival 0 $record sta]
	switch $ymode { 
	    distance { set y [expr $Distance($record)*$dscale] } 
	    order    -
	    default { 
		    if { [info exists Yorder($sta)] } {
			set y $Yorder($sta)
		    } else { 
			set y [expr [incr Ysta_cnt] * $sta_height]
			set Yorder($sta) $y
		    }
	    }
	    return $y
	}
    }

    method get_arids_used {} {
	set result ""
	foreach i $arrival_records { 
	    if { [$carr.a$i used ] } {
		append result " $Arid($i)"
	    }
	}
	return $result
    }

    method get_records_used {} { 
	set result ""
	foreach i $arrival_records { 
	    if { [$carr.a$i used ] } {
		append result " $i"
	    }
	}
	return $result
    }

    method reap {} { 
	set result ""
	foreach i $arrival_records { 
	    append result [$carr.a$i reap]
	}
	return $result
    }

    method forget {} { 
	if { [info exists Station_arrivals] } { 
	    foreach i [array names Station_arrivals] {
		foreach j $Station_arrivals($i) { 
		    catch {destroy $carr.a$j}
		}
		catch {destroy $csta.s$i}
	    }
	    catch "unset Station_arrivals"
	    catch "unset Ysta"
	    set Ysta_cnt 0
	    catch "unset Xsta_cnt"
	    catch "unset Xorder"
	    catch "unset Arid"
	    catch "unset Record"
	    global ::State
	    set State(old_evids) ""
	    set State(arrival_records) ""
	    set State(old_orids) ""
	    global ::Old_prefor
	    catch "unset Old_prefor"
	    global ::Prefor
	    catch "unset Prefor"
	    global ::Prefor2
	    catch "unset Prefor2"
	    catch "unset Arids"
	    global ::Evid
	    catch "unset Evid"
	    global ::Id
	    catch "unset Id"
	    global ::Arrival_button
	    catch "unset Arrival_button"
	    catch "unset Xsv"
	    catch "unset Ysv"
	    set Orid -1

	    if { [info exists Arrows] } { 
		foreach i [array names Arrows] { 
		    $carr delete $i 
		    unset Arrows($i)
		}
		foreach i [array names ResidualTimes] {
		    $carr delete $i
		    unset ResidualTimes($i)
		}
	    }

	    set old_bad_arids ""
	    global OriginalTime
	    catch "unset OriginalTime"
	}
    }

    method origin {orid args} { 
	global ::State
	lappend State(old_orids) $orid
	set Arids($orid) $args
	return
    }

    method origin_arrival_records {orid} {
	set records {}
	if {[info exists Arids($orid)]} {
	    foreach arid $Arids($orid) {
		if { [info exists Record($arid)] } {
		    lappend records $Record($arid)
		}
	    }
	}
	return $records 
    }

	
    method event {evid prefor args} { 
	global ::State
	global ::Prefor
	global ::Prefor2
	global ::Old_prefor
	global ::Evid
	set bad_arids ""
	set bad_evids ""
	if { $evid > 0 } { 
	    lappend State(old_evids) $evid
	    set Old_prefor($evid) $prefor
	    set Prefor($evid) $prefor
	    set Prefor2($evid) $prefor2
	    foreach orid $args { 
		foreach arid $Arids($orid) { 
		    if { [info exists Evid($arid)] } { 
			if { $Evid($arid) != $evid } { 
			    lappend bad_evids $evid $Evid($arid)
			    lappend bad_arids $arid
			}
		    } else { 
			set Evid($arid) $evid
		    }
		}
	    }
	}
	if { $bad_arids != "" } { 
	    set bad_evids [lrmdups $bad_evids]
	    set bad_arids [lrmdups $bad_arids]
	    errlog complain arrivals "Arids $bad_arids are associated with multiple events $bad_evids"
	}
    }

    method setup_arrival { i } {
	set sta [dbgetv $dbarrival 0 $i sta]
	set Arid($i) [dbgetv $dbarrival 0 $i arid]
	set Record($Arid($i)) $i
	global OriginalTime
	set OriginalTime($i) [dbgetv $dbarrival 0 $i time]
	if { ! [winfo exists $csta.s$sta] } { 
	    StationButton $csta.s$sta $dbsite $sta $Site($sta)
	    set Station_arrivals($sta) ""
	} 
	ArrivalButton $carr.a$i \
	    -record $i \
	    -db $dbarrival
	lappend Station_arrivals($sta) $i
    }

    method setup {} {
	foreach i $arrival_records {
	    setup_arrival $i
	}
    }

    method show_scale {xmin xmax ymin ymax factor} {
	global ::Define
	set ymin [expr $ymin+30]
	foreach i $scale_ids {
	    $carr delete $i
	}
	set scale_ids ""

	switch $xmode {
		time    { set t $t0 }
		predicted { set t $source_time }
		order    - 
		default { return }
	    }
	set delta [expr ($xmax-$xmin) / $factor]
	set dx 600
	foreach i { .2 .5 2 5 10 15 30 60 300 } {
	    if { $delta/$i < 8 } { 
		set dx $i 
		break 
	    }
	}

	set xmin [expr floor (($xmin+$t)/$dx) *$dx]
	set xmax [expr ceil ($xmax+$t)]
	while { $xmin < $xmax } {
	    set xpos [expr ($xmin-$t)*$tscale]
	    set lbl [lindex [strtime $xmin] 1]
	    regsub ".000" $lbl "" lbl
	    lappend scale_ids [$carr create line $xpos $ymin $xpos $ymax \
		-fill gray50 \
		-width 1.0]
	    lappend scale_ids [$carr create text $xpos $ymin \
		-anchor s \
		-text $lbl \
		-font Time \
		-fill gray50]
	    lappend scale_ids [$carr create text $xpos $ymax \
		-anchor s \
		-text $lbl \
		-font Time \
		-fill gray50]

	    set xmin [expr $xmin+$dx]
	}
    }


    method display {} { 
	global ::Define
	if { ! [winfo exists $w] || $arrival_records == "" } { 
	    return 
	}

	set i [lindex $arrival_records 0]
	set xmin [xpos $i]
	set ymin [ypos $i]
	set xmax $xmin
	set ymax $ymin

	foreach i $arrival_records { 
	    set sta [dbgetv $dbarrival 0 $i sta]
	    set Xpos($i) [xpos $i]
	    set Ypos($i) [ypos $i]
	    if { ! [ info exists done($sta) ] } { 
		move_canvas_window $csta $csta.s$sta 0 $Ypos($i)
		set done($sta) 1
	    }
	    set xmax [max $xmax $Xpos($i)]
	    set ymax [max $ymax $Ypos($i)]
	    set xmin [min $xmin $Xpos($i)]
	    set ymin [min $ymin $Ypos($i)]
	}

	if { $xmax == $xmin } {
	    set xmin [expr $xmin-20]
	    set xmax [expr $xmax+20]
	    set ymin [expr $ymin-20]
	    set ymax [expr $ymax+20]
	}
	set dx [expr ($xmax-$xmin)*.1]
	set xmin [expr $xmin-$dx]
	set xmax [expr $xmax+$dx]

	set dy [expr ($ymax-$ymin)*.1]
	set ymin [expr $ymin-$sta_height]
	set ymax [expr $ymax+$dy]


	set tscale [expr $Define(arrivals_width)/($xmax-$xmin)]
	set tscale_orig $tscale

	set Xmin [expr $tscale*$xmin]
	set Xmin_orig $Xmin
	set Xmax [expr $tscale*$xmax]
	set Tmin $xmin
	set Tmax $xmax

	set Ymin $ymin
	set Ymax $ymax

	$this show_scale $Tmin $Tmax $Ymin $Ymax 1

	foreach i $arrival_records { 
	    set xpos [expr $Xpos($i)*$tscale]
	    set ypos $Ypos($i)
	    $carr.a$i move_to $xpos $ypos

	    set arid [dbgetv $dbarrival 0 $i arid]
	    set Xsv($arid) $Xpos($i)
	    set Ysv($arid) $Ypos($i)
	}
	$csta configure \
	    -scrollregion "0 $ymin $sta_width $ymax"
	$carr configure \
	    -scrollregion "$Xmin $ymin $Xmax $ymax"

	show_residuals
	$this yview moveto 0
    }

    method delete_residuals {} {
	if { [info exists Arrows] } { 
	    foreach i [array names Arrows] { 
		$carr delete $i 
		unset Arrows($i)
	    }
	    foreach i [array names ResidualTimes] {
		$carr delete $i
		unset ResidualTimes($i)
	    }
	}
    }

    method show_residuals {} {
	delete_residuals
	if { $Orid > 0 } {
	    set n [dbquery $dbassoc dbRECORD_COUNT]
	    loop i 0 $n { 
		set orid [dbgetv $dbassoc 0 $i orid]
		if { $orid == $Orid } { 
		    set arid [dbgetv $dbassoc 0 $i arid]
		    if { [info exists Record($arid)] } { 
			$this residual_arrow $carr $arid $i \
			    [expr $tscale*$Xsv($arid)] \
			    [expr $Ysv($arid)+$Residual_delta]
		    }
		}
	    }
	}
    }

    method flag { args } { 
	foreach arid $old_bad_arids {
	    if { [info exists Record($arid)] } { 
		$carr.a$Record($arid) unflag
	    }
	}
	set old_bad_arids $args
#  When arrivals have been deleted from a database, but not the assocs,
#  there may be arrival arids found with multiple evids which have no
#  button in the arrival display.
	foreach arid $args {
	    if { [info exists Record($arid)] } { 
		$carr.a$Record($arid) flag
	    }
	}
    }

    method residual_arrow {canvas arid record x y} {    
	global ::Define User
	set sta [dbgetv $dbassoc 0 $record sta]
	set timeres [dbgetv $dbassoc 0 $record timeres]
	set phase [dbgetv $dbassoc 0 $record phase]
	switch -glob -- $phase {
	    P*	{ set max $User(Presidual_max) }
	    default { set max $User(Sresidual_max) }
	}
	if { abs($timeres) > $max } { 
	    set color $Define(bad_residual_color)
	} else { 
	    set color $Define(ok_residual_color)
	}
	set id [$canvas create line $x $y [expr $x-$tscale*$timeres] $y \
	    -arrow last \
	    -fill $color]
	set Arrows($id) $arid
	if { $timeres < 0 } { 
	    set anchor sw
	} else { 
	    set anchor se
	}
	set id [$canvas create text [expr $x-$tscale*$timeres] $y \
	    -anchor $anchor \
	    -text $timeres \
	    -fill $color]
	set ResidualTimes($id) $arid
    }


    method select_sta { sta action }  {
	foreach record $Station_arrivals($sta) {
	    catch {$carr.a$record $action}
	}
    }

    method select_all {action} {
	foreach record $arrival_records { 
	    catch {$carr.a$record $action}
	}
    }

    method ignore_associated {} {
	set n [dbquery $dbassoc dbRECORD_COUNT]
	loop i 0 $n { 
	    set arid [dbgetv $dbassoc 0 $i arid]
	    if { $arid > 0 && [info exists Record($arid)] } { 
		$carr.a$Record($arid) ignore
	    }
	}
    }

    method mark_associated {} {
	set n [dbquery $dbassoc dbRECORD_COUNT]
	loop i 0 $n { 
	    set arid [dbgetv $dbassoc 0 $i arid]
	    if { $arid > 0 && [info exists Record($arid)] } {
		$carr.a$Record($arid) mark_associated
	    }
	}
    }


    method select_orid {orid action} {
	if { $action == "use" } { select_all ignore }
	set n [dbquery $dbassoc dbRECORD_COUNT]
	loop i 0 $n { 
	    set match [dbgetv $dbassoc 0 $i orid]
	    if { $match == $orid } { 
		set arid [dbgetv $dbassoc 0 $i arid]
		if { [info exists Record($arid)] } {
		    switch $action {
			use {
			    set timedef [dbgetv $dbassoc 0 $i timedef]
			    switch -- $timedef { 
				n	{ $carr.a$Record($arid) residuals }
				default	{ $carr.a$Record($arid) $action }
			    }
			}
			default	{ $carr.a$Record($arid) $action }
		    }
		}
	    }
	}
    }

    method stations {} { 
	if { [info exists Station_arrivals] } { 
	    return [array names Station_arrivals]
	} else {
	    return ""
	}
    }

    method arrival_added { i } { 
	errlog report arrival_added "added arrival record #$i"
	global phases_to_ignore 
	loop j 0 20 { 
	    set time [dbgetv $dbarrival 0 $i time]
	    if { $time > 0 } break 
	    after 500	# wait for record to be updated
	}
	set iphase [dbgetv $dbarrival 0 $i iphase]
	if {! [info exists phases_to_ignore($iphase)] } {
	    lappend arrival_records $i 
	    set record [lindex $arrival_records 0]
	    set arid $Arid($record)
	    setup_source arid $arid
	    set arid [dbgetv $dbarrival 0 $i arid]
	    setup_arrival $i
	    if { $Orid > 0 } {
		setup_source orid $Orid
	    } 
	    $this display
	} else {
	    errlog report arrival_added "ignoring arrival record #$i: $iphase"
	}
    }


    method arrival_changed_phase { i } {
	if { ! [info exists Arid($i)] } { 
	    arrival_added $i
	}
	if { [info exists Arid($i)] } { 
	    $carr.a$i change_phase
	}
    }

    method arrival_changed_measurements { i } {
	if { ! [info exists Arid($i)] } { 
	    arrival_added $i
	}
	if { [info exists Arid($i)] } { 
	    $carr.a$i update_measurements
	}
    }
    
    method arrival_moved { i } { 
	if { ! [info exists Arid($i)] } { 
	    arrival_added $i
	}
	if { [info exists Arid($i)] } { 
	    set Xpos($i) [xpos $i]
	    set Ypos($i) [ypos $i]
	    set xpos [expr $Xpos($i)*$tscale]
	    set ypos $Ypos($i)
	    set sta [dbgetv $dbarrival 0 $i sta]
	    $carr.a$i move_to $xpos $ypos
	}
    }

    method arrival_deleted { i } { 
	if { [info exists Arid($i)] } { 
	    ldelete arrival_records $i 
	    set arid $Arid($i)
	    unset Record($arid)
	    unset Arid($i)
	    destroy $carr.a$i
	}
    }

    method records { args } { 
	# errlog report arrival_records "$args"
	set last_arrival_records $arrival_records
	set arrival_records "$args"
	global State
	set State(arrival_records) $arrival_records
	set n1 [llength $arrival_records]
	if { $n1 > 0 } { 
	    errlog report arrivals "$n1 arrivals found"
	} else { 
	    errlog complain arrivals "no more arrivals"
	}
	if { $n1 > 0 } { 
	    dbquery $dbarrival dbRECORD_COUNT ; # force a recount of arrival table
	    set i [lindex $arrival_records 0]
	    if { "$i" != "" } {
		set arid [dbgetv $dbarrival 0 $i arid]
		set Record($arid) $i
		setup_source arid $arid
	    }
	}
	global ::Prefor
	global ::Prefor2
	setup
	if { [clength $State(old_evids)] > 0 } {
	    set evid [lindex $State(old_evids) 0]
	    if { [info exists Prefor($evid)] && $Prefor($evid) >= 0} { 
		set prefor $Prefor($evid)
	    } else { 
		errlog report arrivals "no preferred origin for $evid"
		set prefor [lindex $State(old_orids) 0]
	    }

	    if { [info exists Prefor2($evid)] && $Prefor2($evid) >= 0} {
                set prefor2 $Prefor2($evid)
            } else {
                errlog report arrivals "no preferred2 origin for $evid"
                set prefor2 [lindex $State(old_orids) 0]
            }

	    after_next
	    display
	    origins show_residuals $prefor
	} else {
	    set_xmode time
	    display
	    after_next
	}

	catch {eval $State(pending)}
	set State{pending} {}
	show_conflicting_events
    }

    method range {min max arrival_min arrival_max} {
	global ::Define ::State
	next set_range $min $max $arrival_min $arrival_max
	set t0 $arrival_min
	set t1 $arrival_max
	return 
    }   
     
    public variable arrival_records {} 

    public variable ymode order
    public variable xmode time 
    public variable timescale
    public variable t0
    public variable t1
    public variable db {} {
	set dbsite [dblookup $db 0 site 0 0]
	set dbarrival [dblookup $db 0 arrival 0 0]
	set db $dbarrival
	set dborigin [dblookup $db 0 origin 0 0]
	set dbassoc [dblookup $db 0 assoc 0 0]
	dbcompile $db {Relation compute Fields (arrival origin site) ; }
	set dbcompute [dblookup $db 0 compute 0 dbSCRATCH]
    }

    public variable timeflag 1

    public variable sta_height 25
    public variable sta_width 150
    public variable arrival_width 50
    public variable max_height 800
    public variable max_width  800
    public variable Residual_delta 14
    public variable Orid -1

    protected variable scale_ids ""
    protected variable last_arrival_records ""
    protected variable Station_arrivals
    protected variable csta
    protected variable carr
    protected variable Xsv
    protected variable Ysv
    protected variable Xsta_cnt
    protected variable Xorder
    protected variable Yorder
    protected variable Tmin
    protected variable Tmax
    protected variable Xmin
    protected variable Xmax
    protected variable Ymin
    protected variable Ymax
    protected variable Ysta
    protected variable Ysta_cnt 0
    protected variable dscale
    protected variable tscale
    protected variable tscale_orig
    protected variable Xmin_orig
    protected variable Record
    protected variable Arid
    protected variable Arids
    protected variable x_anchor
    protected variable y_anchor
    protected variable dbsite
    protected variable dbarrival
    protected variable dborigin
    protected variable dbcompute
    protected variable dbassoc
    protected variable source_time 0
    protected variable source_lat 0
    protected variable source_lon 0
    protected variable max_distance
    protected variable Site
    protected variable Sta
    protected variable Lat
    protected variable Lon
    protected variable Arrows 
    protected variable ResidualTimes 
    protected variable mouse_mode
    protected variable old_bad_arids ""
    protected variable w
}

proc set_visual { array index operation } { 
    $index adjust_look
}

proc by_distance { r1 r2 } { 
    global ::Distance
    set delta [expr $Distance($r1) - $Distance($r2)]
    if { $delta < 0 } { return -1 } 
    if { $delta > 0 } { return  1 } 
    global ::Iphase
    if { [regexp P.* $Iphase($r1)] } { return -1 }  
    if { [regexp P.* $Iphase($r2)] } { return 2 }  
    return 0
}

proc mode_switch {type mode}  { 
    global ::Arrivals
    $Arrivals(display) config -$type $mode
    $Arrivals(display) display 
    if { $type == "xmode" } { 
	waveforms update
    }
}

proc fix_select { menu action} {
    global ::Tdb
    $menu delete 0 last
    set db [dblookup $Tdb 0 origin 0 0]
    set n [dbquery $db dbRECORD_COUNT]
    loop i 0 $n { 
	set orid [dbgetv $db 0 $i orid]
	if { $orid > 0 } {
	    $menu add command \
		-label $orid \
		-command "arrivals select_orid $orid $action"
	}
    }
}

proc fix_predict { menu } {
    global ::Tdb
    $menu delete 0 last
    set db [dblookup $Tdb 0 origin 0 0]
    set n [dbquery $db dbRECORD_COUNT]
    loop i 0 $n { 
	set orid [dbgetv $db 0 $i orid]
	if { $orid > 0 } {
	    $menu add command \
		-label $orid \
		-command "arrivals set_source orid $orid"
	}
    }
}


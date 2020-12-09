
proc assign_evids {} {
    global ::Tdb ::Define Db
    set dborigin [dblookup $Tdb 0 origin 0 0] 
    set n [dbquery $dborigin dbRECORD_COUNT]
    set evids ""
    # errlog report assign_evids "assigning evids for $n records"
    loop i 0 $n {
	set orid [dbgetv $dborigin 0 $i orid]
	# errlog report assign_evids "for record #$i orid=$orid"
	if { $orid < 1 } { continue }
	set evid [dbgetv $dborigin 0 $i evid]
	# errlog report assign_evids "for record #$i evid=$evid"
	set Evid($orid) $evid
	set Lat($orid) [dbgetv $dborigin 0 $i lat]
	set Lon($orid) [dbgetv $dborigin 0 $i lon]
	set Time($orid) [dbgetv $dborigin 0 $i time]
	if { $evid > 0 } {
	    if { ! [info exists Orid($evid)] } {
		set Orid($evid) $orid
		lappend evids $evid
	    } 
	} else { 
	    # errlog report assign_evids "existing evids are '$evids' "
	    foreach event $evids {
		set event_orid $Orid($event)
		set dtime [expr abs($Time($orid) - $Time($event_orid))]
		set distance [lindex [dbdist $Lat($orid) $Lon($orid) $Lat($event_orid) $Lon($event_orid)] 0]
		if { $dtime < $Define(max_event_time_difference) && $distance < $Define(max_event_delta) } {
		    set Evid($orid) $event
		    break 
		    }
	    }
	    # errlog report assign_evids "checking: evid=$evid orid=$orid Evid($orid)=$Evid($orid)"
	    if { $Evid($orid) < 1 } {
		set evid [dbnextid $Db evid]
		set Evid($orid) $evid
		set Orid($evid) $orid
		lappend evids $evid
	    }
	    origins set_evid $i $orid $Evid($orid)
	}
    }
}




    proc show_conflicting_events {} {
# This is supposed to show any arrivals which are associated with multiple
# events.
	global ::Tdb
	set bad_arids ""
	assign_evids

	set dborigin [dblookup $Tdb 0 origin 0 0]
	set n [dbquery $dborigin dbRECORD_COUNT]
	loop i 0 $n {
	    set orid [dbgetv $dborigin 0 $i orid]
	    if { $orid < 1 } { continue }
	    set evid [dbgetv $dborigin 0 $i evid]
	    set orid2evid($orid) $evid
	}

	set dbassoc [dblookup $Tdb 0 assoc 0 0]
	set n [dbquery $dbassoc dbRECORD_COUNT]
	loop i 0 $n {
	    set orid [dbgetv $dbassoc 0 $i orid]
	    if { [info exists orid2evid($orid)] } {
		set evid $orid2evid($orid)
		set arid [dbgetv $dbassoc 0 $i arid]
		if { [info exists arid2evid($arid)]
		    && $arid2evid($arid) != $evid } {
		    lappend bad_arids $arid
		    set bad_evid($evid) 1
		    set bad_evid($arid2evid($arid)) 1
		} else { 
		    set arid2evid($arid) $evid
		}
	    }
	}

	if { $bad_arids != "" } {
	    set evids [array names bad_evid]
	    set bad_arids [lrmdups $bad_arids]
	    errlog complain arrivals "evids $evids share arrivals $bad_arids"
	    set subset "arid=~/^([join $bad_arids {|}])/"
	    set dbt [dbsubset $dbassoc $subset]
	    set n [dbquery $dbt dbRECORD_COUNT]
	    set bad_orids [dbgetr $dbt 0 0 $n orid]
	    regsub -all \{ $bad_orids "" bad_orids
	    regsub -all \} $bad_orids "" bad_orids
	    set bad_orids [lrmdups $bad_orids]
	    dbfree $dbt
	} else {
	    set bad_orids ""
	}

	eval arrivals flag $bad_arids
	eval origins flag $bad_orids
    }
 


# $Id$ 


# This file should contain all of the proc's which relate to the 
# "Save" operation and windows

# creates a save button for the buttonbar
proc save_button {parent} {
    global ::Save ::State ::Define
    return [Buttonmenu $parent.#auto \
	-text Save \
	-command save \
    ]
}

# dispatches all save operations
proc save {args} { 
    global ::Save ::State ::Define

    set cmd [lindex $args 0]
    switch $cmd {
	init	{}
	summon	{summon .save_controls}
	dismiss {dismiss .save_controls}
	Controls {summon .save_controls}
	Save	{save_away }
	default	{ tkerror "bad command to Save" }
    }
}

proc mark_origins {reviewed orids} { 
    global Database
    if { [llength $orids] > 0 } { 
	append equal "orid == " [join $orids { || orid ==}]
	set cmd "dbset $Database.origin review $equal $reviewed"
	errlog report Save $cmd
	if { [catch {exec dbset $Database.origin review $equal $reviewed} result]} {
	    # actually ok: dbset returns 1 if something got set
	} else { 
	    errlog complain Save "trouble setting review field: $result"
	}
    }
}

proc reassoc {orid orid_record} { 
    errlog report reassoc "reassociating origin orid=$orid"
    set evid -1

    global OriginalTime Db Tdb
    set arrival_records [arrivals origin_arrival_records $orid]
    set dbarr [dblookup $Tdb 0 arrival 0 0]
    set dbassoc [dblookup $Db 0 assoc 0 dbSCRATCH]
    set dborigin [dblookup $Db 0 origin 0 dbSCRATCH]
    set dborigerr [dblookup $Db 0 origerr 0 dbSCRATCH]
    set sdobs 0
    set nass 0
    set ndef 0
    foreach i $arrival_records { 
	set time [dbgetv $dbarr 0 $i time]
	if { ! [info exists OriginalTime($i)] } {
	    set arid [dbgetv $dbarr 0 $i arid]
	    set sta [dbgetv $dbarr 0 $i sta]
	    set iphase [dbgetv $dbarr 0 $i iphase]
	    errlog report reassoc "No original time for arrival $arid $sta $iphase [strtime $time]"
	} else { 
	    set arid [dbgetv $dbarr 0 $i arid]
	    set sta [dbgetv $dbarr 0 $i sta]
	    set iphase [dbgetv $dbarr 0 $i iphase]
	    set arid_lddate [dbgetv $dbarr 0 $i lddate]
	    set delta [ expr $time - $OriginalTime($i) ] 
	    errlog report reassoc "time shifted $delta seconds for arrival $arid $sta $iphase [strtime $time]"
	    dbputv $dbassoc 0 dbSCRATCH arid $arid orid $orid
	    set matches [dbmatches $dbassoc $dbassoc assoc arid orid]
	    # errlog report reassoc "dbassoc = ($dbassoc) arid=$arid orid=$orid => matches=$matches"
	    foreach j $matches { 
		set timeres [dbgetv $dbassoc 0 $j timeres]
		set assoc_lddate [dbgetv $dbassoc 0 $j lddate]
		if { $arid_lddate > $assoc_lddate } { 
		    set timeres [expr $timeres+$delta]
		    errlog report reassoc "new timeres $timeres for arid $arid (record #$j)"
		    dbputv $dbassoc 0 $j timeres $timeres 
		}
		set timedef [dbgetv $dbassoc 0 $j timedef]
		if { "$timedef" == "d" } {
		    set sdobs [expr $sdobs + ($timeres*$timeres)]
		    incr ndef
		}
		incr nass
	    }
	}
    }
	
    dbputv $dborigin 0 dbSCRATCH orid $orid
    set matches [dbmatches $dborigin $dborigin origin orid]
    foreach j $matches { 
	set this_auth [dbgetv $dborigin 0 $j auth]
	set this_auth [lindex $this_auth 0]
	regsub -all -- --reassoc $this_auth {} this_auth
	set this_auth "$this_auth-reassoc"
	errlog report reassoc "changing auth for origin orid=$orid (record $j)"
	dbputv $dborigin 0 $j auth $this_auth nass $nass ndef $ndef
    }
	
    if { $ndef > 0 } { 
	set sdobs [expr sqrt($sdobs/$ndef)]
	dbputv $dborigerr 0 dbSCRATCH orid $orid
	set matches [dbmatches $dborigerr $dborigerr origerr orid]
	foreach j $matches { 
	    set old [dbgetv $dborigerr 0 $j sdobs]
	    errlog report reassoc "changing sdobs for origerr orid=$orid (record $j) from $old to $sdobs"
	    dbputv $dborigerr 0 $j sdobs $sdobs
	}
    }
}

proc save2pf {file name list} { 
    puts $file "$name  $list"
}

proc save_away {} {
    global ::Save ::State ::Define ::Tdb
# This needs to 
#	1) check for 
#		a) all events saved?
#		b) some origins saved?
#		c) 
# 	2) save all orids
#	3) delete all orids which must be deleted
#	4) clear displays?
    global ::Prefor ::Old_prefor
    global ::Db ::Tdb
    global  Trial

    set db [dblookup $Tdb 0 origin 0 0]
    save_state 
    if { [dbquery $db dbRECORD_COUNT] < 1 } { 
	return 0
    }
    thinking "saving results"
# don't try saving if these global variables are missing
    # if { ! [ info exists Prefor ] || ! [info exists Old_prefor] } { 
	# origins forget
	# return 0
    # }

    assign_evids 

    set orids ""
    set keepers [origins keepers]
    set reassocs [origins reassocs]
    set recalcs [origins recalcs]
    foreach i $keepers {
	set evid [dbgetv $Tdb origin $i evid]
	set orid [dbgetv $Tdb origin $i orid]
	if { [lsearch -exact $reassocs $orid] == -1 
	    && [lsearch -exact $recalcs $orid] == -1 } {
	    lappend orids $orid
	}
	set auth($orid) [dbgetv $Tdb origin $i auth]
	if { [info exists found($evid)] } {
	    if { $Prefor($evid) < 0 } {
		errlog dialog .abort Save "Please set the preferred origin for event #$evid" abort
		errlog report Save "No action taken"
		waiting
		return -1
	    }
	} else { 
	    set found($evid) 1
	}
    }

# on second time through keepers, make sure Prefor is set.
    foreach i $keepers {
	set evid [dbgetv $Tdb origin $i evid]
	set orid [dbgetv $Tdb origin $i orid]
	if { $Prefor($evid) < 0 || ! [info exists auth($Prefor($evid))] } { 
	    set Prefor($evid) $orid 
	} 
    }

    if { "$recalcs" != "" } { 
	set cmd "dbloc_delorids -k $Trial $recalcs"
	errlog report Save ": $cmd"
	catch {eval exec dbloc_delorids -k $Trial $recalcs 2>> $Define(Work_dir)/log } problems
	if { $problems != "" } { 
	    errlog complain Save $problems
	    waiting
	    return -1
	}
    }

# ignore license expiring messages
    if { "$orids" != "" } { 
	set cmd "dbloc_verify $Trial $orids"
	errlog report Save $cmd
	catch {eval exec dbloc_verify $Trial $orids 2> /dev/null } problems
	if { $problems != "" } { 
	    errlog complain Save $problems
	    waiting
	    return -1
	}
	errlog report Save "dbloc_verify is ok"
    }

    global Database
    if { "$reassocs" != "" } {
	# errlog report Save "doing reassocs"
	set reassoc_records [origins reassoc_records]
	set j 0
	foreach orid $reassocs { 
	    set orid_record [lindex $reassoc_records $j]
	    reassoc $orid $orid_record
	    incr j
	}
	set nreassoc [llength $reassocs]
	errlog report Save "reassociated $nreassoc origins ('$reassocs')"
    }
    
    set saved 0
    set savers [origins savers]
    thinking "saving origin records $savers"
    foreach i $savers {
	set evid [dbgetv $Tdb origin $i evid]
	set orid [dbgetv $Tdb origin $i orid]
	copy_origin $evid $orid $i
	incr saved
#	tkdialog .warning message "dbsplit for KMA eq. database is working" ok
#	exec kma_db &
    }

    set changed 0
    set new_events 0
    if { [info exists found] } {
	set evids [array names found]
	foreach evid $evids {
	    if { [info exists Old_prefor($evid)] } { 
		if { $Prefor($evid) != $Old_prefor($evid) } {
		    errlog report Save "setprefor $evid $Prefor($evid) $auth($Prefor($evid))"
		    send2dbloc setprefor $evid $Prefor($evid) $auth($Prefor($evid))
		    incr changed
	tkdialog .warning message "dbsplit for KMA eq. database is working" ok
	exec kma_db &
		}
	    } else { 
		if { [catch {dbaddv $Db event evid $evid prefor $Prefor($evid) auth $auth($Prefor($evid))} result] } {
		    errlog complain Save "failed to add event record for evid=$evid prefor=$Prefor($evid) auth=$auth($Prefor($evid)) : $result"
	tkdialog .warning message "dbsplit for KMA eq. database is working" ok
	exec kma_db &
		}
		incr new_events
	    }
	}
    }

    global Origins
    switch --  $Origins(reviewed)  {
	1	{ mark_origins  y $orids } 
	2	{ }
	3	{ mark_origins NULL $orids }
    }

    errlog report Save "Saved $saved origins with $new_events new events, changing $changed prefors"

    set deletions [origins deletions]
    set plain_deletions $deletions
    set ndeletions [llength $deletions]
    errlog report Save "deleting $ndeletions origins ('$deletions')"
    if { $deletions != "" || $recalcs != "" } { 
	global ::Database
	append deletions " -k $recalcs"

        # The deletions must be finished before going on to group, especially regroup
	set Save(deleted) 0
        # The eval is to ensure that there aren't extra curly brackets around the list of deletions
	eval send2dbloc delorids $deletions
	tkwait variable Save(deleted)

	errlog report Save "Deleted $ndeletions origins ($deletions)"
    }

    global ::User
    if { [info exists User(save_programs)] && [llength $User(save_programs) ] > 0 } { 
	set dborigin [dblookup $Tdb 0 origin 0 0]
	set save {}
	foreach record $savers { 
	    lappend save [dbgetv $dborigin 0 $record orid]
	}
	set pf $Define(Work_dir)/origin_save.pf
	set file [open $pf w]
	save2pf $file database $Database
	save2pf $file trial $Trial
	save2pf $file save $save
	save2pf $file delete $plain_deletions
	save2pf $file reassoc $reassocs
	save2pf $file chop $recalcs
	close $file
	foreach pgm $User(save_programs) { 
	    catch {eval exec $pgm $pf} problems 
	    if { $problems != "" } { 
		errlog complain Save "$pgm: $problems"
	    }
	}
    }

    arrivals forget
    origins forget
    waiting
    return 0
}

proc dbloc_delorids: {args} {
    global ::Save
    set Save(deleted) 1
}

proc dbcopy { dbin dbout } { 
    set dbin [lreplace $dbin 2 2 -501]
    set record [dbget $dbin]
    if { [catch {dbadd $dbout $record} result] } { 
	errlog complain Save "failed to copy record #$dbin '$record' : $result" 
    }
}

proc copy_origin {evid orid record} {  
    global ::Db ::Tdb
    errlog report Save "copying origin $evid $orid $record"
    set dbinput [dblookup $Tdb 0 origin 0 0]
    set dbinput [lreplace $dbinput 3 3 $record]
    set dboutput [dblookup $Db 0 origin 0 0]
    if { [dbgetv $dbinput 0 $record orid] == $orid } { 
	dbcopy $dbinput $dboutput
    } else {
	tkerror "bad copy_origin expected evid=$evid orid=$orid record=$record -- got orid=[dbgetv $dbinput 0 $record orid]"
	return
    }

    errlog report Save "copying matching assoc records for orid=$orid"
    set dbinput [dblookup $Tdb 0 assoc 0 0]
    set dboutput [dblookup $Db 0 assoc 0 0]
    loop i 0 [dbquery $dbinput dbRECORD_COUNT] { 
	if { [dbgetv $dbinput 0 $i orid] == $orid } { 
	    set dbinput [lreplace $dbinput 3 3 $i]
	    dbcopy $dbinput $dboutput
	    }
	}

    errlog report Save "copying matching origerr records for orid=$orid"
    set dbinput [dblookup $Tdb 0 origerr 0 0]
    set dboutput [dblookup $Db 0 origerr 0 0]
    loop i 0 [dbquery $dbinput dbRECORD_COUNT] { 
	if { [dbgetv $dbinput 0 $i orid] == $orid } { 
	    set dbinput [lreplace $dbinput 3 3 $i]
	    dbcopy $dbinput $dboutput
	    }
	}

    errlog report Save "copying matching emodel records for orid=$orid"
    set dbinput [dblookup $Tdb 0 emodel 0 0]
    set dboutput [dblookup $Db 0 emodel 0 0]
    loop i 0 [dbquery $dbinput dbRECORD_COUNT] { 
	if { [dbgetv $dbinput 0 $i orid] == $orid } { 
	    set dbinput [lreplace $dbinput 3 3 $i]
	    dbcopy $dbinput $dboutput
	    }
	}

    errlog report Save "copying matching predarr records for orid=$orid"
    set dbinput [dblookup $Tdb 0 predarr 0 0]
    set dboutput [dblookup $Db 0 predarr 0 0]
    loop i 0 [dbquery $dbinput dbRECORD_COUNT] { 
	if { [dbgetv $dbinput 0 $i orid] == $orid } { 
	    set dbinput [lreplace $dbinput 3 3 $i]
	    dbcopy $dbinput $dboutput
	    }
	}

    set dbinput [dblookup $Tdb 0 netmag 0 0]
    set dboutput [dblookup $Db 0 netmag 0 0]
    set nnetmag [dbquery $dbinput dbRECORD_COUNT]
    errlog report Save "copying matching netmag records for orid=$orid: nnetmag = $nnetmag"
    loop i 0 $nnetmag { 
	if { [catch {dbgetv $dbinput 0 $i orid} result] } { 
	    errlog complain Save "failed to get orid from record #$i of netmag table: $nnetmag records"
	} elseif { $result == $orid } { 
	    set dbinput [lreplace $dbinput 3 3 $i]
	    dbcopy $dbinput $dboutput
	}
    }

    errlog report Save "copying matching stamag records for orid=$orid"
    set dbinput [dblookup $Tdb 0 stamag 0 0]
    set dboutput [dblookup $Db 0 stamag 0 0]
    loop i 0 [dbquery $dbinput dbRECORD_COUNT] { 
	if { [dbgetv $dbinput 0 $i orid] == $orid } { 
	    set dbinput [lreplace $dbinput 3 3 $i]
	    dbcopy $dbinput $dboutput
	    }
	}

    errlog report Save "copying matching commid records for orid=$orid"
    set commid [dbgetv $dbinput origin $record commid] 
    set dbinput [dblookup $Tdb 0 remark 0 0]
    set dboutput [dblookup $Db 0 remark 0 0]
    loop i 0 [dbquery $dbinput dbRECORD_COUNT] { 
	if { [dbgetv $dbinput 0 $i commid] == $commid } { 
	    set dbinput [lreplace $dbinput 3 3 $i]
	    dbcopy $dbinput $dboutput
	    }
	}
}

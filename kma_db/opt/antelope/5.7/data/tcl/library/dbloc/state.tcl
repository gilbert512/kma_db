
# dbloc keeps a set of "state" variables which change dynamically, 
# and need to be periodically saved and then restored during startup.
# The plan for these variables is to use a parameter file
# to save and restore the state.  Initial values of the state parameters
# will come from dbloc's parameter file.


proc pfload { var pf } { 
    global $var
    pfgetarr $var $pf 
    foreach i [array names $var] {
	eval set value \$[set var]($i)
	switch -glob -- $value {
	    @*	{ set [set var]($i) [pfgetlist $value] }
	    %*	{ global $i ; pfload $i $value } 
	}
    }
}


proc pfdump1 { var file flag} { 
    global $var
    set PFDUMPED($var) 1
    if { $flag > 0 } {
	puts $file "$var	&Arr\{"
	}
    foreach i [array names $var] {
	global $i
	set names [array names $i]
	if { [llength $names] == 0 } {
	    eval puts $file \"\$i	\$[set var]($i)\" 
	} else {
	    pfdump1 $i $file 1
	}
    }
    if { $flag > 0 } { 
	puts $file "\}"
    }
}

proc pfdump { var file flag} { 
    global $var
    global PFDUMPED
    if { [info exists PFDUMPED($var)] } { return }
    set PFDUMPED($var) 1
    if { $flag > 0 } {
	puts $file "$var	&Arr\{"
	}
    foreach i [array names $var] {
	global $i
	set names [array names $i]
	if { [llength $names] == 0 } {
	    eval puts $file \"\$i	\$[set var]($i)\" 
	} else {
	    pfdump1 $i $file 1
	}
    }
    if { $flag > 0 } { 
	puts $file "\}"
    }
    unset PFDUMPED
}

proc save_state {} {
    global Statefile 
    global State
    set file [open $Statefile w]
    pfdump State $file 1
    close $file
}

proc load_state {} {
    global Statefile env
    if { [ info exists env(PFPATH) ] } { 
	set save $env(PFPATH)
    }
    set env(PFPATH) tmp

    if {[file exists $env(PFPATH)/state.pf]} { 
	if { [catch "pfload GLOBAL state" result] } { 
	    puts stderr "error loading state: $result"
	}
    } else { 
	global State
	global Db
	set db [dblookup $Db 0 arrival 0 0]
	set db [dbsubset $db iphase!="del"&&time!=NULL]
	# puts stderr "about to evaluate  min(time) for db=$db"
	set State(current_start_time) [dbeval $db min(time)]
	# puts stderr "min(time) is $State(current_start_time)"
	set State(next_start_time) $State(current_start_time)
    }

    if { [info exists save] } { 
	set env(PFPATH) $save
    } else {
	unset env(PFPATH) 
    }
    global State
    set State(old_orids) {}
    set State(old_evids) {}
}


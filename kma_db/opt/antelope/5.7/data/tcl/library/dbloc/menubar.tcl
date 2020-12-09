
proc report_bug {} {
    global Database
    catch {exec dbloc_report_bug $Database {Please describe the problem and how to reproduce it} {}}
}

proc menubar w {
    global Define Database

    frame $w -borderwidth 1 -relief raised -pady 2
    set parent [winfo parent $w]
    blt::table $parent \
	$w  0,0	-columnspan $Define(maxcol) -anchor w -fill x

    menubutton $w.file -text File -underline 0 -menu $w.file.menu -padx 2 -pady 1
    menu $w.file.menu -tearoff 0

    $w.file.menu add command \
	-label Quit \
	-command quit

    $w.file.menu add command \
	-label "Quit without saving" \
	-command quit_without_saving

    menubutton $w.view -text View -underline 0 -menu $w.view.menu -padx 2 -pady 1
    menu $w.view.menu -tearoff 0

    $w.view.menu add command \
	-label "View dbloc2 status message log" \
	-command "tailFile {dbloc2 status} Status tmp/logger destroy"

    $w.view.menu add command \
	-label "View dbloc2 IPC" \
	-command "tailFile {dbloc2 interprocess log} IPC tmp/log destroy"

    pack $w.file $w.view -side left 

    menubutton $w.help -text Help -underline 0 -menu $w.help.menu -pady 1
    menu $w.help.menu -tearoff 0
    global ::Program ::Version ::Date
    $w.help.menu add command \
	-label "About $Program" \
	-command "about $Program $Version \{$Date\}"

    $w.help.menu add separator

    $w.help.menu add command \
	-label "Host:  [id host]" \
	-state disabled 
    $w.help.menu add command \
	-label "Who:   [id user]" \
	-state disabled 
    $w.help.menu add command \
	-label "Where: [pwd]" \
	-state disabled 

    pack $w.help -side right

}



# $Id$ 



proc dbloc_window {w} {
    global Define 

    toplevel $w
    menubar $w.menubar

    button $w.dismiss -text Dismiss -command "dismiss $w"
    blt::table $w \
	$w.dismiss $Define(maxrow),0 -anchor center -fill x -columnspan $Define(maxcol)
    
    buttonbar $w.buttonbar
	
}

# $Id$ 

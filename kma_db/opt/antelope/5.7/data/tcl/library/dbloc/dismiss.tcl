
proc dismiss w { 
    wm withdraw $w
}

proc summon w {
    wm deiconify $w
    blt::winop raise $w
}


# $Id$ 


# dbloc_buttons will communicate with other processes two different
# ways:
#	1) by writing to stdout, which will be read by dbloc
#	2) using tksend to talk with dbpick

proc send2dbloc {args} { 
    puts $args
    flush stdout
}


# $Id$ 

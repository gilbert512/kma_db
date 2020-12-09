
proc dbgenloc_options {} {
    set w .dbgenloc
    if { [winfo exists $w] } { 
	wm deiconify $w
	blt::winop raise $w
	return
    } 

    global dbgenloc

    if { ! [info exists dbgenloc(Already-Initialized)] } {
	dbgenloc_default
    }

    global Color

    toplevel $w
    wm title $w "Pf dbgenloc"
    wm iconname $w "Pf dbgenloc"

    label $w.weights \
	-text "Weights" \
	-bg $Color(disabledForeground) 

    SelectorButton $w.arrival_residual_weight_method \
	-text "Arrival residual weight method" \
	-options {huber none thomson bisquare} \
	-variable dbgenloc(arrival_residual_weight_method) 


    SelectorButton $w.slowness_residual_weight_method \
	-text "Slowness residual weight method" \
	-options {huber none thomson bisquare} \
	-variable dbgenloc(slowness_residual_weight_method) 

    checkbutton $w.time_distance_weighting \
	-anchor w \
	-variable dbgenloc(time_distance_weighting) \
	-text "Time distance weighting"

    SelectorButton $w.generalized_inverse \
	-text "Generalized inverse" \
	-options {pseudoinverse marquardt} \
	-variable dbgenloc(generalized_inverse)

    checkbutton $w.recenter \
	-anchor w \
	-variable dbgenloc(recenter) \
	-onvalue yes \
	-offvalue no \
	-text "estimate origin time by recenter procedure"


    checkbutton $w.slowness_distance_weighting \
	-anchor w \
	-variable dbgenloc(slowness_distance_weighting) \
	-text "Slowness distance weighting"


    scale $w.slowness_weight_scale_factor \
	-label "Slowness weight scale factor" \
	-from 0.0 -to 2.0 \
	-resolution 0.1 \
	-orient horizontal \
	-variable dbgenloc(slowness_weight_scale_factor)


    label $w.starting_Location \
	-text "Starting Location" \
	-bg bisque2 

    checkbutton $w.fix_latitude \
	-anchor w \
	-variable dbgenloc(fix_latitude) \
	-text "Fix latitude"


    checkbutton $w.fix_longitude \
	-anchor w \
	-variable dbgenloc(fix_longitude) \
	-text "Fix longitude"


    checkbutton $w.fix_origin_time \
	-anchor w \
	-variable dbgenloc(fix_origin_time) \
	-text "Fix origin time"


    SelectorButton $w.initial_location_method \
	-text "Initial location method" \
	-options {manual rectangle_gridsearch radial_gridsearch nearest_station S-Ptime} \
	-variable dbgenloc(initial_location_method) 



    button $w.gsopts -text "Gridsearch options" -command "grid_setup"
    button $w.default -text Default -command "dbgenloc_default" 
    button $w.dismiss -text Dismiss -command "wm withdraw $w" -bg red -fg white

    set col 0
    set row 0
    blt::table $w \
	$w.weights [incr row],$col -fill x -anchor w \
	$w.arrival_residual_weight_method [incr row],$col -fill x -anchor w \
        $w.time_distance_weighting [incr row],$col -fill x -anchor w\
	$w.slowness_residual_weight_method [incr row],$col -fill x -anchor w \
	$w.slowness_distance_weighting [incr row],$col -fill x -anchor w \
	$w.slowness_weight_scale_factor [incr row],$col -rowspan 2 -fill x -anchor w \
        $w.starting_Location  [set row 1],[incr col] -fill x -anchor w \
	$w.starting_Location [incr row],$col -fill x -anchor w \
	$w.fix_latitude [incr row],$col -fill x -anchor w \
	$w.fix_longitude [incr row],$col -fill x -anchor w \
	$w.fix_origin_time [incr row],$col -fill x -anchor w \
	$w.generalized_inverse [incr row],$col -fill x -anchor w \
	$w.recenter [incr row],$col -fill x -anchor nw \
	$w.initial_location_method [incr row],$col -fill x -anchor w \
	$w.gsopts [incr row],$col -fill x -anchor w \
	$w.default	20,0 -fill x \
	$w.dismiss	20,1 -cspan 10 -fill x

}
proc grid_setup {} {
	global dbgenloc
	set w .gridsearch

	if { [winfo exists $w]  } {
        wm deiconify $w
        blt::winop raise $w
        return
    }

    toplevel $w
    wm title $w "Gridsearch Options"
    wm iconname $w "Gridsearch Options"

    SelectorButton $w.gridsearch_norm \
	-text "Gridsearch norm" \
	-options {raw weighted_rms} \
	-variable dbgenloc(gridsearch_norm) 


    LblEntry $w.center_latitude \
	-label "Center latitude" \
	-textvariable dbgenloc(center_latitude) 


    LblEntry $w.center_longitude \
	-label "Center longitude" \
	-textvariable dbgenloc(center_longitude) 


    LblEntry $w.center_depth \
	-label "Center depth" \
	-textvariable dbgenloc(center_depth) 


    LblEntry $w.depth_range \
	-label "Depth range" \
	-textvariable dbgenloc(depth_range) 


    LblEntry $w.ndepths \
	-label "Ndepths" \
	-textvariable dbgenloc(ndepths) 


    label $w.rectangle_Gridsearch \
	-text "Rectangle Gridsearch" \
	-bg bisque2 

    LblEntry $w.latitude_range \
	-label "Latitude range" \
	-textvariable dbgenloc(latitude_range) 


    LblEntry $w.nlat \
	-label "Nlat" \
	-textvariable dbgenloc(nlat) 


    LblEntry $w.longitude_range \
	-label "Longitude range" \
	-textvariable dbgenloc(longitude_range) 


    LblEntry $w.nlon \
	-label "Nlon" \
	-textvariable dbgenloc(nlon) 


    label $w.radial_Gridsearch \
	-text "Radial Gridsearch" \
	-bg bisque2 

    LblEntry $w.minimum_distance \
	-label "Minimum distance" \
	-textvariable dbgenloc(minimum_distance) 


    LblEntry $w.maximum_distance \
	-label "Maximum distance" \
	-textvariable dbgenloc(maximum_distance) 


    LblEntry $w.number_points_r \
	-label "Number points r" \
	-textvariable dbgenloc(number_points_r) 


    LblEntry $w.minimum_azimuth \
	-label "Minimum azimuth" \
	-textvariable dbgenloc(minimum_azimuth) 


    LblEntry $w.maximum_azimuth \
	-label "Maximum azimuth" \
	-textvariable dbgenloc(maximum_azimuth) 


    scale $w.number_points_azimuth \
	-label "Number points azimuth" \
	-from 10 -to 360 \
	-resolution 0 \
	-orient horizontal \
	-variable dbgenloc(number_points_azimuth)

    button $w.dismiss -text Dismiss -command "wm withdraw $w" -bg red -fg white

    set col 0
    set row 0
    blt::table $w \
        $w.gridsearch_norm [incr row],$col -fill x -anchor w \
        $w.center_latitude [incr row],$col -fill x -anchor w \
        $w.center_longitude [incr row],$col -fill x -anchor w \
        $w.center_depth [incr row],$col -fill x -anchor w \
        $w.depth_range [incr row],$col -fill x -anchor w \
        $w.ndepths [incr row],$col -fill x -anchor w \
        $w.rectangle_Gridsearch [set row 1],[incr col] -fill x -anchor w \
        $w.latitude_range [incr row],$col -fill x -anchor w \
        $w.nlat [incr row],$col -fill x -anchor w \
        $w.longitude_range [incr row],$col -fill x -anchor w \
        $w.nlon [incr row],$col -fill x -anchor w \
        $w.radial_Gridsearch [set row 1],[incr col] -fill x -anchor w \
        $w.minimum_distance [incr row],$col -fill x -anchor w \
        $w.maximum_distance [incr row],$col -fill x -anchor w \
        $w.number_points_r [incr row],$col -fill x -anchor w \
        $w.minimum_azimuth [incr row],$col -fill x -anchor w \
        $w.maximum_azimuth [incr row],$col -fill x -anchor w \
        $w.number_points_azimuth [incr row],$col -fill x -anchor w \
        $w.dismiss	20,1 -cspan 10 -fill x

}
proc dbgenloc_pf {} {
    global dbgenloc


    if { ! [info exists dbgenloc(Already-Initialized)] } {
	dbgenloc_default
    }

    global Locate
    if { $Locate(origin_time) > 0 } { 
	append pf "initial_origin_time	$Locate(origin_time)\n"
    } else {
	append pf "initial_origin_time	$Locate(first_arrival_time)\n"
    }
    append pf "deltax_convergence_size	$dbgenloc(deltax_convergence_size)\n"
    append pf "relative_rms_convergence_value	$dbgenloc(relative_rms_convergence_value)\n"
    append pf "generalized_inverse	$dbgenloc(generalized_inverse)\n"
    append pf "depth_ceiling	$dbgenloc(depth_ceiling)\n"
    append pf "depth_floor	$dbgenloc(depth_floor)\n"
    append pf "recenter	$dbgenloc(recenter)\n"
    append pf "min_error_scale	$dbgenloc(min_error_scale)\n"
    append pf "max_error_scale	$dbgenloc(max_error_scale)\n"
    append pf "min_relative_damp	$dbgenloc(min_relative_damp)\n"
    append pf "max_relative_damp	$dbgenloc(max_relative_damp)\n"
    append pf "damp_adjust_factor	$dbgenloc(damp_adjust_factor)\n"
    append pf "singular_value_cutoff	$dbgenloc(singular_value_cutoff)\n"
    append pf "step_length_scale_factor	$dbgenloc(step_length_scale_factor)\n"
    append pf "min_step_length_scale	$dbgenloc(min_step_length_scale)\n"
    append pf "arrival_residual_weight_method	$dbgenloc(arrival_residual_weight_method)\n"
    append pf "slowness_residual_weight_method	$dbgenloc(slowness_residual_weight_method)\n"
    append pf "time_distance_weighting	$dbgenloc(time_distance_weighting)\n"
    append pf "slowness_distance_weighting	$dbgenloc(slowness_distance_weighting)\n"
    append pf "slowness_weight_scale_factor	$dbgenloc(slowness_weight_scale_factor)\n"
    append pf "fix_latitude	$dbgenloc(fix_latitude)\n"
    append pf "fix_longitude	$dbgenloc(fix_longitude)\n"
    append pf "fix_origin_time	$dbgenloc(fix_origin_time)\n"

    if { $Locate(use_starting_location) } {
	append pf "initial_location_method	manual\n"
    } else { 
	append pf "initial_location_method	$dbgenloc(initial_location_method)\n"
    }
    append pf "gridsearch_norm	$dbgenloc(gridsearch_norm)\n"
    append pf "center_latitude	$dbgenloc(center_latitude)\n"
    append pf "center_longitude	$dbgenloc(center_longitude)\n"
    append pf "center_depth	$dbgenloc(center_depth)\n"
    append pf "depth_range	$dbgenloc(depth_range)\n"
    append pf "ndepths	$dbgenloc(ndepths)\n"
    append pf "latitude_range	$dbgenloc(latitude_range)\n"
    append pf "nlat	$dbgenloc(nlat)\n"
    append pf "longitude_range	$dbgenloc(longitude_range)\n"
    append pf "nlon	$dbgenloc(nlon)\n"
    append pf "minimum_distance	$dbgenloc(minimum_distance)\n"
    append pf "maximum_distance	$dbgenloc(maximum_distance)\n"
    append pf "number_points_r	$dbgenloc(number_points_r)\n"
    append pf "minimum_azimuth	$dbgenloc(minimum_azimuth)\n"
    append pf "maximum_azimuth	$dbgenloc(maximum_azimuth)\n"
    append pf "number_points_azimuth	$dbgenloc(number_points_azimuth)\n"
    append pf "maximum_hypocenter_adjustments 100\n"
    append pf "confidence	$dbgenloc(confidence)\n"
    append pf "ellipse_type	$dbgenloc(ellipse_type)\n"

    return $pf
}

proc dbgenloc_default {} {
    global dbgenloc

    set pf dbgenloc_default
    pfread $pf
    set dbgenloc(deltax_convergence_size) [pfget $pf deltax_convergence_size]
    set dbgenloc(relative_rms_convergence_value) [pfget $pf relative_rms_convergence_value]
    set dbgenloc(generalized_inverse) [pfget $pf generalized_inverse]
    set dbgenloc(depth_ceiling) [pfget $pf depth_ceiling]
    set dbgenloc(depth_floor) [pfget $pf depth_floor]
    set dbgenloc(recenter) [pfget $pf recenter]
    set dbgenloc(min_error_scale) [pfget $pf min_error_scale]
    set dbgenloc(max_error_scale) [pfget $pf max_error_scale]
    set dbgenloc(min_relative_damp) [pfget $pf min_relative_damp]
    set dbgenloc(max_relative_damp) [pfget $pf max_relative_damp]
    set dbgenloc(damp_adjust_factor) [pfget $pf damp_adjust_factor]
    set dbgenloc(singular_value_cutoff) [pfget $pf singular_value_cutoff]
    set dbgenloc(step_length_scale_factor) [pfget $pf step_length_scale_factor]
    set dbgenloc(min_step_length_scale) [pfget $pf min_step_length_scale]
    set dbgenloc(arrival_residual_weight_method) [pfget $pf arrival_residual_weight_method]
    set dbgenloc(slowness_residual_weight_method) [pfget $pf slowness_residual_weight_method]
    set dbgenloc(time_distance_weighting) [pfget $pf time_distance_weighting]
    set dbgenloc(slowness_distance_weighting) [pfget $pf slowness_distance_weighting]
    set dbgenloc(slowness_weight_scale_factor) [pfget $pf slowness_weight_scale_factor]
    set dbgenloc(fix_latitude) [pfget $pf fix_latitude]
    set dbgenloc(fix_longitude) [pfget $pf fix_longitude]
    set dbgenloc(fix_origin_time) [pfget $pf fix_origin_time]
    set dbgenloc(initial_location_method) [pfget $pf initial_location_method]
    set dbgenloc(gridsearch_norm) [pfget $pf gridsearch_norm]
    set dbgenloc(center_latitude) [pfget $pf center_latitude]
    set dbgenloc(center_longitude) [pfget $pf center_longitude]
    set dbgenloc(center_depth) [pfget $pf center_depth]
    set dbgenloc(depth_range) [pfget $pf depth_range]
    set dbgenloc(ndepths) [pfget $pf ndepths]
    set dbgenloc(latitude_range) [pfget $pf latitude_range]
    set dbgenloc(nlat) [pfget $pf nlat]
    set dbgenloc(longitude_range) [pfget $pf longitude_range]
    set dbgenloc(nlon) [pfget $pf nlon]
    set dbgenloc(minimum_distance) [pfget $pf minimum_distance]
    set dbgenloc(maximum_distance) [pfget $pf maximum_distance]
    set dbgenloc(number_points_r) [pfget $pf number_points_r]
    set dbgenloc(minimum_azimuth) [pfget $pf minimum_azimuth]
    set dbgenloc(maximum_azimuth) [pfget $pf maximum_azimuth]
    set dbgenloc(number_points_azimuth) [pfget $pf number_points_azimuth]
    set dbgenloc(confidence) [pfget $pf confidence]
    set dbgenloc(ellipse_type) [pfget $pf ellipse_type]
    set dbgenloc(Already-Initialized) 1 
}

# $Id$ 

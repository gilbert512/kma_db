: # use perl
eval 'exec $ANTELOPE/bin/perl -S $0 "$@"'
if 0;

use lib "$ENV{ANTELOPE}/data/perl" ;

# modifyed by CH.YUK, 2019.10.14 - getopt function call change
# modifyed by Gilbert, 2020.08.14 - arrival.sh with sendforwarn work
# modifyed by Gilbert 2020.09.08 - change for sendforwarn
# modifyed by Gilbert 2020.10.15 - change for for_eqdb
#require "getopts.pl" ;
use Getopt::Std ;

use Datascope ;
use Sys::Hostname;
use File::Copy;

#added in 20150128
use POSIX;
use File::Spec::Functions;

$LOGFILE;

sub logit_init
{
	$dirname  = shift;
	$filename = shift;

	mkdir $dirname unless -d $dirname;

	open $LOGFILE, ">>", catfile($dirname, $filename) or die "$!";

	print $LOGFILE "-------------------------------------------------\n";
	print $LOGFILE "startup at UTC_", strftime "%Y%m%d_%H:%M:%S", gmtime(time);
	print $LOGFILE "\n";
	print $LOGFILE "-------------------------------------------------\n";
	print $LOGFILE "\n";
}

sub logit
{
	$str = shift;

	print $LOGFILE strftime "%Y%m%d_UTC_%H:%M:%S", gmtime(time);
	print $LOGFILE " ", $str, "\n";
}

sub logit_close
{
	print $LOGFILE "\n";
	print $LOGFILE "all done ----------------------------------------\n";
	close $LOGFILE;
}
#end of addition

chomp( $host );
 
$program = `basename $0`;
chomp( $program );

#if ( ! &Getopts('sc:a:') || @ARGV != 1 ) {
if ( ! getopts('sc:a:') || @ARGV != 1 ) {
	print " \n";
	print " Usage   : $program ORID_NO \n";
	print " Example : $program  3234 \n";
	die ( "\n" );
} else {
	$orid = pop( @ARGV );
}

$host = hostname;
chomp( $host );

($name,$pwcode,$uid,$gid,$quota,$comment,$gcos,$home,$logprog) = getpwnam("rt");

chomp($home);
$dbname_o ="$home/knsn/db/knsn";
chomp($dbname_o);
$dbname ="$home/knsn/db/tmp/trial";
chomp($dbname);
$out = "arrival.temp";
$save_dir = "$home/knsn/Arrivals";
chomp($save_dir);
$save_db_dir = "$home/knsn/pick_db";
chomp($save_db_dir);
$save_db_dir1 = "$home/knsn/for_eqdb";
chomp($save_db_dir1);
$now = `epoch now`;
$year = epoch2str( $now,"%Y");
$day_o = epoch2str( $now,"%m%d");

$msave ="$home/knsn/miniseed";
$archive_d = "$home/knsn/Archive";
chomp($msave);

if (-f $out) {
unlink < $out >;
} 

@db = dbopen( $dbname, "r" );

@db = dblookup( @db, "", "event", "", "" );
if( dbquery( @db, "dbTABLE_PRESENT" ) ) {
	@dbt = dblookup( @db, "", "origin", "", "" );
	@db = dbjoin( @db, @dbt );
} else {
	@db = dblookup( @db, "", "origin", "", "" );
	if( dbquery( @db, "dbRECORD_COUNT" ) <= 0 ) {
		die( "$program: no hypocenters in $dbname\n" );
	} 
} 

if( dbquery( @db, "dbRECORD_COUNT" ) <= 0 ) {
	print "$program: no qualifying hypocenters in $dbname\n";
	exit( 0 );
} 

@dbt = dblookup( @db, "", "assoc", "", "" );
@db = dbjoin( @db, @dbt );
if( dbquery( @db, "dbRECORD_COUNT" ) <= 0 ) {
	die( "$program: no arrival associations for hypocenters in $dbname\n" );
} 

@dbt = dblookup( @db, "", "arrival", "", "" );
@db = dbjoin( @db, @dbt );
if( dbquery( @db, "dbRECORD_COUNT" ) <= 0 ) {
	die( "$program: no arrivals for hypocenters in $dbname\n" );
}
@db = dbsubset( @db, "orid==$orid" );
if( dbquery( @db, "dbRECORD_COUNT" ) <= 0 ) {
                die( "$program: no hypocenters for events in $dbname\n" );
     }

@db = dbsort( @db, "origin.time", "sta", "iphase" );
$nrecs = dbquery( @db, "dbRECORD_COUNT" );

@dbm = dblookup( @db, "", "stamag", "", "" );
if( dbquery( @dbm, "dbRECORD_COUNT" ) <= 0 ) {
        die( "$program: no netmag associations for hypocenters in $dbname\n" );
}

@dbm = dbsubset( @dbm, "orid==$orid");
$nstamag = dbquery( @ dbm, "dbRECORD_COUNT" );

$db[3] =0;


open (MYFILE,">$out") || die("Can't open $out");
if($nrecs>0)
{
   print MYFILE " \n";
   print  MYFILE sprintf( "------------------Earthquake Information------------------- \n");
   ( $evid ) = dbgetv( @db, "evid" );
   ( $origintime, $auth ) = dbgetv( @db, "origin.time", "origin.auth" );
   ( $lat, $lon, $depth, $ml ) = dbgetv( @db, "lat", "lon", "depth", "ml" );

   print MYFILE sprintf( "	Time  : %s (UTC) \n",epoch2str( $origintime, "%Y-%m-%d %H:%M:%S.%s"));
   print MYFILE sprintf( "	Time  : %s (KST) \n",epoch2str( $origintime + 32400.0, "%Y-%m-%d %H:%M:%S.%s"));
   print MYFILE sprintf( "	LAT   : %.4f\n", abs( $lat ) );
   print MYFILE sprintf( "	LONG  : %.4f\n", abs( $lon ) );
   print MYFILE sprintf( "	DEPTH : %.1f \n", $depth );
   print MYFILE sprintf( "	MAG   : %.1f ML.\n", $ml );
   print MYFILE sprintf( "	Auth  : %s \n", $auth );
   print MYFILE sprintf( "	Evid  : %i \n", $evid );
   print MYFILE sprintf( "	Orid  : %i \n\n", $orid );
   print MYFILE sprintf( "------------------------- By aNmain2 ------------------------  \n");
   print MYFILE " \n";
   print MYFILE sprintf( " STA CHA    YYYY-MM-DD hh:mm:ss(UTC)  ML      MB  hh:mm:ss(UTC)  S-P \n");
   print MYFILE " \n";

   my $dsta = "     ";
   my $first_p = 1000000000000000.0;
   my $fsta = "     ";

   for( $db[3] = 0; $db[3] < $nrecs; $db[3]++ ) 
   {
	( $sta, $chan, $iphase, $arrtime ) = dbgetv( @db, "sta", "chan", "iphase", "arrival.time" );
	if ( $iphase eq "mb" ) { next; }
	if ( $sta ne $dsta )
        {
		
   		print MYFILE " \n";
		print MYFILE sprintf( "%-4s %-4s %s ", $sta, $chan, $iphase );
        	print MYFILE epoch2str( $arrtime, "%Y-%m-%d %H:%M:%S.%s " );

		@dbt = dbsubset( @dbm, "sta=='$sta' && magtype=='ml'" );
		$nsta = dbquery( @dbt, "dbRECORD_COUNT" );
		if($nsta>0)
		{
	  		$dbt[3]=0;
	  		( $magnitude ) = dbgetv( @dbt, "magnitude" );
	  		print MYFILE sprintf( "/ ml %.1f ", $magnitude);
		}

		@dbt = dbsubset( @dbm, "sta=='$sta' && magtype=='mb'" );
                $nsta = dbquery( @dbt, "dbRECORD_COUNT" );
		if($nsta>0)
                {
                        $dbt[3]=0;
                        ( $magnitude ) = dbgetv( @dbt, "magnitude" );
                        print MYFILE sprintf( " mb %.1f ", $magnitude);
                }


	    	$dsta = $sta;
		$ptime = $arrtime;
		if( $first_p > $arrtime ) { 
                        $first_p = $arrtime; 
                        $fsta = $sta ;
     		}
	}
	else
        {
		print MYFILE sprintf( "/ %s ", $iphase );
        	print MYFILE epoch2str( $arrtime, "%H:%M:%S.%s");
		print MYFILE sprintf( "  %.2f ", $arrtime - $ptime);
	}

   }
   print MYFILE sprintf(" \n \n");
   print MYFILE sprintf(" \n \n");
   print MYFILE sprintf(" First P wave - Origin time : %s %.2f sec.\n", $fsta, $first_p-$origintime);
   print MYFILE sprintf(" \n \n");
}
close(MYFILE);


if (-e "$save_dir/arrival.orid_$orid.$year.$day_o.$host" ) {
    print "\n";
    print "\n";
    print "  ************ ARRIVAL FILE NOT SAVED ****************************************  \n";
    print "    Because a file you requested has ALREADY been on a directory of ~/Arrivals. \n";
    print "  ***************************************************************************** \n";
    print "\n";
    print "\n";
} else {

    if (-e "location_output") {
	copy( "location_output", "$save_dir/location.orid_$orid.$year.$day_o.$host");
    } else {
	print "Can't find location_output\n";
    }

    if (-e "rundbevproc.magnitude") {
	copy( "rundbevproc.magnitude", "$save_dir/magnitude.orid_$orid.$year.$day_o.$host");
    } else {
	print "Can't find rundbevproc.magnitude\n";
    }

    if(-e "$out") {
    	open (F,"$out") || die("Can't open $out");
    	@mullines = <F>;
    	close(F);
    	print @mullines;

	copy( "$out", "$save_dir/arrival.orid_$orid.$year.$day_o.$host" );
    } else {
	print " Can't fine $out \n";
    }


    print "\n";
    print "  ------------------------------------------------------------------------------------- \n";
    print "    Saved to a file; arrival.orid_$orid.$year.$day_o.$host on a directory of ~/Arrivals.       \n";
    print "  ------------------------------------------------------------------------------------- \n";
    print "\n";
}



if (-f "$out") {
unlink < $out >;
}

if (-f "location_output") {
unlink < location_output >;
}

$fname = epoch2str( $origintime, "%Y_%m_%d_%H_%M_%S");
chomp($fname);
$ffname = sprintf("__%.4f_%.4f_%.1f__%s",$lat, $lon, $ml, $host);
chomp($ffname);

$getstart = $origintime-180.0;

$orig = sprintf("%s", epoch2str( $origintime, "%Y_%m_%d_%H_%M_%S"));
chomp($orig);

system("streamfilecut $getstart $fname $ffname &");

print "dbsplit -s 'orid==$orid' $dbname $save_db_dir/knsn_$orid_$orig \n";
#exec "dbsplit -s 'orid==$orid' $dbname $save_db_dir/knsn_$orid_$orig";
system("dbsplit -s 'orid==$orid' $dbname $save_db_dir/knsn_$orid_$orig");
#system("dbsplit -p /home/rt/knsn/pf/dbsplit.pf -s 'orid==$orid' $dbname $save_db_dir1/knsn_$orid");
system("echo '$orid' > $save_db_dir1/orid");

$ot = epoch2str( $origintime, "%Y-%m-%d %H:%M:%S");
$sdir = epoch2str( $origintime, "%Y%m%d%H%M%S");

$getstart = $origintime-60.0;
$trim_window = 360;

if(-d "$msave/$sdir$orid" ) {
 print "\n\n Already find directory of $msave/$sdir$orid \n";
 exit(0);
}
else
{
 print "mkdir $msave/$sdir$orid \n";
 system("mkdir $msave/$sdir$orid");
}

print "Please wait minute \n\n";

print  "trexcerpt -m time -o sd -c \"chan=='HHZ' ||chan=='HHN' || chan=='HHE' || chan=='HGZ' || chan=='HGN' || chan=='HGE' || chan=='ELZ' ||chan=='ELN' || chan=='ELE' || chan=='ELZ'\" -w \"%{sta}.%{chan}.%Y.%m.%d.%H.%M.%S\" $dbname_o $msave/$sdir$orid/knsn $getstart $trim_window\n\n\n";

system("trexcerpt -m time -o sd -c \"chan=='HHZ' ||chan=='HHN' || chan=='HHE' || chan=='HGZ' || chan=='HGN' || chan=='HGE' || chan=='ELZ' ||chan=='ELN' || chan=='ELE' || chan=='ELZ'\" -w \"%{sta}.%{chan}.%Y.%m.%d.%H.%M.%S\" $dbname_o $msave/$sdir$orid/knsn $getstart $trim_window");

#system("rm -r $msave/$sdir/k.*");
system("fname_chang.sh $msave/$sdir$orid");
system("rm -r $home/knsn/db/.%knsn.*");

system("epid.csh $orid $year");

system("cp_db_arr.csh $orid $year $host $sdir$orid");
system("dbsplit -s 'orid==$orid' $dbname $msave/$sdir$orid/knsn");
system("tar -cvf $archive_d/$sdir$orid.tar --directory='$msave' $sdir$orid");

print "Finished batch Job \n \n \n";

exit( 0 );

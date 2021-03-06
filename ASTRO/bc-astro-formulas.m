(*

Hopefully canonical-at-last astronomical formulas, simple ones
building up. Coventions:

all units are in radians except where noted

functions are camel cased on each side with "2" representing "to"

Modules only permitted with "="

TODO: rationalization is used to preserve accuracy (but does not imply
infinite accuracy)

see bc-astro.dot for adjacency graph

date - number of days since 2000 January 1, at 12h UT (Unix second
946728000 = JD 2451545)

gmst - Greenwich mean sidereal time (radians)

lst - local sidereal time (radians)

ra - right ascension (radians)

dec - declination (radians)

lat - latitude (radians)

lon - longitude (radians)

ha - hour angle (radians)

haSet - local hour angle setting time

haRise - local hour angle rising time

earthRadius - radius of the Earth (varies with latitude)

xyzAltAz - the xyz coordinates for a given altitude and azimuth
(virtual sphere of radius 1)

xyzRaDec - the xyz coordinates for a given right ascension and
declination (virtual sphere of radius 1)

xyzEarth - xyz coordinates on Earth for current epoch, in km (no
precession/nutation)

*)

(* these conditions apply to the values above *)

conds = {-Pi/2<dec<Pi/2, -Pi/2<lat<Pi/2, 0<ra<2*Pi, -Pi<lon<Pi,
Element[date,Reals], Element[gmst,Reals]
}

(* constants (km) *)

earthMeanRadius = 6378.1370;
earthPolarRadius = 6356.7523;

(* http://en.wikipedia.org/wiki/Earth_radius#Geocentric_radius *)

lat2earthRadius[lat_] = Sqrt[
((earthMeanRadius^2*Cos[lat])^2 + (earthPolarRadius^2*Sin[lat])^2)/
((earthMeanRadius*Cos[lat])^2 + (earthPolarRadius*Sin[lat])^2)
]

(* http://aa.usno.navy.mil/faq/docs/GAST.php converted to radians *)

date2gmst[date_] = (18.697374558+24.06570982441908*date)/12*Pi

gmstLon2lst[gmst_,lon_] = gmst+lon

lstRa2ha[lst_,ra_] = lst-ra

(* http://idlastro.gsfc.nasa.gov/ftp/pro/astro/hadec2altaz.pro *)

decHaLat2xyzAltAz[dec_,ha_,lat_] = Module[{sh,sd,sl,ch,cd,cl},
 sh = Sin[ha];
 ch = Cos[ha];
 sd = Sin[dec];
 cd = Cos[dec];
 sl = Sin[lat];
 cl = Cos[lat];
{-ch*cd*sl + sd*cl, -sh*cd, ch*cd*cl + sd*sl}
]

(* Mathematica convention: ArcTan[x,y] ~ ArcTan[x/y] *)

decHaLat2azEl[dec_,ha_,lat_] = Module[{r,x,y,z},
 {x,y,z} = decHaLat2xyzAltAz[dec,ha,lat];
 r = Sqrt[1-z^2];
 {ArcTan[x,y],ArcTan[r,z]}
]

(* the rise and set are not necessarily on the same day *)

decLat2haRise[dec_,lat_] = -ArcCos[-Tan[dec]*Tan[lat]]
decLat2haSet[dec_,lat_] = ArcCos[-Tan[dec]*Tan[lat]]

latLst2xyzEarth[lat_,lst_] = 
 lat2earthRadius[lat]*{Sin[lat]*Cos[lst],Sin[lat]*Sin[lst],Cos[lat]}



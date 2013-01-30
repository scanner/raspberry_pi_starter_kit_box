//
// A simple platform to hold the raspberry pi and the breadboard that comes
// in the starter kit from makershed
//

breadboard_w = 55;
breadboard_l = 166;
breadboard_h = 9.4;
breadboard_tab_w = 6;
breadboard_tab_l = 2.3;
base_h = 7;
inset_depth = 3;
rpi_base_w = 70;
rpi_base_l = 95.6;

rpi_l = 85;
rpi_w = 56;
rpi_bottom_offset = 5;
rpi_gap = 2;
box_t = 2.5;
rpi_box_h = 9;
hole_r = 3/2;
mount_r = 2.5;
mounting_holes = [[rpi_l - 25.5, rpi_w - 18, -box_t],[5, 12.5, -box_t]];
rpi_mounts = [["plain", [rpi_l - 25.5, rpi_w - 18, -box_t], 5, 0],
              ["plain", [5, 12.5, -box_t], 5, 0],
              ["split_base", [rpi_l - 25.5, rpi_w - 18, -box_t], 5, 3],
              ["split_base", [5, 12.5, -box_t], 5, 3],
              ["plain", [rpi_l - 25.5, 11.5, -box_t], 4, 0],
              ["plain", [5, rpi_w - 5, -box_t], 4, 0]];

sd_card_w = 28.3;
sd_card_offset = 11.5;

stands = [[],[]];

padding = 0.05;

expansion = 3;

breadboard_tab_pos = [13, 80, 148];

use <MCAD/shapes.scad>;
use <pcb_stand_off_v1.scad>;

//////////////////////////////////////////////////////////////////////////////
//
// a small box that describes the outline of the raspberry pi with standoffs
// for mounting
//
module pi_box() {
    translate([-(rpi_l+(box_t*2))/2,-(rpi_w+(box_t*2))/2,0]) {
        union() {
            difference() {
                cube([rpi_l+(box_t*2), rpi_w+(box_t*2), rpi_box_h]);
                translate([box_t-rpi_gap/2,box_t-rpi_gap/2,box_t+padding]) {
                    cube([rpi_l+rpi_gap, rpi_w+rpi_gap, rpi_box_h]);
                }
                translate([rpi_l + box_t, sd_card_offset + (sd_card_w+1)/2,box_t + 5]) {
                    cube([10, sd_card_w+1, 10], true);
                }
            }
            translate([box_t,box_t,box_t+padding]) {
                for (i = rpi_mounts) {
                    translate(i[1]) {
                        pcb_stand_off(type=i[0],
                            hex = "false",
                            od = i[2],
                            id = i[3],
                            len = rpi_bottom_offset+box_t,
                            cl = 0.25, thk_base = box_t, thk_pcb = 1.7);
                    }
                }
            }
        }
    }
}

//////////////////////////////////////////////////////////////////////////////
//
module pi_base() {
    difference() {
        union() {
            // the base plate for our raspberry pi
            //
            translate([0,0,base_h/2]) {
                roundedBox(rpi_base_l, rpi_base_w, base_h, 5);
            }
            // And the box with the mounting for the raspberry pi
            //
            translate([0,0,base_h]) {
                rotate([0,0,180]) {
                    pi_box();
                }
            }
        }
        // and cutouts in our raspberry pi base to save on plastic, printing
        // time, and when we reduce long stretches of plastic we reduce the
        // warping pressure due to ABS shrinkage.
        //
        for( j = [18, 0, -19] ) {
            for ( i = [-1,0] ) {
                translate([i*(rpi_l/3), j, base_h-padding]) {
                    rounded_equi_triangle(rpi_l/4, base_h*2, 2);
                }
            }
            translate([(rpi_l/3)-3, j, base_h-padding]) {
                rounded_equi_triangle(rpi_l/4, base_h*2, 2);
            }
        }
    }
}

//////////////////////////////////////////////////////////////////////////////
//
module breadboard() {
    union() {
        cube([breadboard_l, breadboard_w, breadboard_h], true);
        for( i = breadboard_tab_pos ) {
            translate([(i - (breadboard_l/2))+(breadboard_tab_w/2),-(breadboard_w/2)-(breadboard_tab_l/2)+padding,0]) {
                cube([breadboard_tab_w, breadboard_tab_l, breadboard_h],true);
            }
        }
    }
}

//////////////////////////////////////////////////////////////////////////////
//
// We have our breadboard base which has a recessed area in which the
// breadboard fits.
//
// we cut rounded triangles out of the center of the breadboard base to use
// less plastic and so that there is less plastic to shrink causing less
// warping.
//
module breadboard_base() {
    tri_side = breadboard_w;
    tri_h = (sqrt(3)/2)*tri_side;
    // an array of x,y translations and the rotation of the rounded triangle
    //
    tri_positions = [[-68,0,30],[-65 + tri_side + base_h,0,-30]];

    difference() {
        translate([0,0,base_h/2]) {
            roundedBox(breadboard_l + (expansion*2), breadboard_w + (expansion*2), base_h, 5);
        }
        translate([0, 0, (breadboard_h/2) + 2]) {
            breadboard();
        }
        for( i = [0:2] ) {
            translate([(tri_side * i) - (breadboard_l/3), -8,(base_h/2)-padding]) {
                rounded_equi_triangle(tri_side, base_h + (2*padding),4);
            }
        }
        for( i = [0:1] ) {
            translate([(tri_side * i) - (tri_side/2), 11,(base_h/2)-padding]) {
                rounded_equi_triangle(tri_side*.8, base_h + (2*padding),4, rotation=60);
            }
        }
    }
}

//////////////////////////////////////////////////////////////////////////////
//
// a rounded triangle is a triangle with the pointy ends capped by a circle
//
// This means that the actual length of a side will be less than what
// is specified because the rounding of the tip shortens it.
//
// XXX If I properly remembered my highschool geometry I could
//     actually calculate this and explain it here better.
//
module rounded_equi_triangle(side, height, radius, rotation = 0) {
    // At each point of the triangle is a cylinder that caps each point.
    //
    angles = [0,120,240];
    tri_h = (sqrt(3)/2)*side;
    centroid_h = ((sqrt(3)/2)*side)/3;
    points = [[0,0,0],[-side,0,0],[-(side/2),tri_h,0]];
    center = [-(side/2),centroid_h,0];
    rotate([0,0,rotation]) {
        translate([side/2,-centroid_h,0]) {
            union() {
                // We make a triangle and chop off the tips.
                //
                difference() {
                    equiTriangle(side, height);
                    translate(center) {
                        for(a = angles) {
                            rotate(a = a, v = [0,0,1]) {
                                translate([0,((tri_h/(3/2))-(radius*(2/3)))-(radius*(4/3))+(radius*(4/3)),0]) {
                                    cube(size = [radius*2, radius*2,height*2], center = true);
                                }
                            }
                        }
                    }
                }

                // Then we place a cylinder where each tip is chopped off.
                //
                translate(center) {
                    for(a = angles) {
                        rotate(a = a, v = [0,0,1]) {
                            translate([0,((tri_h/(3/2))-(radius*(2/3)))-(radius*(4/3)),0]) {
                                cylinder(r=radius,h=height,center = true, $fn = 30);
                            }
                        }
                    }
                }
            }
        }
    }
}

//////////////////////////////////////////////////////////////////////////////
//
module starter_kit_box() {
    union() {
        translate([0,-2,0]) {
            pi_base();
        }
        translate([(breadboard_l+2*expansion)/2 - rpi_base_l/2, breadboard_w+(expansion*2)+2, 0]) {
            breadboard_base();
        }

        // Do a smooth join between the breadboard and pi base
        //
        translate([(-rpi_base_l/2) + (expansion/2),rpi_base_w/2-expansion,base_h/2]) {
            cube([expansion, 12, base_h], center = true);
        }

        // and a curved join between the pi base and breadboard on the
        // other side
        difference() {
            translate([(rpi_base_l/2)+3,(rpi_base_w/2)-8.4,base_h/2]) {
                cube([12,13,base_h],true);
            }
            translate([(rpi_base_l/2)+9.7,rpi_base_w/2-12.5,-(base_h/2)]) {
                cylinder(h = base_h *2 , r = 10);
            }
        }
    }
}

//////////////////
//////////////////
//
//

starter_kit_box();
// pi_base();
// pi_box();
// breadboard_base();
//
//
//////////////////
//////////////////

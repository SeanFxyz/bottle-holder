$fn = 100;

// Rows of bottle holes
rows = 2;
// Columns of bottle holes
cols = 3;
// Diameter of holes
hole_diam = 25;
// Minimum spacing between holes, regardless of bottle size
min_hole_space = 4;
// Minimum additional spacing between the walls and the holes
min_wall_space = 1;
// Diameter of the bottles to be held at their widest point (determines hole spacing)
max_bottle_diam = 31;
// Thickness of the rack
rack_thickness = 4;
// Thickness of the walls/legs
wall_thickness = 4;
// Elevation of the rack (determines height of walls)
rack_elevation = 35;
// Minimum floor footprint of walls
min_foot_size = 8;
// Space between the wall arch the bottom of the rack
wall_top_gap = 4;
// minimum rack_width, regardless of cols
min_rack_width = 0;
// minimum rack_depth, regardless of rows
min_rack_depth = 0;


// Higher definition curves
$fs = 0.01;

module roundedcube(size = [1, 1, 1], center = false, radius = 0.5, apply_to = "all") {
    // If single value, convert to [x, y, z] vector
    size = (size[0] == undef) ? [size, size, size] : size;

    translate_min = radius;
    translate_xmax = size[0] - radius;
    translate_ymax = size[1] - radius;
    translate_zmax = size[2] - radius;

    diameter = radius * 2;

    module build_point(type = "sphere", rotate = [0, 0, 0]) {
        if (type == "sphere") {
            sphere(r = radius);
        } else if (type == "cylinder") {
            rotate(a = rotate)
            cylinder(h = diameter, r = radius, center = true);
        }
    }

    obj_translate = (center == false) ?
        [0, 0, 0] : [
            -(size[0] / 2),
            -(size[1] / 2),
            -(size[2] / 2)
        ];

    translate(v = obj_translate) hull() {
        for (translate_x = [translate_min, translate_xmax]) {
            x_at = (translate_x == translate_min) ? "min" : "max";
            for (translate_y = [translate_min, translate_ymax]) {
                y_at = (translate_y == translate_min) ? "min" : "max";
                for (translate_z = [translate_min, translate_zmax]) {
                    z_at = (translate_z == translate_min) ? "min" : "max";

                    translate(v = [translate_x, translate_y, translate_z])
                    if (
                        (apply_to == "all") ||
                        (apply_to == "xmin" && x_at == "min") || (apply_to == "xmax" && x_at == "max") ||
                        (apply_to == "ymin" && y_at == "min") || (apply_to == "ymax" && y_at == "max") ||
                        (apply_to == "zmin" && z_at == "min") || (apply_to == "zmax" && z_at == "max")
                    ) {
                        build_point("sphere");
                    } else {
                        rotate =
                            (apply_to == "xmin" || apply_to == "xmax" || apply_to == "x") ? [0, 90, 0] : (
                            (apply_to == "ymin" || apply_to == "ymax" || apply_to == "y") ? [90, 90, 0] :
                            [0, 0, 0]
                        );
                        build_point("cylinder", rotate);
                    }
                }
            }
        }
    }
}

hole_space = max(min_hole_space, max_bottle_diam - hole_diam);

rack_wd_offset = max(wall_thickness - hole_space, min_wall_space * 2);
base_rack_width = cols * hole_diam + (cols + 1) * hole_space + rack_wd_offset;
base_rack_depth = rows * hole_diam + (rows + 1) * hole_space + rack_wd_offset;
rack_width = max(base_rack_width, min_rack_width);
rack_depth = max(base_rack_depth, min_rack_depth);
//rack_width = cols * hole_diam + (cols + 1) * hole_space + rack_wd_offset;
//rack_depth = rows * hole_diam + (rows + 1) * hole_space + rack_wd_offset;

echo("rack_width: ", rack_width);
echo("rack depth: ", rack_depth);

// rack
translate([0, 0, rack_elevation])
difference() {
    rack_size = [rack_width, rack_depth, rack_thickness];
    roundedcube(rack_size, radius = 1, apply_to = "zmax");
    
    row_start_offset = hole_space +
        (rack_width == base_rack_width ?
            rack_wd_offset / 2 : (rack_width - base_rack_width) / 2);
    col_start_offset = hole_space +
        (rack_depth == base_rack_depth ?
            rack_wd_offset / 2 : (rack_depth - base_rack_depth) / 2);
    grid_space = hole_diam + hole_space;
    hole_radius = hole_diam / 2;
    for (i = [0:rows - 1]) {
        for (j = [0:cols - 1]) {
            tr = [
                row_start_offset + j * grid_space + hole_radius,
                col_start_offset + i * grid_space + hole_radius,
                -1
            ];
            translate(tr) cylinder(h = rack_thickness + 2, r = hole_diam / 2);
        }
    }
    
    
}

// walls
module wall(depth) {
    arch_depth = (depth - min_foot_size * 2);
    arch_radius = arch_depth / 2;
    difference() {
        roundedcube([wall_thickness, depth, rack_elevation], radius = 1, apply_to = "zmin");
        
        tr = [-1, arch_radius + min_foot_size];
        
        translate(tr) 
        resize([wall_thickness + 2, arch_depth, rack_elevation * 2 - wall_top_gap], auto=true)
        rotate([0, 90, 0])
        cylinder(h = wall_thickness + 2, r = 1);
    }
}

wall(rack_depth);
translate([rack_width - wall_thickness, 0, 0]) wall(rack_depth);

translate([0, wall_thickness, 0]) rotate([0, 0, -90]) wall(rack_width);
translate([0, rack_depth, 0]) rotate([0, 0, -90]) wall(rack_width);
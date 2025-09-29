// ===== MAIN PARAMETERS =====

// Overall shelf dimensions - USER INPUT (inches)
shelf_width_inches = 22.75;   // Width in inches
shelf_depth_inches = 17.875;  // Depth in inches

// Convert to mm
shelf_width = shelf_width_inches * 25.4;
shelf_depth = shelf_depth_inches * 25.4;
shelf_thickness = 3;  // Base thickness

// Build volume constraint (mm)
build_volume = 256;

// Determine number of pieces needed
pieces_x = ceil(shelf_width / build_volume);
pieces_y = ceil(shelf_depth / build_volume);
total_pieces = pieces_x * pieces_y;

// Calculate piece offset to fit nicely - 0.15mm per connection
piece_offset = 0.15;

// Actual piece dimensions with offset for fit
piece_width = (shelf_width - (pieces_x - 1) * piece_offset) / pieces_x;
piece_depth = (shelf_depth - (pieces_y - 1) * piece_offset) / pieces_y;

// Corner cut for posts (mm)
corner_cut = 38.1;  // 1.5 inches into each side

// Raised perimeter
enable_perimeter = true;
perimeter_height = 10;  // Height of raised edge
perimeter_width = 5;    // Width of perimeter wall

// Gridfinity options
enable_gridfinity = false;
gridfinity_unit = 42;   // Standard gridfinity base unit (mm)
gridfinity_height = 5;  // Height of gridfinity base features

// Wire shelf mounting nubs
wire_spacing = 25.4;    // Inside-to-inside wire spacing (1 inch typical)
wire_diameter = 3.175;  // Wire diameter (1/8" = 3.175mm)
nub_height = 10;        // How far nubs extend down from shelf bottom
nub_width = 6;          // Width of nub (fits between wires)
nub_depth = 15;         // Depth of nub (along wire direction)
nub_tolerance = 0.4;    // Gap for fit between wires

// Connection system between pieces
connector_width = 20;
connector_depth = 3;
connector_tolerance = 0.2;

// ===== CALCULATED VALUES =====

// Gridfinity calculations
gridfinity_cols = enable_gridfinity ? floor((shelf_width - 2*perimeter_width) / gridfinity_unit) : 0;
gridfinity_rows = enable_gridfinity ? floor((shelf_depth - 2*perimeter_width) / gridfinity_unit) : 0;
gridfinity_offset_x = enable_gridfinity ? (shelf_width - gridfinity_cols * gridfinity_unit) / 2 : 0;
gridfinity_offset_y = enable_gridfinity ? (shelf_depth - gridfinity_rows * gridfinity_unit) / 2 : 0;

echo(str("Total pieces needed: ", total_pieces, " (", pieces_x, "x", pieces_y, ")"));
echo(str("Each piece: ", piece_width, "mm x ", piece_depth, "mm"));
if (enable_gridfinity) {
    echo(str("Gridfinity grid: ", gridfinity_cols, "x", gridfinity_rows, " units"));
}

// ===== MODULES =====

// Main shelf piece
module shelf_piece(x_index, y_index) {
    x_pos = x_index * (piece_width + piece_offset);
    y_pos = y_index * (piece_depth + piece_offset);
    
    difference() {
        union() {
            // Main base
            translate([x_pos, y_pos, 0])
                base_with_corners(x_index, y_index);
            
            // Raised perimeter
            if (enable_perimeter) {
                translate([x_pos, y_pos, shelf_thickness])
                    perimeter_walls(x_index, y_index);
            }
            
            // Male connectors (right and top edges)
            if (x_index < pieces_x - 1) {
                translate([x_pos + piece_width, y_pos, 0])
                    male_connector_x();
            }
            if (y_index < pieces_y - 1) {
                translate([x_pos, y_pos + piece_depth, 0])
                    male_connector_y();
            }
            
            // Wire mounting nubs on bottom
            translate([x_pos, y_pos, 0])
                wire_nubs(x_index, y_index);
        }
        
        // Female connectors (left and bottom edges)
        if (x_index > 0) {
            translate([x_pos, y_pos, 0])
                female_connector_x();
        }
        if (y_index > 0) {
            translate([x_pos, y_pos, 0])
                female_connector_y();
        }
    }
    
    // Gridfinity base pattern
    if (enable_gridfinity) {
        translate([x_pos, y_pos, shelf_thickness + (enable_perimeter ? perimeter_height : 0)])
            gridfinity_pattern(x_index, y_index);
    }
}

// Base plate with corner cuts
module base_with_corners(x_index, y_index) {
    x_pos = x_index * piece_width;
    y_pos = y_index * piece_depth;
    
    difference() {
        cube([piece_width, piece_depth, shelf_thickness]);
        
        // Cut corners only for pieces at the corners of the full shelf
        // Bottom-left corner (x=0, y=0)
        if (x_index == 0 && y_index == 0) {
            translate([-1, -1, -1])
                linear_extrude(shelf_thickness + 2)
                    polygon([
                        [0, 0],
                        [corner_cut, 0],
                        [0, corner_cut]
                    ]);
        }
        
        // Bottom-right corner (x=max, y=0)
        if (x_index == pieces_x - 1 && y_index == 0) {
            translate([piece_width + 1, -1, -1])
                rotate([0, 0, 90])
                    linear_extrude(shelf_thickness + 2)
                        polygon([
                            [0, 0],
                            [corner_cut, 0],
                            [0, corner_cut]
                        ]);
        }
        
        // Top-right corner (x=max, y=max)
        if (x_index == pieces_x - 1 && y_index == pieces_y - 1) {
            translate([piece_width + 1, piece_depth + 1, -1])
                rotate([0, 0, 180])
                    linear_extrude(shelf_thickness + 2)
                        polygon([
                            [0, 0],
                            [corner_cut, 0],
                            [0, corner_cut]
                        ]);
        }
        
        // Top-left corner (x=0, y=max)
        if (x_index == 0 && y_index == pieces_y - 1) {
            translate([-1, piece_depth + 1, -1])
                rotate([0, 0, 270])
                    linear_extrude(shelf_thickness + 2)
                        polygon([
                            [0, 0],
                            [corner_cut, 0],
                            [0, corner_cut]
                        ]);
        }
    }
}

// Perimeter walls
module perimeter_walls(x_index, y_index) {
    wall_t = 2;  // Wall thickness
    
    // Left wall (only on leftmost pieces)
    if (x_index == 0) {
        difference() {
            cube([perimeter_width, piece_depth, perimeter_height]);
            
            // Cut bottom-left corner
            if (y_index == 0) {
                translate([-1, -1, -1])
                    linear_extrude(perimeter_height + 2)
                        polygon([
                            [0, 0],
                            [corner_cut + 1, 0],
                            [0, corner_cut + 1]
                        ]);
            }
            
            // Cut top-left corner
            if (y_index == pieces_y - 1) {
                translate([-1, piece_depth + 1, -1])
                    rotate([0, 0, 270])
                        linear_extrude(perimeter_height + 2)
                            polygon([
                                [0, 0],
                                [corner_cut + 1, 0],
                                [0, corner_cut + 1]
                            ]);
            }
        }
    }
    
    // Right wall (only on rightmost pieces)
    if (x_index == pieces_x - 1) {
        difference() {
            translate([piece_width - perimeter_width, 0, 0])
                cube([perimeter_width, piece_depth, perimeter_height]);
            
            // Cut bottom-right corner
            if (y_index == 0) {
                translate([piece_width + 1, -1, -1])
                    rotate([0, 0, 90])
                        linear_extrude(perimeter_height + 2)
                            polygon([
                                [0, 0],
                                [corner_cut + 1, 0],
                                [0, corner_cut + 1]
                            ]);
            }
            
            // Cut top-right corner
            if (y_index == pieces_y - 1) {
                translate([piece_width + 1, piece_depth + 1, -1])
                    rotate([0, 0, 180])
                        linear_extrude(perimeter_height + 2)
                            polygon([
                                [0, 0],
                                [corner_cut + 1, 0],
                                [0, corner_cut + 1]
                            ]);
            }
        }
    }
    
    // Bottom wall (only on bottom pieces)
    if (y_index == 0) {
        difference() {
            cube([piece_width, perimeter_width, perimeter_height]);
            
            // Cut bottom-left corner
            if (x_index == 0) {
                translate([-1, -1, -1])
                    linear_extrude(perimeter_height + 2)
                        polygon([
                            [0, 0],
                            [corner_cut + 1, 0],
                            [0, corner_cut + 1]
                        ]);
            }
            
            // Cut bottom-right corner
            if (x_index == pieces_x - 1) {
                translate([piece_width + 1, -1, -1])
                    rotate([0, 0, 90])
                        linear_extrude(perimeter_height + 2)
                            polygon([
                                [0, 0],
                                [corner_cut + 1, 0],
                                [0, corner_cut + 1]
                            ]);
            }
        }
    }
    
    // Top wall (only on top pieces)
    if (y_index == pieces_y - 1) {
        difference() {
            translate([0, piece_depth - perimeter_width, 0])
                cube([piece_width, perimeter_width, perimeter_height]);
            
            // Cut top-left corner
            if (x_index == 0) {
                translate([-1, piece_depth + 1, -1])
                    rotate([0, 0, 270])
                        linear_extrude(perimeter_height + 2)
                            polygon([
                                [0, 0],
                                [corner_cut + 1, 0],
                                [0, corner_cut + 1]
                            ]);
            }
            
            // Cut top-right corner
            if (x_index == pieces_x - 1) {
                translate([piece_width + 1, piece_depth + 1, -1])
                    rotate([0, 0, 180])
                        linear_extrude(perimeter_height + 2)
                            polygon([
                                [0, 0],
                                [corner_cut + 1, 0],
                                [0, corner_cut + 1]
                            ]);
            }
        }
    }
}

// Male connector along X axis (protrudes in +X direction)
module male_connector_x() {
    num_connectors = max(1, floor(piece_depth / 80));
    spacing = piece_depth / (num_connectors + 1);
    
    for (i = [1:num_connectors]) {
        translate([0, spacing * i - connector_width/2, shelf_thickness/2 - connector_depth/2])
            cube([connector_depth - connector_tolerance, connector_width, connector_depth]);
    }
}

// Female connector along X axis (slot in -X direction)
module female_connector_x() {
    num_connectors = max(1, floor(piece_depth / 80));
    spacing = piece_depth / (num_connectors + 1);
    
    for (i = [1:num_connectors]) {
        translate([-connector_depth - connector_tolerance, spacing * i - connector_width/2, shelf_thickness/2 - connector_depth/2])
            cube([connector_depth + connector_tolerance*2, connector_width + connector_tolerance*2, connector_depth + connector_tolerance*2]);
    }
}

// Male connector along Y axis (protrudes in +Y direction)
module male_connector_y() {
    num_connectors = max(1, floor(piece_width / 80));
    spacing = piece_width / (num_connectors + 1);
    
    for (i = [1:num_connectors]) {
        translate([spacing * i - connector_width/2, 0, shelf_thickness/2 - connector_depth/2])
            cube([connector_width, connector_depth - connector_tolerance, connector_depth]);
    }
}

// Female connector along Y axis (slot in -Y direction)
module female_connector_y() {
    num_connectors = max(1, floor(piece_width / 80));
    spacing = piece_width / (num_connectors + 1);
    
    for (i = [1:num_connectors]) {
        translate([spacing * i - connector_width/2, -connector_depth - connector_tolerance, shelf_thickness/2 - connector_depth/2])
            cube([connector_width + connector_tolerance*2, connector_depth + connector_tolerance*2, connector_depth + connector_tolerance*2]);
    }
}

// Simple wire mounting nubs - rectangular protrusions that fit between wires
module wire_nubs(x_index, y_index) {
    // Calculate wire positions (center-to-center)
    wire_center_spacing = wire_spacing + wire_diameter;
    
    // Number of rows of wires that cross this piece (running along X axis)
    num_wire_rows = floor(piece_depth / wire_center_spacing) + 1;
    wire_offset_y = (piece_depth - (num_wire_rows - 1) * wire_center_spacing) / 2;
    
    // Create nubs between each pair of wires
    for (row = [0:num_wire_rows-2]) {
        // Position between two wires
        y_pos = wire_offset_y + row * wire_center_spacing + wire_diameter/2 + nub_tolerance/2;
        
        // Number of nubs along the X direction for this row
        num_nubs = max(2, floor(piece_width / 80));
        nub_spacing = piece_width / (num_nubs + 1);
        
        for (i = [1:num_nubs]) {
            x_pos = i * nub_spacing;
            
            translate([x_pos - nub_depth/2, y_pos, -nub_height]) {
                // Simple rectangular nub with chamfered top for easier insertion
                hull() {
                    // Bottom full size
                    cube([nub_depth, nub_width, 0.1]);
                    // Top slightly chamfered
                    translate([1, 0.5, nub_height])
                        cube([nub_depth - 2, nub_width - 1, 0.1]);
                }
            }
        }
    }
}

// Gridfinity base pattern
module gridfinity_pattern(x_index, y_index) {
    piece_min_x = x_index * piece_width;
    piece_max_x = (x_index + 1) * piece_width;
    piece_min_y = y_index * piece_depth;
    piece_max_y = (y_index + 1) * piece_depth;
    
    for (col = [0:gridfinity_cols-1]) {
        for (row = [0:gridfinity_rows-1]) {
            gf_x = gridfinity_offset_x + col * gridfinity_unit;
            gf_y = gridfinity_offset_y + row * gridfinity_unit;
            
            // Check if this gridfinity unit overlaps current piece
            if (gf_x + gridfinity_unit > piece_min_x && gf_x < piece_max_x &&
                gf_y + gridfinity_unit > piece_min_y && gf_y < piece_max_y) {
                
                translate([gf_x - piece_min_x, gf_y - piece_min_y, 0])
                    gridfinity_base_unit();
            }
        }
    }
}

// Single gridfinity base unit (baseplate socket)
module gridfinity_base_unit() {
    unit_size = 42;  // Standard gridfinity unit
    
    difference() {
        // Base platform
        cube([unit_size, unit_size, gridfinity_height]);
        
        // Create the z-shaped socket profile
        // Inner recess for bin base
        translate([4, 4, gridfinity_height - 2.6])
            cube([unit_size - 8, unit_size - 8, 2.7]);
        
        // Outer lip recess
        translate([0.8, 0.8, gridfinity_height - 4.8])
            cube([unit_size - 1.6, unit_size - 1.6, 2.3]);
        
        // Optional magnet holes in corners (6mm diameter x 2.4mm deep)
        for (x = [0, 1]) {
            for (y = [0, 1]) {
                translate([x * (unit_size - 8) + 4, y * (unit_size - 8) + 4, gridfinity_height - 2.4])
                    cylinder(h=2.5, d=6.5, $fn=30);
            }
        }
        
        // Optional screw holes in corners (for M3 screws from bottom)
        for (x = [0, 1]) {
            for (y = [0, 1]) {
                translate([x * (unit_size - 8) + 4, y * (unit_size - 8) + 4, -0.1])
                    cylinder(h=gridfinity_height - 2.4 + 0.2, d=3.2, $fn=20);
            }
        }
    }
}

// ===== RENDER SELECTION =====

// Change this value to render different pieces (0 to total_pieces-1)
// Or use "all" to see the complete assembly
render_mode = "single";  // "single", "all", or "assembly"
piece_to_render = 0;     // Which piece to render in "single" mode (0 to 5 for 6 pieces)

if (render_mode == "all") {
    // Render all pieces spaced out for visualization
    for (x = [0:pieces_x-1]) {
        for (y = [0:pieces_y-1]) {
            translate([x * (piece_width + 20), y * (piece_depth + 20), 0])
                shelf_piece(x, y);
        }
    }
} else if (render_mode == "assembly") {
    // Render as assembled
    for (x = [0:pieces_x-1]) {
        for (y = [0:pieces_y-1]) {
            shelf_piece(x, y);
        }
    }
} else {
    // Render single piece for printing
    x_index = piece_to_render % pieces_x;
    y_index = floor(piece_to_render / pieces_x);
    shelf_piece(x_index, y_index);
}

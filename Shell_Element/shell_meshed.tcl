wipe;
model BasicBuilder -ndm 3 -ndf 6;

#node

set node_tag 1;
set ele_tag 1;

set block_no 1;
set width 1.0;
set depth 1.0;
set mesh_width 10;
set mesh_depth 10;



set step_width [expr $width / $mesh_width];
set step_depth [expr $depth / $mesh_depth];

for {set i 1} {$i <= [expr 1+$mesh_width]} {incr i} {
    for {set j 1} {$j <= [expr 1+$mesh_depth]} {incr j} {
        set temp_x [expr ($i-1) * $step_width];
        set temp_y [expr ($j-1) * $step_depth];
        node ${block_no}0${i}0${j} $temp_x $temp_y 0.0;
    }
}

#node region
set node_nos_side1 [list];
set node_nos_side2 [list];
set node_nos_side3 [list];
set node_nos_side4 [list];
for {set j 1} {$j <= [expr 1+$mesh_width]} {incr j} {
    set temp [expr $mesh_depth + 1];
    lappend node_nos_side1 ${block_no}010${j};
    lappend node_nos_side3 ${block_no}0${temp}0${j};
}

for {set i 1} {$i <= [expr 1+$mesh_depth]} {incr i} {
    set temp [expr $mesh_width + 1];
    lappend node_nos_side2 ${block_no}0${i}0${temp};
    lappend node_nos_side4 ${block_no}0${i}01;
}
eval "region ${block_no}${node_tag}1 -node ${node_nos_side1}";
eval "region ${block_no}${node_tag}2 -node ${node_nos_side2}";
eval "region ${block_no}${node_tag}3 -node ${node_nos_side3}";
eval "region ${block_no}${node_tag}4 -node ${node_nos_side4}";

#boundary
proc comment {} {
    foreach temp $node_nos_side1 {
        fix $temp 1 1 1 0 1 1;
    }

    foreach temp $node_nos_side3 {
        fix $temp 1 0 1 0 1 1;
    }
}

#material
set E 1.0;
set v 0.1;
nDMaterial ElasticIsotropic 1 $E $v;

#Section
set shell_section_tag 1;
section PlateFiber $shell_section_tag 1 1.0;

#Element
#element ShellMITC4 1 1 2 3 4 1;
for {set i 1} {$i < [expr 1+$mesh_width]} {incr i} {
    for {set j 1} {$j < [expr 1+$mesh_depth]} {incr j} {
        set temp_i [expr $i+1];
        set temp_j [expr $j+1];
        set temp_ele_tag ${block_no}0${i}0${j};
        set node1_tag ${block_no}0${i}0${j};
        set node2_tag ${block_no}0${i}0${temp_j};
        set node3_tag ${block_no}0${temp_i}0${temp_j};
        set node4_tag ${block_no}0${temp_i}0${j};
        element ShellMITC4 $temp_ele_tag $node1_tag $node2_tag $node3_tag $node4_tag $shell_section_tag;
    }
}

#Constrain
set RefNodeTag1 9991;
set RefNodeTag2 9992;
node $RefNodeTag1 0.0 [expr $width / 2.0] 0.0;
node $RefNodeTag2 $depth [expr $width / 2.0] 0.0;

fix $RefNodeTag1 1 1 1 1 1 1;
fix $RefNodeTag2 1 0 1 1 1 1;

foreach temp $node_nos_side1 {
    equalDOF $RefNodeTag1 $temp 1 2 3 4 5 6;
}

foreach temp $node_nos_side3 {
    #equalDOF $RefNodeTag2 $temp 1 2 3 4 5 6;
    rigidLink bar $RefNodeTag2 $temp;
}
#Load
pattern Plain 1 Linear {
    load $RefNodeTag2 0.0 1.0 0.0 0.0 0.0 0.0;
}


#Analysis
constraints Plain;
numberer Plain;
system BandGeneral;
test NormDispIncr 1.0E-3 50;
algorithm Newton;
set temp [expr 1+$mesh_depth];
integrator DisplacementControl $RefNodeTag2 2 0.001;
analysis Static;
analyze 10;

print -node ${block_no}0${temp}02;
print -node ${block_no}0505;
print -node $RefNodeTag2;
print -node $RefNodeTag1;
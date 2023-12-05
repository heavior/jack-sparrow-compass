/*
This model is not licenced for commercial use or redistribution.
For inquiries reach out through contacts here: https://github.com/heavior/jack-sparrow-compass


Last published: Dec 5 2023, newer version migth be in development
To request updated version, leave a comment here: https://www.therpf.com/forums/threads/interactive-jack-sparrow-compass-show-off-and-questions.354776/


How to use: 
1. modify "assemble" and "preview" variables based on your interest
2. at the end of file, you can comment out parts you don't need in a render
3. tweak parameters to change dimensions. All dimensions are in millimeters
4. export STL using OpenSCAD

*/

/*

TODO:

think - brass parts assembly - maybe can move it under decor level? 
    Currently it's placed from inside the box up to decor level (might even stick out), will need some glue from inside (not best). Also, Thicker decor layer will sink the brass too.
    Alternative - make shorter legs (or some kind of anchor), and secure them with decor level.

think - how does decoration end at the bottom of the box?
think - how does decoration end at the bottom of the lid?

test - do box and decor need champher around hinge ?

brass parts - add marks
brass parts - add numbers (maybe in solidworks?)

add assembly:
    placement for nuts/incerts in the box
    holes and champher for screws in the bottom
    
elctronics:
    add hole for magnet in the lid
    figure out lighting (UV LED)

nice to have:
    add champher under the brass dial (though it won'd be cnc-friendly, should work good for 3d printing)
*/

assemble = false; // change rendering mode
preview = true;   // true for fast development, 
                  // false for rendering STL or single part development

if(preview){  // low resolution - faster preview 
   $fa = 60; 
   $fs = 250;
}else{ // smooth surfaces, makes preview almost unresponsive with all parts
   $fn = 2 * 360.0;     
   // TODO: maybe change for sphere or use smarter fa,fs values?
}


decorHeight = .5;       // how thick is decor material, it will increase total box size
boxWallThickness = 3;   //standard wood thickness
innerWidth = 72;        // minimal inner width for electronics, set to 0 if not important

masterReplicaBoxWidth = 75 - 2*decorHeight;                     // 75mm is a width of Master Replicas compass
electronicsRequireBoxWidth = innerWidth + 2*boxWallThickness;   // To allow enough room for inner components

boxWidth = max(masterReplicaBoxWidth, electronicsRequireBoxWidth);          // outer size, not including decor

if(boxWidth == masterReplicaBoxWidth){
    echo("Yaay! Using Master Replica width");
}else{
    echo("Rendering for electronics, larger than Master Replica");
}

boxHeight = 22;         // box height, not including decor
lidHeight = 11;         // lid base hight, not including decor or dome
lidWallThickness = 6;   // thickness for the lid to accomodate magnet inside
bottomThickness = 1.5;  // making bottom box thinner

decorLineThickness = 2.6;   // width of decoration stripes
decorBendThickness = .1;    // how thick is the bendable connection for decor parts
                            // need to be thin enough to bend well, but strong to not fall apart
                            // set to 0 if want decor from separate pieces for each wall
                            // inspired by https://www.youtube.com/watch?v=Lqi2eJV-5_0
                            // watch it to understand the idea

decorOverhang = .5;         // how much does decor overlay the central hole
decorDepth = .5;            // How deep will decor go into the box

decorFullHeight = decorHeight + decorDepth; // this is how thick is decor material
echo("decor material thickness in mm", decorFullHeight);

sphereDiameter = 60; // dome parameters
sphereHeight = 16.7;
sphereThickness = boxWallThickness;
boxTopThickness = boxWallThickness;


// brass part parameters
brassThickness = 2; // brass material
brassSupportBaseWidth = 3;   //max width of one of three suports - "legs" 
brassSupportAngle = 4;  // How brass support narrows
brassChampherAngle = 45; // How sharp should we shape the brass support. Make sure you have cnc mill with that angle
brassSupportExtention = 5; // 5mm brass leg extension that will go under box consturction to secure the brass parts
brassSupportExtentionThickness = .5; // how thick should extensions be
brassDialDiameter = 25; // outer diameter of the brass dial
brassHoleDiameter = 12.8;
brassDialWidth = 4.1; // (= large mark length)
brassMarksInterval = 10; // degrees
brassLargeMarksInterval = 20; // degrees

brassFinHeight = 12;  
brassFinLowerCutoutHeight  = 3.5; 
brassFinVerticalDrop = brassThickness; // vertical part at the tip of the fin 
brassFinUpperCutoutRadius = 8;


// measure hinge parameters
ignoreHinge = false; // if true, it will not carve out hinge from other parts
// if false, it will cutout a part of back decor section regardless of hinge thickness

hingeWidth = 41.5; 
hingeBarrelDiameter = 4.4;

// important to have a larger value than in reality otherwise it's not fixable after production
// if using CNC - make sure there are thin and long enough bits to carve out a slot for hinge
hingeBottomHeightWithBarrel = 17; 
hingeTopHeightWithBarrel = 6; 

hingeTopWidth = 30;
hingeBottomWidth = hingeWidth; // Tune this if needed. Problem: decor inlay might be in conflict with hinge
hingePlateThicknes = 1;
minDecorLengthAroundHinge = 1; // 1 mm is min lengt of decor around hinge cutout. see renderHinge for more details
hingeWoodCover = boxWallThickness/2-hingePlateThicknes/2;// how deep hinge is burried into the wood

boxColor = "brown";
decorColor = "gray";
brassColor = "yellow";

partsDistance =     assemble ? 0 : boxHeight; // rendering spacing when assemble = false
brassPartsSpacing = assemble ? 0 : 2*brassThickness; // rendering spacing when assemble = false
cutoutdelta = .1*boxWallThickness;  // this helps reducing artefact when using difference()

sideLength = .6*boxWidth;   // longer side of octagon compared to the whole size of the box

champherDepth = decorHeight-decorBendThickness;
decorTotalWidth = boxWidth + 2*champherDepth;
decorSide = sideLength + 2*tan(45/2)*champherDepth;

innerBoxWidth = boxWidth - 2*boxWallThickness;
innerSideLength = sideLength - 2*tan(45/2)*boxWallThickness;
innerBoxHeight = boxHeight - boxTopThickness;

boxCircleWindowDiameter = (sideLength - 2*decorLineThickness)*sqrt(2);


innerLidWidth = boxWidth - 2*lidWallThickness;
innerLidSideLength = sideLength - 2*tan(45/2)*lidWallThickness;
innerLidHeight = lidHeight - boxWallThickness;

// Function to create a shape with a square base and cut corners
module octagon(width, side, height) {
    cornerCut = (width - side)/2;

    points = [
        [cornerCut-width/2, 0-width/2], // Bottom left corner cut
        [width - cornerCut-width/2, 0-width/2], // Bottom right corner cut
        [width-width/2, cornerCut-width/2], // Top right corner cut
        [width-width/2, width - cornerCut-width/2], // Top right corner cut
        [width - cornerCut-width/2, width-width/2], // Top left corner cut
        [cornerCut-width/2, width-width/2], // Top left corner cut
        [0-width/2, width - cornerCut-width/2], // Bottom left corner cut
        [0-width/2, cornerCut-width/2] // Bottom left corner cut
    ];

    // Extrude to the specified height
    linear_extrude(height = height) {
        polygon(points);
    }
}


module renderHinge(cutout = false, cutoutDecor = false){ 
    //if cutout = true - render barrel as cube for better cutouts
    decorInnerSide = decorSide - 2*decorLineThickness;
    needSwapCutouts = cutoutDecor && ((decorInnerSide - hingeWidth) < (minDecorLengthAroundHinge * 2));
    cutoutWidth = needSwapCutouts?max(hingeWidth, decorInnerSide):hingeWidth;
    
    if(!ignoreHinge){
        color(brassColor) 
            translate([0, 
                    boxWidth/2 - hingeWoodCover - hingePlateThicknes + hingeBarrelDiameter/2,
                    boxHeight+decorHeight/2]) // Hinge is centred at the barrel
            union(){
                if(cutout || cutoutDecor){
                    translate([0,0,0])
                        cube([cutoutWidth, 
                                cutoutDecor?4*decorLineThickness+2*cutoutdelta:hingeBarrelDiameter, 
                                cutoutDecor?2*decorLineThickness+2*cutoutdelta:hingeBarrelDiameter],center = true);
                }else{
                    // render nice cylinder only for visual rendering
                    translate([-hingeWidth/2,0,0]){
                        rotate([0,90,0])
                            cylinder(h=hingeWidth,d=hingeBarrelDiameter);
                    }
                }
                if(!cutoutDecor){ // decor is not affected by hinge flaps                
                    translate([-hingeBottomWidth/2,- hingeBarrelDiameter/2,
                                    -hingeBottomHeightWithBarrel+hingeBarrelDiameter/2])
                            cube([hingeBottomWidth, hingePlateThicknes, 
                                    hingeBottomHeightWithBarrel-hingeBarrelDiameter/2]);
                    
                    translate([-hingeTopWidth/2,-hingeBarrelDiameter/2, 0])
                            cube([hingeTopWidth, hingePlateThicknes, 
                                    hingeTopHeightWithBarrel+hingeBarrelDiameter/2]);
                }
                
            }
    }
}

module renderBox(){
    // Using difference() to subtract one shape from another
    color(boxColor)
        difference(){
            difference() { // box itself
                // outer box
                octagon(boxWidth, sideLength, boxHeight);
                
                // cut out inner box
                translate([0,0, -cutoutdelta]) 
                    octagon(innerBoxWidth, innerSideLength, innerBoxHeight+cutoutdelta); // Adjust the translate values as needed
               
                // cut out inner circle
                translate([0,0,-cutoutdelta]) 
                    cylinder(h = boxHeight + 2*cutoutdelta,  d=boxCircleWindowDiameter+2*decorOverhang);
               
            }
            // cutouts for other parts
            
            renderBoxDecor(true);   
            renderBrassParts(cutout=true);
            renderHinge(cutout=true);
        }
}


module renderBottom(){
    // Using difference() to subtract one shape from another
    
    color(boxColor)
        difference() {
            // outer box
            octagon(innerBoxWidth, innerSideLength, bottomThickness);
            
        }
}

// Create a hollow sphere
module hollowSphere(outerR, innerR) {
    difference() {
        sphere(outerR); // Larger sphere
        translate([0, 0, -0.1]) // Slightly move the inner sphere down for a clean cut
        sphere(innerR); // Smaller sphere
    }
}

module hollowOctagon(width, side, thickness, height){
    innerSide = side - 2*tan(45/2 )*thickness;
    difference() {
        // outer box
        octagon(width, side, height);
        
        // cut out inner box
        translate([0, 0, -cutoutdelta]) 
            octagon(width - 2*thickness, innerSide, height+2*cutoutdelta); 
    }
}

module hollowBox(a, b, thickness, height, champherD){
    difference() {
        // outer box
        cube([a, b, height],center=true);
        
        // cut out inner box
        cube([a - 2*thickness, b - 2*thickness, height + 2*cutoutdelta],center=true); 
       
        //translate([a/2,b/2,-height/2]) rotate([0,0,180])
        //    champher(a, champherD, 45, 1+cutoutdelta, useX = true);   
        
        translate([-a/2,-b/2,-height/2]) rotate([0,0,0])
            champher(a, champherD, 45, 1+cutoutdelta, useX = true);   

        translate([a/2,-b/2,-height/2]) rotate([0,0,0])
            champher(b, champherD, 45/2, 1+cutoutdelta, useX = false);   
        
        translate([-a/2,-b/2,-height/2]) rotate([0,0,0])
            champher(b, champherD, 45/2, 1+cutoutdelta, useX = false);   
    }   
}

module hollowCylinder(outerDiameter, innerDiameter, height){
    difference() {
        difference(){
           cylinder(h = height,  d=outerDiameter, center = true);
        
           cylinder(h = height + 2*cutoutdelta,  d=innerDiameter, center = true);
        }  
    }   
}

module renderLid(){
    // Using difference() to subtract one shape from another
    
    innerSphereRadius = sphereDiameter/2 - sphereThickness;
    sphereDiameterAtLidLevel = 2*sqrt(pow(innerSphereRadius,2) - pow(innerSphereRadius - sphereHeight + sphereThickness-boxWallThickness,2)); 
    
    color(boxColor) translate([0,0,boxHeight + decorHeight])                       
        union(){
            difference() {
                // outer box
                octagon(boxWidth, sideLength, lidHeight);
                
                // cut out inner box
                translate([0, 0, -cutoutdelta]) 
                    octagon(innerLidWidth, innerLidSideLength, innerLidHeight+cutoutdelta); // Adjust the translate values as needed
               
                // cut out inner circle
                translate([0,0,-cutoutdelta]) 
                      cylinder(h = boxHeight + 2*cutoutdelta,  d=sphereDiameterAtLidLevel);
                
                // cutout decor
                translate([0,0, -boxHeight -decorHeight]){  // TODO: this doesn't look very good - moving coordinates back. Maybe decor should be positioned realitve to the lid
                    renderLidDecor(true);   
                    renderHinge(cutout=true);
                }
            }
            
            // Dome
            
            difference() {
                translate([0,0,sphereHeight + lidHeight - sphereDiameter/2])
                    hollowSphere(sphereDiameter/2,innerSphereRadius);
                
                translate([-boxWidth/2, -boxWidth/2])
                    cube([boxWidth, boxWidth, lidHeight-boxWallThickness]); // A cube that acts as a cutting plane
                
                translate([-boxWidth/2, -boxWidth/2, -sphereDiameter])
                    cube([boxWidth, boxWidth, sphereDiameter+2*cutoutdelta]); // A cube that acts as a cutting plane
            }
        }
}

module champher(length, depth, angle, delta, useX=true)
{
    points = [    
        [-depth * (useX?tan(angle):1), 0],
        [0, -depth * (!useX?tan(angle):1)],
        [depth * (useX?tan(angle):1), 0],
        [0, depth * (!useX?tan(angle):1)] 
    ];

    // Extrude to the specified height
    color("red") rotate([useX?90:0,useX?0:-90,useX?90:-90])
        linear_extrude(height = length+2*delta) {
            polygon(points);
        }
}

module decorFrame(){
    corner = (decorTotalWidth-decorSide)/2;
    color(decorColor)
        difference() {
            union(){
                hollowOctagon(decorTotalWidth, decorSide, decorLineThickness, decorFullHeight);
            }
            translate([-decorTotalWidth/2,-decorTotalWidth/2,0]) rotate([0,0,0]){            
                champher(decorTotalWidth, champherDepth+decorDepth, 45, cutoutdelta, useX = false);    
                champher(decorTotalWidth, champherDepth+decorDepth, 45, cutoutdelta, useX = true);
            }
            translate([decorTotalWidth/2,decorTotalWidth/2,0]) rotate([0,0,180]){
                champher(decorTotalWidth, champherDepth+decorDepth, 45, cutoutdelta, useX = false);
                champher(decorTotalWidth, champherDepth+decorDepth, 45, cutoutdelta, useX = true);
            }
            translate([corner-decorTotalWidth/2,-decorTotalWidth/2,0]) rotate([0,0,45])
                champher(decorTotalWidth, champherDepth+decorDepth, 45, cutoutdelta, useX = false);
            
            translate([decorTotalWidth/2-corner,-decorTotalWidth/2,0]) rotate([0,0,45])
                champher(decorTotalWidth, champherDepth+decorDepth, 45, cutoutdelta, useX = true);
            
            translate([decorTotalWidth/2-corner,decorTotalWidth/2,0]) rotate([0,0,-45-90])
                champher(decorTotalWidth, champherDepth+decorDepth, 45, cutoutdelta, useX = false);
                
            translate([corner-decorTotalWidth/2,decorTotalWidth/2,0]) rotate([0,0,-45-90])
                champher(decorTotalWidth, champherDepth+decorDepth, 45, cutoutdelta, useX = true);
        }
}

module decorSides(height, fold = false){
    decorEdge = (decorTotalWidth - decorSide)*sqrt(2)/2;
    step1 = decorTotalWidth/2;
    step2 = height/2;
    edgestep1 = sqrt(pow(decorTotalWidth,2) + pow(decorSide,2) - pow(decorEdge,2))/2;;
    
    translate([0,step1,decorFullHeight/2]) rotate([fold?-90:0,0,0]) translate([0,step2,-decorFullHeight/2]) 
        hollowBox(decorSide, height, decorLineThickness, decorFullHeight, champherDepth + decorDepth);
    translate([0,-step1,decorFullHeight/2]) rotate([fold?90:0,0,0]) translate([0,-step2,-decorFullHeight/2]) 
        rotate([0,0,180])
        hollowBox(decorSide, height, decorLineThickness, decorFullHeight, champherDepth + decorDepth);
    translate([step1,0,decorFullHeight/2]) rotate([0,fold?90:0,0]) translate([step2,0,-decorFullHeight/2]) 
        rotate([0,0,180+90])
        hollowBox(decorSide, height, decorLineThickness, decorFullHeight, champherDepth + decorDepth);
    translate([-step1,0,decorFullHeight/2]) rotate([0,fold?-90:0,0]) translate([-step2,0,-decorFullHeight/2]) 
        rotate([0,0,180-90])
        hollowBox(decorSide, height, decorLineThickness, decorFullHeight, champherDepth + decorDepth);
    
    rotate([0,0,45]){
        translate([0,edgestep1,decorFullHeight/2]) rotate([fold?-90:0,0,0]) translate([0,step2,-decorFullHeight/2]) 
            hollowBox(decorEdge, height, decorLineThickness, decorFullHeight, champherDepth + decorDepth);
        translate([0,-edgestep1,decorFullHeight/2]) rotate([fold?90:0,0,0]) translate([0,-step2,-decorFullHeight/2]) 
            rotate([0,0,180])
            hollowBox(decorEdge, height, decorLineThickness, decorFullHeight, champherDepth + decorDepth);
        translate([edgestep1,0,decorFullHeight/2]) rotate([0,fold?90:0,0]) translate([step2,0,-decorFullHeight/2]) 
            rotate([0,0,180+90])
            hollowBox(decorEdge, height, decorLineThickness, decorFullHeight, champherDepth + decorDepth);
        translate([-edgestep1,0,decorFullHeight/2]) rotate([0,fold?-90:0,0]) 
            translate([-step2,0,-decorFullHeight/2]) rotate([0,0,180-90])
            hollowBox(decorEdge, height, decorLineThickness, decorFullHeight, champherDepth + decorDepth);   
    }
}
    
module renderBoxDecor( fold = false){
    corner = (decorTotalWidth-decorSide)/2;
    color(decorColor) translate([0,0,boxHeight - decorDepth]) 
        difference() {
            union(){
                decorFrame();
                
                translate([0,0,(decorFullHeight)/2]){
                    translate([0, (decorSide/2-decorLineThickness/2), 0]) 
                        cube([decorTotalWidth-2*decorLineThickness+cutoutdelta,
                                decorLineThickness, decorFullHeight],center=true);
                    
                    translate([0,-(decorSide/2-decorLineThickness/2), 0]) 
                        cube([decorTotalWidth-2*decorLineThickness+cutoutdelta,
                                decorLineThickness, decorFullHeight],center=true);
                    
                    translate([(decorSide/2-decorLineThickness/2), 0, 0]) 
                        cube([decorLineThickness, decorTotalWidth-2*decorLineThickness+cutoutdelta,
                                decorFullHeight],center=true);
                    
                    translate([-(decorSide/2-decorLineThickness/2), 0, 0]) 
                        cube([decorLineThickness, decorTotalWidth-2*decorLineThickness+cutoutdelta,
                                decorFullHeight],center=true);
                    
                    translate([0, 0, -(decorFullHeight)/2]) 
                        cylinder(h = decorFullHeight,  d=boxCircleWindowDiameter + 2*decorLineThickness);
                    
                    decorSides(boxHeight + decorHeight, fold);
                }
            }
            
            translate([0,0,-cutoutdelta]) 
                cylinder(h = decorFullHeight + 2*cutoutdelta,  d=boxCircleWindowDiameter);
            
            translate([0,0,- boxHeight + decorDepth]) { // resetting center point to the bottom
                renderHinge(cutoutDecor=true);
                renderBrassParts(cutout=true);
            }
            
            
        }
}

module renderLidDecor(fold=false){
    innercircle = 2*sqrt(pow(sphereDiameter/2,2) - pow(sphereDiameter/2 - sphereHeight,2)); 
    gap = (decorTotalWidth - innercircle)/2 - 2*decorLineThickness;
    lidBase = boxHeight + decorHeight + lidHeight - decorDepth;
    
    color(decorColor) translate([0,0,lidBase]) 
        difference(){
            union(){
                decorFrame();
                hollowOctagon(decorTotalWidth-2*gap, decorSide-2*gap*tan(45/2), decorLineThickness, decorFullHeight);
                
                translate([0,0,(decorFullHeight)/2])
                    decorSides(lidHeight + decorHeight, fold);
                
            }   
            if(!fold){
                translate([0,lidHeight,-lidBase + lidHeight])
                    renderHinge(cutoutDecor=true);
            }else{
                translate([0,0,-lidBase])
                    renderHinge(cutoutDecor=true);
            }
        }        
        
}

module renderBrassLeg(brassLegLength,cutout = false){
    cutoutWidth = 2*brassThickness;
    cutoutHeight = 2*brassSupportBaseWidth;
    
    if(cutout){
        renderBrassLeg(brassLegLength,false); // repeat the original leg before rendering the cutout
    }
    translate([-brassSupportBaseWidth/2,0,0]) 
        difference(){
            
            if(cutout){
                translate([0,0,-boxWallThickness])
                    cube([brassSupportBaseWidth, brassLegLength, boxWallThickness]);
            } else {
                cube([brassSupportBaseWidth, brassLegLength, brassThickness]);
            }
                
            translate([0,0,0])
                rotate([0,0,-brassSupportAngle/2])
                rotate([0,cutout?0:(90-brassChampherAngle),0])
                translate([-cutoutWidth,-cutoutdelta,-cutoutHeight/2])
                cube([cutoutWidth, brassLegLength+2*cutoutdelta,cutoutHeight]);
            
            
            translate([brassSupportBaseWidth,0,0])
                rotate([0,0,brassSupportAngle/2])
                rotate([0,cutout?0:(-90+brassChampherAngle),0])
                translate([0,-cutoutdelta,-cutoutHeight/2])
                cube([cutoutWidth, brassLegLength+2*cutoutdelta,cutoutHeight]);
        }
}


module renderBrassSupport(cutout = false){
    brassLegStart = brassDialDiameter/2 - brassDialWidth/2 - cutoutdelta;
    brassLegLength = boxCircleWindowDiameter/2 + brassSupportExtention - brassLegStart;
    
    difference(){
        union(){
            translate([0,brassLegStart,0]) renderBrassLeg(brassLegLength,cutout);
            rotate([0,0,120]) translate([0,brassLegStart,0]) renderBrassLeg(brassLegLength,cutout);
            rotate([0,0,240]) translate([0,brassLegStart,0]) renderBrassLeg(brassLegLength,cutout);
            
            if(!cutout){
                translate([0,0,brassThickness/2])
                    hollowCylinder(brassDialDiameter - brassDialWidth, brassHoleDiameter,brassThickness);
            }
        }
        
        translate([0,0,brassSupportExtentionThickness+brassThickness/2])
            hollowCylinder(boxCircleWindowDiameter + 2*brassSupportExtention + 2*cutoutdelta,
                           boxCircleWindowDiameter, brassThickness);
    }
}


module renderBrassDial(){
    hollowCylinder(brassDialDiameter, brassDialDiameter-2*brassDialWidth, brassThickness);
    
    
    // TODO: marks on the dial here - load from SVG, or something
}
module renderBrassFin(){
    lowerCutoutDiameter = brassFinLowerCutoutHeight + pow(brassHoleDiameter/2,2)/brassFinLowerCutoutHeight;
    lowerCutoutShift = lowerCutoutDiameter/2-brassFinLowerCutoutHeight;
    
    // finding the center of the circle to make a cutout on the front of the fin
    // brassFinUpperCutoutRadius is the radius, you can play with it to discover optimal look
    
    // start and end points of the arch on the fin:
    // point A: [+brassDialDiameter/2, brassFinHeight + brassThickness - brassFinVerticalDrop]
    // point B: [+brassDialDiameter/2 - brassDialWidth, brassThickness]

    aX = brassDialDiameter/2;
    aY = brassFinHeight + brassThickness - brassFinVerticalDrop;
    
    bX = brassDialDiameter/2 - brassDialWidth;
    bY = brassThickness;
   
    tana = -(bX-aX)/(bY-aY);
    
    midX = (aX+bX)/2;
    midY = (aY+bY)/2;
    
    // center line: (y-midY)/(x-midX) = tana
    // distance: (x-midX)^2 + (y-midY)^2 = (brassFinUpperCutoutRadius-h)^2
    // (r-h)^2 = r^2 - (AB/2)^2
    // solve as a system, get this:
    
    ab = sqrt(pow(aX-bX,2) + pow(aY-bY,2));
    cutoutH = brassFinUpperCutoutRadius - sqrt(pow(brassFinUpperCutoutRadius,2) - pow(ab/2,2));
    
    // Found it! Here is the center:
    upperCutoutCenterX = midX + (brassFinUpperCutoutRadius-cutoutH)/sqrt(1+pow(tana,2));
    upperCutoutCenterY = midY + tana*(brassFinUpperCutoutRadius-cutoutH)/sqrt(1+pow(tana,2));
    
    
    // Define the points for the square with cut corners
    points = [
        [-brassDialDiameter/2+brassDialWidth/2, brassThickness], 
        [-brassDialDiameter/2+brassDialWidth, brassThickness], 
        [-brassDialDiameter/2+brassDialWidth, 0], 
        [brassDialDiameter/2-brassDialWidth, 0], 
        [brassDialDiameter/2-brassDialWidth, brassThickness],
        [brassDialDiameter/2, brassThickness], 
        [brassDialDiameter/2, brassFinHeight + brassThickness] // tip
    ];
    
    difference(){
        linear_extrude(height = brassThickness) {
            polygon(points);
        }
            
        translate([0,-lowerCutoutShift,-cutoutdelta]) 
            cylinder(h = brassThickness + 2*cutoutdelta,  d=lowerCutoutDiameter);
        
        translate([upperCutoutCenterX,upperCutoutCenterY,-cutoutdelta]) 
            cylinder(h = brassThickness + 2*cutoutdelta,  d=brassFinUpperCutoutRadius*2);
    }

}

module renderBrassParts(cutout = false){
    brassLegStart = brassDialDiameter/2 - brassDialWidth/2 - cutoutdelta;
    brassLegLength = boxCircleWindowDiameter/2 + brassSupportExtention - brassLegStart;
    
    //brassVerticalPosition = boxHeight - brassSupportExtentionThickness;// - boxWallThickness;
    brassVerticalPosition = boxHeight - decorDepth - brassSupportExtentionThickness; //brassSupportExtentionThickness;// - boxWallThickness;
    
    /*
        how to figure out position: 
        2 we need it as high as possible to leave room
    */
    
    color(brassColor)  translate([0,0,brassVerticalPosition]) 
        {
           
            // Brass support:
            renderBrassSupport(cutout);
            
            if(!cutout){ // don't need these parts in cutout mode
                // Brass dial:
                translate([0,0,brassThickness*3/2 + brassPartsSpacing])
                    renderBrassDial();
                
                // Brass fin (sun)
                translate([0,0,brassThickness*3/2 + 2*brassPartsSpacing])  rotate([90,0,90])
                    renderBrassFin();
            }
        }
}


translate([0,0,-partsDistance])   renderBottom();
renderBox();
translate([0,0,1*partsDistance])  renderBrassParts();
translate([0,0,1*partsDistance])  renderHinge();
translate([0,0,2*partsDistance])  renderBoxDecor(fold = assemble);
translate([0,0,3*partsDistance])  renderLid();
translate([0,0,4*partsDistance])  renderLidDecor(fold = assemble);




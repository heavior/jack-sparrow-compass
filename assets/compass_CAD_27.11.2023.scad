/*

This model is not licenced for commercial use or redistribution.
For inquiries reach out through contacts here: https://github.com/heavior/jack-sparrow-compass


Last published: Nov 27 2023, newer version migth be in development
Next version with bugfixes and improvements: https://heavior.github.io/jack-sparrow-compass/assets/compass_CAD_27.11.2023.scad
To request updated version, leave comment here: https://www.therpf.com/forums/threads/interactive-jack-sparrow-compass-show-off-and-questions.354776/



How to use: 
1. modify "assemble" variable based on your interest
2. at the end of file, you can comment out parts you don't need in a render
3. tweak parameters to change dimensions. All dimensions are in millimeters
4. export STL using OpenSCAD

*/



/*

TODO:

fix: figure out artefacts when decor layer is folded - why are they where? what's the correct fix?

think - how does decoration end at the bottom of the box?
think - how does decoration end at the bottom of the lid?


brass parts - add marks
add hinge


add assembly:
    placement for nuts/incerts in the box
    holes and shampher for screws in the bottom
    
elctronics:
    add hole for magnet in the lid
    figure out lighting (UV LED)

*/

assemble = false; // change rendering mode



boxWidth = 80;          // outer size, not including decor
boxHeight = 22;         // box height, not including decor
lidHeight = 11;         // lid base hight, not including decor or dome
boxWallThickness = 3;   //standard wood thickness
lidWallThickness = 6;   // thickness for the lid to accomodate magnet inside

decorThickness = 2.6;       // width of decoration stripes
decorHeight = .5;           // how thick is decor material, it will increase total box size
decorBendThickness = .1;    // how thick is the leftover material where decor layer would be bent
decorOverhang = .5;         // how much does decor overlay the central hole
decorDepth = 1;             // How deep will decor go into the box
// TODO: think if decor should overhang inside like it used to

sphereDiameter = 60; // dome parameters
sphereHeight = 16.7;
sphereThickness = boxWallThickness;
bottomThickness = boxWallThickness;

// brass part parameters
brassThickness = 2; // brass material
brassSupportBaseWidth = 4;   //max width of one of three suports - "legs" 
brassSupportAngle = 4;  // How brass support narrows
brassShampherAngle = 45; // How sharp should we shape the brass support. Make sure you have cnc mill with that angle
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

boxColor = "brown";
decorColor = "gray";
brassColor = "yellow";

partsDistance = assemble?0:2*boxHeight;
brassPartsSpacing = assemble?0:2*brassThickness;
cutoutdelta = .1*boxWallThickness;
$fn = 2*360.0; // circle rendering precision

sideLength = .6*boxWidth;

shampherDepth = decorHeight-decorBendThickness;
decorWidth = boxWidth + 2*shampherDepth;
decorSide = sideLength + 2*tan(45/2)*shampherDepth;
decorFullHeight = decorHeight + decorDepth;

innerBoxWidth = boxWidth - 2*boxWallThickness;
innerSideLength = sideLength - 2*tan(45/2)*boxWallThickness;
innerBoxHeight = boxHeight - boxWallThickness;

boxCircleWindowDiameter = (sideLength - 2*decorThickness)*sqrt(2);


innerLidWidth = boxWidth - 2*lidWallThickness;
innerLidSideLength = sideLength - 2*tan(45/2)*lidWallThickness;
innerLidHeight = lidHeight - boxWallThickness;

       
echo("side:", sideLength);
echo("inner width:", innerBoxWidth);



// Function to create a shape with a square base and cut corners
module octagon(width, side, height) {
    cornerCut = (width - side)/2;
    // Define the points for the square with cut corners
    points = [
        [cornerCut, 0], // Bottom left corner cut
        [width - cornerCut, 0], // Bottom right corner cut
        [width, cornerCut], // Top right corner cut
        [width, width - cornerCut], // Top right corner cut
        [width - cornerCut, width], // Top left corner cut
        [cornerCut, width], // Top left corner cut
        [0, width - cornerCut], // Bottom left corner cut
        [0, cornerCut] // Bottom left corner cut
    ];

    // Extrude to the specified height
    linear_extrude(height = height) {
        polygon(points);
    }
}




module renderBox(){
    // Using difference() to subtract one shape from another
    color(boxColor)
        difference() {
            // outer box
            octagon(boxWidth, sideLength, boxHeight);
            
            // cut out inner box
            translate([(boxWidth - innerBoxWidth)/2, (boxWidth - innerBoxWidth)/2, -cutoutdelta]) 
                octagon(innerBoxWidth, innerSideLength, innerBoxHeight+cutoutdelta); // Adjust the translate values as needed
           
            // cut out inner circle
            translate([boxWidth/2,boxWidth/2,-cutoutdelta]) 
                cylinder(h = boxHeight + 2*cutoutdelta,  d=boxCircleWindowDiameter+2*decorOverhang);
           
            translate([-shampherDepth,-shampherDepth,boxHeight-decorDepth])
                renderBoxDecor(true);   
            
            translate([boxWidth/2, boxWidth/2,boxHeight - boxWallThickness]) 
                renderBrassSupport();
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
        sphere(outerR, $fn=100); // Larger sphere
        translate([0, 0, -0.1]) // Slightly move the inner sphere down for a clean cut
        sphere(innerR, $fn=100); // Smaller sphere
    }
}

module hollowOctagon(width, side, thickness, height){
    innerSide = side - 2*tan(45/2 )*thickness;
    difference() {
        // outer box
        octagon(width, side, height);
        
        // cut out inner box
        translate([thickness, thickness, -cutoutdelta]) 
            octagon(width - 2*thickness, innerSide, height+2*cutoutdelta); 
    }
}

module hollowBox(a, b, thickness, height, shampherD){
    difference() {
        // outer box
        cube([a, b, height],center=true);
        
        // cut out inner box
        cube([a - 2*thickness, b - 2*thickness, height + 2*cutoutdelta],center=true); 
       
        //translate([a/2,b/2,-height/2]) rotate([0,0,180])
        //    shampher(a, shampherD, 45, 1+cutoutdelta, useX = true);   
        
        translate([-a/2,-b/2,-height/2]) rotate([0,0,0])
            shampher(a, shampherD, 45, 1+cutoutdelta, useX = true);   

        translate([a/2,-b/2,-height/2]) rotate([0,0,0])
            shampher(b, shampherD, 45/2, 1+cutoutdelta, useX = false);   
        
        translate([-a/2,-b/2,-height/2]) rotate([0,0,0])
            shampher(b, shampherD, 45/2, 1+cutoutdelta, useX = false);   
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

//
module renderLid(){
    // Using difference() to subtract one shape from another
    
    innerSphereRadius = sphereDiameter/2 - sphereThickness;
    sphereDiameterAtLidLevel = 2*sqrt(pow(innerSphereRadius,2) - pow(innerSphereRadius - sphereHeight + sphereThickness-boxWallThickness,2)); 
    
    color(boxColor)
        union(){
            difference() {
                // outer box
                octagon(boxWidth, sideLength, lidHeight);
                
                // cut out inner box
                translate([(boxWidth - innerLidWidth)/2, (boxWidth - innerLidWidth)/2, -cutoutdelta]) 
                    octagon(innerLidWidth, innerLidSideLength, innerLidHeight+cutoutdelta); // Adjust the translate values as needed
               
                // cut out inner circle
                translate([boxWidth/2,boxWidth/2,-cutoutdelta]) 
                      cylinder(h = boxHeight + 2*cutoutdelta,  d=sphereDiameterAtLidLevel);
                
                // cutout decor
                
                translate([-shampherDepth,-shampherDepth,lidHeight-decorDepth])
                    renderLidDecor(true);   
            }
            
            // Dome
            
            difference() {
                translate([boxWidth/2,boxWidth/2,sphereHeight + lidHeight - sphereDiameter/2])
                    hollowSphere(sphereDiameter/2,innerSphereRadius);
                
                cube([boxWidth, boxWidth, lidHeight-boxWallThickness]); // A cube that acts as a cutting plane
                
                translate([0,0, -sphereDiameter])
                    cube([boxWidth, boxWidth, sphereDiameter+2*cutoutdelta]); // A cube that acts as a cutting plane
            }
        }
}

module shampher(length, depth, angle, delta, useX=true)
{
    points = [
        [-delta, -delta],
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
    corner = (decorWidth-decorSide)/2;
    color(decorColor)
        difference() {
            union(){
                hollowOctagon(decorWidth, decorSide, decorThickness, decorHeight+decorDepth);
            }
            
            shampher(decorWidth, shampherDepth+decorDepth, 45, cutoutdelta, useX = false);    
            shampher(decorWidth, shampherDepth+decorDepth, 45, cutoutdelta, useX = true);
            translate([decorWidth,decorWidth,0]) rotate([0,0,180]){
                shampher(decorWidth, shampherDepth+decorDepth, 45, cutoutdelta, useX = false);
                shampher(decorWidth, shampherDepth+decorDepth, 45, cutoutdelta, useX = true);
            }
            translate([corner,0,0]) rotate([0,0,45])
                shampher(decorWidth, shampherDepth+decorDepth, 45, cutoutdelta, useX = false);
            
            translate([decorWidth-corner,0,0]) rotate([0,0,45])
                shampher(decorWidth, shampherDepth+decorDepth, 45, cutoutdelta, useX = true);
            
            translate([decorWidth-corner,decorWidth,0]) rotate([0,0,-45-90])
                shampher(decorWidth, shampherDepth+decorDepth, 45, cutoutdelta, useX = false);
                
            translate([corner,decorWidth,0]) rotate([0,0,-45-90])
                shampher(decorWidth, shampherDepth+decorDepth, 45, cutoutdelta, useX = true);
        }
}




module decorSides(height, fold = false){
    decorEdge = (decorWidth - decorSide)*sqrt(2)/2;
    step1 = decorWidth/2;
    step2 = height/2;
    edgestep1 = sqrt(pow(decorWidth,2) + pow(decorSide,2) - pow(decorEdge,2))/2;;
    
    translate([0,step1,decorFullHeight/2]) rotate([fold?-90:0,0,0]) translate([0,step2,-decorFullHeight/2]) 
        hollowBox(decorSide, height, decorThickness, decorFullHeight, shampherDepth + decorDepth);
    translate([0,-step1,decorFullHeight/2]) rotate([fold?90:0,0,0]) translate([0,-step2,-decorFullHeight/2]) 
        rotate([0,0,180])
        hollowBox(decorSide, height, decorThickness, decorFullHeight, shampherDepth + decorDepth);
    translate([step1,0,decorFullHeight/2]) rotate([0,fold?90:0,0]) translate([step2,0,-decorFullHeight/2]) 
        rotate([0,0,180+90])
        hollowBox(decorSide, height, decorThickness, decorFullHeight, shampherDepth + decorDepth);
    translate([-step1,0,decorFullHeight/2]) rotate([0,fold?-90:0,0]) translate([-step2,0,-decorFullHeight/2]) 
        rotate([0,0,180-90])
        hollowBox(decorSide, height, decorThickness, decorFullHeight, shampherDepth + decorDepth);
    
    rotate([0,0,45]){
        translate([0,edgestep1,decorFullHeight/2]) rotate([fold?-90:0,0,0]) translate([0,step2,-decorFullHeight/2]) 
            hollowBox(decorEdge, height, decorThickness, decorFullHeight, shampherDepth + decorDepth);
        translate([0,-edgestep1,decorFullHeight/2]) rotate([fold?90:0,0,0]) translate([0,-step2,-decorFullHeight/2]) 
            rotate([0,0,180])
            hollowBox(decorEdge, height, decorThickness, decorFullHeight, shampherDepth + decorDepth);
        translate([edgestep1,0,decorFullHeight/2]) rotate([0,fold?90:0,0]) translate([step2,0,-decorFullHeight/2]) 
            rotate([0,0,180+90])
            hollowBox(decorEdge, height, decorThickness, decorFullHeight, shampherDepth + decorDepth);
        translate([-edgestep1,0,decorFullHeight/2]) rotate([0,fold?-90:0,0]) 
            translate([-step2,0,-decorFullHeight/2]) rotate([0,0,180-90])
            hollowBox(decorEdge, height, decorThickness, decorFullHeight, shampherDepth + decorDepth);   
    }
}
    
module renderBoxDecor( fold = false){
    corner = (decorWidth-decorSide)/2;
    color(decorColor)
        difference() {
            union(){
                decorFrame();
                translate([decorWidth/2,decorWidth/2,(decorFullHeight)/2]){
                    translate([0, (decorSide/2-decorThickness/2), 0]) 
                        cube([decorWidth-2*decorThickness+cutoutdelta,decorThickness, decorFullHeight],center=true);
                    
                    translate([0,-(decorSide/2-decorThickness/2), 0]) 
                        cube([decorWidth-2*decorThickness+cutoutdelta,decorThickness, decorFullHeight],center=true);
                    
                    translate([(decorSide/2-decorThickness/2), 0, 0]) 
                        cube([decorThickness, decorWidth-2*decorThickness+cutoutdelta, decorFullHeight],center=true);
                    
                    translate([-(decorSide/2-decorThickness/2), 0, 0]) 
                        cube([decorThickness, decorWidth-2*decorThickness+cutoutdelta, decorFullHeight],center=true);
                    
                    translate([0, 0, -(decorFullHeight)/2]) 
                        cylinder(h = decorFullHeight,  d=boxCircleWindowDiameter + 2*decorThickness);
                    
                    decorSides(boxHeight + decorHeight, fold);
                   
                }
            }
            
            translate([decorWidth/2,decorWidth/2,-cutoutdelta]) 
                cylinder(h = decorFullHeight + 2*cutoutdelta,  d=boxCircleWindowDiameter);
                          
        }
        
}
/*

function SVG_OCTAGON_DECOR(width, side, thickness, innercircle, cutoutwidth=0, cutoutheight=0,scale=100){

  if(cutoutheight/thickness > cutoutThreshold){
    cutoutheight = thickness;
  }
  var gap = 4*thickness;
  gap = (width - innercircle)/2 - 2*thickness;

  var currentWidth = width;
  var currentSide = side;
  var a = width;
  var b = side;
  var tan = Math.tan( 45.0/2 * (Math.PI / 180));
  return SVG_OCTAGON(currentWidth,currentSide,cutoutwidth, cutoutheight,decorColor, scale) 
        + SVG_OCTAGON(currentWidth-=2*thickness,currentSide-=2*thickness*tan,0,0,emptyColor,scale)
        + SVG_OCTAGON(currentWidth-=gap,currentSide-=gap*tan,0,0,decorColor,scale)
        + SVG_OCTAGON(currentWidth-=2*thickness,currentSide-=2*thickness*tan,0,0,emptyColor,scale);
        //+ SVG_OCTAGON(currentWidth-=gap,currentSide-=gap*tan,0,0,decorColor,scale);
}

*/

module renderLidDecor(fold=false){
    innercircle = 2*sqrt(pow(sphereDiameter/2,2) - pow(sphereDiameter/2 - sphereHeight,2)); 
    gap = (decorWidth - innercircle)/2 - 2*decorThickness;
    
    color(decorColor)
        union(){
            decorFrame();
            translate([gap,gap,0])
                hollowOctagon(decorWidth-2*gap, decorSide-2*gap*tan(45/2), decorThickness, decorFullHeight);
            
            translate([decorWidth/2,decorWidth/2,(decorFullHeight)/2]){
                
                decorSides(lidHeight + decorHeight, fold);
               
            }
        }            
        
}

module renderBrassLeg(brassLegLength){
    cutoutWidth = 2*brassThickness;
    cutoutHeight = 2*brassSupportBaseWidth;
    translate([-brassSupportBaseWidth/2,0,0]) 
        difference(){
            cube([brassSupportBaseWidth, brassLegLength, brassThickness]);
            
            translate([0,0,0])
                rotate([0,0,-brassSupportAngle/2])
                rotate([0,90-brassShampherAngle,0])
                translate([-cutoutWidth,-cutoutdelta,-cutoutHeight/2])
                cube([cutoutWidth, brassLegLength+2*cutoutdelta,cutoutHeight]);
            
            
            translate([brassSupportBaseWidth,0,0])
                rotate([0,0,+brassSupportAngle/2])
                rotate([0,-90+brassShampherAngle,0])
                translate([0,-cutoutdelta,-cutoutHeight/2])
                cube([cutoutWidth, brassLegLength+2*cutoutdelta,cutoutHeight]);
        }
}


module renderBrassSupport(){
    brassLegStart = brassDialDiameter/2 - brassDialWidth/2 - cutoutdelta;
    brassLegLength = boxCircleWindowDiameter/2 + brassSupportExtention - brassLegStart;
    
    difference(){
        union(){
            translate([0,brassLegStart,0]) renderBrassLeg(brassLegLength);
            rotate([0,0,120]) translate([0,brassLegStart,0]) renderBrassLeg(brassLegLength);
            rotate([0,0,240]) translate([0,brassLegStart,0]) renderBrassLeg(brassLegLength);
            
            translate([0,0,brassThickness/2])
                hollowCylinder(brassDialDiameter - brassDialWidth, brassHoleDiameter,brassThickness);
        }
        
        translate([0,0,brassSupportExtentionThickness+brassThickness/2])
            hollowCylinder(boxCircleWindowDiameter + 2*brassSupportExtention+2*cutoutdelta, boxCircleWindowDiameter+2*decorOverhang, brassThickness);
    }
}


module renderBrassDial(){
    hollowCylinder(brassDialDiameter, brassDialDiameter-2*brassDialWidth, brassThickness);
    
    // TODO: marks on the dial here - load from SVG, or something
}
module renderBrassFin(){
    lowerCutoutDiameter = brassFinLowerCutoutHeight + pow(brassHoleDiameter/2,2)/brassFinLowerCutoutHeight;
    lowerCutoutShift = lowerCutoutDiameter/2-brassFinLowerCutoutHeight;
    
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
    
    // could be minus here:
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

module renderBrassParts(){
    brassLegStart = brassDialDiameter/2 - brassDialWidth/2 - cutoutdelta;
    brassLegLength = boxCircleWindowDiameter/2 + brassSupportExtention - brassLegStart;
    
    color(brassColor) translate([boxWidth/2, boxWidth/2,0])
        {
           
            // Brass support:
            renderBrassSupport();
            
            // Brass dial:
            translate([0,0,brassThickness*3/2 + brassPartsSpacing])
                renderBrassDial();
            
            // TODO: marks on the dial here - load from SVG, or something
            
            // Brass fin (sun)
            translate([0,0,brassThickness*3/2 + 2*brassPartsSpacing])  rotate([90,0,90])
                renderBrassFin();
        }
}


lidBase = boxHeight + decorHeight + lidHeight - decorDepth;


translate([boxWallThickness,boxWallThickness,-partsDistance])                       renderBottom();
renderBox();
translate([0,0,boxHeight - boxWallThickness + 1*partsDistance])                     renderBrassParts();
translate([-decorHeight,-decorHeight,boxHeight - decorDepth + 2*partsDistance])     renderBoxDecor(fold = assemble);
translate([0,0,boxHeight + decorHeight + 3*partsDistance])                          renderLid();
translate([-decorHeight,-decorHeight,lidBase + 4*partsDistance])                    renderLidDecor(fold = assemble);




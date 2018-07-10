% determines discrete coordinates of a line between two points
% by Roland Stange 20161025

function [x y] = makeLinePoints(P1x, P1y, P2x, P2y)

nrOfPoints = max([abs(P1x-P2x) abs(P1y-P2y)])+1;
x = round(linspace(P1x, P2x, nrOfPoints));
y = round(linspace(P1y, P2y, nrOfPoints));

end
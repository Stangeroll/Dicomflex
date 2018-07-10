function dist = pointDist(points, point)
x = points(:,1);
y = points(:,2);
dist = arrayfun(@(x,y) sqrt((point(1)-x)^2+(point(2)-y)^2), x, y);
end
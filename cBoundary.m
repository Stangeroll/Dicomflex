classdef boundary
    properties
        name = '';
        coord = [];
        various = {};
    end
    
    methods (static)
    
    end
    
    methods
        function ind = getBoundInd(Bounds, boundName)
            try 
                %ind = ismember(boundName{1}, {Bounds.name});
                ind = find(ismember({Bounds.name}, boundName));
            catch
                ind = 0;
            end
            if isempty(ind)
                ind = 0;
            end
        end
        
        function bound = getBoundOfType(Bounds, boundName)
            ind = Bounds.getBoundInd(boundName);
            if ind==0
                bound = Bounds.empty;
                bound(1).name = boundName;
            else
                bound = Bounds(ind);
            end
        end
        
        function bounds = setBound(Bounds, boundIn)
            ind = Bounds.getBoundInd(boundIn.name);
            if ind==0
                Bounds(end+1) = boundIn;
            else
                Bounds(ind) = boundIn;
            end
            bounds = Bounds;
        end
        
        function area = areaBound(bound)
            xCoord = bound.coord(:,1);
            yCoord = bound.coord(:,2);
            %area = polyarea(bound.coord(:,1), bound.coord(:,2));   % this would not include the boundary itselfe
            
            mask = zeros(max(xCoord), max(yCoord));
            mask(sub2ind(size(mask), xCoord, yCoord)) = 1;
            mask = imfill(mask,'holes');
            area = sum(sum(mask));
        end
        
        function obj = boundary
        end
    end
    
end
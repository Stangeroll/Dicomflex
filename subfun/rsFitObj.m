classdef rsFitObj
    properties
        xData = [];
        yData = [];
        ftype = fittype;
        gof = struct('sse', [], 'rsquare', [], 'dfe', [], 'adjrsquare', [], 'rmse', []);
        cfun = cfit;
        parameters = {};
        values = [];
    end
    
    methods (static)
    
    end
    
    methods
        function rsFitObj = fitIt(rsFitObj)
            [cfun, gof, output] = fit(rsFitObj.xData, rsFitObj.yData, rsFitObj.ftype);
            rsFitObj.gof = gof;
            rsFitObj.cfun = cfun;
            coeffnames = rsFitObj.getCoeffNames;
            for i = 1:numel(coeffnames)
                rsFitObj.parameters(i) = coeffnames(i);
                rsFitObj.values(i) = eval(['cfun.' coeffnames{i} ';']);
            end
        end
        
        function formulaSring = getFormula(rsFitObj)
            formulaSring = formula(rsFitObj.ftype);
        end
        
        function Names = getIndepParNames(rsFitObj)
            Names = indepnames(rsFitObj.ftype);
        end
        
        function Names = getDepParNames(rsFitObj)
            Names = dependnames(rsFitObj.ftype);
        end
        
        function Names = getCoeffNames(rsFitObj)
            Names = coeffnames(rsFitObj.ftype);
        end
        
        function options = getFitOptions(rsFitObj)
            options = fitoptions(rsFitObj.ftype);
        end
        
        function boundReached = isBoundReached(rsFitObj)
            opts = rsFitObj.getFitOptions;
             % is a value closer than 0.01% to the boundary
            upper = abs((rsFitObj.values - opts.upper)./rsFitObj.values)<0.0001;
            lower = abs((rsFitObj.values - opts.lower)./rsFitObj.values)<0.0001;
            boundReached = any(lower|upper);
        end
        
        function [fitOk reason] =  checkFit(rsFitObj)
            if rsFitObj.gof.rsquare == -Inf
                fitOk = false;
                reason = 'rsquare';
            elseif rsFitObj.isBoundReached
                fitOk = false;
                reason = 'ParamBound';
            else
                fitOk = true;
                reason = '';
            end
        end
        
        function obj = rsFitObj
        end
    end
    
end
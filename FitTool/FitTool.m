% FitTool
% transfere name value pairs as follows: raw data is transfered as name value pairs and one name value pair must
% contain the fittype.
% e.g.: FitTool('x', [1 2 3], 'y', [0.5 1.1 1.45], 'fittype', ftype)

classdef FitTool < handle
    
    properties
        versionFitTool = '0.2';
        handles = struct('figure', []);
        dat = struct('name', {}, 'value', {});
        fitInfo = struct('ftype', [], 'current', [], 'gof', []);
        cfg = struct([]); % config file
        cfgPath = '';
        origFittype = [];
        send = false;
    end
    
    methods(Static)
        function fcnString = getFcnString(ftype)
            formulaString = formula(ftype);
            dependString = dependnames(ftype); dependString = dependString{1};
            indepString = indepnames(ftype); indepString = indepString{1};
            
            argumentStrings = argnames(ftype);
            argumentString = [];
            for i = 1:numel(argumentStrings)
                argumentString = [argumentString argumentStrings{i} ','];
            end
            argumentString(end) = []; % remove ","
            
            fcnString = [dependString '(' argumentString ') = ' formulaString];
            
        end
    end
    
    methods
        function dummy(d)
            disp('test dummy');
        end
        
        % % % FitTypeInfo handling % % %
        function d = gui2fittype(d)
            tabDat = d.handles.table.Data;
            
            fitOptions = fitoptions('Method','NonlinearLeastSquares',...
                'Lower',         [tabDat{:,3}],...
                'Upper',         [tabDat{:,4}],...
                'Startpoint',    [tabDat{:,2}]);
            
            d.fitInfo.ftype = fittype(d.handles.fcn.String, 'coefficients', tabDat(:,1),...
                'independent', d.handles.indep.String, 'options', fitOptions );
            
            d.fitInfo.current = [tabDat{:,5}];
            d.fittype2fitInfo;
        end
        
        function d = fittype2fitInfo(d)
            if isempty(d.fitInfo.ftype)
                fitO = fitoptions('Method','NonlinearLeastSquares',...
                    'Lower',         [-Inf,  -Inf],...
                    'Upper',         [ Inf,   Inf],...
                    'Startpoint',    [   0,     0]);
                
                fitFcn = ['m*x+t'];
                
                ftype = fittype(fitFcn, 'coefficients', { 'm', 't' },...
                    'independent', 'x', 'options', fitO );
            else
                ftype = d.fitInfo.ftype;
            end
            d.fitInfo.fcnString = formula(ftype);
            d.fitInfo.indepPar = indepnames(ftype);
            d.fitInfo.depPar = dependnames(ftype);
            d.fitInfo.coeffs = coeffnames(ftype);
            d.fitInfo.foptioins = fitoptions(ftype);
            if isempty(d.fitInfo.current)
                d.fitInfo.current = d.fitInfo.foptioins.StartPoint;
            end
            d.fitInfo2gui;
        end
        
        function d = fitInfo2gui(d) % update GUI
            %% update fitFcn textbox
            coeffStr = [];
            if isempty(d.handles.table.Data)
                coeffs = d.fitInfo.coeffs;
            else
                coeffs = d.handles.table.Data(:,1);
            end
            for i = 1:numel(coeffs)
                coeffStr = [coeffStr coeffs{i} ','];
            end
            coeffStr(end) = [];
            d.handles.coeffs.String = coeffStr;
            d.handles.depend.String = d.fitInfo.depPar;
            d.handles.indep.String = d.fitInfo.indepPar;
            d.handles.fcn.String = d.fitInfo.fcnString;
            
            %% update table            
            singleRow = {};
            tabDat = {};
            
            for i = 1:numel(d.fitInfo.coeffs)
                singleRow = {d.fitInfo.coeffs{i}, d.fitInfo.foptioins.StartPoint(i), d.fitInfo.foptioins.Lower(i), d.fitInfo.foptioins.Upper(i), d.fitInfo.current(i)};
                
                tabData(i,:) = singleRow;
            end
            
            d.handles.table.Data = tabData;
            %d.handles.table.RowName = [1:numel(d.fitInfo.coeffs)];
            
            
            %% update graph
            ax = d.handles.imgAxis;
            axes(ax);
            [xName, xData] =  getIndependent(d);
            [yName, yData] =  getDependent(d);
            hp_raw = plot(xData, yData);  % hp - handlePlot
            hold on;
            hp_raw.LineStyle = 'none';
            hp_raw.Marker = 'o';
            % plot fit with current values
                % generate workspace variables
                for i=1:numel(d.fitInfo.coeffs)
                    eval([d.fitInfo.coeffs{i} '=' num2str(d.fitInfo.current(i))]);
                end
            
%             Fcn1 = @(TE)exp(-TE/T2star)*sqrt(S1^2+S2^2+2*S1*S2*cos(2*pi/2.3*TE));
%             Fcn2 = str2func('(TE)exp(-TE/T2star)*sqrt(S1^2+S2^2+2*S1*S2*cos(2*pi/2.3*TE))');
%             %Fcn2 = str2func(['@(' d.fitInfo.indepPar{1} ')' d.fitInfo.fcnString])
            eval(['Fcn = @(' d.fitInfo.indepPar{1} ')' d.fitInfo.fcnString])
            fplot(Fcn, xlim);
            hold off
        end
        
        function d = coeffs2tableCurrent(d, coeffs)
            % used for fitData method
            coeffs
            names = d.handles.table.Data(:,1);
            for i = 1:numel(names)
                d.handles.table.Data(i,5) = {coeffs.(names{i})};
            end
            d = gui2fittype(d);
        end
        
        % % % Program functions % % %
        function d = newRawData(d, varargin)
            
            j = 0;
            for i = 1:2:numel(varargin)
                j = j+1;
                name = varargin(i);
                value = varargin(i+1);
                switch name{1}
                    case 'fittype'
                        d.fitInfo.ftype = value{1};
                        d.origFittype = value{1};
                    otherwise
                        d.dat(j).name = name{1};
                        
                        if iscolumn(value{1})
                            d.dat(j).value = value{1};
                        elseif isrow(value{1})
                            d.dat(j).value = value{1}';
                        else
                            msgbox(['input array ' name{1} ' not one dimensional']);
                        end
                end
            end
            if numel(d.dat)>j
                d.dat(j+1:end) = [];
            end
        end
        
        function [xName, xData] =  getIndependent(d)
            xName = d.fitInfo.indepPar{1};
            xData = d.dat(ismember({d.dat.name}, xName)).value;
        end
        
        function [yName, yData] =  getDependent(d)
            yName = d.fitInfo.depPar{1};
            yData = d.dat(ismember({d.dat.name}, yName)).value;
        end
        
        % % % Gui interaction % % %
        function imgAxisButtonDown(d, a, hit, varargin)
            
        end
        
        % % Buttons % %
        function d = addRow(d, varargin)
            d.handles.table.Data(end+1,1) = {'new par'};
        end
        
        function d = remRow(d, varargin)
            d.handles.table.Data(end,:) = [];
        end
        
        function d = sendData(d, varargin)
            % this is just a dummy function. The correct callback is set when calling the FitTool from another application
            d.send = true;
        end
        
        function d = fitData(d, varargin)
            [xName, xData] =  getIndependent(d);
            [yName, yData] =  getDependent(d);
            
            [coeffs, gof, output] = fit( xData, yData, d.fitInfo.ftype);
            d = coeffs2tableCurrent(d, coeffs);
            d.fitInfo.gof = gof;
            
            % create report
            f = figure();
            output2 = output;
            output2 = rmfield(output2, 'residuals');
            output2 = rmfield(output2, 'Jacobian');
            fnames = [fieldnames(gof); fieldnames(output2)];
            values = [struct2cell(gof); struct2cell(output2)];
            dat = {};
            for i = 1:numel(fnames)
                dat(i,1) = fnames(i);
                dat(i,2) = values(i);
            end
            
            t = uitable(f, 'data', dat)
            
            
        end
        
        % % Others % %
        function d = fcnChange(d, varargin)
            d.gui2fittype;
        end
        
        function d = indepChange(d, varargin)
            d.gui2fittype;
        end
        
        function d = dependChange(d, varargin)
            d.gui2fittype;
        end
        
        function d = coeffsChange(d, varargin)
            d.gui2fittype;
        end
        
        function d = tableEdit(d, tableData, tableEvent)
            coeffStr = [];
            for i = 1:numel(d.handles.table.Data(:,1))
                coeffStr = [coeffStr d.handles.table.Data{i,1} ','];
            end
            coeffStr(end) = [];
            d.handles.coeffs.String = coeffStr;
            
            d.coeffsChange(d);
        end
        
        function d = tableKeyPress(d, tableData, tableEvent)
                            
        end
        
        % % % ProgramMenue interaction % % %
        function menuCallback(d, fcn, hm, varargin)
            try
                tmp = feval(fcn);
            end
            if exist('tmp')
                d.dat = tmp;
            end
        end
        
        function saveData(d, varargin)
            
            saveDate = datetime('now');
            msgbox(['File saved under: ' path]);
        end
        
        function loadData(d, varargin)
            
        end
        
        % % % Program Start and GUI creation % % %
        function menuHandles = createMenu(d, s, parent)
            for i = 1:numel(s)
                sc = s{i};
                htmp = parent;
                h = htmp;
                
                % check how deep the menu already exists
                lvl = 0;
                while ~isempty(htmp)
                    lvl = lvl+1;
                    tmp = htmp.Children;
                    tmp = tmp(arrayfun(@(x) ismember(class(x), {'matlab.ui.container.Menu'}) , tmp));
                    htmp = tmp(arrayfun(@(x) ismember(x.Label, sc.path(lvl)) ,tmp));
                    if ~isempty(htmp)
                        h = htmp;
                    end
                end
                    
                
                % now create übrige menu entries
                for j = lvl:numel(sc.path)
                    sc.h(j) = uimenu(h, 'Label', sc.path{j});
                    h = sc.h(j);
                    if j==numel(sc.path)
                        sc.h(j).Callback = eval(sc.callback);
                    end
                end
                % store handle data
                menuHandles(i).source = s{i};
                menuHandles(i).handle = sc.h(end);
            end
            
            % obsolete version:
%             for i=1:numel(s.name)
%                 name = s.name{i};
%                 givenName = s.givenName{i};
%                 s.h(i) = uimenu(parent, 'Label', givenName);
%                 if ~isfield(s, name) % generate callback, because if true, its the last element in menu hirarchy
%                     cb = s.callBack{i};
%                     s.h(i).Callback = eval(cb);
%                 else
%                     s.(name) = d.createMenu(s.(name), s.h(i));
%                 end
%                 
%             end
        end
        
        function setGUI(varargin) % set gui object position and size
            % width of table is fix in size and is not allowed to be changed
            d = varargin{1};
            cfg = d.cfg;
            h = d.handles;
            fSize = get(h.figure, 'position');
            fH = fSize(4); fW = fSize(3); % figure Height and Width
            GS1 = cfg.GS1; % GapSize 1 in pxl
            GS2 = cfg.GS2; % GapSize 2 in pxl
            
            tW = h.table.Position(3); % table Height and Width
            
            % positon of Figure window
            imgH = cfg.imgAxis.height;    % image axis hight in percent
            
            h.imgAxis.OuterPosition(1) = GS2;
            h.imgAxis.OuterPosition(3) = fW-tW-GS2-GS2;
            h.imgAxis.OuterPosition(4) = fH*imgH;
            h.imgAxis.OuterPosition(2) = fH-fH*imgH;
            
            h.depend.Position(1) = GS2;
            h.depend.Position(3) = (fW-tW-GS2-GS1)*0.08;
            h.depend.Position(4) = 20;
            h.depend.Position(2) = GS1;
            
            h.indep.Position(1) = GS2+h.depend.Position(1)+h.depend.Position(3);
            h.indep.Position(3) = (fW-tW-GS2-GS1)*0.08;
            h.indep.Position(4) = 20;
            h.indep.Position(2) = GS1;
            
            h.coeffs.Position(1) = GS2+h.indep.Position(1)+h.indep.Position(3);
            h.coeffs.Position(3) = (fW-tW-GS2-GS1)*0.2;
            h.coeffs.Position(4) = 20;
            h.coeffs.Position(2) = GS1;
            
            h.fcn.Position(1) = GS2+h.coeffs.Position(1)+h.coeffs.Position(3);
            h.fcn.Position(3) = (fW-tW-GS2-GS1)*0.6;
            h.fcn.Position(4) = 20;
            h.fcn.Position(2) = GS1;
            
            h.addRow.Position(1) = fW-h.table.Position(3)-GS2;
            h.addRow.Position(3) = tW/4;
            h.addRow.Position(4) = 20;
            h.addRow.Position(2) = GS1;
            
            h.remRow.Position(1) = fW-3*h.table.Position(3)/4-GS2;
            h.remRow.Position(3) = tW/4;
            h.remRow.Position(4) = 20;
            h.remRow.Position(2) = GS1;
            
            h.sendData.Position(1) = fW-2*h.table.Position(3)/4-GS2;
            h.sendData.Position(3) = tW/4;
            h.sendData.Position(4) = 20;
            h.sendData.Position(2) = GS1;
            
            h.fitData.Position(1) = fW-h.table.Position(3)/4-GS2;
            h.fitData.Position(3) = tW/4;
            h.fitData.Position(4) = 20;
            h.fitData.Position(2) = GS1;
            
            % table at top right with fixed width and height tabH
                tabH = 0.8; % table hight in percent
                
                h.table.Position(1) = fW-h.table.Position(3)-GS2;
                h.table.Position(4) = fH*tabH;
                h.table.Position(2) = fH-h.table.Position(4);
            
        end
        
        function d = createGUI(d)   % Define Buttons, Axis,... and set callbacks, initValues,...
            d.handles.figure = figure;
            h = d.handles;
            h.figure.Position(3) = 1024;
            h.figure.Position(4) = 512;
            movegui(h.figure, 'center');
            %h.figure.WindowKeyPressFcn = @d.keyPress;
            %h.figure.WindowScrollWheelFcn = @d.mouseWheel;
            hf = h.figure;
            hf.CloseRequestFcn = @d.closeFitTool;
            h.figure.Color = d.cfg.apperance.color1;
            
            cfg = d.cfg;
            % create all possible gui objects
            set(hf, 'ResizeFcn', @d.setGUI, 'MenuBar', 'none', 'ToolBar', 'none',...
                'NumberTitle', 'off', 'Name', [cfg.programName]);
            
            % image axis
            h.imgAxis = axes('parent', hf, 'Units', 'pixel',...
                'Color', [0 0 0], 'XTick', [], 'YTick', []);
            h.imgAxis.ButtonDownFcn = @d.imgAxisButtonDown;
            
            % function strings
            h.fcn = uicontrol('parent', hf, 'Style', 'edit', 'String', []);
            h.fcn.Callback = @d.fcnChange;
            
            h.indep = uicontrol('parent', hf, 'Style', 'edit', 'String', []);
            h.indep.Callback = @d.indepChange;
            
            h.depend = uicontrol('parent', hf, 'Style', 'edit', 'String', []);
            h.depend.Callback = @d.dependChange;
            
            h.coeffs = uicontrol('parent', hf, 'Style', 'text', 'String', []);
            h.coeffs.Callback = @d.coeffsChange;
            
            % buttons
            h.addRow = uicontrol('parent', hf, 'Style', 'pushbutton', 'String', 'add Row', 'Callback', @d.addRow);
            
            h.remRow = uicontrol('parent', hf, 'Style', 'pushbutton', 'String', 'remove Row', 'Callback', @d.remRow);
            
            h.sendData = uicontrol('parent', hf, 'Style', 'pushbutton', 'String', 'Send Data', 'Callback', @d.sendData);
            
            h.fitData = uicontrol('parent', hf, 'Style', 'pushbutton', 'String', 'Fit Data', 'Callback', @d.fitData);
            
            % parameter table
            h.table = uitable(hf,...
                'ColumnName', cfg.table.ColumnName,...
                'ColumnFormat', cfg.table.ColumnFormat,...
                'ColumnEditable', logical(cfg.table.ColumnEditable), ...
                'RowName',[]);
            h.table.CellEditCallback = @d.tableEdit;
            h.table.ColumnWidth = num2cell(cfg.table.ColumnWidth);
            h.table.Position(3) = sum(cell2mat(h.table.ColumnWidth))+2+17;  % +17 for scrollbar +35 for rownames
            
            % result box
            %h.fcn = uicontrol('parent', hf, 'Style', 'text', 'String', []);
            
            % create menue entry
            s = [cfg.menu];
            h.menu = d.createMenu(s, hf);
            
            d.handles = h;
            
        end
        
        function d = FitTool(varargin) % name value pairs!!
            % transfere name value pairs as follows: raw data is transfered as name value pairs and one name value pair must
            % contain the fittype.
            % e.g.: FitTool('x', [1 2 3], 'y', [0.5 1.1 1.45], 'fittype', ftype)
            %% progress inputs
            d = d.newRawData(varargin{:});
            % now d.dat has name value pairs stored as struct
            %% get program directory
            % determine .m or .exe directory
            if isdeployed
                progDir = getProgrammPath;
            else
                progDir = which('FitTool.m');
                progDir = fileparts(progDir);
            end
            %% load cfg file
            cfgDir = dir(fullfile(progDir, 'cfg_FitTool.json'));
            d.cfgPath = fullfile(cfgDir.folder, cfgDir.name);
            d.cfg = loadjson(d.cfgPath);
                        
            %% create front end
            d.createGUI;
            d.setGUI;
            
            %% update GUI
            d.fittype2fitInfo;
            d.fitInfo2gui;
        end
        
        function closeFitTool(d, varargin)
            if isempty(gcbf)
                if length(dbstack) == 1
                    warning(message('MATLAB:closereq:ObsoleteUsage'));
                end
                close('force');
            else
                delete(gcbf);
                
            end
            delete(d);
        end
    end
end






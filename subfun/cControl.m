% Dicomfelx framework by Roland Stange Uniklinikum Leipzig
% (Ansprechpartner: Dr. Harald Busse Harald.Busse@medizin.uni-leipzig.de)

classdef cControl < handle
    
    properties
        pVersion_cControl = '1.0';
        pApplication = '';
        pHandles = struct('draw', []);
        oComp = [];   % contains an array of cCompute objects
        pTable = struct('row', 1, 'column', 1); % selected table cell
        
        pFcfg = struct([]); % frameworkConfig
        pFcfgPath = '';
        pAcfg = struct([]); % applicationConfig
        pAcfgPath = '';
        
        pLineCoord = []; % coordinates drawn by mouse and temporarily stored for processing in cCompute
        pHistory = struct('data', {{'emptySlot'}});   % used to store history for "undo"
        
        pActiveKey = {}; % press and hold a key will be stored here
        pActiveMouse = '';
        pSaveDate = datetime.empty;  % last data file save time stamp
        pVersions = struct('name', '', 'ver', '', 'updateFcn', '');  % struct with all relevant classes, objects and there current version
        pVarious = {};
        
    end
    
    methods(Static)
        function h = mDrawContour(imgAxis, contCoord, contColor, varargin)
            % draws a set of contour coordinates (contCoord) into an image
            % (imgAxis) with the colors (contColor)
            % imgAxis       - handle to an axis
            % contCoord     - cell array containing an 2xN array per cell
            % as x, y coordinates
            % contColor     - cell array containing a color specifier per
            % array element
            % varargin is string value pairs:
            % 'drawMode' - {'line' 'dot'}
            %
            h = []; % pre allocated, in case all contCoords are empty and h will not be assigned
            
            if isvalid(imgAxis)
                axes(imgAxis); hold on;
            else
                msgbox('no valid handle for plotting contours');
                return;
            end
            
            contCoordSize = size(contCoord);
            if contCoordSize(2) == 2 && contCoordSize(1) > 4
                contCoord = {contCoord};
            end
            
            for i = 1:numel(contCoord)
                c = contCoord{i};
                if ~isempty(c)
                    if iscell(c)
                        c = c{1}; 
                    end
                    if ~isempty(c)
                        h{i} = line(c(:,2), c(:,1), 'Color', contColor{i}, 'LineWidth', 2);
                        h{i}.ButtonDownFcn = imgAxis.ButtonDownFcn;
                        h{i}.HitTest = 'on';
                        
                        %modify apperance
                        for j = 1:2:numel(varargin)
                            switch varargin{j}
                                case 'drawMode'
                                    switch varargin{j+1}{i}
                                        case 'line'
                                            h{i}.LineStyle = '-';
                                            h{i}.Marker = 'none';
                                            h{i}.MarkerSize = 3;
                                        case 'dot'
                                            h{i}.LineStyle = 'none';
                                            h{i}.Marker = '.';
                                            h{i}.MarkerSize = 3;
                                    end
                            end
                        end
                        
                    end
                end
            end
            hold off;
            
        end
    end
    
    methods
        % % % various % % %
        function dummy(cCont)
            disp('test dummy');
        end
        
        function cCont = mSetVersionInfo(oCont, name, ver, updateFcn)
            % overwrites existing version info or creates new entry
            ind = ismember({oCont.pVersions.name}, {name});
            if any(ind)
                oCont.pVersions(ind).ver = ver;
                oCont.pVersions(ind).updateFcn = updateFcn;
            else
                oCont.pVersions(end+1).name = name;
                oCont.pVersions(end).ver = ver;
                oCont.pVersions(end).updateFcn = updateFcn;
            end
        end
        
        function prefix = mGetSaveFilePrefix(oCont)
            switch class(oCont.oComp(1).oImgs)
                case 'cImageDcm'
                    prefix = [oCont.oComp(1).pPatientName '_' oCont.oComp(1).oImgs(1).dicomInfo.AcquisitionDate '_' datestr(now, 'yymmdd_HHMM') '_' oCont.pApplication];
                case 'cImage'
                    prefix = [oCont.oComp(1).pPatientName '_' datestr(now, 'yymmdd_HHMM') '_' oCont.pApplication];
                otherwise
                    prefix = [datestr(now, 'yymmdd_HHMM') '_' oCont.pApplication];
            end
        end
        
        function histData = mGenerateHistData(oCont)
            % create history data structure for storing undo datasets
            histData = struct(oCont);
            histData.oComp = setStructArrayField(histData.oComp, 'oImgs', {});
            histData.oComp = setStructArrayField(histData.oComp, 'pHistory', {});
            histData = rmfield(histData, 'pHistory');
            histData = rmfield(histData, 'pTable');
            histData = rmfield(histData, 'pHandles');
            histData = rmfield(histData, 'pVersion_cControl');
            histData = rmfield(histData, 'pApplication');
            histData = rmfield(histData, 'pFcfg');
            histData = rmfield(histData, 'pAcfg');
            histData = rmfield(histData, 'pFcfgPath');
            histData = rmfield(histData, 'pAcfgPath');
            histData = rmfield(histData, 'pActiveKey');
            histData = rmfield(histData, 'pActiveMouse');
            histData = rmfield(histData, 'pVersions');
            try histData = rmfield(histData, 'PreviousInstance__'); end
        end
        
        function oCont = mMakeUndo(oCont, varargin)
            %             [a b c] = comp_struct(oCont.pHistory.data{1}, oCont.pHistory.data{2})
            %             histData2 = oCont.mGenerateHistData;
            % generate data
            histData = oCont.pHistory.data{2};
            fields = fieldnames(histData);
            oComp = oCont.oComp;
            
            % overwrite fields from histdata to oCont
            for i=1:numel(fields)
                oCont.(fields{i}) = histData.(fields{i});
            end
            % write back images
            oCont.oComp = setStructArrayField(oCont.oComp, 'oImgs', {oComp.oImgs});
            oCont.oComp = setStructArrayField(oCont.oComp, 'pHistory', {oComp.pHistory});
            % delete newest histelement to assure more than one undo is
            % possible. Two must be deletet, because tableCellSelect will
            % generatre a new one
            oCont.pHistory.data(1:2) = [];
            
            oCont.mTableCellSelect('Caller', 'mMakeUndo');
            oCont = oCont.mLogging(['oCont.mMakeUndo']);
        end
        
        % % % Keyboard and Mouse Input processing % % %
        function mGraphAxisButtonDown(oCont, a, hit, varargin)
            oCont.oComp(oCont.pTable.row).mGraphAxisButtonDown(oCont, hit); % execute function associated in cCompute class
            oCont = oCont.mLogging(['oCont.mGraphAxisButtonDown - ' num2str(hit.IntersectionPoint)]);
        end
        
        function mImgAxisButtonDown(oCont, a, hit, varargin)
            oCont.oComp(oCont.pTable.row).mImgAxisButtonDown(oCont, hit); % execute function associated in cCompute class
            oCont = oCont.mLogging(['oCont.mImgAxisButtonDown - ' num2str(hit.IntersectionPoint)]);
        end
        
        function mMouseWheel(oCont, a, b, varargin)
            max = numel(oCont.oComp);
            min = 1;
            new = oCont.pTable.row+b.VerticalScrollCount;
            if new<min
                new = min;
            elseif new>max
                new = max;
            end
            %oCont.pTable.row = new;
            oCont.mTableCellSelect('Caller', 'mMouseWheel', new);
        end
        
        function mKeyPress(oCont, a, key)
            % key already pressed?
            if any(ismember(oCont.pActiveKey, {key.Key}));
                return
            end
            % add key to oCont.pActiveKey
            oCont.pActiveKey = [oCont.pActiveKey {key.Key}];
            % use key input
            switch key.Key
                case {'up' 'down' 'uparrow' 'downarrow'}
                    % up and down keys are reserved for tableCellSelect and thus are already processed there
                case {'z'}   % here keys can be processed directly
                    switch oCont.pActiveKey{1}
                        case {'control'}
                            oCont = oCont.mMakeUndo;
                    end
                otherwise   % here keys are processed in the cCompute class
                    oCont.oComp(oCont.pTable.row) = oCont.oComp(oCont.pTable.row).mKeyPress(oCont, key); % execute function associated in cCompute class
            end
            disp(oCont.pActiveKey);
            oCont = oCont.mLogging(['oCont.mKeyPress - ' key.Key]);
        end
        
        function mKeyRelease(oCont, a, key)
            % remove key from oCont.pActiveKey
            keyInd = ismember(oCont.pActiveKey, {key.Key});
            oCont.pActiveKey(keyInd) = [];
            switch key.Key
                case {'up' 'down' 'uparrow' 'downarrow'}
                    % up and down keys are reserved for tableCellSelect and thus are already processed there
                case {''}   % here keys can be processed directly
                otherwise   % here keys are processed in the cCompute class
                    oCont.oComp(oCont.pTable.row).mKeyRelease(oCont, key); % execute function associated in cCompute class
            end
            disp(oCont.pActiveKey);
            oCont = oCont.mLogging(['oCont.mKeyRelease - ' key.Key]);
        end
        
        % % % ProgramMenue interaction % % %
        function mMenuCallback(oCont, fcn, varargin)
            oCont = oCont.mLogging(['oCont.mMenuCallback - start ' char(fcn)])
            try
                tmp = feval(fcn); % execute the function coming from the menu button callback stored in applicationConfig
            catch
                msgbox([char(fcn) ' could not be excecuted!']);
            end
            if exist('tmp') == 1
                if isa(tmp, 'cControl')
                    oCont = tmp;
                    oCont.mTableCellSelect('Caller', 'mMenuCallback');
                elseif isa(tmp, 'cCompute')
                    oCont.oComp = tmp;
                    oCont.mTableCellSelect('Caller', 'mMenuCallback');
                else
                    uiwait(warndlg([char(fcn) 'is not cCompute or cControl class! revise code!']));
                end
            end
            oCont = oCont.mLogging(['oCont.mMenuCallback - end ' char(fcn)]);
        end
        
        function mImageDisplayMode(oCont, b, varargin)
            % change the current mode of displaying images as stored in
            % applicationConfig
            if numel(oCont.pAcfg.menu)==1
                menuSelection = oCont.pAcfg.menu;
            else
                tmp = arrayfun(@(x) x{1} , oCont.pAcfg.menu);
                callbackEntries = arrayfun(@(x) x.path{end}, tmp, 'un', false);
                menuSelection = oCont.pAcfg.menu{find(ismember(callbackEntries, b.Label))};
            end
            oCont.pAcfg.imageDisplayMode = menuSelection.path{end};
            oCont = oCont.oComp.mImageUpdate(oCont);
            oCont = oCont.mLogging(['oCont.mImageDisplayMode - ' menuSelection.path{end}]);
        end
        
        function mSaveData(oCont, varargin)
            oCont = oCont.mLogging(['oCont.mSaveData - start']);
            wb = waitbar(0.1, 'Data.mat file is beein saved.');
            wb.Name = 'saving....';
            path = fullfile(oCont.pAcfg.lastLoadPath, [oCont.mGetSaveFilePrefix '_data.mat']);
            oCont.oComp.mSave_oComp(path, oCont);
            % execute application specific saving:
            waitbar(0.3, wb, 'Application specific saving has started');
            Fcns = oCont.pAcfg.saveDatFcn;
            for i = 1:numel(Fcns)
                eval(Fcns{i});
            end
            oCont.pSaveDate = datetime('now');
            waitbar(1, wb, 'Done');
            wb.Name = 'Done';
            pause(0.35);
            close(wb);
            oCont = oCont.mLogging(['oCont.mSaveData - done']);
            
        end
        
        function mLoadData(oCont, varargin)
            pFcfg = oCont.pFcfg;
            pAcfg = oCont.pAcfg;
            % find data
            imgLoad = [];
            patDir = uigetdir(pAcfg.lastLoadPath, 'select folder'); % user select dataset
            if patDir==0
                return
            end
            % set logging 
            oCont = oCont.mLogging(['oCont.mLoadData - start - folder ' patDir]);
            % clear prior use of cControl class
            oCont.oComp = [];
            oCont.pTable.row = 1;
            oCont.pTable.column = 1;
            oCont.pVersions(:) = [];  % delete initial entry;
            oCont.mSetVersionInfo(oCont.pFcfg.programName, oCont.pVersion_cControl, '');
            
            % patDir is writable?
            [a, tmp] = fileattrib(patDir)
            if ~tmp.UserWrite
                msgbox('Can not save data file; no write permission in data folder.');
            end
            
            % read data
            try
            if ismember(varargin(1), {'Import'})
                tmp = {'*.mat*'};
                tmp(2:numel(pAcfg.datFileSearchString)+1) = pAcfg.datFileSearchString;
                pAcfg.datFileSearchString = tmp;
            end
            end
            pAcfg.lastLoadPath = patDir;
            oCont.pAcfg = pAcfg;
            try a = cComputeDummy; end % warum auch immer. Bei cComputeDummy Klasse muss er erst einen "Zugriff" machen bevor die nächste Zeile ausgeführt werden kann????
            oCont.oComp = feval(str2func(pAcfg.cComputeFcn));
            oCont = oCont.oComp.mInit_oComp(oCont);  % here data structure is created, images loaded and plotted
            
            % set figure name
            oCont.pHandles.figure.Name = [pFcfg.programName ' - ' pAcfg.applicationName ' - ' oCont.oComp(1).pDataName];
            
            % save config file
            try
            if ismember(varargin(1), {'Import'})
                pAcfg.datFileSearchString(1) = [];
            end
            end
            savejson('',oCont.pAcfg, oCont.pAcfgPath);
            
            % fill table before plotting
            oCont.mUpdateTable;
            
            % init image display
            if ishandle(oCont.pHandles.imgAxis)
                axes(oCont.pHandles.imgAxis); htmp = get(oCont.pHandles.imgAxis, 'Children');
                for i=1:numel(htmp)
                    delete(htmp(i));
                end
                
                oCont = oCont.oComp.mImageUpdate(oCont);
            end
            
            % fill table
            oCont.mUpdateTable;
            
            % set logging
            oCont = oCont.mLogging(['oCont.mLoadData - end - folder ' patDir]);
        end
       
        function mImport(oCont, varargin)
%             imports = {'ISAT-DataFile' 'Nikita File'};
%             listdlg('PromptString',{'What should be imported:'},...
%                     'SelectionMode','single', 'ListString', availableModes,...
%                     'ListSize', [200 150], 'OKString', 'Select Mode', 'CancelString', 'Abord');
            oCont.mLoadData('Import', 'ISAT-DataFile');
            
            oCont = oCont.mLogging(['import of xxxx was done']);
            
%             switch oCont.pApplication
%                 case 'FatSegment'
%                     IsatMode = 'FatSegmentIOphase'
%                 case 'T1Mapper'
%                     IsatMode = 'T1RelaxFitMRoi'
%                 otherwise
%                     msgbox('Mode not supported for old imports');
%             end
%             d = isat('mode', IsatMode);
%             d.loadData
%             % now the data is loaded and updated to the newest ISAT version
%             d.dat
        end
        
        function mCloneSoftware(oCont, varargin)
            clone = cControl('mode', oCont.pApplication);
            clone.oComp = oCont.oComp;
            clone.pTable.row = oCont.pTable.row;
            oCont = oCont.mLogging(['oCont.mCloneSoftware']);
            clone.mTableCellSelect('Caller', 'mCloneSoftware');
        end
        
        % % % GUI interaction % % %
        function mTableCellEdit(oCont, hTab, select, varargin)
            % transfer new value to dat struct
            oCont.oComp(select.Indices(1)).(oCont.pAcfg.table.associatedFieldNames{select.Indices(2)}) = select.NewData;
            
            % execute function due to value change
            oCont.oComp(select.Indices(1)) = oCont.oComp(select.Indices(1)).mTableEdit(select);
            oCont = oCont.mLogging(['oCont.mTableCellEdit - row ' num2str(select.Indices(1)) ' and column ' num2str(select.Indices(2)) ' edited']);
            oCont.mTableCellSelect('Caller', 'mTableCellEdit');
            
        end
        
        function mTableCellSelect(oCont, varargin)
            %% prepare
            if nargin>2
                if isa(varargin{2}, 'char')
                    switch varargin{2}
                        case 'mMouseWheel'
                            % this would be the case for scrawling through the slices
                            select(1) = varargin{3};
                            select(2) = oCont.pTable.column;
                            manualSelected = true;
                            oCont = oCont.mLogging(['oCont.mTableCellSelect - row ' num2str(select(1)) ' and column ' num2str(select(2)) ' selected (by mouse wheel)']);
                        otherwise
                            manualSelected = false;
                    end
                elseif isa(varargin{1}, 'matlab.ui.control.Table')
                    % this would be the case if the user clicks the table
                    select = varargin{2};
                    select = select.Indices;
                    if isempty(select)  % dirty, but i did not find another way (if table data gets updated -> cellselect callback -> arrrgg
                        % terminates an unwanted call by the mUpdateTable methods line: oCont.pHandles.table.Data = tableData;
                        return
                    end
                    
                    % if the cell is editable supress mUpdateTable
                    manualSelected = true;
                    oCont = oCont.mLogging(['oCont.mTableCellSelect - row ' num2str(select(1)) ' and column ' num2str(select(2)) ' selected (by mouse click)']);
                else
                    msgbox('error in GUI update routine! Nr2');
                end
                
            else
                msgbox('error in GUI update routine! Nr1');
            end
            doUpdateTable = ~manualSelected;
            
            
            %-------------------------
            t_tot = tic;
            %% undo History
            t_undo = tic;
            oCont.pHistory.data;
            % make history storage for undo
            histData = oCont.mGenerateHistData;
            
            if numel(oCont.pHistory.data)==1 || ~isequal(histData.oComp, oCont.pHistory.data{1}.oComp)
                
                histSize = 15;
                %[a b c] = comp_struct(histData, oCont.pHistory.data{1})
                % make hist data the correct size (init)
                if numel(oCont.pHistory.data)~=histSize
                    oCont.pHistory.data(numel(oCont.pHistory.data)+1:histSize) = {'emptySlot'};
                end
                % delete last element and shift all to end to make first place free
                shiftSet = oCont.pHistory.data(1:histSize-1);
                oCont.pHistory.data(1) = {histData}; % here the new stuff
                oCont.pHistory.data(2:histSize) = shiftSet; % here the old stuff
                
            else
                disp('no HistChange')
                % -> no change happened
            end
            
            t_undo = toc(t_undo);
            disp(['UndoStorage: ' num2str(t_undo) ' sec']);
            %% mSliceSelected
            if manualSelected
                oCont = oCont.oComp.mSliceSelected(oCont, oCont.pTable.row, select(1));
                oCont.pTable.row = select(1);
                oCont.pTable.column = select(2);
            end
            %% mImageUpdate
            t_Img = tic;
            oCont = oCont.oComp.mImageUpdate(oCont);
            t_Img = toc(t_Img);
            disp(['ImageUpdate: ' num2str(t_Img) ' sec']);
            %% mGraphUpdate
            t_Graph = tic;
            oCont = oCont.oComp.mGraphUpdate(oCont);
            t_Graph = toc(t_Graph);
            disp(['GraphUpdate: ' num2str(t_Graph) ' sec']);
            %% mTextUpdate
            t_Text = tic;
            try oCont = oCont.oComp.mTextUpdate(oCont); end
            t_Text = toc(t_Text);
            disp(['TextUpdate: ' num2str(t_Text) ' sec']);
            %% mUpdateTable
            t_Table = tic;
            if doUpdateTable
            oCont.mUpdateTable;
            end
            t_Table = toc(t_Table);
            disp(['UpdateTable: ' num2str(t_Table) ' sec']);
            %--------------------
            t_tot = toc(t_tot);
            disp(['GuiUpdateRoutine: ' num2str(t_tot) ' sec']);
        end
        
        function mUpdateTable(oCont)
            % fill the table according to applicationConfig entries
            if ishandle(oCont.pHandles.table)
                columNames = oCont.pAcfg.table.columnName;
                fieldNames = oCont.pAcfg.table.associatedFieldNames;
                
                tableData = {};
                for i = 1:numel(oCont.oComp)
                    singleRow = {};
                    for j = 1:numel(columNames)
                        singleRow{j} = oCont.oComp(i).(fieldNames{j});
                    end
                    tableData(i,:) = singleRow;
                end
                oCont.pHandles.table.Data = tableData; % if the data of the table is changed here, the mTableCellSelect callback will be triggered unwanted!!!
                oCont.pHandles.table.RowName = [1:numel(oCont.oComp)];
            end
            
            % create savety copy
            if isempty(oCont.pSaveDate)
                oCont.oComp.mSave_oComp (fullfile(oCont.pAcfg.lastLoadPath, 'tmp_cControl.mat'), oCont);
                oCont.pSaveDate = datetime('now');
                disp('data saved')
            elseif datetime('now')-oCont.pSaveDate > oCont.pFcfg.datAutoSaveTime
                oCont = oCont.oComp.mSave_oComp (fullfile(oCont.pAcfg.lastLoadPath, 'tmp_cControl.mat'), oCont);
                oCont.pSaveDate = datetime('now');
                disp('data saved')
            end
        end
        
        % % % External Windows % % %
        function mCreateZoomView(oCont, varargin)
            oComp = oCont.oComp(oCont.pTable.row);
            img = oComp.mGetStandardImg;
            
            if isfield(oCont.pHandles, 'zoomFig') && isvalid(oCont.pHandles.zoomFig)
                delete(oCont.pHandles.zoomFig);
            end
            oCont.pHandles.zoomFig = figure('units','pixels', 'menubar','none', 'resize','on', 'numbertitle','off', 'name','Zoom View');
            oCont.pHandles.zoomAxis = axes();
            oCont.pHandles.zoomDisplay = imshow(uint8(img.data), 'parent', oCont.pHandles.zoomAxis);
            %colormap(oCont.pHandles.zoomAxis, 'parula');
            oCont.pHandles.zoomRect = imrect(oCont.pHandles.zoomAxis);
            oCont.pHandles.zoomFig.CloseRequestFcn = @oCont.mCloseZoomView;
            oCont.pHandles.zoomRect.addNewPositionCallback(@(oComp)oCont.oComp.mImageUpdate(oCont));
            oCont.mTableCellSelect('Caller', 'mCreateZoomView');
            oCont = oCont.mLogging(['oCont.mCreateZoomView']);
        end
        
        function mCloseZoomView(oCont, varargin)
            delete(varargin{1});
            rmfield(oCont.pHandles, 'zoomFig');
            rmfield(oCont.pHandles, 'zoomAxis');
            rmfield(oCont.pHandles, 'zoomDisplay');
            rmfield(oCont.pHandles, 'zoomRect');
            oCont.mTableCellSelect('Caller', 'mCloseZoomView');
            oCont = oCont.mLogging(['oCont.mCloseZoomView']);
        end
        
        % % % Program Start and GUI creation % % %
        function menuHandles = mCreateMenu(oCont, s, parent)
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
        end
        
        function mSetGUI(oCont, varargin) % set gui object position and size
            % width of table is fix in size and is not allowed to be changed
            pFcfg = oCont.pFcfg;
            pAcfg = oCont.pAcfg;
            h = oCont.pHandles;
            fSize = get(h.figure, 'position');
            fH = fSize(4); fW = fSize(3); % figure Height and Width
            GS1 = pFcfg.GS1; % GapSize 1 in pxl
            GS2 = pFcfg.GS2; % GapSize 2 in pxl
            graphH = pAcfg.graphAxis.height;    % histogram hight in percent
            imgH = pAcfg.imgAxis.height;    % image axis hight in percent
            tabH = pAcfg.table.height; % table hight in percent
            boxH = pAcfg.textBox.height;
            borderW = pFcfg.apperance.borderWidth;
            
            if ishandle(h.table)
                tW = h.table.Position(3); % table Height and Width
            else
                tw = 0;
            end
            
            if ishandle(h.graphAxis)
                h.graphAxisPanel.Position(1) = 1;
                h.graphAxisPanel.Position(2) = 1;
                h.graphAxisPanel.Position(3) = fW-tW;
                h.graphAxisPanel.Position(4) = fH*graphH;
                
                h.graphAxis.Position(1) = pAcfg.graphAxis.xBorderGap(1);
                h.graphAxis.Position(2) = pAcfg.graphAxis.yBorderGap(1);
                h.graphAxis.Position(3) = h.graphAxisPanel.Position(3)-2*borderW-pAcfg.graphAxis.xBorderGap(1)-pAcfg.graphAxis.xBorderGap(2);
                h.graphAxis.Position(4) = h.graphAxisPanel.Position(4)-2*borderW-pAcfg.graphAxis.yBorderGap(1)-pAcfg.graphAxis.yBorderGap(2);
            end
            
            if ishandle(h.imgAxis)
                h.imgAxisPanel.Position(1) = 1;
                h.imgAxisPanel.Position(2) = fH*graphH;
                h.imgAxisPanel.Position(3) = fW-tW;
                h.imgAxisPanel.Position(4) = fH*imgH;
                
                h.imgAxis.Position(1) = 1;
                h.imgAxis.Position(2) = 1;
                h.imgAxis.Position(3) = h.imgAxisPanel.Position(3)-2*borderW;
                h.imgAxis.Position(4) = h.imgAxisPanel.Position(4)-2*borderW;
            end
            
            if ishandle(h.textBox)
                h.textBoxPanel.Position(1) = fW-tW;
                h.textBoxPanel.Position(2) = 1;
                h.textBoxPanel.Position(3) = tW;
                h.textBoxPanel.Position(4) = fH*boxH;
                
                h.textBox.Position(1) = 1;
                h.textBox.Position(2) = 1;
                h.textBox.Position(3) = h.textBoxPanel.Position(3)-2*borderW;
                h.textBox.Position(4) = h.textBoxPanel.Position(4)-2*borderW;
            end
            
            if ishandle(h.table)
                h.tablePanel.Position(1) = fW-tW;
                h.tablePanel.Position(2) = fH*boxH;
                h.tablePanel.Position(3) = tW;
                h.tablePanel.Position(4) = fH*tabH;
                
                h.table.Position(1) = 1;
                h.table.Position(2) = 1;
                h.table.Position(3) = tW;
                h.table.Position(4) = h.tablePanel.Position(4)-2*borderW;
            end
            
            
            
        end
        
        function oCont = mCreateGUI(oCont)   % Define Buttons, Axis,... and set callbacks, initValues,...
            pFcfg = oCont.pFcfg;
            pAcfg = oCont.pAcfg;
            %------------------------------------------
            oCont.pHandles.figure = figure;
            
            h = oCont.pHandles;
            hf = h.figure;
            hf.WindowKeyPressFcn = @oCont.mKeyPress;
            hf.WindowScrollWheelFcn = @oCont.mMouseWheel;
            hf.CloseRequestFcn = @oCont.mClose_oCont;
            % set figure apperance
            ScreenSize = get(0,'screensize');
            hf.Position = [(ScreenSize(3)-pFcfg.minfW)/2 (ScreenSize(4)-pFcfg.minfH)/2 pFcfg.minfW pFcfg.minfH];
            hf.Color = pFcfg.apperance.backGroundColor;
            set(hf, 'ResizeFcn', @oCont.mSetGUI, 'MenuBar', 'none', 'ToolBar', 'none',...
                'NumberTitle', 'off', 'Name', [pFcfg.programName ' - ' pAcfg.applicationName]);
            % create all gui objects
            if strcmp(pAcfg.imgAxis.visible, 'on')
                h.imgAxisPanel = uipanel(hf, 'Units', 'pixel');
                h.imgAxisPanel.BorderType = 'line';
                h.imgAxisPanel.BorderWidth = pFcfg.apperance.borderWidth;
                h.imgAxisPanel.HighlightColor = pFcfg.apperance.elementBorderColor;
                h.imgAxisPanel.BackgroundColor =  pFcfg.apperance.backGroundColor;
                %-----
                h.imgAxis = axes('parent',h.imgAxisPanel , 'Units', 'pixel', 'XTick', [], 'YTick', []);
                h.imgAxis.ButtonDownFcn = @oCont.mImgAxisButtonDown;
            else
                h.imgAxis = [];
            end
            
            if strcmp(pAcfg.graphAxis.visible, 'on')
                h.graphAxisPanel = uipanel(hf,'BackgroundColor', 'white', 'Units', 'pixel');
                h.graphAxisPanel.BorderType = 'line';
                h.graphAxisPanel.BorderWidth = pFcfg.apperance.borderWidth;;
                h.graphAxisPanel.HighlightColor = pFcfg.apperance.elementBorderColor;
                h.graphAxisPanel.BackgroundColor = pFcfg.apperance.backGroundColor
                %-----
                h.graphAxis = axes('parent', h.graphAxisPanel, 'Units', 'pixel', 'XTick', [], 'YTick', []);
                h.graphAxis.ButtonDownFcn = @oCont.mGraphAxisButtonDown;
                h.graphAxis.Color = pFcfg.apperance.backGroundColor;
                h.graphAxis.Box = 'on';
                h.graphAxis.YColor = pFcfg.apperance.designColor1;
                h.graphAxis.XColor = pFcfg.apperance.designColor1;
            else
                h.graphAxis = [];
            end
            
            if strcmp(pAcfg.textBox.visible, 'on')
                h.textBoxPanel = uipanel(hf,'BackgroundColor', 'white', 'Units', 'pixel');
                h.textBoxPanel.BorderType = 'line';
                h.textBoxPanel.BorderWidth = pFcfg.apperance.borderWidth;;
                h.textBoxPanel.HighlightColor = pFcfg.apperance.elementBorderColor;
                
                h.textBox = uicontrol('parent', h.textBoxPanel, 'Style', 'text');
                h.textBox.BackgroundColor = pFcfg.apperance.backGroundColor;
                h.textBox.FontSize = 10;
            else
                h.textBox = [];
            end
            
            if pAcfg.table.visible
                h.tablePanel = uipanel(hf,'BackgroundColor', 'white', 'Units', 'pixel');
                h.tablePanel.BorderType = 'line';
                h.tablePanel.BorderWidth = pFcfg.apperance.borderWidth;;
                h.tablePanel.HighlightColor = pFcfg.apperance.elementBorderColor;
                
                h.table = uitable(h.tablePanel,...
                    'ColumnName', pAcfg.table.columnName,...
                    'ColumnFormat', pAcfg.table.columnFormat,...
                    'ColumnEditable', logical(pAcfg.table.columnEditable), ...
                    'RowName',[],...
                    'Visible', pAcfg.table.visible,...
                    'CellSelectionCallback', eval(pFcfg.table.cellSelectionCallback),...
                    'CellEditCallback', eval(pFcfg.table.cellEditCallback));
                h.table.ColumnWidth = num2cell(pAcfg.table.columnWidth);
                h.table.Position(3) = sum(cell2mat(h.table.ColumnWidth))+2+17+35;  % +17 for scrollbar +35 for rownames
                %h.table.BackgroundColor = pFcfg.apperance.elementBackGroundColor;
            else
                h.table = [];
            end
            
            
            % create menue entry
            s = [pFcfg.menu pAcfg.menu];
            h.menu = oCont.mCreateMenu(s, hf);
            
            
            oCont.pHandles = h;
            
        end
        
        function oCont = mLogging(oCont, action, varargin)
            if isfield(oCont.pVarious, 'TimeLogging')
                oCont.pVarious.TimeLogging.Stamp(end+1) = now;
                oCont.pVarious.TimeLogging.Action(end+1) = {action};
            else
                oCont.pVarious.TimeLogging.Stamp(1) = now;
                oCont.pVarious.TimeLogging.Action(1) = {action};
            end
        end
        
        function oCont = cControl(varargin)
            oCont = oCont.mLogging('start cControl');
            %% get program directory
            % determine .m or .exe directory
            if isdeployed
                progDir = getProgrammPath;
            else
                progDir = which('cControl.m');
                progDir = fileparts(progDir);
            end
            %% load framework cfg file
            pFcfgPath = dir(fullfile(progDir, 'cfg_framework.json'));
            oCont.pFcfgPath = fullfile(pFcfgPath.folder, pFcfgPath.name);
            oCont.pFcfg = loadjson(oCont.pFcfgPath);
            %% load application cfg file
            pAcfgPath = dir(fullfile(progDir, 'cfg_application_*.json'));
            for i = 1:numel(pAcfgPath)
                tmp = strsplit(pAcfgPath(i).name, {'cfg_application_' '.json'});
                availableModes(i) = tmp(2);
            end
            
            %% select mode
            if ~isempty(varargin) && isa(varargin{1}, 'char')
                switch varargin{1}
                    case 'mode'
                        Ind = find(ismember(availableModes, varargin{2}));
                end
            else
                Ind = listdlg('PromptString',{'Please select the program mode:'},...
                    'SelectionMode','single', 'ListString', availableModes,...
                    'ListSize', [200 150], 'OKString', 'Select Mode', 'CancelString', 'Abord');
                
                if isempty(Ind)
                    return
                end
            end
            
            oCont.pAcfgPath = fullfile(pAcfgPath(Ind).folder, pAcfgPath(Ind).name);
            oCont.pAcfg = loadjson(oCont.pAcfgPath);
            
            oCont.pApplication = oCont.pAcfg.applicationName;
            oCont = oCont.mLogging([oCont.pAcfg.applicationName ' mode selected']);
            %% check for write permission of cfg files
            [a, tmp1] = fileattrib(oCont.pFcfgPath);
            [a, tmp2] = fileattrib(oCont.pAcfgPath);
            if ~tmp1.UserWrite | ~tmp2.UserWrite
                msgbox('No write permission for CfgFile. Programm will not operate properly!');
            end
            
            %% create and fill front end
            oCont.mCreateGUI;
            oCont.mSetGUI;
            
            %% load data
            oCont.mLoadData;
        end
        
        function oCont = mClose_oCont(oCont, varargin)
            if isempty(oCont.oComp)
            else
                b = questdlg('Save before Exit?', 'saveData yes/no', 'yes', 'no', 'abord', 'yes');
                switch b
                    case 'yes'
                        oCont.mSaveData;
                    case 'no'
                    case 'abord'
                        return
                end
            end
            if isempty(gcbf)
                if length(dbstack) == 1
                    warning(message('MATLAB:closereq:ObsoleteUsage'));
                end
                close('force');
            else
                delete(gcbf);
            end
            h = struct2cell(oCont.pHandles);
            for i = 1:numel(h)
                try
                    delete(h{i});
                end
            end
            delete(oCont);
        end
    end
end






classdef cCompute
    properties
        pVersion_cCompute  = '1.1';
        oImgs = img.empty;   % will store all loaded raw images
        pDataName = '';      % any kind of string describing the data (use for application specific stuff only)
        pHistory = [];       % store history --- not implemented
        pStandardImgType = '';   % an arbitary defined name for the standard image of the specific appliaction
        
        
        pPatientName = '';
        pSliceLocation = '';
        pVarious = {};   % used for application specific unspecific storage
    end
        
    methods(Static)
        % % % Segmentation functions % % %
        function boundCoord = mGetBoundaryImageCoord(boundImg)
            % all pxls of boundImg that are ones will be given back as
            % coordinates
%             [x y] = find(boundImg);
%             boundCoord = [x y];
            % oder:
            boundCoord = bwboundaries(boundImg);
            boundCoord = cellfun(@(x) x', boundCoord, 'un', false);
            boundCoord = [boundCoord{:}]';
        end
        
        function boundMask = mGetBoundMask(imgData, coord, varargin)
            % create binary mask from image and coordiatne values
            % imgData       - 2D array
            % coord         - 2xN array with x,y coordinates
            if ~isempty(varargin)
            switch varargin{1}
                case 'fillHoles'
                    fillHoles = varargin{2};
                otherwise
                    fillHoles = true;
            end
            else
                fillHoles = true;
            end
            
            imgSize = size(imgData);
            mask = zeros(imgSize);
            try coord = coord{1}; end
            
            mask(sub2ind(imgSize, coord(:,1), coord(:,2))) = 1;
            if fillHoles
                boundMask = imfill(mask,'holes');
            else
                boundMask = mask;
            end
        end
        
    end
        
    methods
        %% initialization
        function imgPathes = mGetImgPathes(oComp, oCont)
            pFcfg = oCont.pFcfg;
            pAcfg = oCont.pAcfg;
            imgPathes = [];
            patDir = pAcfg.lastLoadPath;
            % search folders and images for each cfg.imgName
            for i = 1:size(pAcfg.imgNames,2)
                % check with which search string the correct folder is
                % found and search for images in the found folder
                % first found -> done:-)
                imgDir = []; j = 0;
                while ~(numel(imgDir)>0 | j==numel(pAcfg.imgSearchDir{i}))
                    j = j + 1;
                    if ismember('*', pAcfg.imgSearchDir{i}{j})
                        imgSearchDir = pAcfg.imgSearchDir{i}{j};
                    else
                        imgSearchDir = ['*' pAcfg.imgSearchDir{i}{j}];
                    end
                    imgDir = dir(fullfile(patDir, imgSearchDir));
                end
                
                imgDir = imgDir([imgDir.isdir]);
                imgDir(ismember({imgDir.name} , {'.', '..'})) = [];
                % what to do if more than one entry
                if numel(imgDir)>1
                    Ind =  listdlg('PromptString',{'Please select the correct ' pAcfg.imgNames{i} ' path:'},...
                        'SelectionMode','single', 'ListString', {imgDir.name},...
                        'ListSize', [550 150], 'OKString', 'Use Directory', 'CancelString', 'Abord');
                elseif numel(imgDir)==0
                    Ind =  [];
                else
                    Ind =  1;
                end
                
                % select dir or stop if no entry found
                if isempty(Ind)
                    return
                else
                    imgDir = imgDir(Ind);
                    imgDir = fullfile(patDir, imgDir.name);
                end
                
                % gather all image infos
                % check with which search string is correct
                % first found -> done:-)
                imgPath = []; j = 0;
                while ~(numel(imgPath)>0 | j==numel(pAcfg.imgSearchName{i}))
                    j = j + 1;
                    if ismember('*', pAcfg.imgSearchName{i}{j})
                        imgSearchName = pAcfg.imgSearchName{i}{j};
                    else
                        imgSearchName = ['*' pAcfg.imgSearchName{i}{j}];
                    end
                    imgPath = dir(fullfile(imgDir, imgSearchName));
                end
                
                imgTmp = feval(eval(['@(img) ' pAcfg.imgFcn '(imgDir, imgPath, pAcfg.imgNames{i})']));
                imgPathes = [imgPathes imgTmp];
            end
        end
        
        function oCont = mInit_oComp(oComp, oCont)
            pFcfg = oCont.pFcfg;
            pAcfg = oCont.pAcfg;
            %% find possible data files
            datDirs = []; j = 0;
                while ~(numel(datDirs)>0 | j==numel(pAcfg.datFileSearchString))
                    j = j + 1;
                    datDirs = subdir(fullfile(pAcfg.lastLoadPath, pAcfg.datFileSearchString{j}));
                end
            
            %% if multiple data files found select one
            if isempty(datDirs)
                Ind =  [];
            else
                for i = 1:numel(datDirs)
                    datDirs(i).filename = datDirs(i).name(numel(datDirs(i).folder)+2:end);
                end
                Ind =  listdlg('PromptString',{'More than one file found. Please select a file or start new session:'},...
                    'SelectionMode','single', 'ListString', {datDirs.filename},...
                    'ListSize', [550 150], 'OKString', 'Use File', 'CancelString', 'Start New Session');
            end

            %% start new session or load one
            if isempty(Ind)
                % START NEW SESSION
                %% find possible images
                imgPathes = oComp.mGetImgPathes(oCont);
                if isempty(imgPathes)
                    return
                end
                %% read all images
                imgCount = numel(imgPathes);
                wb = waitbar(0, ['Image 1 of ' num2str(imgCount) '. Time left: inf']);
                wb.Name = 'reading image data';
                for i=1:numel(imgPathes)
                    t1 = tic;
                    isa(imgPathes(i), 'cImage')
                    oImgs(i) = imgPathes(i).readData;
                    t2 = toc(t1);
                    time(i) = t2;
                    timeLeft = mean(time(i))*(imgCount-i);
                    waitbar(i/imgCount, wb, ['Image ' num2str(i) ' of ' num2str(imgCount) '. Time left: ' num2str(timeLeft, '%.0f') ' sec']);
                end
                close(wb);
            
                %% sort images and modify according to mode
                oComp = oComp.mInit_oCompApp(oImgs, oCont);
                
                %% set the field "pStandardImgType" to the name in Cfg file
                oComp = setStructArrayField(oComp, 'pStandardImgType', {pAcfg.standardImgType});
                
                %% oComp creation done
                
                oCont.oComp = oComp;
                oCont.pSaveDate = datetime.empty;
                
                %% set version infos
                % update oCont.version struct for classes
                oCont = oComp.mUpdate_cControlVersionInfo(oCont);
                oCont = oComp(1).oImgs(1).update_cControlVersionInfo(oCont);
                % update oCont.version struct for cfg files
                oCont.mSetVersionInfo('applicationCfg', pAcfg.cfg_application_version, '');
                oCont.mSetVersionInfo('frameworkCfg', pFcfg.cfg_framework_version, '');
            else
                % LOAD SESSION FILE
                load(datDirs(Ind).name);
                                
                %% merge data in oComp object:
                if isfield(data, 'version_tabDat')    % do we have a FatSegment data file of ISAT?
                    % update data to Dicomflex (only for old ISAT datasets <20180401)
                    data = oComp.mTabDat2oCompApp(data, saveDate);
                end
                % go to updateFcn of class and there go back to update Fcn of superclass
                oComp = oComp.(['mUpdate_' class(oComp)])(data, saveDate);
                %% update version infos
                % update oCont.version struct for classes
                oCont = oComp.mUpdate_cControlVersionInfo(oCont);
                oCont = oComp(1).oImgs(1).update_cControlVersionInfo(oCont);
                
                % update oCont.version struct for cfg files
                oCont.mSetVersionInfo('applicationCfg', pAcfg.cfg_application_version, '');
                oCont.mSetVersionInfo('frameworkCfg', pFcfg.cfg_framework_version, '');
                
                oCont.oComp = oComp;
                
            end
            
        end
        
        function oCont = mUpdate_cControlVersionInfo(oComp, oCont)
            sc = superclasses(class(oComp));
            sc = [{class(oComp)}; sc];
            for i = 1:numel(sc)
                oCont.mSetVersionInfo(sc{i}, oComp(1).(['pVersion_' sc{i}]), ['mUpdate_' sc{i}]);
                %                     removed at 20170228
                %                     oCont.mSetVersionInfo('oComp', oComp(1).oCompParent_version, ['update' sc{1}]);
                %                     oCont.mSetVersionInfo(oComp(1).oCompChild1_name, oComp(1).oCompChild1_version, ['update' class(oComp)]);
            end
        end
        
        %% GUI Update and Interaction
        function oCont =  mSliceSelected(oComp, oCont, old, new)
            %right now used by mTableCellSelect, however could be used in cComputeApp methods as well when all oComp are
            %available. Else the method must be changed to work for a single oComp object and giving the old oComp object as
            %varargin
            % logging for old slice
            oComp(old) = oCont.oComp(old).mLogging(['oCont.mSliceSelected - deSelect ' num2str(old)]);
            % logging for new slice
            oComp(new) = oCont.oComp(new).mLogging(['oCont.mSliceSelected - select' num2str(new)]);
            
            oCont.oComp = oComp;
        end
        
        function oCont =  mImageUpdate(oComp, oCont)
            %t1 = tic;
            imgAxis = oCont.pHandles.imgAxis;
            pFcfg = oCont.pFcfg;
            pAcfg = oCont.pAcfg;
            datInd =  oCont.pTable.row;
            oComp = oCont.oComp(datInd);
            if ishandle(imgAxis)
                % Axis already exists!
                %% determine image to be shown
                imgDisplay = oComp.mGetImg2Display(oCont);
                oComp.pHistory.plotImg = imgDisplay;
                imgDisplay.data = uint8(imgDisplay.data);
                
                %% update imgAxis with imgDisplay
                axes(imgAxis);
                axChilds = get(imgAxis, 'Children');
                delInd =[];
                for i = 1:numel(axChilds)
                    if isa(axChilds(i), 'matlab.graphics.primitive.Image')
                    else
                        delete(axChilds(i));
                        delInd = [delInd i];
                    end
                end
                axChilds(delInd) = [];
                if numel(axChilds)==0
                    hold all;    % without hold the ButtonDownFcn would be deleted
                    oCont.pHandles.imgDisplay = imshow(imgDisplay.data, 'DisplayRange', [], 'parent', imgAxis);
                    hold off;
                    oCont.pHandles.imgDisplay.ButtonDownFcn = oCont.pHandles.imgAxis.ButtonDownFcn;
                    oCont.pHandles.imgDisplay.HitTest = 'on';
                elseif numel(axChilds)==1
                    oCont.pHandles.imgDisplay = get(imgAxis, 'Children');
                    oCont.pHandles.imgDisplay.CData = imgDisplay.data;
                end
                
                %% define Display size
                if isfield(oCont.pHandles, 'zoomRect') && isvalid(oCont.pHandles.zoomRect)
                    pos = oCont.pHandles.zoomRect.getPosition
                else
                    tmp = size(oCont.pHandles.imgDisplay.CData);
                    pos = [0 0 tmp(2) tmp(1)];
                end
                oCont.pHandles.imgAxis.XLim = [pos(1) pos(1)+pos(3)];
                oCont.pHandles.imgAxis.YLim = [pos(2) pos(2)+pos(4)];
                
                %% post modifications with oCompMODE
                oComp.mPostPlot(oCont);
                
            else
                msgbox('no image Axis found')
            end
            oCont.oComp(datInd) = oComp;
            drawnow
            %t2 = toc(t1);
            %disp(['mImgageUpdate: ' num2str(t2) ' sec']);
        end
        
        function oCont = mGraphUpdate(oComp, oCont)
            %t1 = tic;
            oCont = mDrawGraph(oComp, oCont);
            %t2 = toc(t1);
            %disp(['mGraphUpdate: ' num2str(t2) ' sec']);
        end
        
        function oCont =  mTextUpdate(oComp, oCont)
            %t1 = tic;
            textBox = oCont.pHandles.textBox;
            pFcfg = oCont.pFcfg;
            pAcfg = oCont.pAcfg;
            oComp = oCont.oComp(oCont.pTable.row);
            
            textBox.FontWeight = 'bold';
            textBox.ForegroundColor = pFcfg.apperance.color3;
            textBox.String = oComp.mGetTextBoxLines(oCont);
            textBox.HorizontalAlignment = 'left';
            %t2 = toc(t1);
            %disp(['mTextUpdate: ' num2str(t2) ' sec']);
        end
        
        function oComp = mShowHotkeyInfo(oComp, oCont)
            names = fieldnames(oCont.pAcfg.key);
            txt = (cellfun(@(x) string([oCont.pAcfg.key.(x) ' - ' x]), names, 'un', false));
            uiwait(msgbox(txt));
        end
        
        %% Boundary management
        function oCont =  mMergeContours(oComp, oCont)
            if strcmp(oCont.pActiveKey, '')
                msgbox(['Use one of the following keys to select a Boundary to be changed first:'...
                    cell2mat(oCont.pAcfg.contour.names)]);
            else
                %% determine which contour type
                %nameInd =  ismember(oCont.pAcfg.contour.keyAssociation, oCont.pActiveKey);
                contourName = oCont.pAcfg.contour.names{find(ismember(oCont.pAcfg.contour.keyAssociation, oCont.pActiveKey))};
                
                %% prepare variables
                datInd =  oCont.pTable.row;
                oComp = oCont.oComp(datInd);
                imgBase = oComp.oImgs(1);
                imgZero = zeros(size(imgBase.data));
                newCoord = round(oCont.pLineCoord);
                BoundInd = oComp.oBoundaries.getBoundInd(oComp.pSelectedBound);
                
                if BoundInd == 0;
                    % this gets executed if no old bound exists
                    % fill from newS to newE with pixel points and mit it
                    % old bound
                    empty_oComp = feval(str2func(oCont.pAcfg.cComputeFcn));
                    cBound =  empty_oComp.oBoundaries;
                    BoundInd =  numel(oComp.oBoundaries)+1;
                    cBound(1).name = contourName;
                    [x y] = makeLinePoints(newCoord(1,1), newCoord(1,2), newCoord(end,1), newCoord(end,2));
                    oldCoord = [x' y'];
                else
                    cBound =  oComp.oBoundaries(BoundInd);
                    oldCoord = oComp.oBoundaries(BoundInd).coord;
                end
                
                %% Connect newCoord to oldCoord
                % find start- end-point connection from new to old
                newS = newCoord(1,:);
                newE = newCoord(end,:);
                
                distS = pointDist(oldCoord, newS);
                [a indS] = min(distS);
                
                distE = pointDist(oldCoord, newE);
                [a indE] = min(distE);
                
                oldS = oldCoord(indS,:);
                oldE = oldCoord(indE,:);
                
                % fill new coordinates with pixel points
                for i=1:size(newCoord,1)-1
                    [x y] = makeLinePoints(newCoord(i,1), newCoord(i,2), newCoord(i+1,1), newCoord(i+1,2));
                    newCoord = [newCoord; [x; y]'];
                end
                
                % get connecting line coordinates
                [lineSX lineSY] = makeLinePoints(newS(1), newS(2), oldS(1), oldS(2));
                [lineEX lineEY] = makeLinePoints(newE(1), newE(2), oldE(1), oldE(2));
                newCoord = [newCoord; [lineEX; lineEY]'];
                newCoord = [newCoord; [lineSX; lineSY]'];
                newCoord = unique(newCoord, 'rows');
                
                %% Collect initially important AreaMasks
                % merge new and old Coords and generate allCoordMask
                allCoord = unique([newCoord; oldCoord], 'rows');
                
                % make all coordinate image
                Pxls = allCoord;
                allCoordMask = imgZero;
                for i=1:size(Pxls,1)
                    allCoordMask(Pxls(i,1),Pxls(i,2))=1;
                end
                allMask = imfill(allCoordMask, 'holes');
                
                % make new coordinate image
                Pxls = newCoord;
                newCoordMask = imgZero;
                for i=1:size(Pxls,1)
                    newCoordMask(Pxls(i,1),Pxls(i,2))=1;
                end
                
                % make old coordinate image
                Pxls = oldCoord;
                oldCoordMask = imgZero;
                for i=1:size(Pxls,1)
                    oldCoordMask(Pxls(i,1),Pxls(i,2))=1;
                end
                oldMask = imfill(oldCoordMask, 'holes');
                
                %% Generate all possible areas prepare them for merge
                % prepare areas
                allAreasMask = allMask&~allCoordMask;
                comp = bwconncomp(allAreasMask, 4);
                PixelIdxList = comp.PixelIdxList;
                % also take areas that consist only of new coord pxls
                newCoordAreaMask = newCoordMask&~oldCoordMask;
                comp = bwconncomp(newCoordAreaMask, 4);
                PixelIdxList = [PixelIdxList comp.PixelIdxList];
                areas = struct('areaPxls', [], 'areaMask', [], 'memberOfOld', [], 'memberOfExterior', []);
                
                % determine if area is inside, ouside or mainOldPart
                for i = 1:numel(PixelIdxList)
                    areas(i).areaPxls = PixelIdxList{i};
                    % now sort to oldMask or exterior
                    if sum(oldMask(areas(i).areaPxls)) == numel(areas(i).areaPxls)
                        areas(i).memberOfOld =  1;
                        areas(i).memberOfExterior = 0;
                    elseif sum(oldMask(areas(i).areaPxls)) == 0
                        areas(i).memberOfOld =  0;
                        areas(i).memberOfExterior = 1;
                    else
                        msgbox('area could not be associated to interior or exterior of mask')
                    end
                end
                
                % include coordinate points
                tic
                kernel3x3 = ones(3,3);
                kernel5x3 = ones(5,3);
                for i = 1:numel(areas)
                    
                    areas(i).areaMask = zeros(size(oldMask));
                    areas(i).areaMask(areas(i).areaPxls) = 1;
                    area = areas(i).areaMask;
                    
                    % merge with oldCoordMask
                    areaC = area|oldCoordMask; % area and Coordinates
                    areaC = uint8(areaC);
                    
                    % filter with
                    imgTmp1 = imfilter(areaC, kernel5x3);
                    imgTmp1 = imgTmp1>4;
                    imgTmp2 = imfilter(areaC, kernel5x3');
                    imgTmp2 = imgTmp2>4;
                    imgTmp = uint8(imgTmp1&imgTmp2);
                    
                    imgTmp(areaC==0) = 0;
                    imgTmp = imfilter(imgTmp, kernel3x3);
                    imgTmp = imgTmp>2;
                    imgTmp(areaC==0) = 0;
                    imgTmpO = imgTmp;
                    
                    % merge with newCoordMask
                    areaC = area|newCoordMask; % area and Coordinates
                    areaC = uint8(areaC);
                    
                    % filter with
                    imgTmp1 = imfilter(areaC, kernel5x3);
                    imgTmp1 = imgTmp1>4;
                    imgTmp2 = imfilter(areaC, kernel5x3');
                    imgTmp2 = imgTmp2>4;
                    imgTmp = uint8(imgTmp1&imgTmp2);
                    
                    imgTmp(areaC==0) = 0;
                    imgTmp = imfilter(imgTmp, kernel3x3);
                    imgTmp = imgTmp>2;
                    imgTmp(areaC==0) = 0;
                    imgTmpN = imgTmp;
                    
                    imgTmp = imgTmpN|imgTmpO;
                    
                    
                    
                    if areas(i).memberOfOld
                        areas(i).areaMask = uint8(imgTmp&oldMask);
                    elseif areas(i).memberOfExterior
                        areas(i).areaMask = uint8(imgTmp&~oldMask);
                    end
                end
                toc
                
                %% merge Areas
                Fmask = uint8(zeros(size(oldMask)));
                oldAreasInd =  find([areas.memberOfOld]);
                [a ind] = max(arrayfun(@(x) numel(x.areaPxls), areas(oldAreasInd)));
                oldAreaInd =  oldAreasInd(ind);
                
                for i = 1:numel(areas)
                    currAreaMask = logical(areas(i).areaMask);
                    if i==oldAreaInd
                        % if area is the biggest are in the region of the
                        % old mask, than keep it
                        Fmask(currAreaMask) = 1;
                    else
                        if areas(i).memberOfOld
                            % if area is not the biggest are in the region of the
                            % old mask, than dont keep it
                            % additional: if the area gets rejected, the
                            % coordinates must be excluded from rejection
                            
                            Fmask(currAreaMask&~allCoordMask) = 0;
                        elseif areas(i).memberOfExterior
                            % if area is in the region of the exterior, than keep it
                            Fmask(currAreaMask) = 1;
                        end
                    end
                end
                
                % use biggest Fmask area as Fmask
                comp = bwconncomp(Fmask, 4);
                [a ind] = max(arrayfun(@(x) numel(x{1}), comp.PixelIdxList));
                FmaskPxls = comp.PixelIdxList{ind};
                Fmask = uint8(zeros(size(oldMask)));
                Fmask(FmaskPxls) = 1;
                Fmask = imfill(Fmask, 'holes');
                
                %% store new bound
                b = bwboundaries(Fmask);
                cBound.coord = b{1};
                oComp.oBoundaries(BoundInd) = cBound;
                %oComp.oBoundaries(find(nameInd)).coord = ;
                %oComp = oComp.updateAllVol;
                %oComp.segmentDone = 1;
                
                %% write back to cControl object
                oCont.oComp(datInd) = oComp;
                
            end
        end
        
        function oCont =  mCopyBound(oComp, oCont)
            oCont.pHistory.copy_oComp = oCont.oComp(oCont.pTable.row);
        end
        
        function oCont =  mPasteBound(oComp, oCont)
            nBounds = oCont.pHistory.copy_oComp.oBoundaries;
            oBounds = oCont.oComp(oCont.pTable.row).oBoundaries;
            tmp = oComp;
            emptyBound =  tmp.oBoundaries;
            
            for i=1:numel(nBounds)
                nBound =  nBounds(i);
                tmpBound =  eval(class(nBound));
                tmpBound(1).name = nBound.name;
                tmpBound.coord = nBound.coord;
                ind = oBounds.getBoundInd(nBound.name); % find same name in oBounds to replace bound
                if ind == 0
                    % create new bound
                    oBounds(end+1) = tmpBound;
                else
                    % replace bound
                    oBounds(i) = tmpBound;
                    
                end
            end
            oCont.oComp(oCont.pTable.row).oBoundaries = oBounds;
        end
        
        function oCont = mContourTrackingONOFF(oComp, oCont)
            oCont.pAcfg.contour.contourTracking.enable = ~oCont.pAcfg.contour.contourTracking.enable;
            if oCont.pAcfg.contour.contourTracking.enable == 0
                uiwait(msgbox('Contour Tracking is now disabled'));
            elseif oCont.pAcfg.contour.contourTracking.enable == 1
                uiwait(msgbox('Contour Tracking is now enabled'));
            end
        end
        
        %% Image Management
        function oImg = mGetImgOfType(oComp, type)
            typeInd =  find(ismember({oComp.oImgs.imgType}, type));
            if isempty(typeInd)
                msgbox(['Images of type ' type ' not found!']);
            else
                oImg = oComp.oImgs(typeInd);
            end
        end
        
        function oImg = mGetStandardImg(oComp)
            typeInd =  arrayfun(@(x) find(ismember({x.oImgs.imgType}, {x.pStandardImgType})), oComp, 'un', false); typeInd =  typeInd{1};
            if numel(typeInd)>1
                %msgbox(['More than one ' oComp.pStandardImgType ' image found! First image is useoCont.'], 'unspecific image information');
                typeInd =  typeInd(1);
            end
            for i = 1:numel(oComp)
                oImg(i) = oComp(i).oImgs(typeInd(i));
            end
            
        end
        
        %% Processing
        function mSave_oComp(oComp, path, oCont)
            path2 = dir(path);
            try
            if path2.isdir
                path = fullfile(path, [oCont.pApplication '_tmpdata.m']);
            else
            end
            end
            
            data = arrayfun(@struct ,oComp); % release from class definition (think about verion flexibility)
            saveDate = datetime('now');
            versions = oCont.pVersions;
            oContLogging = oCont.pVarious.TimeLogging;
            save(path, 'data', 'saveDate', 'versions', 'oContLogging');
        end
        
        %% Fitting and so
        function oCont =  mShowFitInFitTool(oComp, oCont)
            boundInd =  oComp.oBoundaries.getBoundInd(oComp.pSelectedBound);
            if ~isempty(boundInd)
                cBound =  oComp.oBoundaries(boundInd);
                if isfield(oCont.pHandles, 'FT') && isvalid(oCont.pHandles.FT) && ishandle(oCont.pHandles.FT.handles.figure)
                    oComp.mUpdateFitTool(oCont, cBound);
                else
                    oComp.mStartFitTool(oCont, cBound);
                end
            else
            end
            oCont.pHandles.FT.handles.sendData.Callback = @(varargin)oComp.mUseFitToolData(oCont, oCont.pHandles.FT,varargin);
            figure(oCont.pHandles.figure);
        end
        
        function oCont =  mStartFitTool(oComp, oCont, cBound)
            oCont.pHandles.FT = FitTool(cBound.FitObj.getDepParNames{1}, cBound.FitObj.yData, cBound.FitObj.getIndepParNames{1}, cBound.FitObj.xData, 'fittype', cBound.FitObj.ftype);
            figure(oCont.pHandles.figure);
            oCont.pHandles.FT.fitInfo.current = cBound.FitObj.values;
            oCont.pHandles.FT.fittype2fitInfo;
            oCont.pHandles.FT.fitInfo2gui;
        end
        
        function oCont =  mUpdateFitTool(oComp, oCont, cBound)
            oCont.pHandles.FT.fitInfo.current = cBound.FitObj.values;
            oCont.pHandles.FT.fitInfo.ftype = cBound.FitObj.ftype;
            oCont.pHandles.FT.newRawData(cBound.FitObj.getDepParNames{1}, cBound.FitObj.yData, cBound.FitObj.getIndepParNames{1}, cBound.FitObj.xData);
            oCont.pHandles.FT.fittype2fitInfo;
            oCont.pHandles.FT.fitInfo2gui;
        end
        
        function oComp = mUseFitToolData(oComp, oCont, dFT, varargin)
            % update current and fittype data
            %oComp.fitData.current = dFT.fitInfo.current;
            %oComp.fitData.ftype = dFT.fitInfo.ftype;
            %oCont.oComp(oCont.pTable.row) = oComp;
            
            oComp.BoundData(oComp.pSelectedBound).ftype = dFT.fitInfo.ftype;
            oComp.BoundData(oComp.pSelectedBound).current = dFT.fitInfo.current;
            oComp.BoundData(oComp.pSelectedBound).gof = dFT.fitInfo.gof;
            oCont.oComp(oCont.pTable.row) = oComp;
            oCont.mTableCellSelect('Caller', 'mUseFitToolData');
        end
        
        %% class methods
        function oComp = mLogging(oComp, action, varargin)
            if isfield(oComp.pVarious, 'TimeLogging')
                oComp.pVarious.TimeLogging.Stamp(end+1) = now;
                oComp.pVarious.TimeLogging.Action(end+1) = {action};
            else
                oComp.pVarious.TimeLogging.Stamp(1) = now;
                oComp.pVarious.TimeLogging.Action(1) = {action};
            end
        end
        
        function oComp = mUpdate_cCompute(oComp)
            oComp;
        end
        
        function oComp = cCompute(cCompArray)
            
        end
    end
end

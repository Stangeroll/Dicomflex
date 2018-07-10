classdef cComputeT1Mapper<cCompute
    properties
        %% these properties must exist
        pVersion_cComputeT1Mapper = '1.2';
        
        %% these properties are just for application specific use
        oBoundaries = boundaryFit.empty;
        pPxlData = struct('pxlNr', [], 'parameters', {}, 'rmse', [], 'rsquare', [], 'badFitReason', {}, 'fitOk', {}, 'values', {[]}, 'cFitObj', rsFitObj);
        pSelectedBound = '';
        pSliceDone = 0;    % 0 means not semented, 1 means segemented but not fitted, 2 means segmented and fitted
    end
    
    methods(Static)
        
    end
    
    methods
        % % % File management % % %
        function oComp = mInit_oCompApp(oComp, oImgs, oCont)
            pFcfg = oCont.pFcfg;
            pAcfg = oCont.pAcfg;
            %-------------------------------%
            % sort images and init dat struct
            i=0;
            sliceLocs = arrayfun(@(x) x.sliceLocation, oImgs, 'un', false);
            for sliceLoc = unique(sliceLocs)
                i=i+1;
                indImg = find(ismember(sliceLocs, sliceLoc(1)));
                oComp(i) = feval(str2func(pAcfg.cComputeFcn));
                imgstmp = oImgs(indImg);
                TI = arrayfun(@(x) x.dicomInfo(1).InversionTime, imgstmp)';
                [a sortInd] = sort(TI, 'ascend');
                oComp(i).oImgs = imgstmp(sortInd);
                oComp(i).pPatientName = oImgs(indImg(1)).patientName;
                oComp(i).pDataName = [oComp(i).pPatientName oComp(1).oImgs(1).dicomInfo.AcquisitionDate];
                oComp(i).pSliceLocation = oImgs(indImg(1)).sliceLocation;
            end
            [a sortInd] = sort(cellfun(@(x) str2num(x) ,{oComp.pSliceLocation}), 'ascend');
            oComp = oComp(sortInd);
        end
        
        % % % GUI update % % %
        function imgDisplay = mGetImg2Display(oComp, oCont)
            pFcfg = oCont.pFcfg;
            pAcfg = oCont.pAcfg;
            oComp = oCont.oComp(oCont.pTable.row);
            %-------------------------------%
            %% determine image to be shown
            switch pAcfg.imageDisplayMode
                case {'Ti', 'Raw Images'}
                    imgDisplay = oComp.mGetImgOfType(pAcfg.standardImgType);
                    imgDisplay = imgDisplay(pAcfg.imageNr);
                case 'T1 Map'
                    oCont.pVarious.T1Range = [100 550];
                    %oCont.pVarious.T1Range = [100 3000];
                    imgDisplay = oComp.mGetT1Img;
                    imgBackground = oComp.mGetStandardImg;
                    
                    T1Zero = imgDisplay.data==0;
                    try
                        % get body mask
                        coord = RSouterBound(oComp.oImgs(5), 'MRT_OutPhase', 2);
                        bodyMask = oComp.mGetBoundMask(oComp.oImgs(1).data, coord);
                        %figure(); imagesc(bodyMask);
                        
                        
                        
                        FOkmask = oComp.pPxlData.fitOk;
                        R2mask = oComp.pPxlData.rsquare<0.92;
                        Window = imgDisplay.data<oCont.pVarious.T1Range(1) | imgDisplay.data>oCont.pVarious.T1Range(2);
                        
                        HideMask = ~FOkmask | R2mask | T1Zero | Window | ~bodyMask;
                        %HideMask = T1Zero| Window;
                        oCont.pVarious.T1MapAvailable = true;
                    catch
                        HideMask = T1Zero;
                        oCont.pVarious.T1MapAvailable = false;
                    end
                    %HideMask = ~FOkmask;
                    bwImg = zeros(size(imgBackground.data));
                    bwImg(imgBackground.data>max(max(imgBackground.data))/8) = 5;
                    bwImg(imgBackground.data>max(max(imgBackground.data))/4) = 10;
                    bwImg(imgBackground.data>max(max(imgBackground.data))/2) = 20;
                    bwImg = bwImg+100;
                    imgDisplay.data(find(HideMask)) = bwImg(find(HideMask));
                    
                    
                case 'T1 Gradient'
                    imgDisplay = oComp.mGetT1Img;
                    FOkmask = oComp.pPxlData.fitOk;
                    R2mask = oComp.pPxlData.rsquare<0.8;
                    T1Mask = imgDisplay.data>500;
                    
                    imgDisplay.data = imgradient(imgDisplay.data, 'sobel');
                    GradMask = imgDisplay.data>400;
                    
                    HideMask = ~FOkmask | R2mask | T1Mask | GradMask;
                    imgDisplay.data(find(HideMask)) = min(min(imgDisplay.data));
                    
            end
            %% convert
            scale = ceil(size(oComp.oImgs(1).data)./size(imgDisplay.data));
            imgDisplay.data = imgDisplay.dataResize(min(scale));
            imgDisplay = imgDisplay.scale2([0 255]);
            
        end
                
        function mPostPlot(oComp, oCont)
            %oCont.pAcfg.contour.colors = {'blue' 'red' 'green' 'blue' [0.85 0.33 0.1] 'red' [0.49 0.18 0.56] [0.47 0.67 0.19] [0.3 0.75 0.93]} ;
            pFcfg = oCont.pFcfg;
            pAcfg = oCont.pAcfg;
            oComp = oCont.oComp(oCont.pTable.row);
            imgAxis = oCont.pHandles.imgAxis;
            %-------------------------------%
            %% apply colormap
            colorbar(oCont.pHandles.imgAxis, 'off');
            switch pAcfg.imageDisplayMode
                case 'T1 Map'
                    colormap(oCont.pHandles.imgAxis, 'jet'); % parula jet hsv colorcube
                    colorbar(oCont.pHandles.imgAxis, 'off');
                    cb = colorbar(oCont.pHandles.imgAxis);
                    cb.FontWeight = 'bold';
                    cb.Color = pFcfg.apperance.designColor1;
                    cb.Position(1) = 0.9
                    cb.Position(2) = 0.075;
                    cb.Position(4) = 0.85;
                    
                    barvals = round(cellfun(@(x) str2num(x), cb.TickLabels)/(255/oCont.pVarious.T1Range(2)));   %255 entspricht oCont.pVarious.T1Range(2)
                    cb.TickLabels = arrayfun(@(x) char(num2str(x)), barvals, 'un', false);
                    if ~oCont.pVarious.T1MapAvailable;
                        Message = text(0, 0, '', 'Parent', oCont.pHandles.imgAxis, 'Color', 'red');
                        Message.String = 'No T1-Map data available. Please process T1 fitting!';
                        Message.Position = [10 40];
                        Message.FontSize = 14;
                        Message.FontWeight = 'bold';
                    end
                case 'T1 Gradient'
                    colormap(oCont.pHandles.imgAxis, 'parula'); % parula jet hsv colorcube
                otherwise
                    colormap(oCont.pHandles.imgAxis, 'gray');
            end
            %% plot segmentation
            contCoord = {};
            colors = {};
            for i=1:numel(oComp.oBoundaries)
                cBound = oComp.oBoundaries(i);
                contCoord{i} = {cBound.coord};
                colors(i) = pAcfg.contour.colors(find(ismember(pAcfg.contour.names, cBound.name)));
            end
            % plot contours
            oCont.pHandles.contour = oCont.mDrawContour(imgAxis, contCoord, colors);
            %% TopLeft text in Image
%             imgText = ['T1-image nr' num2str(pAcfg.imageNr)];
%             imgText = [imgText ' - Row ' num2str(oCont.pTable.row)];
%             oCont.pHandles.imgText = text(10,10, imgText, 'Parent', imgAxis, 'Color', 'white');
%             oCont.pHandles.imgText.HitTest = 'off';
%             
            %% TopLeft text in Image
            pos = [3, 6];
            gap = 8;
            letterSize = 10;
            letterStyle = 'bold';
            imgText = [pAcfg.imageDisplayMode ' - Slice ' num2str(oCont.pTable.row)];
            oCont.pHandles.imgText = text(pos(1),pos(2), imgText, 'Parent', imgAxis, 'Color', 'white'); pos(2) = pos(2)+gap;
            oCont.pHandles.imgText.FontSize = letterSize;
            oCont.pHandles.imgText.FontWeight = letterStyle;
            oCont.pHandles.imgText.HitTest = 'off';
            % boundary text im image
            for i = 1:numel(oComp.oBoundaries)
                if ~isempty(oComp.oBoundaries(i).coord)
                    % plot annotation
                    txt = oComp.oBoundaries(i).name;
                    t = text(pos(1),pos(2), txt, 'Parent', oCont.pHandles.imgAxis, 'Color', colors{i});
                    t.FontSize = letterSize;
                    t.FontWeight = letterStyle;
                    pos(2) = pos(2)+gap;
                end
            end
            
        end
        
        function oCont = mDrawGraph(oComp, oCont)
            pFcfg = oCont.pFcfg;
            pAcfg = oCont.pAcfg;
            oComp = oCont.oComp(oCont.pTable.row);
            graphAxis = oCont.pHandles.graphAxis;
            boundInd = oComp.oBoundaries.getBoundInd(oComp.pSelectedBound);
            %-------------------------------%
            if boundInd == 0;
                delete(oCont.pHandles.graphAxis.Children);
            else
                cBound = oComp.oBoundaries(boundInd);
                if ishandle(graphAxis) & ~isempty(cBound) && ~isempty(cBound.FitObj.xData)
                    % graphAxis exists
                    axes(graphAxis);
                    oCont.pHandles.graphAxis.Box = 'on';
                    
                    %% plot x-y-Data
                    if isfield(oCont.pHandles, 'graphPlot') && isvalid(oCont.pHandles.graphPlot)
                        oCont.pHandles.graphPlot.XData = cBound.FitObj.xData;
                        oCont.pHandles.graphPlot.YData = cBound.FitObj.yData;
                    else
                        oCont.pHandles.graphPlot = plot(cBound.FitObj.xData, cBound.FitObj.yData);
                        oCont.pHandles.graphPlot.LineStyle = 'none';
                        oCont.pHandles.graphPlot.Marker = 'o';
                        oCont.pHandles.graphPlot.HitTest = 'off';
                    end
                    oCont.pHandles.graphPlot.Color = pAcfg.contour.colors{find(ismember(pAcfg.contour.names, cBound.name))};
                    
                    %% plot fit if available
                    if ~isempty(cBound.FitObj.cfun)
                        if isfield(oCont.pHandles, 'graphFplot') && isvalid(oCont.pHandles.graphFplot)
                            oCont.pHandles.graphFplot.YData = cBound.FitObj.cfun(oCont.pHandles.graphFplot.XData);
                        else
                            hold on;
                            oCont.pHandles.graphFplot = plot(cBound.FitObj.cfun);
                            %oCont.pHandles.graphFplot = plot(cBoundaries.FitObj.cfun, cBoundaries.FitObj.xData, cBoundaries.FitObj.yData);
                            legend off;
                            oCont.pHandles.graphFplot.LineWidth = 1.5;
                            hold off;
                        end
                        oCont.pHandles.graphFplot.Color = pAcfg.contour.colors{find(ismember(pAcfg.contour.names, cBound.name))};
                    end
                    
                    %% do style modifiactions
                    oCont.pHandles.graphAxis.Color = pFcfg.apperance.backGroundColor;
                    oCont.pHandles.graphAxis.YColor = pFcfg.apperance.designColor1;
                    oCont.pHandles.graphAxis.XColor = pFcfg.apperance.designColor1;
                    oCont.pHandles.graphAxis.YTick = [];
                    oCont.pHandles.graphAxis.XTickMode = 'auto';
                    oCont.pHandles.graphAxis.FontWeight = 'bold';
                    oCont.pHandles.graphAxis.Box = 'on';
                    oCont.pHandles.graphAxis.YLabel.String = 'Pixel Intensity';
                    oCont.pHandles.graphAxis.XLabel.String = 'Inversion Time TI [msec]';
                else
                    delete(oCont.pHandles.graphAxis.Children);
                end
                drawnow
            end
        end
        
        function lines = mGetTextBoxLines(oComp, oCont)
            textBox = oCont.pHandles.textBox;
            pFcfg = oCont.pFcfg;
            pAcfg = oCont.pAcfg;
            oComp = oCont.oComp(oCont.pTable.row);
            %-------------------------------%
            % are fat values up to date?
            if oComp.pSliceDone == 1 % 1 means segmented, but not fitted
                [d oComp] = oComp.mCalcFatAveraged(oCont);
            end
            
            lines = string.empty;
            count = 0;
            
            for i=1:numel(oComp.oBoundaries)
                cBound = oComp.oBoundaries(i);
                parameters = cBound.FitObj.parameters;
                values = cBound.FitObj.values;
                for j = 1:numel(parameters)
                    count = count+1;
                    lines(count) = string([cBound.name ' ' parameters{j} ': ' sprintf('%.1f', values(j))]);
                end
                
%                 if isfield(cBound.various, 'T1')
%                     count = count+1;
%                     lines(count) = string([cBound.name ' T1_median: ' sprintf('%.1f', median(oComp.mGetT1Img.data(cBound.various.pxlNrT1Img)))]);
%                     count = count+1;
%                     lines(count) = string([cBound.name ' T1_mean: ' sprintf('%.1f', mean(oComp.mGetT1Img.data(cBound.various.pxlNrT1Img)))]);
%                 end
                
            end
            
        end
        
        % % % GUI Interaction % % %
        function oComp = mTableEdit(oComp, select)
            switch select.Source.ColumnName{select.Indices(2)}
                case ''
            end
        end
        
        function oComp = mKeyPress(oComp, oCont, key)
            pAcfg = oCont.pAcfg;
            key = key.Key;
            %-------------------------------%
            oCont.pHandles.figure.WindowKeyReleaseFcn = {@oCont.mKeyRelease};
            %oCont.pHandles.figure.WindowKeyPressFcn = '';
            switch key
                case pAcfg.contour.keyAssociation  % normal grayed out contour display
                    oComp.pSelectedBound = pAcfg.contour.names(find(ismember(pAcfg.contour.keyAssociation, key)));
                    imgAxis = oCont.pHandles.imgAxis;
                    % delete axis childs
                    if exist('oCont.pHandles.contour')
                        for a = oCont.pHandles.contour
                            delete(a);
                        end
                    end
                    
                    %% Plot Contours grayed out
                    contCoord = {};
                    colors = {};
                    for i=1:numel(oComp.oBoundaries)
                        cBound = oComp.oBoundaries(i);
                        contCoord{i} = {cBound.coord};
                        if isequal({cBound.name}, oComp.pSelectedBound)
                            colors(i) = pAcfg.contour.colors(find(ismember(pAcfg.contour.names, oComp.pSelectedBound)));
                        else
                            colors{i} = [0.1 0.1 0.1];
                        end
                    end
                    % plot contours
                    oCont.pHandles.contour = oCont.mDrawContour(imgAxis, contCoord, colors);
                    
                    
                    pause(0);
                    
                case pAcfg.key.deleteContour  % delete selected contour
                    disp('keyDelCont')
                    % delete contour if one contour is selected
                    otherKeys = oCont.pActiveKey(~ismember(oCont.pActiveKey, {key}))
                    if numel(otherKeys) > 1
                        disp('to many keys pressed');
                    else
                        switch otherKeys{1}
                            case pAcfg.contour.keyAssociation
                                contourName = pAcfg.contour.names(find(ismember(oCont.pAcfg.contour.keyAssociation, otherKeys{1})))
                                
                                boundInd = oComp.oBoundaries.getBoundInd(oComp.pSelectedBound);
                                if ~isempty(boundInd)
                                    oComp.oBoundaries(boundInd) = [];
                                    oComp.pSliceDone = 0;
                                end
                                
                        end
                    end
                case pAcfg.key.showFit
                    oComp.mShowFitInFitTool(oCont);
                case pAcfg.key.fitData
                    % start fitting ...
                    oComp = oComp.mCalcRoiAveraged(oCont);
                    %oComp = oCont.oComp;
                    oCont.mUpdateTable;
                case pAcfg.key.nextImage
                    if pAcfg.imageNr < numel(oComp.oImgs)
                    pAcfg.imageNr = pAcfg.imageNr + 1;
                    end
                case pAcfg.key.previousImage
                    if pAcfg.imageNr > 1
                    pAcfg.imageNr = pAcfg.imageNr - 1;
                    end
            end
            %-------------------------------%
            oCont.pAcfg = pAcfg;
        end
        
        function mKeyRelease(oComp, oCont, key)
            pAcfg = oCont.pAcfg;
            pFcfg = oCont.pFcfg;
            key = key.Key;
            %-------------------------------%
            oCont.pHandles.figure.WindowKeyPressFcn = @oCont.mKeyPress;
            switch key
                case pAcfg.contour.keyAssociation  % normal grayed out contour display
                    oComp.pSelectedBound = pAcfg.contour.names(find(ismember(pAcfg.contour.keyAssociation, key)));
                    cBound = oComp.oBoundaries.getBoundOfType(oComp.pSelectedBound);
                    if ~isempty(cBound.coord)
                        if isfield(oCont.pHandles, 'boundInfoFig') && ishandle(oCont.pHandles.boundInfoFig)
                            scale = size(oComp.oImgs(1).data)./size(oComp.mGetT1Img.data);
                            imgDisplay = getimage(oCont.pHandles.imgAxis);
                            cBound = oComp.oBoundaries.getBoundOfType(oComp.pSelectedBound);
                            boundMask = oComp.mGetBoundMask(imgDisplay, cBound.coord);
                            boundMask = imresize(boundMask, 1/scale(1), 'nearest');
                            boundData = oComp.mGetT1Img.data(find(boundMask));
                            %boundData = imgDisplay(find(boundMask));
                            
                            delete(oCont.pHandles.boundInfoAxis.Children);
                            axes(oCont.pHandles.boundInfoAxis);
                            h = histfit(boundData, ceil(sqrt(numel(boundData))), 'normal');
                            h(1).FaceColor = pFcfg.apperance.color3;
                            h(2).Color = pAcfg.contour.colors{find(ismember(pAcfg.contour.names, cBound.name))};
                            oCont.pHandles.boundInfoAxis.XAxis.TickValues = [];
                            oCont.pHandles.boundInfoAxis.YAxis.TickValues = [];
                            
                            %fill text box
                            try 
                                [Kh Kp] = kstest((boundData-mean(boundData))/std(boundData));
                                [Lh Lp] = lillietest(boundData);
                            catch
                                Kh = 1;
                                Kp = 0;
                                Lh = 1;
                                Lp = 0;
                            end
                            boxString = {};
                            boxString{1} = ['Pixel Count: ' num2str(numel(boundData), '%10.0u')];
                            boxString{end+1} = ['Pixel Stdev: ' num2str(std(boundData)  , '%10.2f')];
                            boxString{end+1} = ['Pixel minT1: ' num2str(min(boundData)  , '%10.2f')];
                            boxString{end+1} = ['Pixel maxT1: ' num2str(max(boundData)  , '%10.2f')];
                            boxString{end+1} = ['Pixel medianT1: ' num2str(median(boundData), '%10.2f')];
                            boxString{end+1} = ['Pixel meanT1: ' num2str(mean(boundData), '%10.2f')];
                            %boxString{end+1} = ['Pixel 95 perc: ' num2str(mean(boundData), '%10.2f')];
                            boxString{end+1} = ['is not Normal (Lilli): ' num2str(Lp, '%10.5f')];
                            boxString{end+1} = ['is not Normal (ks): ' num2str(Kp, '%10.5f')];
                            
                            
                            
                            oCont.pHandles.boundInfoBox.String = boxString;
                            axes(oCont.pHandles.imgAxis);
                        else
                        end
                    end
                    
                case pAcfg.key.deleteContour
                case pAcfg.key.showFit
                case pAcfg.key.fitData
                case pAcfg.key.nextImage
                case pAcfg.key.previousImage
            end
            
            %-------------------------------%
            oCont.pAcfg = pAcfg;
            oCont.pHandles.imgDisplay.AlphaData = 1;
            oCont.mTableCellSelect('Caller', 'mKeyRelease');
        end
        
        function mImgAxisButtonDown(oComp, oCont, hit)
            if isempty(oCont.pActiveKey)
                newC = [oCont.pHandles.imgAxis.CurrentPoint(1,2) oCont.pHandles.imgAxis.CurrentPoint(1,1)]; newC = uint16(round(newC));
                newC = fliplr( hit.IntersectionPoint(1:2)); newC = uint16(round(newC));
                if isfield(oCont.pHandles, 'pxlInfoFig') && ishandle(oCont.pHandles.pxlInfoFig)
                else
                    oCont.pHandles.pxlInfoFig = figure('units','pixels', 'position',[140 180 240 240], 'menubar','none', 'resize','off', 'numbertitle','off', 'name','Pixel Info');
                    oCont.pHandles.pxlInfoBox = uicontrol('style','edit', 'units','pix', 'position',[10 10 220 220], 'backgroundcolor','w', 'HorizontalAlign','left', 'min',0,'max',10, 'enable','inactive');
                end
                scale = size(oComp.oImgs(1).data)./size(oComp.mGetT1Img.data);
                imgDisplay = getimage(oCont.pHandles.imgAxis);
                pxlInd = sub2ind(size(imgDisplay), newC(1), newC(2));
                pxlVal = [imgDisplay(newC(1), newC(2), :)];
                boxString = {};
                boxString{1} = ['Pixel Number: ' num2str(newC(1), '%10.0u') ', ' num2str(newC(2), '%10.0u') ' (id: ' num2str(pxlInd, '%10.0u') ')'];
                boxString{end+1} = ['Pixel Value: ' num2str(mean(pxlVal), '%5.2f')];
                % START mode specific:
                newC = [floor(newC(1)/scale(1)), floor(newC(2)/scale(1))];
                ind = sub2ind(size(oComp.mGetT1Img.data), newC(1), newC(2));
                if isempty(oComp.pPxlData)
                    % init PxlData which is done in  mFitMaskedPxls
                    oComp = oComp.mFitMaskedPxls(oCont, zeros(size(imgDisplay)));
                end
                PxlData = oComp.pPxlData;
                
                boxString{end+1} = ['R_Square: ' num2str(PxlData.rsquare(ind), '%10.2f')];
                boxString{end+1} = ['RMSE: ' num2str(PxlData.rmse(ind), '%10.2f')];
                for i=1:numel(PxlData.parameters)
                    boxString{end+1} = [PxlData.parameters{i} ': ' num2str(PxlData.values{ind}(i), '%10.2f')];
                    
                end
                if ~PxlData.fitOk(ind); boxString{end+1} = ['BAD FIT because: ' PxlData.badFitReason{ind}]; end
                % END mode specific!
                
                oCont.pHandles.pxlInfoBox.String = boxString;
                
                
            else
                switch oCont.pActiveKey{1}
                    case ''
                    otherwise
                        oCont.pLineCoord = [oCont.pHandles.imgAxis.CurrentPoint(1,2) oCont.pHandles.imgAxis.CurrentPoint(1,1)];
                        oCont.pActiveMouse = oCont.pHandles.figure.SelectionType;
                        
                        oCont.pHandles.draw = oCont.mDrawContour(oCont.pHandles.imgAxis, {{oCont.pLineCoord}}, {'green'});
                        oCont.pHandles.draw = oCont.pHandles.draw{1};
                        if isempty(oCont.pHandles.figure.WindowButtonMotionFcn) | isempty(oCont.pHandles.figure.WindowButtonMotionFcn)
                            oCont.pHandles.figure.WindowButtonMotionFcn = {@oComp.mImgAxisButtonMotion, oCont};
                            oCont.pHandles.figure.WindowButtonUpFcn = {@oComp.mImgAxisButtonUp, oCont};
                        else
                            msgbox('WindowButtonMotionFcn and WindowButtonUpFcn are already set');
                        end
                end
            end
        end
        
        function mImgAxisButtonMotion(oComp, a, b, oCont)
            newC = [oCont.pHandles.imgAxis.CurrentPoint(1,2) oCont.pHandles.imgAxis.CurrentPoint(1,1)];
            oCont.pLineCoord = [oCont.pLineCoord; newC];
            oCont.pHandles.draw.XData = oCont.pLineCoord(:,2);
            oCont.pHandles.draw.YData = oCont.pLineCoord(:,1);
            drawnow;
        end
        
        function mImgAxisButtonUp(oComp, a, b, oCont)
            oCont.pHandles.figure.WindowButtonMotionFcn = '';
            oCont.pHandles.figure.WindowButtonUpFcn = '';
            oCont = oCont.oComp.mMergeContours(oCont);
        end
        
        function oCont = mGenBoundInfoFig(oComp, oCont)
            oCont.pHandles.boundInfoFig = figure('units','pixels', 'position',[140 400 640 240], 'menubar','none', 'resize','off', 'numbertitle','off', 'name','Pixel Info');
            oCont.pHandles.boundInfoBox = uicontrol('style','edit', 'units','pix', 'position',[410 10 220 220], 'backgroundcolor','w', 'HorizontalAlign','left', 'min',0,'max',10, 'enable','inactive');
            oCont.pHandles.boundInfoAxis = axes('units','pixels','position',[10 10 380 220],'box','on');
            oCont.pHandles.boundInfoAxis.XAxis.TickValues = [];
            oCont.pHandles.boundInfoAxis.YAxis.TickValues = [];
        end
        
        % % % Segmentaion Organisation % % %
            function oCont = mImportNikitaBound(oComp, oCont)
            % import only roi data from old Nikita tool < 2016
            mb = msgbox('klick OK to load an old Nikita mat file <2016 with Bound data to be importeoCont.');
            waitfor(mb);
            [file folder] = uigetfile(fullfile(oCont.pAcfg.lastLoadPath, '*.mat'));
            load(fullfile(folder, file), 'ROIs');
            names = oCont.pAcfg.contour.names;
            [ind b] = listdlg('PromptString', 'where to insert Roi:', 'SelectionMode', 'single', 'ListString', names);
            name = names(ind);
            for i = 1:numel(ROIs(1,1,:))
                cBoundIn = oComp(i).oBoundaries.empty;
                cBoundIn(1).name = name{1};
                cBoundIn.coord = bwboundaries(ROIs(:,:,i));
                cBoundIn.coord = cBoundIn.coord{1};
                
                cBounds = oComp(i).oBoundaries;
                cBounds = setBound(cBounds, cBoundIn);
                
                oComp(i).oBoundaries = cBounds;
                
            end
            %-------------------------------%
            oCont.oComp = oComp;
            oCont.mTableCellSelect('Caller', 'mmImportNikitaBound');
        end
        
        % % % Image Management % % %
        function oImg = mGetT1Img(oComp)
            try
            if numel(oComp)>1
                msgbox('to many oComp objects in mGetT1Img method');
                return
            end
            oImg = cImageDcm;
            if isempty(oComp.pPxlData)
                oImg.data = zeros(size(oComp.oImgs(1).data));
            else
                ind = find(ismember(oComp.pPxlData.cFitObj.getCoeffNames, 'T1'));
                paramCount = numel(oComp.pPxlData.cFitObj.getCoeffNames);
                
                s = size(oComp.pPxlData.values);
                valueData = cell2mat(oComp.pPxlData.values);
                
                oImg.data = valueData(1:1:end, ind:3:end);
            end
            oImg.name = oComp.oImgs(1).name;
            oImg.imgType = 'T1Map';
            catch
                uiwait(msgbox('could not access T1Map! Switch to another image type (e.g. Raw Images).'));
            end
        end
        
        function mask = mGetFitOkMask(oComp)
            if numel(oComp)>1
                msgbox('to many oComp objects in mGetFitOkMask method');
                return
            end
            mask = logical(zeros(size(oComp.oImgs(1).data)));
            
            values = logical(cell2mat(oComp.pPxlData.fitOk));
            indizes = oComp.pPxlData.pxlNr;
            
            mask(indizes) = values;
        end
        
        function RsquareImg = mGetRsquareImg(oComp)
            if numel(oComp)>1
                msgbox('to many oComp objects in mGetRsquareImg method');
                return
            end
            RsquareImg = zeros(size(oComp.oImgs(1).data));
            
            values = oComp.pPxlData.rsquare;
            indizes = oComp.pPxlData.pxlNr;
            
            RsquareImg(indizes) = values;
        end
        
        % % % Fit Management % % %
        function ftype = mMakeStandardFtype(oComp)
            
            % set fit parameters and fcn
            fitOptions = fitoptions('Method','NonlinearLeastSquares', ...
                'Lower', [180, 1, 0 ], ...
                'Upper', [4000, Inf, 100 ], ...
                'Startpoint', [400 200 10]);
            % [T1 S0 Cn]
            
            fitFcn = ['sqrt((S0*(1-2*exp(-TI/T1)+exp(-2500/T1)))^2+Cn^2)'];
            
            ftype = fittype(fitFcn,...
                'coefficients',{'T1','S0','Cn'},'independent', 'TI',...
                'options',fitOptions);
        end
        
        function Xdata = mGetFitXdata(oComp)
            Xdata = arrayfun(@(x) x.dicomInfo(1).InversionTime, oComp.oImgs)';
        end
        
            function oComp = mFitSinglePxl(oComp, oCont)
            if numel(oComp)==1
                oCompInd = 1;
            else
                oCompInd = oCont.pTable.row;
            end
            oCompTmp = oComp(oCompInd);
            mask = Bound;
            
            oComp(oCompInd) = oCompTmp.mFitMaskedPxls(oCont, mask);
        end
        
        function oComp = mFitMeanRoi(oComp, oCont)
            if numel(oComp)==1
                oCompInd = 1;
            else
                oCompInd = oCont.pTable.row;
            end
            oCompTmp = oComp(oCompInd);
            imgStd = oCompTmp.mGetStandardImg;
            boundInd = oCompTmp.oBoundaries.getBoundInd(oCompTmp.pSelectedBound);
            oBoundTmp = oCompTmp.oBoundaries(boundInd);
            oBoundTmp.FitObj.ftype = oCompTmp.mMakeStandardFtype;
            %-------------------------------%
            [pxlNr pxlVal] = oBoundTmp.getBoundPxls(imgStd);
            
            [x, y] = ind2sub(size(imgStd.data), pxlNr);
            imgsData = arrayfun(@(x) x.data, oCompTmp.oImgs, 'un', false);
            
            oBoundTmp.FitObj.xData = oCompTmp.mGetFitXdata;
            oBoundTmp.FitObj.yData = cellfun(@(x) mean(x(pxlNr)), imgsData)';
            
            oBoundTmp.FitObj = oBoundTmp.FitObj.fitIt;
            %-------------------------------%   
            oComp(oCompInd).oBoundaries(boundInd) = oBoundTmp;
        end
        
        function oComp = mFitBoundPxls(oComp, oCont)
            if numel(oComp)==1
                oCompInd = 1;
            else
                oCompInd = oCont.pTable.row;
            end
            oCompTmp = oComp(oCompInd);
            boundInd = oCompTmp.oBoundaries.getBoundInd(oCompTmp.pSelectedBound);
            oBoundTmp = oCompTmp.oBoundaries(boundInd);
            mask = oBoundTmp.getBoundMask(oCompTmp.mGetStandardImg);
            %-------------------------------%
            %-------------------------------%
            oComp(oCompInd) = oCompTmp.mFitMaskedPxls(oCont, mask);
        end
        
        function oComp = mFitAllPxls(oComp, oCont)
            if numel(oComp)==1
                oCompInd = 1;
            else
                oCompInd = oCont.pTable.row;
            end
            oCompTmp = oComp(oCompInd);
            mask = ones(size(oCompTmp.oImgs(1).data));
            %-------------------------------%
            %-------------------------------%
            oComp(oCompInd) = oCompTmp.mFitMaskedPxls(oCont, mask);
        end
        
        function oComp = mFitAllSlices(oComp, oCont)
            for i = 1:numel(oComp)
                oComp(i) = oComp(i).mFitAllPxls(oCont);
            end
        end
        
        function oComp = mFitMaskedPxls(oComp, oCont, mask)
            if numel(oComp)==1
                oCompInd = 1;
            else
                oCompInd = oCont.pTable.row;
            end
            oCompTmp = oComp(oCompInd);
            imgSize = size(mask);
            PxlNr = find(mask);
            pxlDataTmp = oCompTmp.pPxlData;
            %-------------------------------%
%             if numel(pxlDataTmp)~=0 && numel(pxlDataTmp.pxlNr)>0
%                 b = questdlg([num2str(numel(pxlDataTmp.pxlNr)) 'pixels are already fitted!'], 'Fit Warning', 'Abord', 'Overwrite', 'Abord')
%                 switch b
%                     case 'Abord'
%                         return
%                     case 'Overwrite'
%                 end
%             end
            %% prepare fit data
            % xData:
            TI = oCompTmp.mGetFitXdata;
            
            
            % prepare images
            imgsData = arrayfun(@(x) x.data, oCompTmp.oImgs, 'un', false);
            % prepare pxlDataTmp
            pxlDataTmp(1).cFitObj = rsFitObj;
            pxlDataTmp.cFitObj.xData = double(TI);
            pxlDataTmp.cFitObj.ftype = oCompTmp.mMakeStandardFtype;
            
            %% make possibly not good pxlData structs good
            % create empty pxlData variable
            Tmp = pxlDataTmp;
            Tmp.values = repmat({[0 0 0]}, imgSize);
            Tmp.fitOk = repmat(logical(0), imgSize);
            Tmp.badFitReason = repmat({'no_fit'}, imgSize);
            Tmp.rsquare = repmat(0, imgSize);
            Tmp.rmse = repmat(0, imgSize);
            % fill empty variable with existing values
            alreadyFittedInd = find(pxlDataTmp.pxlNr~=0);
            Tmp.values(alreadyFittedInd) = pxlDataTmp.values(alreadyFittedInd);
            Tmp.fitOk(alreadyFittedInd) = pxlDataTmp.fitOk(alreadyFittedInd);
            Tmp.badFitReason(alreadyFittedInd) = pxlDataTmp.badFitReason(alreadyFittedInd);
            Tmp.rsquare(alreadyFittedInd) = pxlDataTmp.rsquare(alreadyFittedInd);
            Tmp.rmse(alreadyFittedInd) = pxlDataTmp.rmse(alreadyFittedInd);
            % now overwrite pxlDataTmp
            pxlDataTmp = Tmp;
            
            %% start fitting loop
            wb = waitbar(0, 'processing single pixel fits');
            i=0;
            for Nr = PxlNr'
                i=i+1;
                [x, y] = ind2sub(imgSize, Nr);
                waitbar(i/numel(PxlNr), wb, ['processing single pixel fits: ' num2str(i/numel(PxlNr)*100) '%']);
                wb.Name = [oCompTmp.pPatientName ' image location ' oCompTmp.pSliceLocation];
                % yData:
                yData = cellfun(@(x) x(Nr), imgsData);
                % PxlData
                pxlDataTmp.pxlNr(Nr) = Nr;
                pxlDataTmp.cFitObj.yData = double(yData');
                % fit Data
                pxlDataTmp.cFitObj = pxlDataTmp.cFitObj.fitIt;
                % is fit good?
                [fitOk reason] =  pxlDataTmp.cFitObj.checkFit;
                % store data
                pxlDataTmp.values{x, y} = pxlDataTmp.cFitObj.values;
                pxlDataTmp.fitOk(x, y) = fitOk;
                pxlDataTmp.badFitReason{x, y} = reason;
                pxlDataTmp.rsquare(x, y) = pxlDataTmp.cFitObj.gof.rsquare;
                pxlDataTmp.rmse(x, y) = pxlDataTmp.cFitObj.gof.rmse;
                
            end
            close(wb);
            pxlDataTmp.parameters = pxlDataTmp.cFitObj.parameters;
            %-------------------------------%
            oCompTmp.pPxlData = pxlDataTmp;
            oComp(oCompInd) = oCompTmp;
        end
                
        % % % Experimental % % %
        function oCont = mSaveRoiResults(oComp, oCont)
            imgDisplay = getimage(oCont.pHandles.imgAxis);
            %oCont.oComp.getStandardFileName
            [file, path] = uiputfile(fullfile(oCont.pAcfg.lastLoadPath, [oCont.mGetSaveFilePrefix '_SinglePxl_data.xls']), 'save xls file');
            if file==0
                return
            end
            count = 0;
            wb = waitbar(0, 'Saving XLS file');
            wb.Name = 'saving....';
            % go through oComps
            for i = 1:numel(oComp)
                oCompTmp = oComp(i);
                cPxlData = oCompTmp.pPxlData;
                cT1Img = oCompTmp.mGetT1Img;
                % got through Boundaries
                for j = 1:numel(oCompTmp.oBoundaries)
                    count = count+1;
                    waitbar(count/numel([oCompTmp.oBoundaries]) , wb);
                    s = struct();
                    cBound = oCompTmp.oBoundaries(j);
                    boundMask = oCompTmp.mGetBoundMask(imgDisplay, cBound.coord);
                    T1times = cT1Img.data(find(boundMask));
                    
                    try
                        [Kh Kp] = kstest((T1times-mean(T1times))/std(T1times));
                        [Lh Lp] = lillietest(T1times);
                    catch
                        Kh = 1;
                        Kp = 0;
                        Lh = 1;
                        Lp = 0;
                    end
                    
                    % create table variables
                    pxlInd = find(boundMask);
                    dicomInfo = oCompTmp.oImgs(1).dicomInfo;
                    hfit = fitdist(T1times, 'Normal');
                    s.BoundName = cBound.name;
                    s.SliceLoc = dicomInfo.SliceLocation;
                    s.Patient = oCompTmp.pPatientName;
                    s.AquDate = dicomInfo.AcquisitionDate;
                    s.PxlCount = numel(T1times);
                    try 
                        s.T1_mean_ofIntensities = cBound.FitObj.values(1); 
                    catch
                        s.T1_mean_ofIntensities = NaN;
                    end
                    s.T1_mean_ofFits = mean(T1times);
                    s.T1_median_ofFits = median(T1times);
                    s.T1_stdAbweichung = std(T1times);
                    s.T1_mean_Ci_95 = 0.95*std(T1times)/sqrt(numel(T1times));
                    s.T1_interQuartileRange = hfit.iqr;
                    s.T1_max = max(T1times);
                    s.T1_min = min(T1times);
                    s.T1_Lilli_isNormal = ~logical(Lh);
                    s.T1_Lilli_pValue = Lp;
                    s.T1_KS_isNormal = ~logical(Kh);
                    s.T1_KS_pValue = Kp;
                    
                    % write to disk
                    sheetName = ['S' num2str(i) '_' s.BoundName];
                    writetable(table(pxlInd, T1times), fullfile(path, file), 'Sheet', sheetName);
                    writetable(struct2table(s), fullfile(path, file), 'Sheet', sheetName,'Range', 'F1');
                    
                    
                end % end Boundaries
                
            end % end oComps
            close(wb);
%             imgDisplay = getimage(oCont.pHandles.imgAxis);
%             scale = size(oComp.oImgs(1).data)./size(oComp.mGetT1Img.data);
%             boundMask = oComp.mGetBoundMask(imgDisplay, cBound.coord);
%             boundMask = imresize(boundMask, 1/scale(1), 'nearest');
%             boundData = oComp.mGetT1Img.data(find(boundMask));
            
            
        end
        
        % % % Application Management % % %
        function mSaveXls(oComp, oCont)
            %% preparation
            xlsPath = fullfile(oCont.pAcfg.lastLoadPath, [oCont.mGetSaveFilePrefix '_data.xlsx']);
            [file, path] = uiputfile(xlsPath);
            if path==0
                return
            end
            xlsPath = fullfile(path,file);
            %% collect infos and store in variables
            dicomInfo = oComp(1).oImgs(1).dicomInfo;
            try info.comment = dicomInfo.StudyComments; end
            try info.description = dicomInfo.RequestedProcedureDescription; end
            try info.physicianName = dicomInfo.ReferringPhysicianName.FamilyName; end
            try info.institution = dicomInfo.InstitutionName; end
            try info.stationName = dicomInfo.StationName; end
            try info.manufacturer = dicomInfo.Manufacturer; end
            try info.manufacturerModelName = dicomInfo.ManufacturerModelName; end
            
            try info.patientName = [dicomInfo.PatientName.FamilyName '_' dicomInfo.PatientName.GivenName]; 
            catch
                try info.patientName = dicomInfo.PatientName.FamilyName;
                catch
                    info.patientName = 'NoName';
                end
            end
            try info.patientWeight = num2str(dicomInfo.PatientWeight); end
            try info.patientAge = dicomInfo.PatientAge; end
            try info.patientSex = dicomInfo.PatientSex; end
            try info.patientBirthDat = dicomInfo.PatientBirthDate; end
            try info.patientIoCont = dicomInfo.PatientID; end
            
            try info.creationDate = datestr(datenum(dicomInfo.InstanceCreationDate, 'yyyymmdd'), 'dd.mm.yyyy'); end
            
            % remove empty entries
            emptyInd = structfun(@isempty, info);
            infoFields = fieldnames(info);
            for i = 1:numel(emptyInd)
                if emptyInd(i)
                    info = rmfield(info, infoFields(i));
                end
            end
            
            
            %% create data structre for xls storage
            s = struct();
            for i = 1:numel(oComp) % i is for slice
                oCompTmp = oComp(i);
                count = 0;
                s(i).SliceNr = num2str(i,1);
                s(i).SlicePos = str2num(oCompTmp.pSliceLocation);
                for j = 1:numel(oCompTmp.oBoundaries)
                    cBound = oCompTmp.oBoundaries(j);
                    try
                    for k = 1:numel(cBound.FitObj.parameters)
                        s(i).([cBound.name '_' cBound.FitObj.parameters{k}]) = cBound.FitObj.values(k);   
                        s(i).([cBound.name '_Rsquare']) = cBound.FitObj.gof.rsquare;
                    end
                    end
                end
            end
            
            %% write to xls sheet (use all available data)
            writetable(struct2table(info), xlsPath, 'Sheet', 'infos');
            writetable(struct2table(s), xlsPath, 'Sheet', 'allData');
            
%             %% write to xls sheet (xls file like <nikita 2016)
%             Pos = 1;
%             xlswrite(xlsPath, {info.patientName} , 'Seg1', 'A1');
%             xlswrite(xlsPath, {info.creationDate} , 'Seg1', 'A2');
%             xlswrite(xlsPath, {'Slice #' 'Slice Pos (S)' 'Slice Gap' 'SegVol [cm^3]' 'Fat [%]'} , 'FAT', 'A3');
%             xlswrite(xlsPath, s.sliceNr', 'FAT', 'A4');
%             xlswrite(xlsPath, s.sliceLoc', 'FAT', 'B4');
%             xlswrite(xlsPath, [0 diff(s.sliceLoc)]', 'FAT', 'C4');
%             xlswrite(xlsPath, round(s.Seg1Vol,2)', 'FAT', 'D4');
%             xlswrite(xlsPath, round(s.FatFraction,2)', 'FAT', 'E4');
%             Pos = 3+numel(s.Seg1Vol)+1;
%             xlswrite(xlsPath, {'Slice #' 'Slice Pos (S)' 'Slice Gap' 'SegVol [cm^3]' 'Fat [%]'} , 'FAT', ['A' num2str(Pos)]);
%             Pos = Pos+2;
%             xlswrite(xlsPath, {'Summe'}, 'FAT', ['A' num2str(Pos)]);
%             xlswrite(xlsPath, round(sum(s.Seg1Vol),2), 'FAT', ['D' num2str(Pos)]);
%             xlswrite(xlsPath, round(sum(s.FatFraction),2), 'FAT', ['E' num2str(Pos)]);
            
            
        end
        
        % % % Object Management % % %
        function dataNew = mTabDat2oCompApp(oComp, dataOld, saveDate)
            dataNew = struct(oComp);
            dataNew = repmat(dataNew,1,numel(dataOld));
            % first update data to newest ISAT-tabDat version:
            tabDat = tabDatT1RelaxFitMRoi;
            tabDat = tabDat.updatetabDatT1RelaxFitMRoi(dataOld, saveDate);
            tabDat = arrayfun(@struct, tabDat);
            % convert ISAT to Dicomflex
            fields = fieldnames(dataNew);
            for i = 1:numel(fields)
                field = fields{i};
                switch field
                    case {'oBoundaries'}
                        dataNew = setStructArrayField(dataNew, field, {tabDat.Boundaries});
                    case {'pPxlData'}
                        dataNew = setStructArrayField(dataNew, field, {tabDat.PxlData});
                    case {'pSelectedBound'}
                        dataNew = setStructArrayField(dataNew, field, {tabDat.selectedBound});
                    case {'pSliceDone'}
                        dataNew = setStructArrayField(dataNew, field, {tabDat.segmentDone});
                    case {'oImgs'}
                        oImgTmp = cImageDcm;
                        for j = 1:numel(tabDat)
                            tabDat(j).imgs = oImgTmp.imgDcm2oImageDcm(tabDat(j).imgs);
                        end
                        dataNew = setStructArrayField(dataNew, field, {tabDat.imgs});
                    case {'pDataName'}
                        dataNew = setStructArrayField(dataNew, field, {tabDat.dataName});
                    case {'pHistory'}
                        dataNew = setStructArrayField(dataNew, field, {tabDat.history});
                    case {'pStandardImgType'}
                        dataNew = setStructArrayField(dataNew, field, {tabDat.standardImgType});
                    case {'pPatientName'}
                        dataNew = setStructArrayField(dataNew, field, {tabDat.patientName});
                    case {'pSliceLocation'}
                        dataNew = setStructArrayField(dataNew, field, {tabDat.sliceLocation});
                    case {'pVarious'}
                        dataNew = setStructArrayField(dataNew, field, {tabDat.Various});
                    otherwise
                end
            end
        end
        
        function oComp = mUpdate_cComputeT1Mapper(oComp, data, saveDate)
            % here each slice gets implemented in the current oComp and
            % T1Mapper structure
            for i = 1:numel(data)
                oComp(i) = cComputeT1Mapper;  % object
                oCompTmp = data(i);  % simple variable (struct)
                switch oCompTmp.pVersion_cComputeT1Mapper
                    case '1.2'
                        for f = fieldnames(oComp(i))'
                            f = f{1};
                            oComp(i).(f) = oCompTmp.(f);
                        end
                        % take care about cfgversion!!?!!?!!?!!
                        sc = superclasses(class(oComp(i)));
                        oComp(i) = oComp(i).(['mUpdate_' sc{1}]);
                    otherwise
                        msgbox('oCompute_T1Mapper version problem in oComp_T1Mapper_updateFcn!');
                end
            end
            
        end
        
        function oComp = cComputeT1Mapper(cCompArray)
            
        end
    end
end


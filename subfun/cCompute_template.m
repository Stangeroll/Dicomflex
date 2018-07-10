classdef cCompute_template<cCompute %-%-%
    properties
        %% these properties must exist
        pVersion_cCompute_template = '1.0'; %-%-%
        
        %% these properties are just for application specific use
        %-%-%
    end
    
    methods(Static)
        
    end
    
    methods
        % % % File management % % %
        function oComp = mInit_oCompApp(oComp, oImgs, oCont)
            % uses all prior loaded images as soucre to create the oComp
            % objects. Each oComp object will be represented by a row of
            % the table in the GUI
            pFcfg = oCont.pFcfg;
            pAcfg = oCont.pAcfg;
            %-------------------------------%
            % sort images and init dat struct
            i=0;
            sliceLocs = arrayfun(@(x) x.sliceLocation, oImgs, 'un', false);
            for sliceLoc = unique(sliceLocs)    % go through every slice
                i=i+1;
                indImg = find(ismember(sliceLocs, sliceLoc(1)));    
                oComp(i) = feval(str2func(pAcfg.cComputeFcn));  % create cCompute-app object here
                imgstmp = oImgs(indImg);    % those are images with the same slice location
                
                oComp(i).oImgs = imgstmp;
                oComp(i).pPatientName = oImgs(indImg(1)).patientName;
                oComp(i).pDataName = [oComp(i).pPatientName oComp(1).oImgs(1).dicomInfo.AcquisitionDate];
                oComp(i).pSliceLocation = oImgs(indImg(1)).sliceLocation;
                %-%-% fill oComp with app specific entries.
                % e.g.: oComp(i).pVarious.IgnoreSlice = false;
                
            end
            [a sortInd] = sort(cellfun(@(x) str2num(x) ,{oComp.pSliceLocation}), 'ascend');
            oComp = oComp(sortInd);
        end
        
        % % % GUI update % % %
        function imgDisplay = mGetImg2Display(oComp, oCont)
            % determies wich image will be shown on the image area.
            % imgDisplay is an object of a cImage class.
            pFcfg = oCont.pFcfg;
            pAcfg = oCont.pAcfg;
            oComp = oCont.oComp(oCont.pTable.row);
            %-------------------------------%
            %% determine image to be shown
            %-%-% This switch case is an example:
%             stdImgType = pAcfg.standardImgType;
%             switch pAcfg.imageDisplayMode
%                 case 'imgType_1'
%                     imgDisplay = oComp.mGetImgOfType('imgType_1');
%                 case 'imgType_2'
%                     imgDisplay = oComp.mGetImgOfType('imgType_2');;
%                 case stdImgType
%                     imgDisplay = oComp.mGetImgOfType(stdImgType);
%             end
            
            imgDisplay = oComp.oImgs(1);
            
            %% convert
            imgDisplay = imgDisplay.scale2([0 255]);
            
        end
                
        function mPostPlot(oComp, oCont)
            % after the imgDisplay is shown on the image area,
            % modifications may be made here (e.g. Colormapping)
            pFcfg = oCont.pFcfg;
            pAcfg = oCont.pAcfg;
            oComp = oCont.oComp(oCont.pTable.row);
            imgAxis = oCont.pHandles.imgAxis;
            %-------------------------------%
            %-%-% Do any post modification here. 
            %% For example 
            %Colormapping
            %Boundaries (here commented as an example)
%             %% plot Boundaries
%             contCoord = {};
%             colors = {};
%             for i=1:numel(oComp.oBoundaries)
%                 cBound = oComp.oBoundaries(i);
%                 contCoord{i} = {cBound.coord};
%                 colors(i) = pAcfg.contour.colors(find(ismember(pAcfg.contour.names, cBound.name)));
%             end
%             % plot contours
%             oCont.pHandles.contour = oCont.mDrawContour(imgAxis, contCoord, colors);
            %% TopLeft text in Image
%             pos = [3, 6];
%             gap = 8;
%             letterSize = 10;
%             letterStyle = 'bold';
%             imgText = [pAcfg.imageDisplayMode ' - Slice ' num2str(oCont.pTable.row)];
%             oCont.pHandles.imgText = text(pos(1),pos(2), imgText, 'Parent', imgAxis, 'Color', 'white'); pos(2) = pos(2)+gap;
%             oCont.pHandles.imgText.FontSize = letterSize;
%             oCont.pHandles.imgText.FontWeight = letterStyle;
%             oCont.pHandles.imgText.HitTest = 'off';
%             % boundary text im image
%             for i = 1:numel(oComp.oBoundaries)
%                 if ~isempty(oComp.oBoundaries(i).coord)
%                     % plot annotation
%                     txt = oComp.oBoundaries(i).name;
%                     t = text(pos(1),pos(2), txt, 'Parent', oCont.pHandles.imgAxis, 'Color', colors{i});
%                     t.FontSize = letterSize;
%                     t.FontWeight = letterStyle;
%                     pos(2) = pos(2)+gap;
%                 end
%             end
            
        end
        
        function oCont = mDrawGraph(oComp, oCont)
            % fill the graph area with contend
            pFcfg = oCont.pFcfg;
            pAcfg = oCont.pAcfg;
            oComp = oCont.oComp(oCont.pTable.row);
            graphAxis = oCont.pHandles.graphAxis;
            %-------------------------------%
            %-%-%
        end
        
        function lines = mGetTextBoxLines(oComp, oCont)
            % lines are used to fill the text area. lines must be a array of strings
            textBox = oCont.pHandles.textBox;
            pFcfg = oCont.pFcfg;
            pAcfg = oCont.pAcfg;
            oComp = oCont.oComp(oCont.pTable.row);
            %-------------------------------%
            %-%-%
            lines = string.empty;
            
        end
        
        % % % GUI Interaction % % %
        function oComp = mTableEdit(oComp, select)
            % if a table cell was edited, one can defnie here the
            % accompanied action. E.g. storing of input data in a oComp
            % property
            switch select.Source.ColumnName{select.Indices(2)}
                %-%-%
                case ''
            end
        end
        
        function oComp = mKeyPress(oComp, oCont, key)
            % executed if any key was pressed during the gui was acitve.
            % Some keys (up and down arrow) are reserved and processed by
            % the cControl only
            pAcfg = oCont.pAcfg;
            key = key.Key;
            %-------------------------------%
            oCont.pHandles.figure.WindowKeyReleaseFcn = {@oCont.mKeyRelease};
            switch key
                %-%-% 
                %% This is an example case
%                 case pAcfg.key.saveData
%                     oCont.mSaveData;

                otherwise
            end
            %-------------------------------%
            oCont.pAcfg = pAcfg;
        end
        
        function mKeyRelease(oComp, oCont, key)
            % executed if any key is released during the gui is acitve.
            pAcfg = oCont.pAcfg;
            pFcfg = oCont.pFcfg;
            key = key.Key;
            %-------------------------------%
            oCont.pHandles.figure.WindowKeyPressFcn = @oCont.mKeyPress;
            switch key
                %-%-% 
                %% This is an example case
%                 case pAcfg.key.saveData

                otherwise
            end
            
            %-------------------------------%
            oCont.pAcfg = pAcfg;
            oCont.mTableCellSelect;
        end
        
        function mImgAxisButtonDown(oComp, oCont, hit)
            % executed if the mouse is pressed on the image area.
            if isempty(oCont.pActiveKey)
                %% make pxlInfo box if no key but only mouse is pressed
                newC = [oCont.pHandles.imgAxis.CurrentPoint(1,2) oCont.pHandles.imgAxis.CurrentPoint(1,1)]; newC = uint16(round(newC));
                newC = fliplr( hit.IntersectionPoint(1:2)); newC = uint16(round(newC));
                if isfield(oCont.pHandles, 'pxlInfoFig') && ishandle(oCont.pHandles.pxlInfoFig)
                else
                    oCont.pHandles.pxlInfoFig = figure('units','pixels', 'position',[140 180 240 240], 'menubar','none', 'resize','off', 'numbertitle','off', 'name','Pixel Info');
                    oCont.pHandles.pxlInfoBox = uicontrol('style','edit', 'units','pix', 'position',[10 10 220 220], 'backgroundcolor','w', 'HorizontalAlign','left', 'min',0,'max',10, 'enable','inactive');
                end
                imgDisplay = getimage(oCont.pHandles.imgAxis);
                pxlInd = sub2ind(size(imgDisplay), newC(1), newC(2));
                boxString = {};
                boxString{1} = ['Pixel Number: ' num2str(newC(1), '%10.0u') ', ' num2str(newC(2), '%10.0u') ' (id: ' num2str(pxlInd, '%10.0u') ')'];
                boxString{end+1} = ['Pixel Value: ' num2str(imgDisplay(pxlInd), '%10.0u')];
                
                % START app specific:
                %-%-%
                boxString{end+1} = ['blabla'];
                % END app specific!
                
                oCont.pHandles.pxlInfoBox.String = boxString;
            else
                switch oCont.pActiveKey{1}
                    %-%-% what should happen if a key is pressed and the
                    %mouse button is pressed in the image area
                    case ''
                    otherwise
                        % store coordinates and active mouse button
                        oCont.pLineCoord = [oCont.pHandles.imgAxis.CurrentPoint(1,2) oCont.pHandles.imgAxis.CurrentPoint(1,1)];
                        oCont.pActiveMouse = oCont.pHandles.figure.SelectionType;
                        % plot coordinate in image
                        oCont.pHandles.draw = oCont.mDrawContour(oCont.pHandles.imgAxis, {{oCont.pLineCoord}}, {'green'});
                        oCont.pHandles.draw = oCont.pHandles.draw{1};
                        % set callbacks for mouse movement and mouse button
                        % release
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
            % callback is set in mImgAxisButtonDown for movement of the
            % mouse in the image area
            newC = [oCont.pHandles.imgAxis.CurrentPoint(1,2) oCont.pHandles.imgAxis.CurrentPoint(1,1)];
            oCont.pLineCoord = [oCont.pLineCoord; newC];
            % draw coordinates in image
            oCont.pHandles.draw.XData = oCont.pLineCoord(:,2);
            oCont.pHandles.draw.YData = oCont.pLineCoord(:,1);
            drawnow;
        end
        
        function mImgAxisButtonUp(oComp, a, b, oCont)
            % release motion callback when mouse button is released
            oCont.pHandles.figure.WindowButtonMotionFcn = '';
            oCont.pHandles.figure.WindowButtonUpFcn = '';
            oCont = oCont.oComp.mMergeContours(oCont);
        end
        
        % % % Application Management % % %
        function mSaveStuff(oComp, oCont)
            %-%-% Save e.g. XLS files or ....
        end
        
        % % % Object Management % % %
        function oComp = mUpdate_cCompute_template(oComp, data, saveDate) %-%-%
            % here each slice gets implemented in the current cCompute
            % structure. -> oComp will be an array of cCompute objects with
            % the size of data.
            for i = 1:numel(data)
                oComp(i) = cCompute_template;  %-%-% % object creation line
                oCompTmp = data(i);  % simple struct variable
                switch oCompTmp.pVersion_cCompute_template %-%-%
                    case '1.0'
                        for f = fieldnames(oComp(i))'
                            f = f{1};
                            oComp(i).(f) = oCompTmp.(f);
                        end
                        % take care about cfgversion!!?!!?!!?!!
                        sc = superclasses(class(oComp(i)));
                        oComp(i) = oComp(i).(['mUpdate_' sc{1}]);
                    otherwise
                        msgbox('oCompute_app version problem in oComp_app_updateFcn!');
                end
            end
            
        end
        
        function oComp = cCompute_template(cCompArray) %-%-%
            
        end
    end
end


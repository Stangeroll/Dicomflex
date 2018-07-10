% % % isat data mode config % % %
%% general
savePath = uigetdir('C:\Users\StangeR\Dropbox\UniKlinik\MatlabSource\DicomFlex');   % where to save the config json file

cfg = [];   % init the cfg struct later on stored in the json file
key = [];   % struct containing available keybord input keys
table = []; % struct containing table apperance, header names and their data source to fill the table
contour = [];   % non mandatory struct containing contour/boundary names, colors and their associated key´s for selection
menu = [];  % struct array with all menu button pathes and their callbacks
cfg.cfg_application_version = '0.6.0';
cfg.applicationName = 'Dummy';   % this value is used for switch case selection in this .m file!!!!!

%% mandatory app values
switch cfg.applicationName
    case '_template_'
        %% file handling
        %% data directory
        cfg.datFileSearchString = {['*' cfg.applicationName '*data*.mat'] '*T1RelaxFitMRoi_*data.mat' '*data*.mat'};    % search stings for session files stored on the HDD. First array element is the pattern the files are commonly saved. If the first cell array element does not bring search results Dicomflex uses the next element for search
        cfg.lastLoadPath = 'C:\';   % this value is written in the cfg_application_app.json when using the application
        %% image search and names:
        % for each slice location (each table row) may exist one or more images. Each image type has an entry in imgNames, imgSearchName and imgSearchDir
        cfg.imgNames = {'imgType_1' 'imgType_2'};   % this name is used for programatic organization only (application specific)
        cfg.standardImgType = 'imgType 2';  % this value must exist within the imgNames array. It points to the image used for .... certain fundamental dicomflex operations (search for standardImgType in the code....)
        cfg.imgSearchDir{1} = {'*img1folder*' '*img2folder*'};    % corresponding to each imgName a entry must exist. Used to search for possible folders hosting images to be searched with imgSearchName entries. If more than one result occures, a selection can be made by the user
        cfg.imgSearchName{1} = {'*1.dcm' '*2.dcm'}; % corresponding to each imgName a entry must exist to search for images (must be unambiguous/explicit)
        %% Gui customisation
        %% imgAxis apperance
        cfg.imgAxis.visible = 'on';
        cfg.imgAxis.height = 0.75;  % value in %/100 of total GUI size
        %% graphAxis apperance
        cfg.graphAxis.visible = 'on';
        cfg.graphAxis.height = 0.25;    % value in %/100 of total GUI size
        cfg.graphAxis.xBorderGap = [30 20]; % gap between plot axis and panel around plot
        cfg.graphAxis.yBorderGap = [30 2]; % gap between plot axis and panel around plot
        %% table apperance
        % for each element of ColumnName a corresponding associatedFieldNames entry, columnFormat, ... must exist to be called during the GUI update routine to fill the table
        table.columnName = {'Pos' 'ResultValue' 'IgnoreSlice'}; % header line names of the table
        table.associatedFieldNames = {'pSliceLocation', 'mGetResultValue', 'pVarious.IgnoreSlice'};    % cCompute properties or methods to be used to get the values filling the table
        table.columnFormat = {'numeric' 'char' 'logical'};   % datatype coming from the associatedFieldNames call
        table.columnEditable = [false false true];  % if the column is editable, the cControl calls the mTableEdit method of cCompute-app. So fill it with code :-)...
        table.columnWidth = {100 240 40};   % in pxl
        table.visible = 'on';
        table.height = 0.5; % value in %/100 of total GUI size
        %% textBox apperance
        cfg.textBox.visible = 'on';
        cfg.textBox.height = 1-table.height;    % value in %/100 of total GUI size
        %% colors
        % colors are not used for framework purposes .... ignore it if you like of use them for e.g. boundaries,.....
        cfg.color1 = [1 0 0];
        cfg.color2 = [0 0 1];
        cfg.color3 = [0 1 0];
        cfg.color4 = [0 0.45 0.74];
        cfg.color5 = [0.85 0.33 0.1];
        cfg.color6 = [0.93 0.69 0.13];
        cfg.color7 = [0.49 0.18 0.56];
        cfg.color8 = [0.47 0.67 0.19];
        cfg.color9 = [0.3 0.75 0.93];
        %% function calls
        cfg.cComputeFcn = 'cCompute-app';   % cCompute-app class: used when loading a dataset or creating a new one
        cfg.imgFcn = 'cImageDcm'; % define cImage class: used when loading the imgs
        cfg.saveDatFcn = {'oCont.oComp.mSaveStuff(oCont)'};    % used after saving the mat file for application specific saving of data
        cfg.closeRequestFcn = 'oCont.oComp.mCloseReq(oCont)'; % executed if Dicomflex is closed by X
        
    case 'Dummy'
        %% file handling
        %% data directory
        cfg.datFileSearchString = {['*' cfg.applicationName '*data*.mat'] '*data*.mat'};    % search stings for session files stored on the HDD. First array element is the pattern the files are commonly saved. If the first cell array element does not bring search results Dicomflex uses the next element for search
        cfg.lastLoadPath = 'C:\';   % this value is written in the cfg_application_app.json when using the application
        %% image search and names:
        % for each slice location (each table row) may exist one or more images. Each image type has an entry in imgNames, imgSearchName and imgSearchDir
        cfg.imgNames = {'image'};   % this name is used for programatic organization only (application specific)
        cfg.standardImgType = 'image';  % this value must exist within the imgNames array. It points to the image used for .... certain fundamental dicomflex operations (search for standardImgType in the code....)
        cfg.imgSearchDir{1} = {'DummyImgFolder'};    % corresponding to each imgName a entry must exist. Used to search for possible folders hosting images to be searched with imgSearchName entries. If more than one result occures, a selection can be made by the user
        cfg.imgSearchName{1} = {'DummyImg*.jpg'}; % corresponding to each imgName a entry must exist to search for images (must be unambiguous/explicit)
        %% Gui customisation
        %% imgAxis apperance
        cfg.imgAxis.visible = 'on';
        cfg.imgAxis.height = 0.75;  % value in %/100 of total GUI size
        %% graphAxis apperance
        cfg.graphAxis.visible = 'on';
        cfg.graphAxis.height = 0.25;    % value in %/100 of total GUI size
        cfg.graphAxis.xBorderGap = [30 20]; % gap between plot axis and panel around plot
        cfg.graphAxis.yBorderGap = [30 2]; % gap between plot axis and panel around plot
        %% table apperance
        % for each element of ColumnName a corresponding associatedFieldNames entry, columnFormat, ... must exist to be called during the GUI update routine to fill the table
        table.columnName = {'Nr'}; % header line names of the table
        table.associatedFieldNames = {'pSliceLocation'};    % cCompute properties or methods to be used to get the values filling the table
        table.columnFormat = {'numeric'};   % datatype coming from the associatedFieldNames call
        table.columnEditable = [false];  % if the column is editable, the cControl calls the mTableEdit method of cCompute-app. So fill it with code :-)...
        table.columnWidth = {100};   % in pxl
        table.visible = 'on';
        table.height = 1; % value in %/100 of total GUI size
        %% textBox apperance
        cfg.textBox.visible = 'off';
        cfg.textBox.height = 1-table.height;    % value in %/100 of total GUI size
        %% colors
        % colors are not used for framework purposes .... ignore it if you like of use them for e.g. boundaries,.....
        cfg.color1 = [1 0 0];
        cfg.color2 = [0 0 1];
        cfg.color3 = [0 1 0];
        cfg.color4 = [0 0.45 0.74];
        cfg.color5 = [0.85 0.33 0.1];
        cfg.color6 = [0.93 0.69 0.13];
        cfg.color7 = [0.49 0.18 0.56];
        cfg.color8 = [0.47 0.67 0.19];
        cfg.color9 = [0.3 0.75 0.93];
        %% function calls
        cfg.cComputeFcn = 'cComputeDummy';   % cCompute-app class: used when loading a dataset or creating a new one
        cfg.imgFcn = 'cImage'; % define cImage class: used when loading the imgs
        cfg.saveDatFcn = {'oCont.oComp.mSaveStuff(oCont)'};    % used after saving the mat file for application specific saving of data
        cfg.closeRequestFcn = 'oCont.oComp.mCloseReq(oCont)'; % executed if Dicomflex is closed by X
        
    case 'FatQuant'
        %% file handling
        %% data directory
        cfg.datFileSearchString = {['*' cfg.applicationName '*data*.mat'] '*data*.mat'};    % search stings for session files stored on the HDD. First array element is the pattern the files are commonly saved. If the first cell array element does not bring search results Dicomflex uses the next element for search
        cfg.lastLoadPath = 'C:\';   % this value is written in the cfg_application_app.json when using the application
        %% image search and names:
        % for each slice location (each table row) may exist one or more images. Each image type has an entry in imgNames, imgSearchName and imgSearchDir
        cfg.imgNames = {'Real', 'Imaginary', 'Magnitude'};   % this name is used for programatic organization only (application specific)
        cfg.standardImgType = 'Magnitude';  % this value must exist within the imgNames array. It points to the image used for .... certain fundamental dicomflex operations (search for standardImgType in the code....)
        
        cfg.imgSearchDir{1} = {'*11P*'};    % corresponding to each imgName a entry must exist. Used to search for possible folders hosting images to be searched with imgSearchName entries. If more than one result occures, a selection can be made by the user
        cfg.imgSearchDir{2} = {'*11P*'};    % corresponding to each imgName a entry must exist. Used to search for possible folders hosting images to be searched with imgSearchName entries. If more than one result occures, a selection can be made by the user
        cfg.imgSearchDir{3} = {'*11P*'};    % corresponding to each imgName a entry must exist. Used to search for possible folders hosting images to be searched with imgSearchName entries. If more than one result occures, a selection can be made by the user
        cfg.imgSearchName{1} = {'*11P_Re*.dcm'}; % corresponding to each imgName a entry must exist to search for images (must be unambiguous/explicit)
        cfg.imgSearchName{2} = {'*11P_Im*.dcm'}; % corresponding to each imgName a entry must exist to search for images (must be unambiguous/explicit)
        cfg.imgSearchName{3} = {'*11P *.dcm'}; % corresponding to each imgName a entry must exist to search for images (must be unambiguous/explicit)
        %% Gui customisation
        %% imgAxis apperance
        cfg.imgAxis.visible = 'on';
        cfg.imgAxis.height = 0.75;  % value in %/100 of total GUI size
        %% graphAxis apperance
        cfg.graphAxis.visible = 'on';
        cfg.graphAxis.height = 0.25;    % value in %/100 of total GUI size
        cfg.graphAxis.xBorderGap = [30 20]; % gap between plot axis and panel around plot
        cfg.graphAxis.yBorderGap = [30 2]; % gap between plot axis and panel around plot
        %% table apperance
        % for each element of ColumnName a corresponding associatedFieldNames entry, columnFormat, ... must exist to be called during the GUI update routine to fill the table
        table.columnName = {'Pos', 'ResultValue', 'IgnoreSlice'}; % header line names of the table
        table.associatedFieldNames = {'pSliceLocation', 'mGetResultValue', 'pVarious.IgnoreSlice'};    % cCompute properties or methods to be used to get the values filling the table
        table.columnFormat = {'numeric', 'char', 'logical'};   % datatype coming from the associatedFieldNames call
        table.columnEditable = [false, false, true];  % if the column is editable, the cControl calls the mTableEdit method of cCompute-app. So fill it with code :-)...
        table.columnWidth = {100, 240, 40};   % in pxl
        table.visible = 'on';
        table.height = 0.5; % value in %/100 of total GUI size
        %% textBox apperance
        cfg.textBox.visible = 'on';
        cfg.textBox.height = 1-table.height;    % value in %/100 of total GUI size
        %% colors
        % colors are not used for framework purposes .... ignore it if you like of use them for e.g. boundaries,.....
        cfg.color1 = [1 0 0];
        cfg.color2 = [0 0 1];
        cfg.color3 = [0 1 0];
        cfg.color4 = [0 0.45 0.74];
        cfg.color5 = [0.85 0.33 0.1];
        cfg.color6 = [0.93 0.69 0.13];
        cfg.color7 = [0.49 0.18 0.56];
        cfg.color8 = [0.47 0.67 0.19];
        cfg.color9 = [0.3 0.75 0.93];
        %% function calls
        cfg.cComputeFcn = 'cComputeFatQuant';   % cCompute-app class: used when loading a dataset or creating a new one
        cfg.imgFcn = 'cImageDcm'; % define cImage class: used when loading the imgs
        cfg.saveDatFcn = {'oCont.oComp.mSaveStuff(oCont)'};    % used after saving the mat file for application specific saving of data
        cfg.closeRequestFcn = 'oCont.oComp.mCloseReq(oCont)'; % executed if Dicomflex is closed by X
        
    case 'T1Mapper'
        %% file handling
        % data directory
        cfg.datFileSearchString = {'*T1*data.mat' ['*' cfg.applicationName '*data*.mat'] '*T1RelaxFitMRoi_*data.mat' '*data*.mat'};
        cfg.lastLoadPath = 'C:\';
        % image specification
        % image directories
        cfg.imgNames = {'Ti'};
        cfg.standardImgType = 'Ti';
        % search string from speciftic to unspecific (if first brings no results it searches the next one
        % {'*.dcm'}; {'*InPhase*Mg*.dcm', '*InPhase*.dcm'};
        cfg.imgSearchName{1} = {'*.dcm'};
        cfg.imgSearchDir{1} = {'*STIR*'};    % search string from speciftic to unspecific (if first brings no results it searches the next one
        %% Gui customisation
        %% imgAxis apperance
        cfg.imgAxis.visible = 'on';
        cfg.imgAxis.height = 0.75;
        %% graphAxis apperance
        cfg.graphAxis.visible = 'on';
        cfg.graphAxis.height = 0.25;
        cfg.graphAxis.xBorderGap = [30 20]; % gap between plot axis and panel around plot
        cfg.graphAxis.yBorderGap = [50 2]; % gap between plot axis and panel around plot
        %% table apperance
        table.columnName = {'Pos'};
        table.associatedFieldNames = {'pSliceLocation'};
        table.columnFormat = {'numeric'};
        table.columnEditable = [false];
        table.columnWidth = {100};
        table.visible = 'on';
        table.height = 0.5;
        %% textBox apperance
        cfg.textBox.visible = 'on';
        cfg.textBox.height = 1-table.height;
        %% colors
        cfg.color1 = [1 0 0];
        cfg.color2 = [0 0 1];
        cfg.color3 = [0 1 0];
        cfg.color4 = [0 0.45 0.74];
        cfg.color5 = [0.85 0.33 0.1];
        cfg.color6 = [0.93 0.69 0.13];
        cfg.color7 = [0.49 0.18 0.56];
        cfg.color8 = [0.47 0.67 0.19];
        cfg.color9 = [0.3 0.75 0.93];
        %% function calls
        cfg.cComputeFcn = 'cComputeT1Mapper';   % cComp mode class: used when loading a dataset
        cfg.imgFcn = 'cImageDcm'; % img mode class: used when loading the imgs
        cfg.saveDatFcn = {'oCont.oComp.mSaveXls(oCont)'};    % used after saving the mat file
        cfg.closeRequestFcn = 'oCont.oComp.mCloseReq(oCont)'; % executed if Dicomflex is closed by X
        
    case 'FatSegment'
        %% file handling
        % data directory
        cfg.datFileSearchString = {['*' cfg.applicationName '_data*.mat'] '*Fat_data*.mat' '*FatPig_data*.mat' '*_data*.mat'};
        cfg.lastLoadPath = 'C:\';
        % image specification
        % image directories
        cfg.imgNames = {'InPhase', 'OutPhase'};
        cfg.standardImgType = 'InPhase';
        % search string from speciftic to unspecific (if first brings no results it searches the next one
        % {'*.dcm'}; {'*InPhase*Mg*.dcm', '*InPhase*.dcm'};
        cfg.imgSearchName{1} = {'*InPhase*Mg*.dcm', '*InPhase*.dcm', '*.dcm'};
        cfg.imgSearchName{2} = {'*OutPhase*Mg*.dcm', '*OutPhase*.dcm', '*.dcm'};
        cfg.imgSearchDir{1} = {'*InPhase*'};    % search string from speciftic to unspecific (if first brings no results it searches the next one
        cfg.imgSearchDir{2} = {'*OutPhase*'};   % search string from speciftic to unspecific (if first brings no results it searches the next one
        %% Gui customisation
        %% imgAxis apperance
        cfg.imgAxis.visible = 'on';
        cfg.imgAxis.height = 0.75;
        %% graphAxis apperance
        cfg.graphAxis.visible = 'on';
        cfg.graphAxis.height = 0.25;
        cfg.graphAxis.xBorderGap = [30 15]; % gap between plot axis and panel around plot
        cfg.graphAxis.yBorderGap = [50 2]; % gap between plot axis and panel around plot
        %% table apperance
        table.columnName = {'Pos', 'UseIt', 'SAT [cm^3]', 'VAT [cm^3]', 'WK', 'LM'};
        table.associatedFieldNames = {'pSliceLocation', 'pUseSlice', 'mVolumeSAT', 'mVolumeVAT', 'pLoc1', 'pLoc2'};
        table.columnFormat = {'numeric', 'logical', 'numeric', 'numeric', {'none' 'L5S1', 'L4L5', 'L3L4', 'L2L3', 'L1L2', 'B9'},{'none' 'BB', 'FK', 'BN', 'ZF'}};
        table.columnEditable = [false, true, false, false, true, true];
        table.columnWidth = {35, 40, 75, 75, 55, 55};
        table.visible = 'on';
        table.height = 0.75;
        %% textBox apperance
        cfg.textBox.visible = 'on';
        cfg.textBox.height = 1-table.height;
        %% colors
        cfg.color1 = [1 0 0];
        cfg.color2 = [0 0 1];
        cfg.color3 = [0 1 0];
        cfg.color4 = [0 0.45 0.74];
        cfg.color5 = [0.85 0.33 0.1];
        cfg.color6 = [0.93 0.69 0.13];
        cfg.color7 = [0.49 0.18 0.56];
        cfg.color8 = [0.47 0.67 0.19];
        cfg.color9 = [0.3 0.75 0.93];
        %% function calls
        cfg.cComputeFcn = 'cComputeFatSegment';   % cComp mode class: used when loading a dataset
        cfg.imgFcn = 'cImageDcm'; % img mode class: used when loading the imgs
        cfg.saveDatFcn = {'oCont.oComp.mSaveXls(oCont)'};    % used after saving the mat file
        cfg.closeRequestFcn = 'oCont.oComp.mCloseReq(oCont)'; % executed if Dicomflex is closed by X
end

%% app specific values
menu = struct('path', {}, 'callback', ''); % empty menu
switch cfg.applicationName
    case '_template_'
        cfg.imageDisplayMode = 'Raw Images'; %
        %% external windows
        cfg.showZoomFig = 1;
        %% Key associations
        key.something = 'a';
        %% Gui Menu entries
        % image display
        menu(end+1).path = {'Image Display' 'Raw Images'};
        menu(end).callback = '@oCont.mImageDisplayMode';
        %% Fit parameters
        
        %% Contour settings
        
        %% usability configuration
    
    case 'Dummy'
        cfg.imageDisplayMode = 'images'; %
        %% external windows
        cfg.showZoomFig = 1;
        %% Key associations
        key.something = 'a';
        %% Gui Menu entries
        % image display
        menu(end+1).path = {'Image Display' 'Image Mode' 'images'};
        menu(end).callback = '@oCont.mImageDisplayMode';
        %% Fit parameters
        
        %% Contour settings
        
        %% usability configuration
     
    case 'FatQuant'
        cfg.imageDisplayMode = 'Magnitude'; %
        %% external windows
        cfg.showBoundInfo = 1;
        cfg.showPxlInfo = 1;
        cfg.showZoomFig = 1;
        %% Key associations
        key.deleteContour = 'escape';
        key.showFit = 'f';
        key.fitData = 'space';
        key.nextImage = 'add';
        key.previousImage = 'subtract';
        %% Gui Menu entries
        % image display
        menu(end+1).path = {'Image Display' 'Magnitude'};
        menu(end).callback = '@oCont.mImageDisplayMode';
        
        menu(end+1).path = {'Functions' 'Copy Boundaries'};
        menu(end).callback = '@(varargin)oCont.mMenuCallback(@(oComp)oCont.oComp.mCopyBound(oCont))';
        
        menu(end+1).path = {'Functions' 'Paste Boundaries'};
        menu(end).callback = '@(varargin)oCont.mMenuCallback(@(oComp)oCont.oComp.mPasteBound(oCont))';
        %% Fit parameters
        
        %% Contour settings
        contour.names = {'ROI_1' 'ROI_2' 'ROI_3' 'ROI_4' 'ROI_5' 'ROI_6' 'ROI_7' 'ROI_8' 'ROI_9'};
        contour.colors = {'blue' 'red' 'green' [0 0.45 0.74] [0.85 0.33 0.1] [0.93 0.69 0.13] [0.49 0.18 0.56] [0.47 0.67 0.19] [0.3 0.75 0.93]} ;
        contour.keyAssociation = {'1' '2' '3' '4' '5' '6' '7' '8' '9'};
        %% usability configuration
        
    case 'T1Mapper'
        cfg.imageDisplayMode = 'Raw Images'; %
        cfg.imageNr = 1; % the currently displayed image
        %% external windows
        cfg.showBoundInfo = 1;
        cfg.showPxlInfo = 1;
        cfg.showZoomFig = 1;
        %% Contour settings
        contour.names = {'SAT' 'VAT' 'Seg3' 'Seg4' 'Seg5' 'Seg6' 'Seg7' 'Seg8' 'Seg9'};
        contour.colors = {'blue' 'red' 'green' [0 0.45 0.74] [0.85 0.33 0.1] [0.93 0.69 0.13] [0.49 0.18 0.56] [0.47 0.67 0.19] [0.3 0.75 0.93]} ;
        contour.keyAssociation = {'1' '2' '3' '4' '5' '6' '7' '8' '9'};
        %% Key associations
        key.deleteContour = 'escape';
        key.showFit = 'f';
        key.fitData = 'space';
        key.nextImage = 'add';
        key.previousImage = 'subtract';
        %% Gui Menu entries
        % image display
        menu(end+1).path = {'Image Display' 'Raw Images'};
        menu(end).callback = '@oCont.mImageDisplayMode';
        
        menu(end+1).path = {'Image Display' 'T1 Map'};
        menu(end).callback = '@oCont.mImageDisplayMode';
        
        menu(end+1).path = {'Image Display' 'T1 Gradient'};
        menu(end).callback = '@oCont.mImageDisplayMode';
        
        % functions menu
        menu(end+1).path = {'ModeFunctions' 'Calc T1 value of Roi'};
        menu(end).callback = '@(varargin)oCont.mMenuCallback(@(oComp)oCont.oComp.mFitMeanRoi(oCont))';
        
        menu(end+1).path = {'ModeFunctions' 'Calc T1 of Roi pxls'};
        menu(end).callback = '@(varargin)oCont.mMenuCallback(@(oComp)oCont.oComp.mFitBoundPxls(oCont))';
        
        menu(end+1).path = {'ModeFunctions' 'Calc T1 Map of Slice'};
        menu(end).callback = '@(varargin)oCont.mMenuCallback(@(oComp)oCont.oComp.mFitAllPxls(oCont))';
        
        menu(end+1).path = {'ModeFunctions' 'Calc all T1 Maps'};
        menu(end).callback = '@(varargin)oCont.mMenuCallback(@(oComp)oCont.oComp.mFitAllSlices(oCont))';
        
        
        menu(end+1).path = {'Functions' 'Copy Boundaries'};
        menu(end).callback = '@(varargin)oCont.mMenuCallback(@(oComp)oCont.oComp.mCopyBound(oCont))';
        
        menu(end+1).path = {'Functions' 'Paste Boundaries'};
        menu(end).callback = '@(varargin)oCont.mMenuCallback(@(oComp)oCont.oComp.mPasteBound(oCont))';
        
        menu(end+1).path = {'ModeFunctions' 'Show Bound Info'};
        menu(end).callback = '@(varargin)oCont.mMenuCallback(@(oComp)oCont.oComp.mGenBoundInfoFig(oCont))';
        
        menu(end+1).path = {'ModeFunctions' 'Save ROI Results'};
        menu(end).callback = '@(varargin)oCont.mMenuCallback(@(oComp)oCont.oComp.mSaveRoiResults(oCont))';
        
        %         menu(end+1).path = {'ModeFunctions' 'additional Functions' 'Import Nikita Boundaries'};
        %         menu(end).callback = '@(varargin)oCont.mMenuCallback(@(oComp)oCont.oComp.mImportNikitaBound(oCont))';
        %% Fit parameters
        
        %% usability configuration
        
    case {'FatSegment'}
        cfg.segProps.name = 'RS_BodyBounds'; % 'OuterBound_RS'; 'NikitaFat160322Segmenting.m'; 'OuterBound_RS+NikitaFat';
        cfg.segProps.magThreshold = 8;  % Threshold magnitude is currently used only for RS_outerBound
        cfg.imageDisplayMode = 'Water only';
        cfg.xlsSaveRange = {'BB', 'ZF'}; % use the LandMarks specified in the Table for Ranging (or none if no ranging)
        cfg.doSliceSpacingInterpolation = 1;
        cfg.sliceSpacingInterpolationDistance = 10.5; % used to interpoate data for a systematic homogene result with similar slice distances in mm (max precision = 0.1!!!!)
        %% Contour settings
        contour.names = {'outerBound' 'innerBound' 'visceralBound'};
        contour.colors = {'yellow' 'blue' 'red'};
        contour.keyAssociation = {'1' '2' '3'};
        contour.showFemurBox = 0;
        contour.showHemiLine = 0;
        contour.contourTracking.enable = 1;
        contour.contourTracking.size = 4;
        
        %% Key associations
        key.deleteContour = 'escape';
        key.showVat = 'v';
        key.contourTracking = 'x';
        %% Gui Menu entries
        % image display
        menu(end+1).path = {'Image Display' 'Image Mode' 'In Phase only'};
        menu(end).callback = '@oCont.mImageDisplayMode';
        
        menu(end+1).path = {'Image Display' 'Image Mode' 'Out Phase only'};
        menu(end).callback = '@oCont.mImageDisplayMode';
        
        menu(end+1).path = {'Image Display' 'Image Mode' 'Fat only'};
        menu(end).callback = '@oCont.mImageDisplayMode';
        
        menu(end+1).path = {'Image Display' 'Image Mode' 'Water only'};
        menu(end).callback = '@oCont.mImageDisplayMode';
        
        %         menu(end+1).path = {'Image Display' 'Image Mode' 'All Four'};
        %         menu(end).callback = '@oCont.mImageDisplayMode';
        
        % functions menu
        menu(end+1).path = {'FatFunctions' 'Auto Segment Image'};
        menu(end).callback = '@(varargin)oCont.mMenuCallback(@(oComp)oCont.oComp.mAutoSegmentSingle(oCont))';
        
        menu(end+1).path = {'FatFunctions' 'Auto Segment All Images'};
        menu(end).callback = '@(varargin)oCont.mMenuCallback(@(oComp)oCont.oComp.mAutoSegmentAll(oCont))';
        
        menu(end+1).path = {'FatFunctions' 'Visceral Bound from Inner Bound'};
        menu(end).callback = '@(varargin)oCont.mMenuCallback(@(oComp)oCont.oComp.mVisceralFromInnerBound(oCont))';
        
        menu(end+1).path = {'FatFunctions' 'Find FatTheshold'};
        menu(end).callback = '@(varargin)oCont.mMenuCallback(@(oComp)oCont.oComp.mFindThreshLvl(oCont))';
        
        menu(end+1).path = {'Functions' 'Copy Boundaries'};
        menu(end).callback = '@(varargin)oCont.mMenuCallback(@(oComp)oCont.oComp.mCopyBound(oCont))';
        
        menu(end+1).path = {'Functions' 'Paste Boundaries'};
        menu(end).callback = '@(varargin)oCont.mMenuCallback(@(oComp)oCont.oComp.mPasteBound(oCont))';
        
        menu(end+1).path = {'Functions' 'Contour Tracking ON/OFF'};
        menu(end).callback = '@(varargin)oCont.mMenuCallback(@(oComp)oCont.oComp.mContourTrackingONOFF(oCont))';
        
        % FemurBox
        menu(end+1).path = {'Experimental' 'Femur Box' 'Show Box'};
        menu(end).callback = '@(varargin)oCont.mMenuCallback(@(oComp)oCont.oComp.mShowFemurBox(oCont))';
        
        menu(end+1).path = {'Experimental' 'Femur Box' 'Set Box'};
        menu(end).callback = '@(varargin)oCont.mMenuCallback(@(oComp)oCont.oComp.mSetFemurBox(oCont))';
        
        menu(end+1).path = {'Experimental' 'Femur Box' 'Remove Box'};
        menu(end).callback = '@(varargin)oCont.mMenuCallback(@(oComp)oCont.oComp.mDelFemurBox(oCont))';
        
        menu(end+1).path = {'Experimental' 'Femur Box' 'Save Box Results'};
        menu(end).callback = '@(varargin)oCont.mMenuCallback(@(oComp)oCont.oComp.mSaveBoxResults(oCont))';
        
        % HemiFat
        menu(end+1).path = {'Experimental' 'Hemi FAT' 'Show Line'};
        menu(end).callback = '@(varargin)oCont.mMenuCallback(@(oComp)oCont.oComp.mShowHemiLine(oCont))';
        
        menu(end+1).path = {'Experimental' 'Hemi FAT' 'Set Line'};
        menu(end).callback = '@(varargin)oCont.mMenuCallback(@(oComp)oCont.oComp.mSetHemiLine(oCont))';
        
        menu(end+1).path = {'Experimental' 'Hemi FAT' 'Remove Line'};
        menu(end).callback = '@(varargin)oCont.mMenuCallback(@(oComp)oCont.oComp.mDelHemiLine(oCont))';
        
        menu(end+1).path = {'Experimental' 'Hemi FAT' 'Save Hemi Results'};
        menu(end).callback = '@(varargin)oCont.mMenuCallback(@(oComp)oCont.oComp.mSaveHemiResults(oCont))';
        
        %% usability configuration
        cfg.tableSelAutoSegment = false;
end

%% collect in cfg struct
cfg.menu = menu;
cfg.table = table;
cfg.key = key;
cfg.contour = contour;

%% save
savejson('',cfg,fullfile(savePath, ['cfg_application_' cfg.applicationName '.json']));
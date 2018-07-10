% % % isat master mode config
%% general
savePath = uigetdir('C:\Users\StangeR\Dropbox\UniKlinik\MatlabSource\DicomFlex');   % where to save the config json file
cfg = [];   % init the cfg struct later on stored in the json file
cfg.cfg_framework_version = '0.3.0';
cfg.programName = 'Dicomflex';

cfg.datAutoSaveTime = 300;  % time in seconds after which an automatic session file with the name "tmp_cControl.mat" will be created in the data directory

%% gui customisation
% general apperance
cfg.apperance.borderWidth = 2;  % size of Gui element borders
cfg.apperance.designColor1 = [0.462 0.790 1];   % used for graph box and axis lable
cfg.apperance.backGroundColor = [0.1 0.1 0.1];
cfg.apperance.elementBorderColor = cfg.apperance.designColor1*0.5;
cfg.apperance.color2 = [0 0 0];
cfg.apperance.color3 = [.95 .95 .95];
cfg.apperance.color4 = [0 .45 .74];

% % % menu apperance
menu = struct('path', {}, 'callback', '');  % menu struct used to programatically create the menu entries and their callbacks
% File menu
menu(end+1).path = {'File' 'Load'};
menu(end).callback = '@oCont.mLoadData';

menu(end+1).path = {'File' 'Save'};
menu(end).callback = '@oCont.mSaveData';

menu(end+1).path = {'File' 'Import...'};
menu(end).callback = '@(varargin)oCont.mLoadData(''Import'', ''ISAT-DataFile'')';

menu(end+1).path = {'File' 'Clone Tool'};
menu(end).callback = '@oCont.mCloneSoftware';

% menu(end+1).path = {'Functions' 'Snapshot'};
% menu(end).callback = '@(varargin)oCont.mMenuCallback(@() print(''-clipboard'', ''-dbitmap''))';

menu(end+1).path = {'Functions' 'Undo    Ctr+Z'};
menu(end).callback = '@(varargin)oCont.mMakeUndo';

menu(end+1).path = {'Image Display' 'Image Zoom'};
menu(end).callback = '@oCont.mCreateZoomView';

menu(end+1).path = {'Info' 'Hotkeys'};
menu(end).callback = '@(varargin)oCont.mMenuCallback(@(tabDat)oCont.oComp.mShowHotkeyInfo(oCont))';

cfg.menu = menu;

%% other
% constants which are meant to stay as they are
cfg.GS1 = 25;   % GapSize of figure (e.g. the border around the figure or gap between gui objects)
cfg.GS2 = 7;    % GapSize of figure (e.g. the border around the figure or gap between gui objects)

cfg.minfH = 768;    % minimum figure height used at program start (there should also be a size definition in the app-config for each application.... to be done)
cfg.minfW = 1024;   % minimum figure height used at program start

%% Callbacks
cfg.table.cellSelectionCallback = '@oCont.mTableCellSelect';    % executed when selecting a table cell
cfg.table.cellEditCallback = '@oCont.mTableCellEdit';   % executed when chaning the value of a table cell

%% save
savejson('',cfg,fullfile(savePath, 'cfg_framework.json'));  % save the cfg struct to the savePath

% % % FitTool config
%% general
savePath = uigetdir('C:\Users\StangeR\Dropbox\UniKlinik\MatlabSource\FitTool', 'please choose the config file folder');
cfg = [];
cfg.cfgVersion = '0.0.2';
cfg.programName = 'FitTool by Roland Stange';

%% gui customisation
% general apperance
cfg.apperance.color1 = [1 1 1];
cfg.apperance.color2 = [0 0 0];
cfg.apperance.color3 = [.95 .95 .95];
cfg.apperance.color4 = [0 .45 .74];

% imgAxis apperance
cfg.imgAxis.height = 0.85;

% parameter table apperance
table.ColumnName = {'Parameter', 'Start', 'Lower', 'Upper', 'Current'};
table.ColumnFormat = {'char', 'numeric', 'numeric', 'numeric', 'numeric'};
table.ColumnEditable = [true, true, true, true, true];
table.ColumnWidth = {60, 60, 40, 40, 100};
cfg.table = table;

% % % menu apperance
menu = struct('path', {}, 'callback', '');
% File menu
menu(end+1).path = {'File' 'Load'};
menu(end).callback = '@d.loadData';

menu(end+1).path = {'File' 'Save'};
menu(end).callback = '@d.saveData';

% menu(end+1).path = {'File' 'Send Data to external App'};
% menu(end).callback = '@d.sendData';

cfg.menu = menu;

%% other

% constants which are meant to stay as they are
cfg.GS1 = 25;   % GapSize of figure (e.g. the border around the figure or gap between gui objects)
cfg.GS2 = 7;
cfg.minfH = 500;

%% save
savejson('',cfg,fullfile(savePath, 'cfg_FitTool.json'));

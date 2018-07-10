function programmPath = getProgrammPath
if isdeployed % Stand-alone mode.
    [status, result] = system('path');
    programmPath = char(regexpi(result, 'Path=(.*?);', 'tokens', 'once'));
else % MATLAB mode.
    programmPath = pwd;
end
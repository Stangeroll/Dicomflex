% sets the value of the struct field "field" to the value "val" in each
% struct of the struct array "s". 
% "val" must be a cellarray of size 1 or of size of "s"

function s = setStructArrayField(s, field, val)
%field = strsplit(field, '.');   % if field is not only a field, but a subfield like 'test.value' and not just 'value'

if numel(val) == numel(s)
    for i = 1:numel(s)
        eval(['s(i).' field ' = val{i};']);
        %s(i).(field) = val{i};
    end
elseif numel(val) == 1
    for i = 1:numel(s)
        eval(['s(i).' field ' = val{1};']);
        %s(i).(field) = val{1};
    end
elseif numel(val) == 0
    for i = 1:numel(s)
        eval(['s(i).' field ' = val;']);
        %s(i).(field) = val{1};
    end
else
    disp('val has wrong size');
end
end
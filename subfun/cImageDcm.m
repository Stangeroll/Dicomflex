classdef cImageDcm < cImage
    properties
        dicomInfo = struct([]);
        pVersion_cImageDcm = '1';
    end
    
    methods
        function imgs = readDicom(imgs)
            for i = 1:numel(imgs)
                imgs(i).dicomInfo = dicominfo(imgs(i).path);
                imgs(i).data = dicomread(imgs(i).path);
                imgs(i).imgType = imgs(i).imgType;
                imgs(i).name = imgs(i).name;
                imgs(i).date = imgs(i).date;
                imgs(i).datenum = imgs(i).datenum;
                imgs(i).path = imgs(i).path;
            end

        end
        
        function imgs = rescaleDicom(imgs)
            for j = 1:numel(imgs)
                imgs(j).data = double(imgs(j).data).*imgs(j).dicomInfo.RescaleSlope + imgs(j).dicomInfo.RescaleIntercept;
            end
        end
                
        function voxVol = getVoxelVolume(imgs)
            imgInfo = {imgs.dicomInfo};
            for i = 1:numel(imgInfo)
                voxVol(i) = 0.001*imgInfo{i}.SpacingBetweenSlices*imgInfo{i}.PixelSpacing(1)*imgInfo{i}.PixelSpacing(2); % voxel volume in cm^3
                
            end
        end
        
        function patientName = patientName(img)
            dcmInfo = img.dicomInfo;
                if isfield(dcmInfo.PatientName, 'FamilyName') && isfield(dcmInfo.PatientName, 'GivenName')
                    patientName = [dcmInfo.PatientName.FamilyName '_' dcmInfo.PatientName.GivenName];
                elseif isfield(dcmInfo.PatientName, 'FamilyName') && ~isfield(dcmInfo.PatientName, 'GivenName')
                    patientName = [dcmInfo.PatientName.FamilyName];
                elseif ~isfield(dcmInfo.PatientName, 'FamilyName') && isfield(dcmInfo.PatientName, 'GivenName')
                    patientName = [dcmInfo.PatientName.GivenName];
                elseif ~isfield(dcmInfo.PatientName, 'FamilyName') && ~isfield(dcmInfo.PatientName, 'GivenName')
                    patientName = [];
                end
                if isempty(patientName)
                    hdialog = msgbox({'There exits no patient name!' 'Please fill out the following form after pressing OK' 'In case of problems contact the developer.'});
                    uiwait(hdialog);
                    Names = inputdlg({'Family Name:', 'Given Name:'}, 'Enter patient name')
                    patientName = [Names{1} '_' Names{2}];
                end
        end
        
        function sliceLocation = sliceLocation(img)
            sliceLocation = sprintf('%.1f', img.dicomInfo.SliceLocation);
        end
        
        function sliceThickness = sliceThickness(img)
            sliceThickness = sprintf('%.1f', img.dicomInfo.SliceThickness);
        end
        
        function slicePosition = slicePosition(img)
            slicePosition = sprintf('%.1f', img.dicomInfo.ImagePositionPatient(3));
        end        
        
        function img = imgDcm2oImageDcm(oImg, img)
            dataOld = arrayfun(@struct, img);
            dataNew = repmat(oImg,1,numel(dataOld));
            
            fields = fieldnames(oImg);
            for i = 1:numel(fields)
                field = fields{i};
                switch field
                    case {'dicomInfo'}
                        dataNew = setStructArrayField(dataNew, field, {dataOld.dicomInfo});
                    case {'name'}
                        dataNew = setStructArrayField(dataNew, field, {dataOld.name});
                    case {'date'}
                        dataNew = setStructArrayField(dataNew, field, {dataOld.date});
                    case {'datenum'}
                        dataNew = setStructArrayField(dataNew, field, {dataOld.datenum});
                    case {'path'}
                        dataNew = setStructArrayField(dataNew, field, {dataOld.path});
                    case {'nr'}
                        dataNew = setStructArrayField(dataNew, field, {dataOld.nr});
                    case {'imgType'}
                        dataNew = setStructArrayField(dataNew, field, {dataOld.imgType});
                    case {'data'}
                        dataNew = setStructArrayField(dataNew, field, {dataOld.data});
                    otherwise
                end
            end
            img = dataNew;
        end
        
        function img = cImageDcm(path, imgPathes, imgName)
            if nargin ~= 0
                for j = 1:numel(imgPathes)
                    if iscell(path)
                        file = fullfile(path{j}, imgPathes(j).name);
                    else
                        file = fullfile(path, imgPathes(j).name);
                    end
                    a = dir(file);
                    try a = rmfield(a, 'bytes'); end
                    try a = rmfield(a, 'isdir'); end
                    try a = rmfield(a, 'folder'); end
                    
                    img(j) = cImageDcm;
                    for fn = fieldnames(a)'
                        img(j).(fn{1}) = a.(fn{1});
                    end
                    img(j).imgType = imgName;
                    img(j).path = file;
                end
            end
        end
        
    end
end
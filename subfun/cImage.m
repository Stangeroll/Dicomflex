classdef cImage
    properties
        name = '';
        date = '';
        datenum = '';
        path = '';
        nr = '';
        imgType = '';
        data = [];
        pVersion_cImage = '1';
    end
    
    methods
        function imgs = readData(imgs)
            for i = 1:numel(imgs)
                if isa(imgs(i), 'cImageDcm')
                    imgs(i) = imgs(i).readDicom;
                else
                imgs(i).data = imread(imgs(i).path);
                imgs(i).imgType = imgs(i).imgType;
                imgs(i).name = imgs(i).name;
                imgs(i).date = imgs(i).date;
                imgs(i).datenum = imgs(i).datenum;
                imgs(i).path = imgs(i).path;    
                end
            end

        end
        
        function RGBimg = conv2RGB(img);
            % scale max is the maximum value the resulting image will have
            data = cat(3, img.data, img.data, img.data);
            RGBimg = img;
            RGBimg.data = data;
        end

        function imgData = dataResize(img, scale)
            imgData = imresize(img.data, scale, 'nearest');
        end
        
        function img = scale2(img, scaleMinMax)
            % scales a BW or RGB cImage.data to the Range specified by scale, a two element array.
            Min = scaleMinMax(1);
            Max = scaleMinMax(2);
            im = double(img.data);
            switch numel(size(im))
                case 2
                    im = im+(Min-min(min(im)));
                    range = max(max(im)) - min(min(im));
                    im = im./range.*Max;
                case 3
                    im = im+(Min-min(min(min(im))));
                    range = max(max(max(im))) - min(min(min(im)));
                    im = im./range.*Max;
                otherwise
                    msgbox('image has wrong dimensionality');
                    return
            end
            img.data = cast(im, 'like', img.data);
        end
        
        function d = update_cControlVersionInfo(img, d)
            sc = superclasses(class(img));
            sc = [{class(img)}; sc];
            for i = 1:numel(sc)
                d.mSetVersionInfo(sc{i}, img.(['pVersion_' sc{i}]), ['mUpdate_' sc{i}]);
                %                     removed at 20170228
                %                     d.setVersionInfo('img', tabDat(1).imgs(1).img_version, ['update' sc{1}]);
                %                     d.setVersionInfo(tabDat(1).imgs(1).imgChild1_name, tabDat(1).imgs(1).imgChild1_version, ['update' class(tabDat(1).imgs(1))]);
            end
        end
        
        function img = cImage(path, imgPathes, imgName)
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
                    
                    img(j) = cImage;
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

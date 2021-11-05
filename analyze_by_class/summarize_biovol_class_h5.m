function [classcount, classbiovol, classC, classcount_above_optthresh, classbiovol_above_optthresh, classC_above_optthresh, classcount_above_adhocthresh, classbiovol_above_adhocthresh, classC_above_adhocthresh, class_labels, classFeaList, classPidList] = summarize_biovol_class_h5(classfile, feafile, adhocthresh)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
persistent ind_diatom class2use
%micron_factor = 1/3.4; %microns per pixel
micron_factor = 1/2.77; %microns per pixel

%load(classfile)
%[bin_id, scores, roi_numbers, class_labels] = load_class_scores(classfile);
classTable = load_class_scores(classfile);
class_labels = classTable.class_labels;
if isempty(class2use)
    class2use = class_labels;
end
if ~isequal(class_labels,class2use)
    disp('class2use different between calls to this function')
    keyboard
end
classcount = NaN(length(class_labels),1);
classcount_above_optthresh = classcount;
classcount_above_adhocthresh = classcount;
classbiovol = classcount;
classbiovol_above_optthresh = classcount;
classbiovol_above_adhocthresh = classcount;
classC = classcount;
classC_above_optthresh = classcount;
classC_above_adhocthresh = classcount;
feastruct = importdata(feafile);
%ind = strmatch('Biovolume', feastruct.colheaders);
ind = strmatch('summedBiovolume', feastruct.textdata);
targets.Biovolume = feastruct.data(:,ind)*micron_factor.^3;
%targets.esd = (targets.Biovolume*3/4/pi).^(1/3)*2; 
targets.esd = biovol2esd(targets.Biovolume);
ind = strmatch('maxFeretDiameter', feastruct.textdata);
targets.maxFeretDiameter = feastruct.data(:,ind)*micron_factor;
ind = strmatch('summedMajorAxisLength', feastruct.textdata);
targets.summedMajorAxisLength = feastruct.data(:,ind)*micron_factor;
ind = strmatch('numBlobs', feastruct.textdata);
targets.numBlobs = feastruct.data(:,ind);
targets.pid = cellstr(strcat(classTable.metadata.bin_id, '_', num2str(classTable.roi_numbers, '%05.0f')));
%%
adcfile = regexprep(feafile, '_fea_v4.csv', '.adc');
adcfile = regexprep(adcfile, 'IFCB_products', 'IFCB_data');
adcfile = regexprep(adcfile, 'IFCB_products', 'IFCB_data');
adcfile = regexprep(adcfile, 'features\\D', 'data\');

%temp fudge for old MVCO products
mvco_flag = 0;
if strfind(feafile, 'MVCO')
    mvco_flag = 1;
    [p,f] = fileparts(feafile);
    f = regexprep(f, '_fea_v2', '');
    if strmatch(f(1),'I')
        adcfile = strcat('\\sosiknas1\IFCB_data\MVCO\data\',f(7:10), filesep, f(1:14),filesep, f, '.adc');
    else
        adcfile = strcat('\\sosiknas1\IFCB_data\MVCO\data\',f(2:5), filesep, f(1:9),filesep, f, '.adc')
    end
end

%add opts to address adc files with only 1 row of data
opts = delimitedTextImportOptions("NumVariables", 24);
opts.VariableTypes = repmat("double", 1,24); %["double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double"];
adc = readtable(adcfile, opts);
%adc = readtable(adcfile, 'FileType', 'text');
targets.adc = adc{classTable.roi_numbers, 3:11};

%% get the Predicted_class labels with application of adhocthresh
if length(adhocthresh) == 1
    t = ones(size(classTable.scores))*adhocthresh;
else
    t = repmat(adhocthresh,length(Predicted_class),1);
end
win = (classTable.scores > t);
[i,j] = find(win);
%if ~exist('TBclass', 'var')
    %[~,TBclass] = max(scores');
    [targets.maxscore, Predicted_class] = max(classTable.scores');
    Predicted_class = class_labels(Predicted_class)';
%end
Predicted_class_above_adhocthresh = cell(size(Predicted_class));
Predicted_class_above_adhocthresh = cell(size(Predicted_class));
Predicted_class_above_adhocthresh(:) = deal(repmat({'unclassified'},1,length(Predicted_class)));
Predicted_class_above_adhocthresh(i) = class_labels(j); %most are correct his way (zero or one case above threshold)
ind = find(sum(win')>1); %now go back and fix the conflicts with more than one above threshold
for count = 1:length(ind)
    [~,ii] = max(scores(ind(count),:));
    Predicted_class_above_adhocthresh(ind(count)) = class_labels(ii);
end
%%

%[ind_diatom] = get_diatom_ind(class_labels,class_labels);
if isempty(ind_diatom) %first call to function
    gfile = '\\sosiknas1\training_sets\IFCB\config\IFCB_classlist_type.csv';
    disp('Loading list of diatom classes from:')
    disp(gfile)
    group_table = readtable(gfile);
    [~,ia,ib] = intersect(group_table.CNN_classlist, class2use);
    ind_diatom = ib(find(group_table.Diatom(ia)));
end
diatom_flag = zeros(size(class_labels));
diatom_flag(ind_diatom) = 1;
cellC_diatom = biovol2carbon(targets.Biovolume,1);
cellC_notdiatom = biovol2carbon(targets.Biovolume,0);
for ii = 1:length(class_labels)
    if diatom_flag(ii)
        cellC = cellC_diatom;
    else
        cellC = cellC_notdiatom;
    end
    ind = strmatch(class_labels(ii), Predicted_class,'exact');
    classcount(ii) = size(ind,1);
    classbiovol(ii) = sum(targets.Biovolume(ind));
    classC(ii) = sum(cellC(ind));
    if ~isempty(ind)
        if mvco_flag %temp fudge for old mvco features
            classFeaList{ii} = [targets.esd(ind) targets.summedMajorAxisLength(ind) targets.Biovolume(ind) cellC(ind) targets.numBlobs(ind) targets.adc(ind,:) targets.maxscore(ind)'];
        else
            classFeaList{ii} = [targets.esd(ind) targets.maxFeretDiameter(ind) targets.summedMajorAxisLength(ind) targets.Biovolume(ind) cellC(ind) targets.numBlobs(ind) targets.adc(ind,:) targets.maxscore(ind)'];
        end
    else
        classFeaList{ii} = single.empty(0,size(targets.adc,2)+7);
    end
    classPidList{ii} = targets.pid(ind);

    if exist('Predicted_class_above_threshold', 'var')
        ind = strmatch(class_labels(ii), Predicted_class_above_threshold, 'exact');
        classcount_above_optthresh(ii) = size(ind,1);
        classbiovol_above_optthresh(ii) = sum(targets.Biovolume(ind));
        classC_above_optthresh(ii) = sum(cellC(ind));
    else 
        Predicted_class_above_threshold = NaN;
    end
    ind = strmatch(class_labels(ii), Predicted_class_above_adhocthresh, 'exact');
    classcount_above_adhocthresh(ii) = size(ind,1);
    classbiovol_above_adhocthresh(ii) = sum(targets.Biovolume(ind));
    classC_above_adhocthresh(ii) = sum(cellC(ind));
end
end


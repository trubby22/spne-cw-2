function BlindData_PCV
%
% A script to blind the PCV dataset.
%
%
%
% Author: Felipe Orihuela-Espina
%

%% Log
%
% 2-Dec-2022: FOE
%   + File created from an axisting script (BlindVMData.m for Storing
%   and Managing Data 2022)
%
%

%% Preliminaries
srcDir = ['..' filesep 'data' filesep 'BonusTask' filesep];
destDir = ['..' filesep 'data' filesep 'BonusTask_Blinded' filesep];
if ~exist(destDir, 'dir')
    mkdir(destDir);
end


srcFiles = dir([srcDir '*.csv']);
nFiles = length(srcFiles);
for iFile = 1:nFiles
    
    inFile = srcFiles(iFile);

    %Ignore Total Hb files
    if ~isempty(strfind(inFile.name,'_Total.'))
        continue;
    else
        disp(['Processing file ' inFile.name]);
    end
    
    
    %Read the source file
    [~,~,data] = xlsread([inFile.folder filesep inFile.name]);
    
    nanIdx = find(cell2mat(cellfun(@(x)any(isnan(x)),data,'UniformOutput',false)));
    data(nanIdx) = {[]}; %Replacing the NaN entries with []
    
    %Blind subject name
    subjID = inFile.name(3:6);
    data(5,2) = {['Subj' subjID]};
    
    
    
    writecell(data,[destDir filesep inFile.name],...
            'FileType','text', ...
            'WriteMode','overwrite', ...
            'Delimiter',',');
    
end





end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Auxiliary functions


function seriesSPNDataChallenge0001(optDB)
%A starting script to process the PCV data for the Sensing, Perception and Neuroergonomics (SPN) data challenge
%
%
% Experiment: PCV - Prefrontal Contruct Validity
%   Main researcher: Dan Leff.
%
%   Data: PCV fNIRS data from the HITACHI ETG-4000 machine.
%
%   This dataset was used in MICCAI 2007, but this script has been
%generated many years later.
%
% In this series, @sessions are associated to expertise; e.g.
%   + Consultants
%   + Registrars
%   + Novices
%
% This script generates an ICNA experiment file from the PCV experiment data
%files. In the second part of the script, an activity matrix is generated.
%
%
%   +==================================================+
%   | This series produces a new ICNNA experiment file |
%   |and an activity matrix figure as output.          |
%   +==================================================+
%
%
%% Parameter
%
% options - An struct of options
%   .destinationFolder - Destination folder. Default value is
%       './results/'
%   .save - True if you want your figures to be saved. False (default)
%       otherwise. Figures are saved in MATLAB .fig format and in
%       .tif format non-compressed at 300dpi.      
%
%
%
% Copyright 2007-24
% @author: Felipe Orihuela-Espina
%
% See also 
%

%% Log
%
% 5-Dec-2021: FOE
%   File created (from a preexisting script).
%
% 2-Dec-2022: FOE
%   Adaptations to 2022 data challenge.
%
% 3-Dec-2023: FOE
%   Adaptations to 2023 data challenge.
%
% 28-Nov-2024: FOE
%   Adaptations to 2023 data challenge.
%

baseDir = ['..' filesep];
	%Create the folder BEFORE running this script. This script does
	%not create the folders on the fly.

%This is your source directory. All your raw files are expected to be in this folder.
srcDir = [baseDir 'data' filesep 'BonusTask' filesep];


%% Deal with options
opt.save=true;
opt.destinationFolder=[baseDir 'results' filesep];
if exist('optDB','var')
    if isfield(optDB,'destinationFolder')
        opt.destinationFolder=optDB.destinationFolder;
    end
    if isfield(optDB,'save')
        opt.save=optDB.save;
    end
end

subseries=''; %Original run. Suggestion: Change this as you test different
			  %things. You can also use it as a rudimentary version track
			  %as well as for allowing different behaviours of the script
			  %base on the subseries.

%Setup ICNNA path if not done
%ICNNApath = [baseDir filesep 'code' filesep 'ICNNA' filesep];
ICNNApath = ['D:' filesep 'FOE' filesep 'OneDrive' filesep 'Git' filesep 'ICNNA' filesep 'src' filesep];
if ~exist('icnna.m','file')
    tmp = pwd;
    addpath(ICNNApath);
    cd(ICNNApath)
    icnna_startup;
    cd(tmp)
end





%% Part 1: Generation of the experiment file
files=dir([srcDir '*_MES_Probe*.csv']); %Get the list of data files.
nFiles=length(files);


%Create the experiment object
E = experiment();
E.name = 'PCV';
E.description = 'Prefrontal Construct Validity';

%Add the dataSourceDefinitions
dsdeff=dataSourceDefinition(1,'nirs_neuroimage',1);
E=addDataSourceDefinition(E,dsdeff);

%Add the sessionDefinitions
sdeff=sessionDefinition(1,'Consultant');
sdeff=addSource(sdeff,dsdeff);
E=addSessionDefinition(E,sdeff);

sdeff=sessionDefinition(2,'Registrar');
sdeff=addSource(sdeff,dsdeff);
E=addSessionDefinition(E,sdeff);

sdeff=sessionDefinition(3,'Novice');
sdeff=addSource(sdeff,dsdeff);
E=addSessionDefinition(E,sdeff);

%% Loop 1: Import data
addedSubjectsList=[];
for ii=1:nFiles
    disp(['Processing file ' files(ii).name])
    
    [subjID,sessID,pn,hand]=parcelFilename(files(ii).name);
    %Re-set subject id according to expertise to avoid clash
    subjID = 100*sessID + subjID;
    disp(['   Subject ID: ' num2str(subjID)]);
    disp(['   Session ID: ' num2str(sessID)]);
    disp(['   Probe number: ' num2str(pn)]);
    disp(['   Hand: ' hand]);
    
    %Ignore left hand (LH) measurements
    if strcmp(hand,'LH')
        continue
    end
    
    switch (sessID)
        case 1
            sessName = 'Consultant';
        case 2
            sessName = 'Registrar';
        case 3
            sessName = 'Novice';
        otherwise
            error('Unexpected session ID.');
    end
     
    
    %Get or add the subject to the experiment
    if ismember(subjID,addedSubjectsList)
        subj=getSubject(E,subjID);
        sess=getSession(subj,sessID);
        ds=getDataSource(sess,1);
        r=getRawData(ds);
    else
        subjName=[sessName num2str(subjID,'%04d')];
        
        subj=subject(subjID,subjName);
        E=addSubject(E,subj);
        addedSubjectsList=[addedSubjectsList, subjID];
        
        %Create the new session
        disp(['   Session ID: ' num2str(sessID)]);
        disp(['   Session Name: ' sessName]);
        sdeff=sessionDefinition(sessID,sessName);
        sdeff=addSource(sdeff,dsdeff);
        sess=session(sdeff);
        ds=dataSource(1);
        r=rawData_ETG4000();
        
        %Add the session to the subject
        ds=setRawData(ds,r);
        sess=addDataSource(sess,ds);
        subj=addSession(subj,sess);
    end
    
    %Read the file
    r=r.import([srcDir files(ii).name]);
    
    
    %Add the session to the subject
    ds=setRawData(ds,r);
        %Include the raw data, for convert/process/integrity later on
    %ds=addStructuredData(ds,1,sd);
    sess=setDataSource(sess,1,ds);
    subj=setSession(subj,sessID,sess);
    
    %And replace the subject in the experiment
    E=setSubject(E,subjID,subj);
    
end



%% Loop 2: Convert and process
subjects = getSubjectList(E);
for subjID=subjects
    subj=getSubject(E,subjID);
    sessions=getSessionList(subj);
    for sessID=sessions
        sess=getSession(subj,sessID);
        ds=getDataSource(sess,1);
        r=getRawData(ds);

        %Convert and process (decimate and detrend) to a structuredData
        sd=convert(r);
        sd=decimate(sd);
        sd=detrend(sd);
			%ICNNA is very limited in its processing capabilities as that is 
			%not is main purpose, so it does not give you much more support 
			%beyond this. If you want to improve this, you may:
			%Opt 1) Use other software
			%Opt 2) Create your own processing scripts.
        
        %Add the session to the subject
        ds=addStructuredData(ds,sd);
        sess=setDataSource(sess,1,ds);
        subj=setSession(subj,sessID,sess);
    
    end
    
    %And replace the subject in the experiment
    E=setSubject(E,subjID,subj);
    
end
if opt.save
    disp('Now saving')
    save([opt.destinationFolder 'icnna_PCV.mat'],'E');
end


%% Deal with data collection errors
%Add here any code that has to deal with specific particularities in the dataset.

% if opt.save
%     disp('Now saving')
%     save([opt.destinationFolder 'icnna_PCV.mat'],'E');
% end




%% Integrity check
disp('Running integrity check')
%Collect all the options
optIntegrity.nirs_neuroimage.Complex=1;
optIntegrity.nirs_neuroimage.ApparentNonRecording=1;
optIntegrity.nirs_neuroimage.Mirroring=1;
optIntegrity.nirs_neuroimage.OptodeMovement=1;
optIntegrity.nirs_neuroimage.testAllChannels=1;
optIntegrity.testInRawWhenPossible=1;
E=runIntegrity(E,optIntegrity);
disp('Done!')

if opt.save
    disp('Now saving')
    save([opt.destinationFolder 'icnna_PCV.mat'],'E');
end



%% Part 2a: Generation of the activity matrix
%
% Initial parameterization matches that of MICCAI 2007 but
%feel free to explore others.
%
warning('off') %Avoid the warning for deprecated use of probeMode
load([opt.destinationFolder 'icnna_PCV.mat'],'E');
warning('on')

s = experimentSpace;

%== Block splitting
s.baselineSamples = 20;
s.restSamples = -1;

%== Temporal window selection
baseline=20;
duration = 57;
s.ws_onset = -baseline;
s.ws_duration = baseline + duration;
s.ws_breakDelay = 5;
            
%== Resampling
s.resampled = true;
s.rs_baseline = 20;
s.rs_task = 37; 
s.rs_rest = 20;

%== Averaging
s.averaged = true;

%== Normalization
s.normalized = false;
%s.normalizationScope = 'blockIndividual';
%s.normalizationScope = 'Individual';
%s.normalizationScope = 'Collective';

%s.normalizationDimension = 'Channel';
%s.normalizationDimension = 'Signal';
%s.normalizationDimension = 'Combined';

%s.normalizationMethod = 'Normal';
%s.normalizationMethod = 'Range';

%s.normalizationMean = 0;
%s.normalizationVar = 1;
%s.normalizationMin = 0;
%s.normalizationMax = 1;



s=compute(s,E);
optDB.outputFilename = [opt.destinationFolder 'SPNDataChallenge0001' subseries '.csv'];
optDB.helpFilename = [opt.destinationFolder 'SPNDataChallenge0001' subseries '_help.txt'];
[db]=generateDB_withBreak(s,optDB);

[db]=load([opt.destinationFolder 'SPNDataChallenge0001' subseries '.csv']);
dbCons=getDBConstants;

groups(1).name='All';
groups(1).subjects=getSubjectList(E);

nGroups=length(groups);
for gg=1:nGroups
    idx=find(ismember(db(:,dbCons.COL_SUBJECT),groups(gg).subjects));
    if ~isempty(idx)
        tmpDB = db(idx,:);
        
        optAM.destinationFolder = opt.destinationFolder;
        optAM.save=true;
        optAM.sessionLabels={'Consultant','Registrar','Novice'};
        %optAM.stimulusLabels={'KnotTying'};
        optAM.outputFilename = ['SPNDataChallenge0001' subseries '_' groups(gg).name ...
            '_ActivityMatrixFiltered_Combined_SignRank'];
        optAM.type='combined';
        [M,P,S,Im,hFig]=getActivityMatrix(tmpDB,optAM);
        xlswrite([opt.destinationFolder optAM.outputFilename '.xls'],M,'ActivityMatrix');
        xlswrite([opt.destinationFolder optAM.outputFilename '.xls'],P(:,:,1),'Oxy - p values');
        xlswrite([opt.destinationFolder optAM.outputFilename '.xls'],P(:,:,2),'Deoxy - p values');
        xlswrite([opt.destinationFolder optAM.outputFilename '.xls'],S(:,:,1),'Oxy - sign');
        xlswrite([opt.destinationFolder optAM.outputFilename '.xls'],S(:,:,2),'Deoxy - sign');
        
        optAM.outputFilename = ['SPNDataChallenge0001' subseries '_' groups(gg).name ...
            '_ActivityMatrixFiltered_Oxy_SignRank'];
        optAM.type='oxy';
        [M,P,S,Im,hFig]=getActivityMatrix(tmpDB,optAM);
        
        optAM.outputFilename = ['SPNDataChallenge0001' subseries '_' groups(gg).name ...
            '_ActivityMatrixFiltered_Deoxy_SignRank'];
        optAM.type='deoxy';
        [M,P,S,Im,hFig]=getActivityMatrix(tmpDB,optAM);
    end
end



end

%% AUXILIAR FUNCTIONS
function [subjID,sessID,probeNumber,hand]=parcelFilename(filename)
%Parcels the filename to extract the subject ID, the longitudinal
%session ID and the probe number
idx=find(filename=='_');
subjID=str2double(filename(2:idx(1)-1));
switch(filename(1))
    case 'C'
        sessID=1;
    case 'R'
        sessID=2;
    case 'N'
        sessID=3;
    otherwise
        error('Unexpected expertise group.')
end
idx2=find(filename=='.');
probeNumber=str2double(filename(idx(end)+6:idx2(end)-1));

hand = 'RH';
if ~isempty(strfind(filename,'_LH_')) 
    hand = 'LH';
end
end

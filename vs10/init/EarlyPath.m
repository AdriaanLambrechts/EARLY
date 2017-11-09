function EarlyPath(VD, varargin);
% EarlyPath - set path of EARLY toolbox
%    EarlyPath('vsdir') sets the path of the EARLY toolbox using the specified
%    versiondir. This call is issued at startup time. The directories
%    listed in stimdefPath are inserted into the path; their position in
%    the path is before the directories of the Matlab installation, but
%    after the Early-specific directories.
%
%    Earlypath('insert', 'dir1', 'dir2', ...) inserts the specified
%    directories into the  Matlab path. Their position in the path is 
%    before the directories of the Matlab installation, but after the 
%    Early-specific directories. In this way, any functions in the newly 
%    added directories may shadow standard Matlab functions, but never any 
%    Early functions.
%
%    EarlyPath() uses the function versiondir to add stuff to the path.
%    This can be used after adding a new dir to the path in the code of
%    Earlypath, though it is safer to quit Matlab and restart Early.
%
%    See also versiondir, stimdefPath.

if nargin<1, 
    VD = versiondir; % this won't work at startup, but can be used for updating the path
elseif isequal('insert', lower(VD)),
    local_insert(varargin{:});
    return;
end
addpath(fullfile(VD, 'init'));

addpath(fullfile(VD, 'utils')); % contains no mfiles, but does contain @XX dirs
addpath(fullfile(VD, 'utils', 'graph'));
addpath(fullfile(VD, 'utils', 'strings_and_IO'));
addpath(fullfile(VD, 'utils', 'conversion'));
addpath(fullfile(VD, 'utils', 'GUIutils'));
addpath(fullfile(VD, 'utils', 'misc'));
addpath(fullfile(VD, 'utils', 'tools'));
addpath(fullfile(VD, 'utils', 'physics'));
% addpath(fullfile(VD, 'utils', 'pics'));
% structtools (temp)
addpath(fullfile(VD, 'utils', 'StructTools'));

addpath(fullfile(VD, 'dashboard'));

addpath(fullfile(VD, 'GUIs'));


% addpath(fullfile(VD, 'sig'));
% addpath(fullfile(VD, 'sig', 'sig_elfun'));
% addpath(fullfile(VD, 'sig', 'sig_ops'));
% addpath(fullfile(VD, 'sig', 'sig_datafun'));

% addpath(fullfile(VD, 'tickle'));

addpath(fullfile(VD, 'TDT', 'sys3basics'));
addpath(fullfile(VD, 'TDT', 'SeqPlay'));

% addpath(fullfile(VD, 'theory', 'prestin'));
% addpath(fullfile(VD, 'theory', 'longitude'));
addpath(fullfile(VD, 'theory', 'cochwaves'));


addpath(fullfile(VD, 'DataAnalysis'));
%addpath(fullfile(VD, 'DataAnalysis', 'RuesAM'));
addpath(fullfile(VD, 'DataAnalysis', 'xfeature'));
addpath(fullfile(VD, 'DataAnalysis', 'ZWOAE'));
addpath(fullfile(VD, 'DataAnalysis', 'SGSR'));
addpath(fullfile(VD, 'DataAnalysis', 'CVdata'));
addpath(fullfile(VD, 'DataAnalysis', 'CVdata', 'DP_phase'));
addpath(fullfile(VD, 'DataAnalysis', 'JLdata'));
addpath(fullfile(VD, 'DataAnalysis', 'TKdata'));
addpath(fullfile(VD, 'DataAnalysis', 'JSdata'));
addpath(fullfile(VD, 'DataAnalysis', 'CAP'));
addpath(fullfile(VD, 'DataAnalysis', 'DataviewHelpers'));
addpath(fullfile(VD, 'DataAnalysis', 'ZWOAE', 'TDTgerbil'));
addpath(fullfile(VD, 'DataAnalysis', 'SPTcorr'));
addpath(fullfile(VD, 'DataAnalysis', 'SPTcorr', 'SPTcorrMEX'));
addpath(fullfile(VD, 'DataAnalysis', 'EvalRoutines'))
addpath(fullfile(VD, 'DataAnalysis', 'Tools'))
addpath(fullfile(VD, 'DataAnalysis', 'strfun'))
addpath(fullfile(VD, 'DataAnalysis', 'specific'))
addpath(fullfile(VD, 'DataAnalysis', 'Plot'))
addpath(fullfile(VD, 'DataAnalysis', 'Plot','KPlot'))
addpath(fullfile(VD, 'DataAnalysis', 'Plot','KPlot','plotObjects'))
addpath(fullfile(VD, 'DataAnalysis', 'Plot','plotObjects'))
addpath(fullfile(VD, 'DataAnalysis', 'GenCalcFnc'))
addpath(fullfile(VD, 'DataAnalysis', 'ConvFnc'))
addpath(genpath([VD '\' 'DataAnalysis' '\' 'SPTcorr']))
addpath(genpath([VD '\' 'DataAnalysis' '\' 'Tools']))
addpath(genpath([VD '\' 'DataAnalysis' '\' 'Plot']))
addpath(genpath([VD '\' 'DataAnalysis' '\' 'GenCalcFnc']))
addpath(fullfile(VD, 'DataAnalysis', 'GenCalcFnc','calcvsph'))
addpath(fullfile(VD, 'DataAnalysis', 'EvalRoutines'))
% addpath(fullfile(VD, 'Hardware', 'Multiclamp'));
% addpath(fullfile(VD, 'Hardware', 'Polytec'));


% addpath(fullfile(VD, 'Axon', 'ABF'));
% addpath(fullfile(VD, 'Igor'));
% addpath(fullfile(VD, 'BinBera'));

% addpath(fullfile(VD, 'StimGen', 'Keele'));
addpath(fullfile(VD, 'StimGen', 'Clix'));
addpath(fullfile(VD, 'StimGen', 'JSS'));
addpath(fullfile(VD, 'StimGen', 'Calib'));
addpath(fullfile(VD, 'StimGen', 'StimDef'));
addpath(fullfile(VD, 'StimGen', 'StimDef', 'helpers'));
addpath(fullfile(VD, 'StimGen', 'StimGUIutils'));

addpath(fullfile(VD, 'recordings'));

addpath(fullfile(VD, 'zwuis'));

% finally, add the dirs requested by stimdefPath
stimdefPathExtension = strrep(stimdefPath, [stimDefDir pathsep], '');
stimdefPathExtension = Words2cell(stimdefPathExtension, pathsep);
EarlyPath('insert', stimdefPathExtension{:});

%========================================================
function local_insert(varargin);
% check existence of dirs to be added
AP = '';
for ii=1:numel(varargin),
    d = varargin{ii};
    if exist(d, 'dir'),
        AP = [AP d pathsep];
    else,
        error(['Attempt to insert nonexistent directory ''' d ''' into Matlab path.']);
    end
end
if isempty(AP), return; end
% find the point at which to insert AP into the Path
sud = fileparts(which('findversiondir')); % the startup dir in which findversiondir resides
pp = path;
ihit = strfind(lower(pp), lower(sud));
i_insert = ihit+(length(sud)); % index in path marking the semicolon just before the standard Matlab path
newpp = [pp(1:i_insert) AP pp(i_insert:end)];
path(newpp);










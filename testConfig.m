% Copyright (C) 2018 Intel Corporation
% SPDX-License-Identifier: BSD-3-Clause

function cfg = testConfig()

% % 6rsp @~5hz, Real data set 
% % Tx time is randomly spread.
cfg.measFile = 'RD.csv';

cfg.name = cfg.measFile(1:end-4);

cfg.initPos = [-1.5; 7; 1.7];

% file contain measurement from 6 bSTA, we remove 2 of them.
cfg.bSTA2remove = [1,6]; % for using all bSTAs: cfg.bSTA2remove = []; 

% value must be the equal or bigger than the biggest bSTA id used.
cfg.maxSTAid = 6; 
cfg.disableClkTracking = 0;

% Map image filename, xMinMax, yMinMax
cfg.mapFile = 'arc_map.png';
cfg.xMinMax = [-44.5301, 6.7192];
cfg.yMinMax = [-15.3423, 35.9070];
end
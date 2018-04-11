% ReadFile - extracts measurement file.
% usage: [measTableOut,bPos,refPosMat] = ReadFile(cfg)

% For questions/comments contact: 
% leor.banin@intel.com, 
% ofer.bar-shalom@intel.com, 
% nir.dvorecki@intel.com,
% yuval.amizur@intel.com

% Copyright (C) 2018 Intel Corporation
% SPDX-License-Identifier: BSD-3-Clause

function [measTableOut,bPos,refPosMat] = ReadFile(cfg)

measTable = load(cfg.measFile);

% remove bSTAs ---------------------------------------------------
for k = 1:length(cfg.bSTA2remove)
    id = cfg.bSTA2remove(k);
    z=measTable(:,3)==id | measTable(:,4)==id;
    measTable(z,:)=[];
end
% ----------------------------------------------------------------

% extract available bSTA position for plot
[~,z] = unique(measTable(:,3));
bPos   = measTable(z,5:7);     

% extract reference trajectory - ground truth of client position
refPosMat = measTable(:,13:15); 

% prepare input to PE
measTableOut = measTable(:,1:12);
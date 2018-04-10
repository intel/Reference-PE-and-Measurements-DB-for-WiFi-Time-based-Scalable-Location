% mainPE - main functon for simulation.
% usage: mainPE(configMfile)

% For questions/comments contact: 
% leor.banin@intel.com, 
% ofer.bar-shalom@intel.com, 
% nir.dvorecki@intel.com,
% yuval.amizur@intel.com

% Copyright (C) 2018 Intel Corporation
% SPDX-License-Identifier: BSD-3-Clause

function mainPE(configMfile)

if exist('configMfile','var')
    configFunc = str2func(configMfile);
else
    configFunc = @testConfig;
end

cfg = configFunc();

[measTable, bPos, refPos] = ReadFile(cfg); % Read measurements file

[posEst,pValid] = RunPE(cfg,measTable); % Run PE

% pValid - designates the entries produced for every packet received by the client

posMat = posEst(:,pValid)';
refPosMat = refPos(pValid,:);
 
PlotResults(cfg,posMat,bPos,refPosMat) % plot results

end

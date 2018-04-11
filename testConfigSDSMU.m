% Copyright (C) 2018 Intel Corporation
% SPDX-License-Identifier: BSD-3-Clause

function cfg = testConfigSDSMU()
cfg = testConfig();
% 6rsp @5hz, dppm=1e-8, measSigma=3e-9, clientMeasSigma=6e-9
% Tx time is aligned in two groups (Split MU):
% [1,2,5] are 100ms offset from [3,4,6]).
cfg.measFile = 'SDSMU.csv';
cfg.name = cfg.measFile(1:end-4);
end
% Copyright (C) 2018 Intel Corporation
% SPDX-License-Identifier: BSD-3-Clause

function cfg = testConfigSDMU()
cfg = testConfig();
% 6rsp @5hz, dppm=1e-8, measSigma=3e-9, clientMeasSigma=6e-9
% all responder Tx time are aligned in time.
cfg.measFile = 'SDMU.csv';
cfg.name = cfg.measFile(1:end-4);
end
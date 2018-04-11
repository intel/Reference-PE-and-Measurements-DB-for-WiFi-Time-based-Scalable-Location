% Copyright (C) 2018 Intel Corporation
% SPDX-License-Identifier: BSD-3-Clause

function cfg = testConfigSDSMU_NT()
cfg = testConfigSDSMU();
cfg.disableClkTracking = 1;
cfg.name = [cfg.name,' NT'];
end
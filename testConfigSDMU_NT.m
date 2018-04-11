% Copyright (C) 2018 Intel Corporation
% SPDX-License-Identifier: BSD-3-Clause

function cfg = testConfigSDMU_NT()
cfg = testConfigSDMU();
cfg.disableClkTracking = 1;
cfg.name = [cfg.name,' NT'];
end
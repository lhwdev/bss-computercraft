local controller = require "lib.train.platform.controller"

local P001 = controller.add_station {
  station = "P001",
  name = "평보", -- '역'자는 생략 (평보역 x, 평보 o)
  direction = "north-south" -- 남북 vs 동서
}

local P001L15 = controller.add_platform {
  station = P001,
  platform = 15,       -- 15선; 타는 곳 15번
  platform_face = 6,   -- 6섬
  direction = {
    line = "downward", -- 상/하행
    facing = "south"   -- 물리적인 방향
  },
  types = { "metro" }
}

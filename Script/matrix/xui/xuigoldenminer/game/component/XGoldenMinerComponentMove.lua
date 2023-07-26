---@class XGoldenMinerComponentMove
local XGoldenMinerComponentMove = XClass(nil, "XGoldenMinerComponentMove")

function XGoldenMinerComponentMove:Ctor()
    self.MoveType = XGoldenMinerConfigs.StoneMoveType.None
    
    self.StartDirection = 0
    self.CurDirection = 0
    self.Speed = 0
    ---@type UnityEngine.Vector3
    self.StartPoint = false         -- 运动轨迹起点
    ---@type UnityEngine.Vector3
    self.CircleMovePoint = false    -- 圆周运动圆心
    self.MoveMinLimit = 0
    self.MoveMaxLimit = 0
end

return XGoldenMinerComponentMove
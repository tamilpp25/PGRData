---@class XGoldenMinerComponentMouse
local XGoldenMinerComponentMouse = XClass(nil, "XGoldenMinerComponentDirectionPoint")

function XGoldenMinerComponentMouse:Ctor()
    self.Status = XGoldenMinerConfigs.GAME_MOUSE_STATE.NONE

    ---@type UnityEngine.Transform[]
    self.StateTrans = {}

    ---@type UnityEngine.Transform[]
    self.CarryPoint = {}

    self.BoomTime = 1
    ---@type UnityEngine.Vector3
    self.BoomStartPos = Vector3.zero
    ---@type UnityEngine.Vector3
    self.BoomBezierControlPoint = Vector3.zero
    ---@type UnityEngine.Vector3
    self.BoomEndPos = Vector3.zero

    self.IsBoom = 0
end

return XGoldenMinerComponentMouse
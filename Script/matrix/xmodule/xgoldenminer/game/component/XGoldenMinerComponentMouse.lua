---@class XGoldenMinerComponentMouse:XEntity
---@field _OwnControl XGoldenMinerGameControl
---@field _ParentEntity XGoldenMinerEntityStone
local XGoldenMinerComponentMouse = XClass(XEntity, "XGoldenMinerComponentDirectionPoint")

--region Override
function XGoldenMinerComponentMouse:OnInit()
    self.Status = XEnumConst.GOLDEN_MINER.GAME_MOUSE_STATE.NONE

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

function XGoldenMinerComponentMouse:OnRelease()
    self.StateTrans = nil
    self.CarryPoint = nil
end
--endregion

return XGoldenMinerComponentMouse
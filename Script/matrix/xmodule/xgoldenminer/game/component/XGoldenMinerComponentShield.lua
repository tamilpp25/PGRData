---@class XGoldenMinerComponentShield:XEntity
---@field _OwnControl XGoldenMinerGameControl
---@field _ParentEntity XGoldenMinerEntityStone
local XGoldenMinerComponentShield = XClass(XEntity, "XGoldenMinerComponentShield")

--region Override
function XGoldenMinerComponentShield:OnInit()
    -- Static Value
    ---@type UnityEngine.Transform
    self.Transform = nil
end

function XGoldenMinerComponentShield:OnRelease()
    self.Transform = nil
end
--endregion

return XGoldenMinerComponentShield
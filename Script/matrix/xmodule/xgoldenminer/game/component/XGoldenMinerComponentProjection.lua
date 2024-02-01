---@class XGoldenMinerComponentProjection:XEntity
---@field _OwnControl XGoldenMinerGameControl
---@field _ParentEntity XGoldenMinerEntityStone
local XGoldenMinerComponentProjection = XClass(XEntity, "XGoldenMinerComponentProjection")

--region Override
function XGoldenMinerComponentProjection:OnInit()
    -- Static Value
    ---@type UnityEngine.Transform
    self.Transform = nil
end

function XGoldenMinerComponentProjection:OnRelease()
    self.Transform = nil
end
--endregion

return XGoldenMinerComponentProjection
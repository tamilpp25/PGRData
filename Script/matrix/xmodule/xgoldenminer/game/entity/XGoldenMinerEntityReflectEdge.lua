---@class XGoldenMinerEntityReflectEdge:XEntity
---@field _OwnControl XGoldenMinerGameControl
local XGoldenMinerEntityReflectEdge = XClass(XEntity, "XGoldenMinerEntityReflectEdge")

--region Be Override
function XGoldenMinerEntityReflectEdge:OnInit()
end

function XGoldenMinerEntityReflectEdge:OnRelease()
end
--endregion

--region Getter
---@return XGoldenMinerComponentReflectEdge
function XGoldenMinerEntityReflectEdge:GetComponentReflectEdge()
    return self:GetFirstChildEntityWithType(self._OwnControl.COMPONENT_TYPE.REFLECT_EDGE)
end
--endregion

return XGoldenMinerEntityReflectEdge
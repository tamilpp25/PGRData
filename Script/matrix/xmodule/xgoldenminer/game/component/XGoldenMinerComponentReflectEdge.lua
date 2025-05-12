---@class XGoldenMinerComponentReflectEdge:XEntity
---@field _OwnControl XGoldenMinerGameControl
---@field _ParentEntity XGoldenMinerEntityStone
local XGoldenMinerComponentReflectEdge = XClass(XEntity, "XGoldenMinerComponentReflectEdge")

--region Override
function XGoldenMinerComponentReflectEdge:OnInit()
    -- Static Value
    self._Flag = XEnumConst.GOLDEN_MINER.REFLECT_EDGE_FLAG.NONE
    self._Transform = nil
    self._Collider = nil
    ---@type XLuaVector2
    self._NormalVector = XLuaVector2.New()
end

function XGoldenMinerComponentReflectEdge:OnRelease()
    self._Flag = XEnumConst.GOLDEN_MINER.REFLECT_EDGE_FLAG.NONE
    self._Transform = nil
    self._Collider = nil
    self._NormalVector = nil
end
--endregion

--region Getter

function XGoldenMinerComponentReflectEdge:GetNormalVector()
    return self._NormalVector
end

function XGoldenMinerComponentReflectEdge:GetCollider()
    return self._Collider
end

function XGoldenMinerComponentReflectEdge:GetTransform()
    return self._Transform
end

function XGoldenMinerComponentReflectEdge:GetFlag()
    return self._Flag
end
--endregion

--region Setter
function XGoldenMinerComponentReflectEdge:SetNormalVector(value)
    self._NormalVector = value
end

function XGoldenMinerComponentReflectEdge:SetCollider(value)
    self._Collider = value
end

function XGoldenMinerComponentReflectEdge:SetTransform(value)
    self._Transform = value
end

function XGoldenMinerComponentReflectEdge:SetFlag(value)
    self._Flag = value
end
--endregion

return XGoldenMinerComponentReflectEdge
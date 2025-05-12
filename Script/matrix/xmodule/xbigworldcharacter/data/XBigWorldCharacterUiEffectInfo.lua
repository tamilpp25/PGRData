---@class XBigWorldCharacterUiEffectInfo
local XBigWorldCharacterUiEffectInfo = XClass(nil, "XBigWorldCharacterUiEffectInfo")

function XBigWorldCharacterUiEffectInfo:Ctor(fashionId, actionId, rootName)
    self._Effects = {}
    self:SetFashionId(fashionId)
    self:SetActionId(actionId)
    self:SetRootName(rootName)
end

function XBigWorldCharacterUiEffectInfo:SetRootName(rootName)
    if not string.IsNilOrEmpty(rootName) then
        self._RootName = rootName
    end
end

function XBigWorldCharacterUiEffectInfo:SetFashionId(fashionId)
    if XTool.IsNumberValid(fashionId) then
        self._FashionId = fashionId
    end
end

function XBigWorldCharacterUiEffectInfo:SetActionId(actionId)
    if not string.IsNilOrEmpty(actionId) then
        self._ActionId = actionId
    end
end

function XBigWorldCharacterUiEffectInfo:GetRootName()
    return self._RootName or ""
end

function XBigWorldCharacterUiEffectInfo:GetFashionId()
    return self._FashionId or 0
end

function XBigWorldCharacterUiEffectInfo:GetActionId()
    return self._ActionId or ""
end

function XBigWorldCharacterUiEffectInfo:AddEffectId(effectId)
    table.insert(self._Effects, effectId)
end

function XBigWorldCharacterUiEffectInfo:GetEffectIdByIndex(index)
    return self._Effects[index] or 0
end

function XBigWorldCharacterUiEffectInfo:GetEffectCount()
    return table.nums(self._Effects)
end

function XBigWorldCharacterUiEffectInfo:GetEffectPathByIndex(index)
    local effectId = self:GetEffectIdByIndex(index)

    if string.IsNilOrEmpty(effectId) then
        return ""
    end

    return XMVCA.XBigWorldResource:GetEffectUrl(effectId)
end

return XBigWorldCharacterUiEffectInfo
---@class XBigWorldBattleRoomProxy Dlc编队代理
local XBigWorldBattleRoomProxy = XClass(nil, "XBigWorldBattleRoomProxy")

function XBigWorldBattleRoomProxy:Ctor()
end

function XBigWorldBattleRoomProxy:IsCommandant(entityId)
    return XMVCA.XBigWorldCharacter:IsCommandant(entityId)
end

function XBigWorldBattleRoomProxy:GetUiModelId(entityId)
    return XMVCA.XBigWorldCharacter:GetUiModelId(entityId)
end

function XBigWorldBattleRoomProxy:GetModelUrl(entityId)
    local modelId = self:GetUiModelId(entityId)
    if not string.IsNilOrEmpty(modelId) then
        return XMVCA.XBigWorldResource:GetModelUrl(modelId)
    end
    return nil
end

function XBigWorldBattleRoomProxy:GetModelController(entityId)
    local modelId = self:GetUiModelId(entityId)
    if not string.IsNilOrEmpty(modelId) then
        return XMVCA.XBigWorldResource:GetModelControllerUrl(modelId)
    end
    return nil
end

function XBigWorldBattleRoomProxy:GetDefaultAnimName(entityId)
    local modelId = self:GetUiModelId(entityId)
    if not string.IsNilOrEmpty(modelId) then
        return XMVCA.XBigWorldResource:GetDlcUiDefaultAnimationName(modelId)
    end
    return XMVCA.XBigWorldResource:GetUiDefaultAnimaName()
end

function XBigWorldBattleRoomProxy:DragEnable()
    return true
end

return XBigWorldBattleRoomProxy
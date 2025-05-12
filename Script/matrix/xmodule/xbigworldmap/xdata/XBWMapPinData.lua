---@class XBWMapPinData
local XBWMapPinData = XClass(nil, "XBWMapPinData")

function XBWMapPinData:Ctor()
    self.LevelId = 0
    self.WorldId = 0
    self.PinId = 0
    self.QuestId = 0
    self.IsDisplay = false
    self.ForceDisplay = false
end

function XBWMapPinData:UpdateDisplay(isDisplay)
    self.IsDisplay = isDisplay
end

function XBWMapPinData:UpdateData(worldId, levelId, config, textConfig)
    self.PinId = config.Id
    self.LevelId = levelId
    self.WorldId = worldId
    self.SceneObjectPlaceId = config.SceneObjectPlaceId
    self.NpcPlaceId = config.NpcPlaceId
    self.Name = textConfig and textConfig.Name or ""
    self.Desc = textConfig and textConfig.Desc or ""
    self.StyleId = config.StyleId
    self.ActivityId = config.ActivityId
    self.MapAreaGroupId = config.MapAreaGroupId
    self.WorldPosition = config.WorldPosition
    self.TeleportEnable = config.TeleportEnable
    self.TeleportPosition = config.TeleportPosition
    self.TeleportEulerAngleY = config.TeleportEulerAngleY

    if not self:IsQuest() then
        local isDisplay = false

        if self:IsSceneObject() then
            isDisplay = XMVCA.XBigWorldMap:CheckSceneObjectMapPinDefalutDisplay(levelId, self.SceneObjectPlaceId)
        elseif self:IsNpc() then
            isDisplay = XMVCA.XBigWorldMap:CheckNpcMapPinDefalutDisplay(levelId, self.NpcPlaceId)
        end

        self:UpdateDisplay(isDisplay)
    end
end

function XBWMapPinData:IsActive()
    if self:IsQuest() or self:IsNpc() then
        return true
    end

    return XMVCA.XBigWorldService:CheckSceneObjectActive(self.WorldId, self.LevelId, self.SceneObjectPlaceId)
end

function XBWMapPinData:IsNpc()
    return XTool.IsNumberValid(self.NpcPlaceId)
end

function XBWMapPinData:IsSceneObject()
    return XTool.IsNumberValid(self.SceneObjectPlaceId)
end

function XBWMapPinData:IsNil()
    return not XTool.IsNumberValid(self.PinId)
end

function XBWMapPinData:IsActivity()
    return XTool.IsNumberValid(self.ActivityId)
end

function XBWMapPinData:IsQuest()
    return XTool.IsNumberValid(self.QuestId)
end

function XBWMapPinData:IsDisplaying()
    return self.ForceDisplay or self.IsDisplay
end

function XBWMapPinData:GetWorldPosition2D()
    return {
        x = self.WorldPosition.x,
        y = self.WorldPosition.z,
    }
end

return XBWMapPinData

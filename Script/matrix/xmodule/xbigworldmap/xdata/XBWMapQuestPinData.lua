local XBWMapPinData = require("XModule/XBigWorldMap/XData/XBWMapPinData")

---@class XBWMapQuestPinData : XBWMapPinData
local XBWMapQuestPinData = XClass(XBWMapPinData, "XBWMapQuestPinData")

function XBWMapQuestPinData:UpdateData(pinId, data)
    local questId = data.QuestId

    self.QuestId = questId
    self.ForceDisplay = data.ForceActive
    self.Super.UpdateData(self, 0, data.LevelId, {
        Id = pinId,
        StyleId = XMVCA.XBigWorldMap:GetQuestPinStyleIdByQuestId(questId),
        ActivityId = 0,
        MapAreaGroupId = 0,
        WorldPosition = {
            x = data.PositionX,
            y = data.PositionY,
            z = data.PositionZ,
        },
        TeleportEnable = false,
        TeleportPosition = {
            x = 0,
            y = 0,
            z = 0,
        },
        TeleportEulerAngleY = 0,
        SceneObjectPlaceId = 0,
        NpcPlaceId = 0,
    }, {
        Name = XMVCA.XBigWorldQuest:GetQuestText(questId),
        Desc = XMVCA.XBigWorldQuest:GetQuestDesc(questId),
    })
end

return XBWMapQuestPinData

--地图抓取物数据
---@class XGoldenMinerFaceEmojiDataEntity
local XGoldenMinerFaceEmojiDataEntity = XClass(nil, "XGoldenMinerFaceEmojiDataEntity")

function XGoldenMinerFaceEmojiDataEntity:Ctor()
    self.Status = XGoldenMinerConfigs.GAME_FACE_PLAY_STATUS.NONE
    ---@type number
    self.StatusFaceId = false
    ---@type number
    self.BeStatusFaceId = false
    ---@type number
    self.PlayDuration = 0
    ---@type number
    self.CurPlayDuration = 0
    ---@type number
    self.CurFaceId = 0
    ---@type XQueue
    self.CurPlayQueue = XQueue.New()
    ---@type boolean
    self.IsAim = false
end

return XGoldenMinerFaceEmojiDataEntity
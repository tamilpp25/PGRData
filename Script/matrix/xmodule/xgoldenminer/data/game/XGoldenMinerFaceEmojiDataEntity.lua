---地图表情数据
---表情分类: 普通表情(响应玩家操作,可以有N个) 状态表情(根据钩爪抓取状态的基础表情,只有1个根据状态切换)
---优先级: 普通表情 > 状态表情
---@class XGoldenMinerFaceEmojiDataEntity
local XGoldenMinerFaceEmojiDataEntity = XClass(nil, "XGoldenMinerFaceEmojiDataEntity")

function XGoldenMinerFaceEmojiDataEntity:Ctor()
    self.Status = XEnumConst.GOLDEN_MINER.GAME_FACE_PLAY_STATUS.NONE
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

--region Play
function XGoldenMinerFaceEmojiDataEntity:RefreshCurPlayDuration(time)
    self.CurPlayDuration = self.CurPlayDuration - time
end

function XGoldenMinerFaceEmojiDataEntity:AddPlayFaceId(faceId)
    self.CurPlayQueue:Enqueue(faceId)
end

function XGoldenMinerFaceEmojiDataEntity:RemoveCurPlayFaceId()
    self.CurPlayQueue:Dequeue()
end
--endregion

--region Getter
function XGoldenMinerFaceEmojiDataEntity:GetStatusFaceId()
    return self.StatusFaceId
end

function XGoldenMinerFaceEmojiDataEntity:GetBeStatusFaceId()
    return self.BeStatusFaceId
end

function XGoldenMinerFaceEmojiDataEntity:GetCurFaceId()
    return self.CurFaceId
end

function XGoldenMinerFaceEmojiDataEntity:GetBePlayFaceId()
    return self.CurPlayQueue:Peek()
end

function XGoldenMinerFaceEmojiDataEntity:GetPlayDuration()
    return self.PlayDuration
end
--endregion

--region Setter
function XGoldenMinerFaceEmojiDataEntity:SetStatusFaceId(value)
    self.StatusFaceId = value
end

function XGoldenMinerFaceEmojiDataEntity:SetBeStatusFaceId(value)
    self.BeStatusFaceId = value
end

function XGoldenMinerFaceEmojiDataEntity:SetCurFaceId(value)
    self.CurFaceId = value
end

function XGoldenMinerFaceEmojiDataEntity:SetCurPlayDuration(value)
    self.CurPlayDuration = value
end

---@param status number XEnumConst.GOLDEN_MINER.GAME_FACE_PLAY_STATUS
function XGoldenMinerFaceEmojiDataEntity:SetStatus(status)
    self.BeStatusFaceId = false
    self.Status = status
end

function XGoldenMinerFaceEmojiDataEntity:SetPlayDuration(value)
    self.PlayDuration = value
end

function XGoldenMinerFaceEmojiDataEntity:SetIsAnim(value)
    self.IsAim = value
end
--endregion

--region Checker
function XGoldenMinerFaceEmojiDataEntity:CheckHasCurFaceId()
    return self.CurFaceId
end

function XGoldenMinerFaceEmojiDataEntity:CheckIsPlayFaceId(faceId)
    return self.CurFaceId == faceId
end

function XGoldenMinerFaceEmojiDataEntity:CheckIsPlaying()
    return self.CurPlayDuration > 0
end

function XGoldenMinerFaceEmojiDataEntity:CheckIsAnim()
    return self.IsAim
end
--endregion

return XGoldenMinerFaceEmojiDataEntity
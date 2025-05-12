local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")
local XRedPointConditionTempleTask = require("XRedPoint/XRedPointConditions/XRedPointConditionTempleTask")
local XTempleEnumConst = require("XEntity/XTemple/XTempleEnumConst")

---@class XTempleAgency : XFubenActivityAgency
---@field private _Model XTempleModel
local XTempleAgency = XClass(XFubenActivityAgency, "XTempleAgency")
function XTempleAgency:OnInit()
    --初始化一些变量
    self:RegisterActivityAgency()

    self._Offline = false

    self._IsRequesting = false

    self._CurrentStageId = false
end

function XTempleAgency:IsOffline()
    return self._Offline
end

function XTempleAgency:SetRequesting(value)
    self._IsRequesting = value
end

-- 等待请求完成后，才能进行下一步，否则容易出问题
function XTempleAgency:IsRequesting()
    return self._IsRequesting
end

function XTempleAgency:RequestStart(stageId, callback)
    if self._Offline then
        callback()
        return
    end
    self:SetRequesting(true)
    XNetwork.Call("TempleFairStartRequest", { StageId = stageId }, function(res)
        self:SetRequesting(false)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if callback then
            callback()
        end
    end)
end

function XTempleAgency:RequestRestart(callback)
    if self._Offline then
        callback()
        return
    end
    self:SetRequesting(true)
    XNetwork.Call("TempleFairRestartRequest", {
        StageId = self:GetCurrentStageId()
    }, function(res)
        self:SetRequesting(false)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        local chapter = self._Model:GetChapterId(self:GetCurrentStageId())
        self._Model:GetActivityData():SetStage2Continue(false, chapter)
        if callback then
            callback()
        end
    end)
end

---@param record XTempleGameActionRecord
function XTempleAgency:RequestOperation(record, score, scoreDetail, characterId)
    if self._Offline then
        return
    end
    XMessagePack.MarkAsTable(scoreDetail)
    self:SetRequesting(true)
    XNetwork.Call("TempleFairOperatorRequest", {
        StageId = self:GetCurrentStageId(),
        Round = record.Round,
        BlockId = record.BlockId,
        Rotation = record.Rotation,
        X = record.X,
        Y = record.Y,
        Score = score,
        IsSkip = record.BlockId <= 0,
        OptionId = record.OptionId,
        ScoreDetail = scoreDetail,
        ArchitectureId = characterId,
    }, function(res)
        self:SetRequesting(false)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
    end)
end

function XTempleAgency:RequestSuccess(score, picData, characterId, callback)
    if self._Offline then
        callback()
        return
    end
    self:SetRequesting(true)
    local message = XMessagePack.Encode(picData)
    XNetwork.Call("TempleFairSettleRequest", {
        StageId = self:GetCurrentStageId(),
        SettleType = 2,
        Score = score,
        PicData = message,
        RoleId = characterId,
    }, function(res)
        self:SetRequesting(false)
        if callback then
            callback()
        end
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
    end)
end

function XTempleAgency:RequestFail(stageId)
    if self._Offline then
        local chapter = self._Model:GetChapterId(stageId)
        self._Model:GetActivityData():SetStage2Continue(false, chapter)
        XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_UPDATE_STAGE)
        return
    end
    self:SetRequesting(true)
    XNetwork.Call("TempleFairSettleRequest", {
        SettleType = 3,
        Score = 0,
        RoleId = 0,
        PicData = {},
        StageId = stageId,
    }, function(res)
        self:SetRequesting(false)
        local chapter = self._Model:GetChapterId(stageId)
        self._Model:GetActivityData():SetStage2Continue(false, chapter)
        XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_UPDATE_STAGE)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
    end)
end

function XTempleAgency:NotifyTempleFairActivity(data)
    self._Model:SetServerData(data)
    XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_UPDATE_STAGE)
end

function XTempleAgency:InitRpc()
    XRpc.NotifyTempleFairActivity = handler(self, self.NotifyTempleFairActivity)
end

function XTempleAgency:ExCheckInTime()
    return self._Model:CheckInTime()
end

function XTempleAgency:ExGetIsLocked()
    return self.Super.ExGetIsLocked(self)
end

function XTempleAgency:ExGetFunctionNameType()
    return XFunctionManager.FunctionName.Temple
end

function XTempleAgency:ExCheckIsShowRedPoint()
    return XRedPointConditionTempleTask.CheckActivityBanner()
end

function XTempleAgency:CheckPhotoJustUnlock()
    local allPhotoData = self._Model:GetActivityData():GetAllPhotoData()
    for characterId, photoData in pairs(allPhotoData) do
        local key = self:GetPhotoJustUnlockKey(characterId)
        if XSaveTool.GetData(key) == nil then
            return true
        end
    end
end

function XTempleAgency:SetPhotoJustUnlock()
    local allPhotoData = self._Model:GetActivityData():GetAllPhotoData()
    for characterId, photoData in pairs(allPhotoData) do
        local key = self:GetPhotoJustUnlockKey(characterId)
        XSaveTool.SaveData(key, true)
    end
end

function XTempleAgency:GetPhotoJustUnlockKey(characterId)
    local key = "XTemplePhotoJustUnlock" .. XPlayer.Id .. characterId
    return key
end

function XTempleAgency:IsChapterJustUnlock(chapter)
    local timeId = self._Model:GetChapterTimeId(chapter)
    if not XFunctionManager.CheckInTimeByTimeId(timeId) then
        return false
    end

    local value = XSaveTool.GetData(self:GetChapterJustUnlockKey(chapter))
    if value == nil then
        return true
    end
    return false
end

function XTempleAgency:IsCoupleChapterJustUnlock()
    return self:IsChapterJustUnlock(XTempleEnumConst.CHAPTER.COUPLE)
end

function XTempleAgency:GetChapterJustUnlockKey(chapterId)
    return "XTempleChapterJustUnlock" .. XPlayer.Id .. chapterId
end

function XTempleAgency:IsNewStageJustUnlock(stageId)
    local value = XSaveTool.GetData(self:GetStageJustUnlockKey(stageId))
    if value == nil then
        return true
    end
    return false
end

function XTempleAgency:GetStageJustUnlockKey(stageId)
    return "XTempleStageJustUnlock" .. XPlayer.Id .. stageId
end

function XTempleAgency:GetChapterStageJustUnlockKeyOnce(stageId)
    return "XTempleChapterStageJustUnlock" .. XPlayer.Id .. stageId
end

function XTempleAgency:IsNewChapterStageJustUnlockOnce(stageId)
    local value = XSaveTool.GetData(self:GetChapterStageJustUnlockKeyOnce(stageId))
    if value == nil then
        return true
    end
    return false
end

function XTempleAgency:SetChapterStageNotJustUnlock(stageId)
    XSaveTool.SaveData(self:GetChapterStageJustUnlockKeyOnce(stageId), true)
end

function XTempleAgency:IsChapterStageJustUnlockOnce(chapter)
    local timeId = self._Model:GetChapterTimeId(chapter)
    if not XFunctionManager.CheckInTimeByTimeId(timeId) then
        return false
    end
    local allStage = self._Model:GetStageConfigList()
    for i, config in pairs(allStage) do
        if config.ChapterId == chapter then
            local stageId = config.Id
            if self._Model:IsStageCanChallenge(stageId) and not self._Model:IsStageHasRecord(stageId) then
                if self:IsNewChapterStageJustUnlockOnce(stageId) then
                    return true
                end
            end
        end
    end
    return false
end

function XTempleAgency:IsChapterHasJustUnlockStage(chapter)
    local timeId = self._Model:GetChapterTimeId(chapter)
    if not XFunctionManager.CheckInTimeByTimeId(timeId) then
        return false
    end
    local allStage = self._Model:GetStageConfigList()
    for i, config in pairs(allStage) do
        if config.ChapterId == chapter then
            local stageId = config.Id
            if self._Model:IsStageCanChallenge(stageId) then
                if self:IsNewStageJustUnlock(stageId) then
                    return true
                end
            end
        end
    end
    return false
end

function XTempleAgency:SetChapterAllStageNotJustUnlockOnce(chapter)
    local allStage = self._Model:GetStageConfigList()
    for i, config in pairs(allStage) do
        if config.ChapterId == chapter then
            local stageId = config.Id
            if self._Model:IsStageCanChallenge(stageId) then
                if self:IsNewChapterStageJustUnlockOnce(stageId) then
                    self:SetChapterStageNotJustUnlock(stageId)
                end
            end
        end
    end
end

function XTempleAgency:SetStageNotJustUnlock(stageId)
    XSaveTool.SaveData(self:GetStageJustUnlockKey(stageId), true)
end

function XTempleAgency:GetMessageJustUnlockKey(stageId)
    return "XTempleMessageJustUnlock" .. XPlayer.Id .. stageId
end

function XTempleAgency:IsNewMessageJustUnlock(stageId)
    local value = XSaveTool.GetData(self:GetMessageJustUnlockKey(stageId))
    if value == nil then
        return true
    end
    return false
end

function XTempleAgency:IsChapterHasJustUnlockMessage(chapter)
    local allStage = self._Model:GetStageConfigList()
    for i, config in pairs(allStage) do
        if config.ChapterId == chapter then
            if not string.IsNilOrEmpty(config.Message) then
                local stageId = config.Id
                if self._Model:IsStagePassed(stageId) then
                    if self:IsNewMessageJustUnlock(stageId) then
                        return true
                    end
                end
            end
        end
    end
    return false
end

function XTempleAgency:SetAllMessageNotJustUnlock(chapter)
    local allStage = self._Model:GetStageConfigList()
    for i, config in pairs(allStage) do
        if config.ChapterId == chapter then
            local stageId = config.Id
            if not string.IsNilOrEmpty(config.Message) then
                if self._Model:IsStagePassed(stageId) then
                    if self:IsNewMessageJustUnlock(stageId) then
                        self:SetMessageNotJustUnlock(stageId)
                    end
                end
            end
        end
    end
end

function XTempleAgency:SetMessageNotJustUnlock(stageId)
    XSaveTool.SaveData(self:GetMessageJustUnlockKey(stageId), true)
end

function XTempleAgency:SetCurrentStageId(stageId)
    self._CurrentStageId = stageId
end

function XTempleAgency:ClearCurrentStageId()
    self:SetCurrentStageId()
end

function XTempleAgency:IsOnStage(stageId)
    return self._CurrentStageId == stageId
end

function XTempleAgency:GetCurrentStageId()
    return self._CurrentStageId
end

return XTempleAgency
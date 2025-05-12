local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")

---@class XTemple2Agency : XFubenActivityAgency
---@field private _Model XTemple2Model
local XTemple2Agency = XClass(XFubenActivityAgency, "XTemple2Agency")

function XTemple2Agency:OnInit()
    self:RegisterActivityAgency()
    self._IsRequesting = false
end

function XTemple2Agency:InitRpc()
    XRpc.NotifyTemple2Activity = handler(self, self.NotifyTemple2Activity)
    XRpc.NotifyTemple2Character = handler(self, self.NotifyTemple2Character)
end

function XTemple2Agency:ClearRequesting()
    self._IsRequesting = false
end

function XTemple2Agency:OnRelease()
    self._IsRequesting = false
end

function XTemple2Agency:ResetAll()
    self._IsRequesting = false
end

--region proto
function XTemple2Agency:IsRequesting()
    return self._IsRequesting
end

function XTemple2Agency:NotifyTemple2Activity(data)
    self._Model:SetActivityData(data)
end

function XTemple2Agency:NotifyTemple2Character(data)
    self._Model:SetCharacterData(data)
end

function XTemple2Agency:Temple2StartRequest(stageId, characterId, startType, callback)
    if self:IsRequesting() then
        XLog.Warning("[XTemple2Agency] 重复请求Temple2StartRequest")
        return
    end
    self._IsRequesting = true
    XNetwork.Call("Temple2StartRequest", {
        StageId = stageId,
        CharacterId = characterId,
        Type = startType,
    }, function(res)
        self._IsRequesting = false
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            if res.Code == 20230004 then
                self:Temple2ResetRequest(stageId, true)
            end
            return
        end
        local curData = res.XTemple2Data
        self._Model:SetCurData(curData)
        callback(res)
    end)
end

function XTemple2Agency:Temple2ResetRequest(stageId, isAbandon)
    if self:IsRequesting() then
        XLog.Warning("[XTemple2Agency] Temple2ResetRequest")
        return
    end
    self._IsRequesting = true
    XNetwork.Call("Temple2ResetRequest", {
        StageId = stageId,
        -- 类型 1 重新开始本局 2 放弃本局
        Type = isAbandon and 2 or 1,
    }, function(res)
        self._IsRequesting = false
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model:GiveUpOngoingStage()
        XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE2_UPDATE_STAGE)
    end)
end

function XTemple2Agency:Temple2OperatorRequest(stageId, operationType, round, blockId, rotation, x, y)
    if self:IsRequesting() then
        XLog.Warning("[XTemple2Agency] Temple2OperatorRequest")
        return
    end
    self._IsRequesting = true
    XNetwork.Call("Temple2OperatorRequest", {
        StageId = stageId,
        -- 操作类型 1 增加 2 删除 3 修改
        OperatorType = operationType,
        Round = round,
        BlockId = blockId,
        Rotation = rotation,
        X = x,
        Y = y
    }, function(res)
        self._IsRequesting = false
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
    end)
end

function XTemple2Agency:Temple2SettleRequest(stageId, score, plotIds, callback, jsonRecord)
    if self:IsRequesting() then
        XLog.Warning("[XTemple2Agency] Temple2SettleRequest")
        return
    end
    self._IsRequesting = true
    XNetwork.Call("Temple2SettleRequest", {
        StageId = stageId,
        Score = score,
        PlotIdList = plotIds,
        Detail = jsonRecord or ""

    }, function(res)
        self._IsRequesting = false
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE2_SETTLE)

        if callback then
            callback()
        end
    end)
end
--endregion proto

function XTemple2Agency:ExCheckInTime()
    return self._Model:CheckInTime()
end

function XTemple2Agency:ExGetIsLocked()
    return self.Super.ExGetIsLocked(self)
end

function XTemple2Agency:ExGetFunctionNameType()
    return XFunctionManager.FunctionName.Temple2
end

--function XTemple2Agency:ExCheckIsShowRedPoint()
--return XRedPointConditionTempleTask.CheckActivityBanner()
--end

function XTemple2Agency:ExGetProgressTip()
    local taskType = XDataCenter.TaskManager.TaskType.Temple2
    local amount, totalAmount = XDataCenter.TaskManager.GetTaskProgress(taskType)
    return amount .. "/" .. totalAmount
end

function XTemple2Agency:IsOnStage(value)
    return self._Model:GetCurrentGameStageId() == value
end

function XTemple2Agency:PlayMovie(movieId, callback)
    local timeScale = CS.UnityEngine.Time.timeScale
    CS.UnityEngine.Time.timeScale = 1
    XDataCenter.MovieManager.PlayMovie(movieId, function()
        CS.UnityEngine.Time.timeScale = timeScale
        if callback then
            callback()
        end
    end, nil, nil, false)
end

function XTemple2Agency:RequestBubble(bubbleId, callback)
    --self._IsRequesting = true
    XNetwork.Call("Temple2PlotRequest", {
        PlotId = bubbleId,
    }, function(res)
        --self._IsRequesting = false
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model:SetStoryUnlock(bubbleId)
        if callback then
            callback()
        end
    end)
end

function XTemple2Agency:IsBubbleUnlock(bubbleId)
    return self._Model:IsStoryUnlock(bubbleId)
end

return XTemple2Agency
local XFubenActivityAgency = require('XModule/XBase/XFubenActivityAgency')

---@class XBagOrganizeActivityAgency : XFubenActivityAgency
---@field private _Model XBagOrganizeActivityModel
local XBagOrganizeActivityAgency = XClass(XFubenActivityAgency, "XBagOrganizeActivityAgency")
function XBagOrganizeActivityAgency:OnInit()
    self:RegisterActivityAgency()
    self.EnumConst = require('XModule/XBagOrganizeActivity/XBagOrganizeActivityEnumConst')
    self.EventIds = require('XModule/XBagOrganizeActivity/XBagOrganizeActivityEventId')
end

function XBagOrganizeActivityAgency:InitRpc()
    XRpc.NotifyBagOrganizeActivity = handler(self, self.UpdateBagOrganizeActivityData)
end

function XBagOrganizeActivityAgency:InitEvent()
    --实现跨Agency事件注册
end


--region -----------------------------override------------------------------->>

-------------------------------------活动入口----------------------------------
function XBagOrganizeActivityAgency:ExOpenMainUi()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.BagOrganizeActivity) then
        return
    end
    if XTool.IsNumberValid(self._Model:GetCurActivityId()) and self:ExCheckInTime() then
        XLuaUiManager.Open('UiBagOrganizeMain')
    else
        XUiManager.TipText('CommonActivityNotStart')
    end
end

function XBagOrganizeActivityAgency:ExGetProgressTip()
    local chapterIds = self:GetInTimeActivityChapterIds()
    
    local totalStageCount = 0
    local passedStageCount = 0
    local tipFormat = self._Model:GetClientConfigText('ProgressTip')

    if not XTool.IsTableEmpty(chapterIds) then
        for i, v in pairs(chapterIds) do
            ---@type XTableBagOrganizeChapter
            local chapterCfg = self._Model:GetBagOrganizeChapterConfig()[v]

            if chapterCfg then
                local chapterUnLock = self:CheckChapterUnLockById(v)
                local stageIds = chapterCfg.StageIds
                totalStageCount = totalStageCount + #stageIds

                if chapterUnLock then
                    for i, v in ipairs(stageIds) do
                        if self:CheckPassedByStageId(v) then
                            passedStageCount = passedStageCount + 1
                        end
                    end
                end
            end
            
        end
    end
    
    return XUiHelper.FormatText(tipFormat, passedStageCount, totalStageCount)
end

------------------------------------关卡---------------------------------
---@param stageId @Stage.tab表的Id
function XBagOrganizeActivityAgency:CheckPassedByStageId(stageId)
    return not XTool.IsTableEmpty(self._Model:GetStageRecordById(stageId))
end

---@param stageId @Stage.tab表的Id
function XBagOrganizeActivityAgency:CheckUnlockByStageId(stageId)
    local cfg = self._Model:GetBagOrganizeStageConfig()[stageId]

    if cfg then
        if XTool.IsNumberValid(cfg.PreStageId) then
            local preStageIsPass = self:CheckPassedByStageId(cfg.PreStageId)
            return preStageIsPass, cfg.PreStageId
        else
            return true
        end
    end
    
    return false
end
--endregion

--region -------------------------- 蓝点 -------------------------->>>
function XBagOrganizeActivityAgency:CheckChapterIsNew(chapterId)
    return self._Model.ReddotData:CheckChapterIsNew(chapterId)
end

function XBagOrganizeActivityAgency:SetChapterToOld(chapterId)
    self._Model.ReddotData:SetChapterToOld(chapterId)
end

function XBagOrganizeActivityAgency:CheckAnyTaskCanFinish()
    local taskTimelimitId = self:GetCurTaskTimelimitId()

    if XTool.IsNumberValid(taskTimelimitId) then
        local taskDataList = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(taskTimelimitId, false)

        if not XTool.IsTableEmpty(taskDataList) then
            for i, v in pairs(taskDataList) do
                if v.State == XDataCenter.TaskManager.TaskState.Achieved then
                    return true
                end
            end
        end
    end
    
    return false
end

--endregion <<<------------------------------------------------------

--region ------------------------- Condition -------------------->>>
function XBagOrganizeActivityAgency:CheckChapterUnLockById(chapterId)
    local timeId = self:GetChapterTimeIdById(chapterId)

    if XTool.IsNumberValid(timeId) then
        return XFunctionManager.CheckInTimeByTimeId(timeId)
    end

    return false
end
--endregion <<<-------------------------------------------------------

--region ------------------------- Configs ------------------------>>>
function XBagOrganizeActivityAgency:GetChapterTimeIdById(chapterId)
    local cfg = self._Model:GetBagOrganizeChapterConfig()[chapterId]
    if cfg then
        return cfg.TimeId
    end

    return 0
end
--endregion <<<-------------------------------------------------------

--region ---------------------------- Activity Data ------------------------>>>

function XBagOrganizeActivityAgency:GetCurActivityId()
    return self._Model:GetCurActivityId()
end

function XBagOrganizeActivityAgency:GetCurChapterIds()
    local activityId = self:GetCurActivityId()

    if XTool.IsNumberValid(activityId) then
        ---@type XTableBagOrganizeActivity
        local cfg = self._Model:GetBagOrganizeActivityConfig()[activityId]

        if cfg then
            return cfg.ChapterIds
        end
    end
end

function XBagOrganizeActivityAgency:GetCurTaskTimelimitId()
    local activityId = self:GetCurActivityId()

    if XTool.IsNumberValid(activityId) then
        local cfg = self._Model:GetBagOrganizeActivityConfig()[activityId]

        if cfg then
            return cfg.TaskTimelimitId
        end
    end
    
    return 0
end

function XBagOrganizeActivityAgency:GetInTimeActivityChapterIds()
    local chapterIds = self:GetCurChapterIds()
    local anyActivityInTime = false
    if XTool.IsTableEmpty(chapterIds) then
        local activityCfgs = self._Model:GetBagOrganizeActivityConfig()

        for i, v in pairs(activityCfgs) do
            if XFunctionManager.CheckInTimeByTimeId(v.TimeId) then
                chapterIds =  v.ChapterIds
                anyActivityInTime = true
                break
            end
        end
    else
        anyActivityInTime = true
    end

    if not anyActivityInTime then
        XLog.Error('[BagOrganizeActivity]遍历了整张活动表，但不存在时间范围内的活动，请检查时间配置，或移除该活动配置减少不必要的遍历')
    end
    
    return chapterIds
end

function XBagOrganizeActivityAgency:GetCurShopId()
    return self._Model:GetClientConfigNum('ShopId')
end

--endregion <<<----------------------------------------------------------------

function XBagOrganizeActivityAgency:UpdateBagOrganizeActivityData(data)
    self._Model:UpdateActivityId(data.ActivityId)
    self._Model:UpdateStageRecords(data.StageRecords)
end

function XBagOrganizeActivityAgency:GetCurStageId()
    return self._Model:GetCurStageId()
end

function XBagOrganizeActivityAgency:ClearStarRequestLock()
    self._LockStartRequest = nil
end

--region ----------------------------- 协议请求 -------------------------------->>>

function XBagOrganizeActivityAgency:RequestBagOrganizeStart(stageId, cb)
    if self._LockStartRequest then
        return
    end
    
    self._LockStartRequest = true
    XLuaUiManager.SetMask(true)
    
    XNetwork.Call("BagOrganizeStartRequest", {StageId = stageId}, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            self._LockStartRequest = false
            XLuaUiManager.SetMask(false)
            return
        end
        
        if res.CurData then
            self._Model:UpdateCurStageStartTime(res.CurData.StartTime)
            self._Model:UpdateCurStageTurnId(res.CurData.Id)
        end

        if cb then
            cb()
        end

        self._LockStartRequest = false
    end)
end

function XBagOrganizeActivityAgency:RequestBagOrganizeSettle(stageId, settleType, score, cb)
    XNetwork.Call("BagOrganizeSettleRequest", {StageId = stageId, SettleType = settleType, Score = score}, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            if cb then
                cb(nil, false)
            end
            return
        end

        if cb then
            cb(res.SettleData, true, score)
        end

        if res.CurData then
            self._Model:UpdateCurStageStartTime(res.CurData.StartTime)
            self._Model:UpdateCurStageTurnId(res.CurData.Id)
        end
    end)
end

function XBagOrganizeActivityAgency:RequestBagOrganizeRank(successCb)
    XNetwork.Call("BagOrganizeRankRequest", nil, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        if successCb then
            successCb(res)
        end
    end)
end

--endregion <<<------------------------------------------------------------------

return XBagOrganizeActivityAgency
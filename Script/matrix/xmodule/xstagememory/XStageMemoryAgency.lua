local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")

---@class XStageMemoryAgency : XAgency
---@field private _Model XStageMemoryModel
local XStageMemoryAgency = XClass(XFubenActivityAgency, "XStageMemoryAgency")
function XStageMemoryAgency:OnInit()
    --初始化一些变量
    self:RegisterActivityAgency()
    XMVCA.XFuben:RegisterFuben(XEnumConst.FuBen.StageType.StageMemory, ModuleId.XStageMemory)
end

function XStageMemoryAgency:InitRpc()
    --实现服务器事件注册
    XRpc.NotifyStageMemoryActivity = handler(self, self.NotifyStageMemoryActivity)
end

function XStageMemoryAgency:NotifyStageMemoryActivity(data)
    self._Model:SetServerData(data)
end

function XStageMemoryAgency:RequestStageChoiceGetReward(index)
    XNetwork.Call("StageMemoryGetRewardRequest", { Index = index }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        XUiManager.OpenUiObtain(res.RewardList)
        self._Model:SetRewardReceived(index)
        XEventManager.DispatchEvent(XEventId.EVENT_STAGE_MEMORY_UPDATE_REWARD)
    end)
end

function XStageMemoryAgency:ExCheckInTime()
    if not self.Super.ExCheckInTime(self) then
        return false
    end
    local config = self._Model:GetActivityConfig()
    if not config then
        return false
    end
    local timeId = config.TimeId
    return XFunctionManager.CheckInTimeByTimeId(timeId)
end

function XStageMemoryAgency:IsShowChallengeRedPoint()
    if self:ExGetIsLocked() then
        return false
    end
    if self:ExCheckInTime() then
        local config = self._Model:GetActivityConfig()
        if not config then
            return false
        end
        local stages = config.StageIds
        for i = 1, #stages do
            local stageId = stages[i]
            if XFunctionManager.CheckInTimeByTimeId(config.StageTimeIds[i]) then
                local isPassed = XMVCA.XFuben:CheckStageIsPass(stageId)
                if not isPassed then
                    return true
                end
            end
        end
    end
    return false
end

function XStageMemoryAgency:IsShowRewardRedPoint()
    if self:ExGetIsLocked() then
        return false
    end
    if self:ExCheckInTime() then
        local config = self._Model:GetActivityConfig()
        if not config then
            return false
        end
        local stages = config.StageIds
        local stageAmount = 0
        for i = 1, #stages do
            local stageId = stages[i]
            local isPassed = XMVCA.XFuben:CheckStageIsPass(stageId)
            if isPassed then
                stageAmount = stageAmount + 1
                --else
                --    -- 未通关 但是已开放
                --    if XFunctionManager.CheckInTimeByTimeId(config.StageTimeIds[i]) then
                --        return true
                --    end
            end
        end

        for i = 1, #config.RequireStages do
            local amount = config.RequireStages[i]
            if stageAmount >= amount then
                if not self._Model:IsRewardReceived(i) then
                    return true
                end
            end
        end
    end
    return false
end

function XStageMemoryAgency:ExGetProgressTip()
    ---@type XTable.XTableStageMemoryActivity
    local activityConfig = self._Model:GetActivityConfig()
    if not activityConfig then
        XLog.Error("[XStageMemoryControl] 找不到活动配置")
        return ""
    end
    local passedStageAmount = 0
    local stages = activityConfig.StageIds
    local totalAmount = #stages
    for i = 1, totalAmount do
        local stageId = stages[i]
        if XMVCA.XFuben:CheckStageIsPass(stageId) then
            passedStageAmount = passedStageAmount + 1
        end
    end
    return passedStageAmount .. "/" .. totalAmount
end

function XStageMemoryAgency:ShowReward(winData)
    XLuaUiManager.Open("UiStageMemorySettlement", winData)
end

function XStageMemoryAgency:IsDisableInstruction(stageId)
    local stageConfig = self._Model:GetStageConfig(stageId)
    if stageConfig then
        if stageConfig.NoInstructionOnUiFightPause then
            return true
        end
    end
    return false
end

function XStageMemoryAgency:SetHasViewedToday()
    XSaveTool.SaveData("StageMemory" .. XPlayer.Id, XTime.GetServerNowTimestamp())
end

local function GetMorningFiveTimestamp(timestamp)
    -- 获取时间元表
    local timeTable = os.date("*t", timestamp)

    -- 设置时间为早上五点
    timeTable.hour = 5
    timeTable.min = 0
    timeTable.sec = 0

    -- 转换回时间戳
    local morningFiveTimestamp = os.time(timeTable)
    return morningFiveTimestamp
end

function XStageMemoryAgency:GetHasViewedToday()
    local timestamp = XSaveTool.GetData("StageMemory" .. XPlayer.Id)
    if not timestamp then
        return false
    end
    local current = XTime.GetServerNowTimestamp()
    local morningFiveTimestamp = GetMorningFiveTimestamp(timestamp)
    if current - morningFiveTimestamp < 86400 then
        return true
    end
    return false
end

function XStageMemoryAgency:OpenMain()
    if self:ExCheckInTime() then
        XLuaUiManager.Open("UiStageMemory")
    else
        XUiManager.TipText("FestivalActivityNotInActivityTime")
    end
end

return XStageMemoryAgency
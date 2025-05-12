local XFubenActivityAgency = require('XModule/XBase/XFubenActivityAgency')

---@class XGame2048Agency : XFubenActivityAgency
---@field private _Model XGame2048Model
local XGame2048Agency = XClass(XFubenActivityAgency, "XGame2048Agency")

local Day = 24 * 3600

function XGame2048Agency:OnInit()
    self:RegisterActivityAgency()
    self.EventIds = require('XModule/XGame2048/XGame2048EventId')
    self.EnumConst = require('XModule/XGame2048/XGame2048EnumConst')
end

function XGame2048Agency:InitRpc()
    XRpc.NotifyGame2048DataDb = handler(self, self.UpdateActivityData)
end

function XGame2048Agency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

--region -----------------------------override------------------------------->>

-------------------------------------活动入口----------------------------------
function XGame2048Agency:ExOpenMainUi()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Game2048) then
        return false
    end
    if XTool.IsNumberValid(self._Model:GetCurActivityId()) and self:ExCheckInTime() then
        XLuaUiManager.Open('UiGame2048Main')
        return true
    else
        XUiManager.TipText('CommonActivityNotInTime')
    end
    
    return false
end

function XGame2048Agency:ExGetProgressTip()
    ---@type XTableGame2048Activity
    local activityCfg = self._Model:GetCurActivityCfg()

    if activityCfg and not XTool.IsTableEmpty(activityCfg.ChapterIds) then
        local getStarSummary = 0
        local totalStarSummary = 0

        for i, chapterId in pairs(activityCfg.ChapterIds) do
            getStarSummary = getStarSummary + self._Model:GetChapterCurStarSummary(chapterId)
            totalStarSummary = totalStarSummary + self._Model:GetChapterStarTotalById(chapterId)
        end
        
        return XUiHelper.FormatText(self._Model:GetClientConfigText('ProgressTip'), getStarSummary, totalStarSummary)
    end
    
    return ''
end

------------------------------------关卡---------------------------------
---@param stageId @Stage.tab表的Id
function XGame2048Agency:CheckPassedByStageId(stageId)
    if XTool.IsNumberValid(stageId) then
        local info = self._Model:GetStageInfoById(stageId)
        return not XTool.IsTableEmpty(info)
    end
end

---@param stageId @Stage.tab表的Id
function XGame2048Agency:CheckUnlockByStageId(stageId)
    if XTool.IsNumberValid(stageId) then
        ---@type XTableGame2048Stage
        local stageCfg = self._Model:GetGame2048StageCfgs()[stageId]
        if stageCfg then
            if XTool.IsNumberValid(stageCfg.PreStageId) then
                -- 优先级最高的是时间
                if XTool.IsNumberValid(stageCfg.TimeId) then
                    if not XFunctionManager.CheckInTimeByTimeId(stageCfg.TimeId) then
                        -- 如果连时间都不满足，则输出时间描述
                        return false, nil, stageCfg.TimeId
                    end
                end
                
                local isPass = self:CheckPassedByStageId(stageCfg.PreStageId)
                -- 除了通关还有至少拿1星的要求
                local stageInfo = self._Model:GetStageInfoById(stageCfg.PreStageId)
                if isPass and stageInfo then
                    return not XTool.IsTableEmpty(stageInfo.GetRewardIndex), stageCfg.PreStageId
                end
                return false, stageCfg.PreStageId
            else
                return true
            end
        end
    end
end
--endregion <<<-----------------------------------------------------------


--region ---------------------------- Activity Data ------------------------>>>

function XGame2048Agency:UpdateActivityData(data)
    self._Model:UpdateActivityId(data.Game2048DataDb.ActivityId)
    self._Model:UpdateStageInfos(data.Game2048DataDb.StageFinish)
    self._Model:UpdateCurStageData(data.Game2048DataDb.StageContext)

    --因为需要商店数据进行蓝点判定，当活动开启时就请求获取商店数据
    --仅当玩家商店权限开放和需要蓝点判定时才主动提前请求数据
    if self:ExCheckInTime() and XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon,false,true) then
        local shopId = self:GetCurShopId()
        if XTool.IsNumberValid(shopId) then
            XShopManager.GetShopInfo(shopId, nil, true)
        end
    end
end

function XGame2048Agency:GetCurActivityId()
    return self._Model:GetCurActivityId()
end

function XGame2048Agency:GetCurChapterIds()
    local activityId = self:GetCurActivityId()

    if XTool.IsNumberValid(activityId) then
        ---@type XTableGame2048Activity
        local activityCfg = self._Model:GetGame2048ActivityCfgs()[activityId]

        if activityCfg then
            return activityCfg.ChapterIds
        end
    end
end

function XGame2048Agency:GetCurShopId()
    local activityId = self._Model:GetCurActivityId()

    if XTool.IsNumberValid(activityId) then
        ---@type XTableGame2048Activity
        local activityCfg = self._Model:GetGame2048ActivityCfgs()[activityId]

        if activityCfg then
            return activityCfg.ShopId
        end
    end
end

function XGame2048Agency:CheckChapterUnLockById(chapterId)
    if XTool.IsNumberValid(chapterId) then
        ---@type XTableGame2048Chapter
        local cfg = self._Model:GetGame2048ChapterCfgs()[chapterId]
        if cfg then
            local inTime = XTool.IsNumberValid(cfg.TimeId) and XFunctionManager.CheckInTimeByTimeId(cfg.TimeId) or false
            local satisfyCondition = not XTool.IsNumberValid(cfg.Condition) and true or XConditionManager.CheckCondition(cfg.Condition)
            
            return inTime and satisfyCondition
        end
    end
    return false
end

function XGame2048Agency:GetCurPlayingStageId()
    local curStageData = self._Model:GetCurStageData()

    if not XTool.IsTableEmpty(curStageData) then
        return curStageData.StageId
    end
    
    return 0
end

function XGame2048Agency:CheckPassStageAchieveStarCount(stageId, count)
    if XTool.IsNumberValid(stageId) then
        local info = self._Model:GetStageInfoById(stageId)
        if not XTool.IsTableEmpty(info) then
            local getRewardCount = XTool.GetTableCount(info.GetRewardIndex)
            return getRewardCount >= count
        end 
    end
    return false
end
--endregion <<<----------------------------------------------------------------

--region -------------------------- 蓝点 -------------------------->>>
function XGame2048Agency:CheckChapterIsNew(chapterId)
    local key = self._Model:GetChapterNewReddotKey(chapterId)
    return not XSaveTool.GetData(key) and true or false
end

function XGame2048Agency:SetChapterToOld(chapterId)
    local key = self._Model:GetChapterNewReddotKey(chapterId)

    if not XSaveTool.GetData(key) then
        XSaveTool.SaveData(key, true)
    end
end

--- 检查活动结束剩余时间是否满足开启商店蓝点判断
function XGame2048Agency:CheckLeftDaySatisfyStoreReddotEnable()
    if self._ShopReddotTipsLeftDay == nil or XMain.IsEditorDebug then
        self._ShopReddotTipsLeftDay = self._Model:GetClientConfigNum('ShopReddotTipsLeftDay')
    end

    local timeId = self._Model:GetCurActivityTimeId()

    if XTool.IsNumberValid(timeId) then
        local now = XTime.GetServerNowTimestamp()
        local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
        
        local leftTime = endTime - now

        if leftTime > 0 and leftTime / Day <= self._ShopReddotTipsLeftDay then
            return true
        end
    end
    
    return false
end

--endregion <<<------------------------------------------------------

return XGame2048Agency
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiGridWheelchairManualGuide: XUiNode
---@field _Control XWheelchairManualControl
---@field ViewData XWheelchairManualGuideViewData
local XUiGridWheelchairManualGuide = XClass(XUiNode, 'XUiGridWheelchairManualGuide')
local XUiGridWheelchairManualGuideTag = require('XUi/XUiWheelchairManual/UiPanelWheelchairManualGuide/XUiGridWheelchairManualGuideTag')
local ReddotIdMartix = XMath.ToMinInt(math.pow(2, 32)) -- 红点Id的位数计算（与服务端对应，long，前四位记录类型，后四位则是任意类型配置的Id）

-- 需要特殊处理显示逻辑的周常Id
local TipIndexByMainId = {
    [1003] = true, -- 幻痛囚笼
}


function XUiGridWheelchairManualGuide:OnStart()
    self.Reward.gameObject:SetActiveEx(false)
end

function XUiGridWheelchairManualGuide:OnDisable()
    if not XTool.IsTableEmpty(self._TagGrids) then
        for i, v in pairs(self._TagGrids) do
            v:Close()
        end
    end
end

function XUiGridWheelchairManualGuide:Refresh(data)
    self.ViewData = data

    --刷新背景、名称
    self.ImgBg:SetRawImage(self.ViewData:GetActivityIcon())
    self.TxtName.text = self.ViewData:GetName()

    if self._TagGrids == nil then
        self._TagGrids = {}
    end

    -- 刷新标签
    if self._TagGrid == nil then
        self._TagGrid = XUiGridWheelchairManualGuideTag.New(self.PanelTag, self)
    end

    local kindId = self.ViewData:GetKindId()
    if XTool.IsNumberValid(kindId) then
        self._TagGrid:Open()
        self._TagGrid:Refresh(kindId)
    else
        self._TagGrid:Close()
    end

    -- 刷新完成情况
    self:RefreshActivityIsComplete()
    
    -- 刷新活动时间
    self:RefreshTime()

    -- 刷新道具获取进度
    self:RefreshRewards()
    
    self:RefreshReddot()
end

function XUiGridWheelchairManualGuide:RefreshActivityIsComplete()
    local isComplete = self._Control:CheckGuideActivityIsFinishedByData(self.ViewData)

    if not self.ViewData:IsTimelimitActivity() then
        local mainId = self.ViewData:GetMainId()
        if self._Control:CheckWeekIsShowTips(mainId) and TipIndexByMainId[mainId] then
            -- 当需要有特殊显示时，不需要显示完成
            isComplete = false
        end
    end

    self.PanelComplete.gameObject:SetActiveEx(isComplete)
end

function XUiGridWheelchairManualGuide:RefreshTime()
    if self.ViewData:IsTimelimitActivity() then
        self:_RefreshTimelimitActivityTime()
    else
        self:_RefreshWeekActivityTime()
    end
end

function XUiGridWheelchairManualGuide:_RefreshTimelimitActivityTime()
    -- 刷新剩余时间
    local timeId = self.ViewData:GetTotalTimeId()
    local timeStr = ''
    
    local isHideTime = self.ViewData:GetIsHideTime()

    if not isHideTime and XTool.IsNumberValid(timeId) then
        local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
        local now = XTime.GetServerNowTimestamp()

        local leftTime = endTime - now

        if leftTime < 0 then
            leftTime = 0
        end

        timeStr =XUiHelper.FormatText(XMVCA.XWheelchairManual:GetWheelchairManualConfigString('GuideActivityTimeLabel'), XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY))
    end

    self.TxtTime.text = timeStr
end

function XUiGridWheelchairManualGuide:_RefreshWeekActivityTime()
    self.TxtTime.text = self._Control:GetWeekRemainingTimeDesc(self.ViewData:GetMainId())
end

function XUiGridWheelchairManualGuide:RefreshRewards()
    -- 隐藏之前的显示
    if not XTool.IsTableEmpty(self._RewardGrids) then
        for i, v in pairs(self._RewardGrids) do
            v.GameObject:SetActiveEx(false)
        end
    end
    
    if self.ViewData:IsTimelimitActivity() then
        -- 获取当前活动的期数
        local periodId = self._Control:GetTimelimitActivityCurPeriodId(self.ViewData)

        if XTool.IsNumberValid(periodId) then
            local templateIds, templateCounts = self._Control:GetPeriodTemplatesAndCount(periodId)

            if not XTool.IsTableEmpty(templateIds) and not XTool.IsTableEmpty(templateCounts) then
                self:_RefreshRewards(self.ViewData:GetReceiveTemplateCounts(periodId), templateIds, templateCounts)
            end
        end
    else
        local templateIds, templateCounts = self._Control:GetWeekActivityTemplatesAndCount(self.ViewData)
        local isShowReceiveCount = self:CheckIsShowReceiveCount()

        if not XTool.IsTableEmpty(templateIds) and not XTool.IsTableEmpty(templateCounts) then
            local recieveCountMap = self.ViewData:GetWeekActivityReceiveTemplateCounts()
            -- 如果需要特殊显示，目前的逻辑是当前进度清0
            local mainId = self.ViewData:GetMainId()
            if not XTool.IsTableEmpty(recieveCountMap) and self._Control:CheckWeekIsShowTips(mainId) and TipIndexByMainId[mainId] then
                for i, id in pairs(templateIds) do
                    if recieveCountMap[id] then
                        recieveCountMap[id] = 0
                    end
                end
            end
            
            self:_RefreshRewards(recieveCountMap, templateIds, templateCounts, isShowReceiveCount)
        end
    end
end

function XUiGridWheelchairManualGuide:_RefreshRewards(templateCountMap, templateIds, templateCounts, isShowReceiveCount)
    if self._RewardGrids == nil then
        self._RewardGrids = {}
    end

    isShowReceiveCount = isShowReceiveCount == nil and true or isShowReceiveCount
    
    XUiHelper.RefreshCustomizedList(self.Reward.transform.parent, self.Reward, templateIds and #templateIds or 0, function(index, go)
        ---@type XUiGridCommon
        local grid = self._RewardGrids[go]

        if not grid then
            grid = XUiGridCommon.New(nil, go)
            self._RewardGrids[go] = grid
        end
        local templateId = templateIds[index]
        grid.GameObject:SetActiveEx(true)
        grid:Refresh(templateId)
        
        local currentCount = (XTool.IsTableEmpty(templateCountMap) or not XTool.IsNumberValid(templateCountMap[templateId])) and 0 or templateCountMap[templateId]

        if XTool.IsNumberValid(templateCounts[index]) then
            local processContent = XUiHelper.FormatText(XMVCA.XWheelchairManual:GetWheelchairManualConfigString('ActivityGuideProcessLabel'), currentCount, templateCounts[index])
            grid.TxtNum.text = processContent
        else
            isShowReceiveCount = false
            grid.TxtNum.text = ''
        end

        if isShowReceiveCount then
            grid:SetReceived(currentCount >= templateCounts[index])
        else
            grid:SetReceived(false)
        end
    end)
end

function XUiGridWheelchairManualGuide:RefreshReddot()
    local skipId = self.ViewData:GetSkipId()

    if XTool.IsNumberValid(skipId) then
        if XFunctionManager.IsCanSkip(skipId) then
            local id = self.ViewData:IsTimelimitActivity() and self.ViewData:GetId() or self.ViewData:GetMainId()
            local reddotId = XEnumConst.WheelchairManual.TabType.Guide * ReddotIdMartix + id

            self.RedPoint.gameObject:SetActiveEx(XMVCA.XWheelchairManual:CheckNewUnlockReddotIsShow(reddotId))
            
            return
        end
    end
    self.RedPoint.gameObject:SetActiveEx(false)
end

function XUiGridWheelchairManualGuide:OnClick()
    local skipId = self.ViewData:GetSkipId()

    if XTool.IsNumberValid(skipId) then
        if XFunctionManager.IsCanSkip(skipId) then
            XFunctionManager.SkipInterface(skipId)

            -- 尝试消除存在的红点
            local id = self.ViewData:IsTimelimitActivity() and self.ViewData:GetId() or self.ViewData:GetMainId()
            local reddotId = XEnumConst.WheelchairManual.TabType.Guide * ReddotIdMartix + id

            if XMVCA.XWheelchairManual:SetNewUnlockReddotIsOld(reddotId) then
                self:RefreshReddot()
                XEventManager.DispatchEvent(XEventId.EVENT_WHEELCHAIRMANUAL_REFRESH_TABS_REDDOT)
            end
        else
            local skipCfg = XFunctionConfig.GetSkipFuncCfg(skipId)
            if skipCfg and XTool.IsNumberValid(skipCfg.FunctionalId) then
                local desc = XFunctionManager.GetFunctionOpenCondition(skipCfg.FunctionalId)
                XUiManager.TipMsg(desc)
            end
        end
    end
end

-- 检查是否显示领取的数量
function XUiGridWheelchairManualGuide:CheckIsShowReceiveCount()
    if not self.ViewData:IsTimelimitActivity() then
        return self._Control:CheckWeekIsShowReceiveCount(self.ViewData:GetMainId())
    end
    return true
end

function XUiGridWheelchairManualGuide:SetRootCanvasGroupAlpha(alpha)
    if self.CanvasGroup then
        self.CanvasGroup.alpha = alpha
    end
end

return XUiGridWheelchairManualGuide
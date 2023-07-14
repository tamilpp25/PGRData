local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate
local tableInsert = table.insert
local CSXTextManagerGetText = CS.XTextManager.GetText
local CSXScheduleManagerUnSchedule = XScheduleManager.UnSchedule

local XUiMoeWarPreparationStageGrid = require("XUi/XUiMoeWar/Preparation/XUiMoeWarPreparationStageGrid")
local XUiMoeWarPreparationRewardGrid = require("XUi/XUiMoeWar/Preparation/XUiMoeWarPreparationRewardGrid")
local XUiMoeWarPreparationBtnTab = require("XUi/XUiMoeWar/Preparation/XUiMoeWarPreparationBtnTab")

--赛事筹备
local XUiMoeWarPreparation = XLuaUiManager.Register(XLuaUi, "UiMoeWarPreparation")

function XUiMoeWarPreparation:OnAwake()
    self:InitParamater()
    self:InitCourseHeadPositionX()
    self:AutoAddListener()
    self:InitDynamicTable()
    self:InitAssetPanel()
    self:InitRedPoint()
    self:AddCoinListener()
end

function XUiMoeWarPreparation:OnStart()
    self:InitPercentRewardGrid()
    self:InitPanelTab()
    self:RefreshAssetPanel()
end

function XUiMoeWarPreparation:OnEnable()
    self:PlayAnimation("AnimaOpen")
    self:Refresh()
    self:StartTimer()
    self:CheckPreparationActivityIsOpen()
    XDataCenter.MoeWarManager.JudgeGotoMainWhenFightOver()
end

function XUiMoeWarPreparation:OnDisable()
    self:StopTimer()
    self:StopTweenTimer()
    self:StopRefreshStageGridsTimer()
end

function XUiMoeWarPreparation:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    self:RegisterClickEvent(self.BtnRecruit, self.OnBtnRecruitClick)
    self:RegisterClickEvent(self.BtnSupport, self.OnBtnSupportClick)
    self:BindHelpBtn(self.BtnHelp, "MoeWar")
end

function XUiMoeWarPreparation:OnGetEvents()
    return {
        XEventId.EVENT_MOE_WAR_PREPARATION_UPDATE,
        XEventId.EVENT_MOE_WAR_PREPARATION_DAILY_RESET,
    }
end

function XUiMoeWarPreparation:OnNotify(event, ...)
    if event == XEventId.EVENT_MOE_WAR_PREPARATION_UPDATE then
        self:Refresh()
    elseif event == XEventId.EVENT_MOE_WAR_PREPARATION_DAILY_RESET then
        self:Refresh()
    end
end

function XUiMoeWarPreparation:AddCoinListener()
    local itemId = XDataCenter.ItemManager.ItemId.MoeWarPreparationItemId
    XDataCenter.ItemManager.AddCountUpdateListener(itemId, function()
        self:RefreshPercent()
        self:UpdatePanelPhasesReward()
    end, self.TxtPoint)
end

function XUiMoeWarPreparation:InitRedPoint()
    XRedPointManager.AddRedPointEvent(self.BtnRecruit,
        self.OnRedPointEvent, self,
        { XRedPointConditions.Types.CONDITION_MOEWAR_RECRUIT })
end

function XUiMoeWarPreparation:InitAssetPanel()
    if not self.PanelSpecialTool then
        return
    end
    local actInfo = XDataCenter.MoeWarManager.GetActivityInfo()
    local currencyIdList = actInfo and actInfo.CurrencyId or {}
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool)

    XDataCenter.ItemManager.AddCountUpdateListener(currencyIdList, function()
        self.AssetActivityPanel:Refresh(currencyIdList)
    end, self.AssetActivityPanel)
end

function XUiMoeWarPreparation:OnRedPointEvent(count)
    self.BtnRecruit:ShowReddot(count >= 0)
end

function XUiMoeWarPreparation:RefreshAssetPanel()
    if not self.AssetActivityPanel then
        return
    end
    local actInfo = XDataCenter.MoeWarManager.GetActivityInfo()
    local currencyIdList = actInfo and actInfo.CurrencyId or {}
    self.AssetActivityPanel:Refresh(currencyIdList)
end

function XUiMoeWarPreparation:InitCourseHeadPositionX()
    if not self.PreparationActivityId then return end

    self.CourseHeadPosition = self.CourseHead.transform.localPosition
    self.CurrPanelCoursePercent = 0
    self.PreHavePreparationItemCount = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.MoeWarPreparationItemId)
end

function XUiMoeWarPreparation:InitPercentRewardGrid()
    self.ActiveProgressRect = self.PanelPassedLine:GetComponent("RectTransform")
    if not self.PreparationActivityId then return end

    self.PercentRewardGrids = {}
    self.PercentRewardGridRects = {}
    local UpdatePanelPhasesRewardCb = function()
        self:UpdatePanelPhasesReward()
    end

    local gears = XMoeWarConfig.GetPreparationActivityPreparationGears(self.PreparationActivityId)
    for i, gearId in ipairs(gears) do
        local obj = i == 1 and self.GridCourse or CSUnityEngineObjectInstantiate(self.GridCourse, self.PanelGridCourse)
        local grid = XUiMoeWarPreparationRewardGrid.New(obj, UpdatePanelPhasesRewardCb, gearId, self)
        self.PercentRewardGrids[i] = grid
        self.PercentRewardGridRects[i] = grid.Transform:GetComponent("RectTransform")
    end

    -- 自适应调整
    self.OriginPosition = self.PercentRewardGrids[1] and self.PercentRewardGrids[1].Transform.localPosition
end

function XUiMoeWarPreparation:UpdatePanelPhasesReward()
    if not self.PreparationActivityId or XTool.UObjIsNil(self.ActiveProgressRect) then
        return
    end

    local activeProgressRectSize = self.ActiveProgressRect.rect.size
    local haveCount = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.MoeWarPreparationItemId)
    local maxCount = XMoeWarConfig.GetPreparationGearMaxNeedCount(self.PreparationActivityId)
    local percent = maxCount > 0 and math.min(haveCount / maxCount, 1) or 0
    local headWidth = self.CourseHead.sizeDelta.x * 0.6
    local headPos = CS.UnityEngine.Vector3(activeProgressRectSize.x * percent + headWidth, self.CourseHeadPosition.y, self.CourseHeadPosition.z)
    local percentRewardGridsCount = #self.PercentRewardGrids

    -- 自适应
    for i = 1, percentRewardGridsCount do
        local grid = self.PercentRewardGrids[i]
        if grid then
            local gearId = grid:GetGearId()
            local itemWidth = self.PercentRewardGridRects[i].sizeDelta.x / 2
            local needCount = gearId and XMoeWarConfig.GetPreparationGearNeedCount(gearId) or 0
            local rewardPercent = maxCount > 0 and needCount / maxCount or 0
            local adjustPosition = CS.UnityEngine.Vector3(activeProgressRectSize.x * rewardPercent + itemWidth, self.OriginPosition.y, self.OriginPosition.z)
            self.PercentRewardGridRects[i].anchoredPosition3D = adjustPosition
        end
    end

    self:RefreshPercentRewardGrids()

    if self.CurrPanelCoursePercent ~= percent then
        self.CourseHead.gameObject:SetActiveEx(true)
        self.CurrPanelCoursePercent = percent
        self:PlayHeadPercentMoveAnima(headPos, percent)
    else
        self.CourseHead.anchoredPosition3D = headPos
        self.PanelPassedLine.fillAmount = percent
        self.CourseHead.gameObject:SetActiveEx(haveCount == 0)
    end
end

function XUiMoeWarPreparation:RefreshPercentRewardGrids()
    if XTool.UObjIsNil(self.GameObject) then
        return
    end
    for _, grid in ipairs(self.PercentRewardGrids) do
        grid:Refresh()
    end
end

function XUiMoeWarPreparation:PlayHeadPercentMoveAnima(endHeadPos, percent)
    local headMoveAnimaTime = CS.XGame.ClientConfig:GetFloat("MoeWarPreparaHeadMoveAnimaTime")
    local startPositionX = self.CourseHead.anchoredPosition3D.x
    local pointDifference = endHeadPos.x - startPositionX
    local haveCount = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.MoeWarPreparationItemId)
    local preHaveCount = self.PreHavePreparationItemCount
    self.PreHavePreparationItemCount = haveCount
    if preHaveCount ~= 0 then
        self:PlayAnimation("CourseHeadEnable")
    end

    local currFillAmount = self.PanelPassedLine.fillAmount
    local fillAmountDifference = percent - currFillAmount

    self:StopTweenTimer()
    self.TweenTimer = XUiHelper.Tween(headMoveAnimaTime, function(f)
        if XTool.UObjIsNil(self.Transform) then
            return
        end
        self.PanelPassedLine.fillAmount = currFillAmount + f * fillAmountDifference
        self.CourseHead.anchoredPosition3D = CS.UnityEngine.Vector3(startPositionX + f * pointDifference, endHeadPos.y, endHeadPos.z)
    end, function ()
        if haveCount > 0 then
            self:PlayAnimation("CourseHeadDisable")
        end
        self:RefreshPercentRewardGrids()
    end)
end

function XUiMoeWarPreparation:StopTweenTimer()
    if self.TweenTimer then
        CSXScheduleManagerUnSchedule(self.TweenTimer)
        self.TweenTimer = nil
    end
end

function XUiMoeWarPreparation:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiMoeWarPreparationStageGrid, self)
    self.GridShop.gameObject:SetActiveEx(false)
end

function XUiMoeWarPreparation:InitParamater()
    self.PreparationActivityId = XMoeWarConfig.GetPreparationActivityIdInTime()
    if not self.PreparationActivityId then return end

    local timeId = XMoeWarConfig.GetPreparationActivityTimeId(self.PreparationActivityId)
    self.PreparationActivityEndTime = XFunctionManager.GetEndTimeByTimeId(timeId)

    if self.TxtTitle then
        self.TxtTitle.text = XMoeWarConfig.GetPreparationActivityName(self.PreparationActivityId)
    end
end

function XUiMoeWarPreparation:CheckPreparationActivityIsOpen()
    if not self.PreparationActivityId then
        self:Close()
    end
end

function XUiMoeWarPreparation:InitPanelTab()
    if not self.PreparationActivityId then return end

    self.TabBtns = {}
    local matchIds = XMoeWarConfig.GetPreparationActivityMatchIds(self.PreparationActivityId)
    local tabBtn
    for index, matchId in ipairs(matchIds) do
        tabBtn = XTool.IsTableEmpty(self.TabBtns) and self.BtnFirst or CSUnityEngineObjectInstantiate(self.BtnFirst, self.TabBtnContent)
        self.TabBtns[index] = XUiMoeWarPreparationBtnTab.New(tabBtn, matchId)
    end
end

function XUiMoeWarPreparation:StartTimer()
    self:StopTimer()
    self.Timer = XScheduleManager.ScheduleForever(function()
        self:RefreshTabBtnTime()
    end, XScheduleManager.SECOND)
end

function XUiMoeWarPreparation:CheckStartRefreshStageGridsTimer()
    self:StopRefreshStageGridsTimer()

    if XTool.IsTableEmpty(self.Stages) or not self.PreparationActivityId then
        return
    end

    local currOpenStageCount = XDataCenter.MoeWarManager.GetPreparationAllOpenStageCount()
    local maxStageCount = XMoeWarConfig.GetPreparationActivityMaxStageCount(self.PreparationActivityId)
    if maxStageCount == currOpenStageCount then
        return
    end

    self.RefreshStageGridsTimer = XScheduleManager.ScheduleForever(function()
        self:CheckRefreshStageGrids()
    end, XScheduleManager.SECOND)
end

function XUiMoeWarPreparation:CheckRefreshStageGrids()
    local stages = self.Stages
    local lastStageIndex = #stages
    local nowServerTime = XTime.GetServerNowTimestamp()
    local reserveTime = XDataCenter.MoeWarManager.GetReserveStageTimeByIndex(lastStageIndex)
    if nowServerTime >= reserveTime then
        self:RefreshStage()
    end
end

function XUiMoeWarPreparation:StopRefreshStageGridsTimer()
    if self.RefreshStageGridsTimer then
        XScheduleManager.UnSchedule(self.RefreshStageGridsTimer)
        self.RefreshStageGridsTimer = nil
    end
end

function XUiMoeWarPreparation:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiMoeWarPreparation:Refresh()
    self:RefreshTabBtnTime()
    self:RefreshStage()
    self:RefreshPercent()
    self:RefreshAndCheckActivityTime()
    XScheduleManager.ScheduleOnce(handler(self, self.UpdatePanelPhasesReward), 1)   --异形屏适配需要
end

function XUiMoeWarPreparation:RefreshPercent()
    local itemId = XDataCenter.ItemManager.ItemId.MoeWarPreparationItemId
    local name = XDataCenter.ItemManager.GetItemName(itemId)
    self.TxtPoint.text = XDataCenter.ItemManager.GetCount(itemId)
    self.TextPointTitle.text = CSXTextManagerGetText("MoeWarGrandTotal", name)
end

function XUiMoeWarPreparation:RefreshStage()
    if not self.PreparationActivityId then return end

    self.Stages = XDataCenter.MoeWarManager.GetStagesAndOneReserveStage()
    local maxStageCount = XMoeWarConfig.GetPreparationActivityMaxStageCount(self.PreparationActivityId)
    local currOpenStageCount = XDataCenter.MoeWarManager.GetPreparationAllOpenStageCount()
    self.TxtNum.text = CSXTextManagerGetText("MoeWarPreparationCount", currOpenStageCount, maxStageCount)

    self.DynamicTable:SetDataSource(self.Stages)
    self.DynamicTable:ReloadDataSync()

    self:CheckStartRefreshStageGridsTimer()
end

function XUiMoeWarPreparation:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local stageId = self.Stages[index]
        grid:Refresh(stageId, index)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:Delete()
    end
end

function XUiMoeWarPreparation:RefreshTabBtnTime()
    if not self.PreparationActivityId or XTool.UObjIsNil(self.GameObject) then
        return
    end

    for _, tabBtn in ipairs(self.TabBtns) do
        tabBtn:Refresh()
    end
end

function XUiMoeWarPreparation:RefreshAndCheckActivityTime()
    local nowServerTime = XTime.GetServerNowTimestamp()
    local lastTime = self.PreparationActivityEndTime and self.PreparationActivityEndTime - nowServerTime or 0
    if lastTime <= 0 then
        self:StopTimer()
        self:Close()
        return
    end

    self.TxtTime.text = XUiHelper.GetTime(self.PreparationActivityEndTime - nowServerTime, XUiHelper.TimeFormatType.ACTIVITY)
end

function XUiMoeWarPreparation:OnBtnRecruitClick()
    XLuaUiManager.Open("UiMoeWarRecruit")
end

function XUiMoeWarPreparation:OnBtnSupportClick()
    XLuaUiManager.Open("UiMoeWarSupport")
end
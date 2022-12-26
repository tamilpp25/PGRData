local XUiGridKillZoneStage = require("XUi/XUiKillZone/XUiGridKillZoneStage")
local XUiGridKillZonePluginSlot = require("XUi/XUiKillZone/XUiGridKillZonePluginSlot")

local CsXTextManagerGetText = CsXTextManagerGetText

local XUiKillZoneMain = XLuaUiManager.Register(XLuaUi, "UiKillZoneMain")

function XUiKillZoneMain:OnAwake()
    self:AutoAddListener()

    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool)
    XDataCenter.ItemManager.AddCountUpdateListener(
    {
        XDataCenter.ItemManager.ItemId.Coin,
        XKillZoneConfigs.ItemIdCoinA,
        XKillZoneConfigs.ItemIdCoinB,
    }, handler(self, self.UpdateAssets), self.AssetActivityPanel)

    self.GridStage.gameObject:SetActiveEx(false)
    self.PanelTxtRewardTime.gameObject:SetActiveEx(false)
    self.BtnSwitchNormal:ShowReddot(false)
end

function XUiKillZoneMain:OnStart()
    self.Diff, self.ChapterId = XDataCenter.KillZoneManager.GetCookieDiffAndChapterId()
    if not self.Diff then
        self.Diff = XKillZoneConfigs.Difficult.Normal
    end

    self.TabBtns = {}
    self.StageGrids = {}
    self.PluginSlotGrids = {}

    self:InitView()
end

function XUiKillZoneMain:OnEnable()
    if self.IsEnd then return end
    if XDataCenter.KillZoneManager.OnActivityEnd() then
        self.IsEnd = true
        return
    end

    self:UpdateAssets()
    self:UpdateDiff()
    self:UpdateLeftTime()
    self:UpdateFarmRewards()
    self:UpdatePlugins()
end

function XUiKillZoneMain:OnDisable()
    XCountDown.UnBindTimer(self, XCountDown.GTimerName.KillZone)
end

function XUiKillZoneMain:OnGetEvents()
    return {
        XEventId.EVENT_KILLZONE_FARM_REWARD_OBTAIN_COUNT_CHANGE,
        XEventId.EVENT_KILLZONE_STAR_REWARD_OBTAIN_RECORD_CHANGE,
        XEventId.EVENT_KILLZONE_STAGE_CHANGE,
        XEventId.EVENT_KILLZONE_ACTIVITY_END,
    }
end

function XUiKillZoneMain:OnNotify(evt, ...)
    if self.IsEnd then return end

    local args = { ... }
    if evt == XEventId.EVENT_KILLZONE_FARM_REWARD_OBTAIN_COUNT_CHANGE then
        self:UpdateFarmRewards()
    elseif evt == XEventId.EVENT_KILLZONE_STAR_REWARD_OBTAIN_RECORD_CHANGE then
        self:UpdateStarRewards()
    elseif evt == XEventId.EVENT_KILLZONE_STAGE_CHANGE then
        self:UpdateStages()
    elseif evt == XEventId.EVENT_KILLZONE_ACTIVITY_END then
        if XDataCenter.KillZoneManager.OnActivityEnd() then
            self.IsEnd = true
            return
        end
    end
end

function XUiKillZoneMain:InitView()
    self.TxtTitleName.text = XDataCenter.KillZoneManager.GetActivityName()
end

function XUiKillZoneMain:UpdateAssets()
    self.AssetActivityPanel:Refresh({
        XDataCenter.ItemManager.ItemId.Coin,
        XKillZoneConfigs.ItemIdCoinA,
        XKillZoneConfigs.ItemIdCoinB,
    })
end

function XUiKillZoneMain:UpdateDiff()
    if self.Diff == XKillZoneConfigs.Difficult.Normal then
        local isLock = not XDataCenter.KillZoneManager.IsDiffHardUnlock()
        self.BtnSwitchHard:SetDisable(isLock)

        XRedPointManager.AddRedPointEvent(self.BtnSwitchHard, function(_, count)
            self.BtnSwitchHard:ShowReddot(count >= 0)
        end, self, { XRedPointConditions.Types.XRedPointConditionKillZoneNewDiff })

        self.BtnSwitchNormal.gameObject:SetActiveEx(false)
        self.BtnSwitchHard.gameObject:SetActiveEx(true)
        self.PanelTabChapterGroup.gameObject:SetActiveEx(true)
    elseif self.Diff == XKillZoneConfigs.Difficult.Hard then
        self.BtnSwitchNormal.gameObject:SetActiveEx(true)
        self.BtnSwitchHard.gameObject:SetActiveEx(false)
        self.PanelTabChapterGroup.gameObject:SetActiveEx(false)

        XDataCenter.KillZoneManager.SetCookieNewDiffClicked(self.ChapterId)
    end

    self:UpdateChapters()
end

function XUiKillZoneMain:UpdateChapters()
    self.ChapterIds = XDataCenter.KillZoneManager.GetChapterIds(self.Diff)

    local firstUnlockIndex, selectIndex

    for index, chapterId in ipairs(self.ChapterIds) do
        local btn = self.TabBtns[index]
        if not btn then
            local go = index == 1 and self.BtnChapter.gameObject or CS.UnityEngine.Object.Instantiate(self.BtnChapter.gameObject, self.PanelTabChapterGroup.transform)
            btn = go:GetComponent("XUiButton")
            self.TabBtns[index] = btn
        end

        local isLock = not XDataCenter.KillZoneManager.IsChapterUnlock(chapterId)
        btn:SetDisable(isLock)

        local name = XKillZoneConfigs.GetChapterName(chapterId)
        btn:SetNameByGroup(0, name)

        if not isLock then
            firstUnlockIndex = firstUnlockIndex or index
            if chapterId == self.ChapterId then
                selectIndex = index
            end

            btn:SetNameByGroup(1, "")
        else
            local leftTime = XDataCenter.KillZoneManager.GetChpaterOpenLeftTime(chapterId)
            btn:SetNameByGroup(1, CsXTextManagerGetText("KillZoneChapterLeftTime", XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)))
        end

        local isFinished = XDataCenter.KillZoneManager.IsChpaterFinished(chapterId)
        btn:ShowTag(isFinished)

        XRedPointManager.AddRedPointEvent(btn, function(_, count)
            btn:ShowReddot(count >= 0)
        end, self, { XRedPointConditions.Types.XRedPointConditionKillZoneNewChapter }, chapterId)

        btn.gameObject:SetActiveEx(true)
    end

    for index = #self.ChapterIds + 1, #self.TabBtns do
        self.TabBtns[index].gameObject:SetActiveEx(false)
    end

    selectIndex = selectIndex or firstUnlockIndex
    if not selectIndex then
        XLog.Error("XUiKillZoneMain:UpdateChapters error:默认选中的章节（上次挑战过/普通区域第一关）未处于开放时间,请检查配置：" .. XKillZoneConfigs.GetChapterConfigPath())
        return
    end

    self.PanelTabChapterGroup:Init(self.TabBtns, function(tabIndex) self:OnClickTabCallBack(tabIndex) end)
    self.PanelTabChapterGroup:SelectIndex(selectIndex)
end

function XUiKillZoneMain:OnClickTabCallBack(tabIndex)
    local chapterId = self.ChapterIds[tabIndex]

    local isLock = not XDataCenter.KillZoneManager.IsChapterUnlock(chapterId)
    if isLock then
        local leftTime = XDataCenter.KillZoneManager.GetChpaterOpenLeftTime(chapterId)
        local msg = CsXTextManagerGetText("KillZoneChapterUnlockLeftTime", XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY))
        XUiManager.TipMsg(msg)
        return
    end

    self.ChapterId = chapterId

    self:UpdateChapter()

    XDataCenter.KillZoneManager.SetCookieNewChapterClicked(chapterId)
    XDataCenter.KillZoneManager.SetCookieDiffAndChapterId(self.Diff, self.ChapterId)

    self:PlayAnimationWithMask("QieHuan1")
end

function XUiKillZoneMain:UpdateChapter()
    local chapterId = self.ChapterId

    local bg = XKillZoneConfigs.GetChapterBg(chapterId)
    self.RImgBg:SetRawImage(bg)

    self:UpdateStages()
end

function XUiKillZoneMain:UpdateStages()
    local chapterId = self.ChapterId

    local stageIds = XKillZoneConfigs.GetChapterStageIds(chapterId)
    self.StageIds = stageIds
    for index, stageId in pairs(stageIds) do
        local grid = self.StageGrids[index]
        if not grid then
            local go = CS.UnityEngine.Object.Instantiate(self.GridStage.gameObject, self.PanelStage)
            local clickCb = handler(self, self.OnClickStage)
            grid = XUiGridKillZoneStage.New(go, clickCb)
            self.StageGrids[index] = grid
        end

        grid:Refresh(stageId)
        grid.GameObject:SetActiveEx(true)
    end
    for index = #stageIds + 1, #self.StageGrids do
        self.StageGrids[index].GameObject:SetActiveEx(false)
    end

    self:UpdateStarRewards()
end

function XUiKillZoneMain:OnClickStage(stageId)
    local isLock = not XDataCenter.KillZoneManager.IsStageUnlock(stageId)
    if isLock then
        local preStageId = XKillZoneConfigs.GetStagePreStageId(stageId)
        local stageName = XKillZoneConfigs.GetStageName(preStageId)
        local msg = CsXTextManagerGetText("KillZoneStageUnlockTip", stageName)
        XUiManager.TipMsg(msg)
        return
    end

    local gridStageId
    for index, grid in pairs(self.StageGrids) do
        gridStageId = self.StageIds[index]
        grid:SetSelect(gridStageId == stageId)
    end

    local closeCb = function()
        for _, grid in pairs(self.StageGrids) do
            grid:SetSelect(false)
        end
    end
    XLuaUiManager.Open("UiKillZoneStageDetail", stageId, closeCb)
end

function XUiKillZoneMain:UpdateLeftTime()
    XCountDown.UnBindTimer(self, XCountDown.GTimerName.KillZone)
    XCountDown.BindTimer(self, XCountDown.GTimerName.KillZone, function(time)
        time = time > 0 and time or 0
        local timeText = XUiHelper.GetTime(time, XUiHelper.TimeFormatType.KillZone)
        self.TxtLeftTime.text = timeText
    end)
end

function XUiKillZoneMain:UpdateFarmRewards()
    local leftCount = XDataCenter.KillZoneManager.GetLeftFarmRewardObtainCount()
    self.TxtChllengeRewardTime.text = leftCount
end

function XUiKillZoneMain:UpdateStarRewards()
    local diff = self.Diff
    self.TxtDescDiff.text = XKillZoneConfigs.GetStarRewardTitleByDiff(diff)

    local star, maxStar = XDataCenter.KillZoneManager.GetTotalStageStarByDiff(diff)
    self.TxtStarNum.text = CsXTextManagerGetText("KillZoneTotalStarProcess", star, maxStar)
    self.ImgJindu.fillAmount = maxStar == 0 and 0 or star / maxStar
    self.ImgLingqu.gameObject:SetActiveEx(XDataCenter.KillZoneManager.IsStarRewardObtainedByDiff(diff))

    XRedPointManager.AddRedPointEvent(self.ImgRedProgress, function(_, count)
        self.ImgRedProgress.gameObject:SetActiveEx(count >= 0)
    end, self, { XRedPointConditions.Types.XRedPointConditionKillZoneStarReward }, diff)

    XRedPointManager.AddRedPointEvent(self.BtnDailyReward, function(_, count)
        self.BtnDailyReward:ShowReddot(count >= 0)
    end, self, { XRedPointConditions.Types.XRedPointConditionKillZoneDailyStarReward })
end

function XUiKillZoneMain:UpdatePlugins()
    local maxSlotNum = XKillZoneConfigs.GetMaxPluginSlotNum()
    for index = 1, maxSlotNum do
        local grid = self.PluginSlotGrids[index]
        if not grid then
            local go = index == 1 and self.GridPlugin or CS.UnityEngine.Object.Instantiate(self.GridPlugin, self.PanelPlugin)
            local clickCb = handler(self, self.OnClickPluginSlot)
            grid = XUiGridKillZonePluginSlot.New(go, clickCb)
            self.PluginSlotGrids[index] = grid
        end

        grid:Refresh(index)
        grid:SetSelect(self.SelectSlot == index)

        grid.GameObject:SetActiveEx(true)
    end

    XRedPointManager.AddRedPointEvent(self.BtnPlugin, function(_, count)
        self.BtnPlugin:ShowReddot(count >= 0)
    end, self, { XRedPointConditions.Types.XRedPointConditionKillZonePluginOperate })
end

function XUiKillZoneMain:OnClickPluginSlot(slot)
    local isLock = not XDataCenter.KillZoneManager.IsPluginSlotUnlock(slot)
    if isLock then
        local msg = XKillZoneConfigs.GetPluginSlotConditionDesc(slot)
        XUiManager.TipMsg(msg)
    else
        local pluginId = XDataCenter.KillZoneManager.GetSlotWearingPluginId(slot)
        if XTool.IsNumberValid(pluginId) then
            self.SelectSlot = slot
            for index, grid in pairs(self.PluginSlotGrids) do
                grid:SetSelect(self.SelectSlot == index)
            end
            local closeCb = function()
                self.SelectSlot = nil
                for index, grid in pairs(self.PluginSlotGrids) do
                    grid:SetSelect(self.SelectSlot == index)
                end
            end
            XLuaUiManager.Open("UiKillZonePluginPopup", slot, pluginId, true, closeCb, nil, true)
        else
            XUiManager.TipText("KillZoneSelectPlguinEmpty")
        end
    end
end

function XUiKillZoneMain:AutoAddListener()
    self:BindHelpBtn(self.BtnHelp, "KillZoneMain")
    self.BtnBack.CallBack = function() self:OnClickBtnBack() end
    self.BtnMainUi.CallBack = function() self:OnClickBtnMainUi() end
    self.BtnPlugin.CallBack = function() self:OnClickBtnPlugin() end
    self.BtnSwitchHard.CallBack = function() self:SelectDiff(XKillZoneConfigs.Difficult.Hard) end
    self.BtnSwitchNormal.CallBack = function() self:SelectDiff(XKillZoneConfigs.Difficult.Normal) end
    self.BtnTreasure.CallBack = function() self:OnClickBtnTreasure() end
    self.BtnChllengeRewardHelp.CallBack = function() self:OnBtnChllengeRewardHelpClick() end
    self.BtnDailyReward.CallBack = function() self:OnClickBtnDailyReward() end
end

function XUiKillZoneMain:OnClickBtnDailyReward()
    XLuaUiManager.Open("UiKillZoneDaily")
end

function XUiKillZoneMain:OnClickBtnBack()
    self:Close()
end

function XUiKillZoneMain:OnClickBtnMainUi()
    XLuaUiManager.RunMain()
end

function XUiKillZoneMain:OnClickBtnPlugin()
    XLuaUiManager.Open("UiKillZonePlugin")
end

function XUiKillZoneMain:OnClickBtnTreasure()
    XLuaUiManager.Open("UiKillZoneReward", self.Diff)
end

function XUiKillZoneMain:OnBtnChllengeRewardHelpClick()
    local title = CsXTextManagerGetText("KillZoneFarmRewardTipTitle")
    local content = XUiHelper.ConvertLineBreakSymbol(CsXTextManagerGetText("KillZoneFarmRewardTipContent"))
    XUiManager.UiFubenDialogTip(title, content)
end

function XUiKillZoneMain:SelectDiff(diff)
    if diff == XKillZoneConfigs.Difficult.Hard then
        local isUnlock, preStageId = XDataCenter.KillZoneManager.IsDiffHardUnlock()
        if not isUnlock then
            local chapterId = XKillZoneConfigs.GetChapterIdByStageId(preStageId)
            local msg = CsXTextManagerGetText("KillZoneDiffHardLockTip"
            , XKillZoneConfigs.GetChapterName(chapterId)
            , XKillZoneConfigs.GetStageName(preStageId)
            )
            XUiManager.TipMsg(msg)
            return
        end
        self:PlayAnimationWithMask("QieHuan2")
    else
        self:PlayAnimationWithMask("AnimEnable")
    end

    self.Diff = diff
    self:UpdateDiff()
end
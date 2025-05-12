local XUiSameColorBossGrid = require("XUi/XUiSameColorGame/Main/XUiSameColorBossGrid")

---@class XUiSameColorGameBossMain:XLuaUi
---@field _Control XSameColorControl
local XUiSameColorGameBossMain = XLuaUiManager.Register(XLuaUi, "UiSameColorGameBossMain")

function XUiSameColorGameBossMain:OnAwake()
    self.SameColorGameManager = XDataCenter.SameColorActivityManager
    self.BossManager = self.SameColorGameManager.GetBossManager()
    self.Bosses = nil
    ---@type XUiSameColorBossGrid[]
    self.BossGridList = {}
    -- 资源栏
    --local itemIds = self._Control:GetCfgAssetItemIds()
    --XUiHelper.NewPanelActivityAssetSafe(itemIds, self.PanelAsset, self, nil , function(uiSelf, index)
    --    local itemId = itemIds[index]
    --    XLuaUiManager.Open("UiSameColorGameSkillDetails", nil, itemId)
    --end)
    self:AddBtnListener()
    XSaveTool.SaveData(string.format("SameColorGameOpen_%s", XPlayer.Id), true)
end

function XUiSameColorGameBossMain:OnStart()
    self.TxtTitle.text = self._Control:GetClientCfgStringValue("Name")
    self._Timer = XScheduleManager.ScheduleForever(function()
        for _, grid in pairs(self.BossGridList) do
            grid:RefreshStatus()
        end
    end, XScheduleManager.SECOND, 0)
    --self:InitAutoClose()
end

function XUiSameColorGameBossMain:OnEnable()
    XUiSameColorGameBossMain.Super.OnEnable(self)
    self:UpdateTaskRedPoint()
    self:RefreshBossList()
    --self.SameColorGameManager.SetMainUiModelInfo(self.UiModel, self.UiModelGo, self.UiSceneInfo)

    self:PlayAnimation("Enable", function()
        self:PlayAnimation("Loop", nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.Loop)
    end)
    XEventManager.AddEventListener(XEventId.EVENT_TASK_SYNC, self.UpdateTaskRedPoint, self)
end

function XUiSameColorGameBossMain:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_TASK_SYNC, self.UpdateTaskRedPoint, self)
end

function XUiSameColorGameBossMain:UpdateTaskRedPoint()
    XRedPointManager.CheckOnceByButton(self.BtnTask, { XRedPointConditions.Types.CONDITION_SAMECOLOR_TASK })
end

function XUiSameColorGameBossMain:OnDestroy()
    --self.SameColorGameManager.ClearMainUiModelInfo()
    XUiSameColorGameBossMain.Super.OnDestroy(self)
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = nil
    end
end

--region Ui - AutoClose
--function XUiSameColorGameBossMain:InitAutoClose()
--    local endTime = self.SameColorGameManager.GetEndTime()
--    self:SetAutoCloseInfo(endTime, function(isClose)
--        if isClose then
--            self.SameColorGameManager.HandleActivityEndTime()
--        else
--            self:RefreshTimeText()
--            for _, grid in pairs(self.BossGridList) do
--                grid:RefreshStatus()
--            end
--        end
--    end, nil, 1)
--end

--function XUiSameColorGameBossMain:RefreshTimeText()
--    local second = self.SameColorGameManager.GetEndTime() - XTime.GetServerNowTimestamp()
--    local day = math.floor(second / (3600 * 24))
--    local _, _, _, hours, minutes, seconds = XUiHelper.GetTimeNumber(second)
--    local result, desc
--    if day >= 1 then
--        result = day
--        desc = XUiHelper.GetText("Day")
--    elseif hours >= 1 then
--        result = hours
--        desc = XUiHelper.GetText("Hour")
--    elseif minutes >= 1 then
--        result = minutes
--        desc = XUiHelper.GetText("Minute")
--    else
--        result = seconds
--        desc = XUiHelper.GetText("Second")
--    end
--    self.TxtTime.text = XUiHelper.GetText("SCActivityTimeText", result, desc)
--end
--endregion

--region Ui - BossStage
function XUiSameColorGameBossMain:RefreshBossList()
    self.Bosses = self.BossManager:GetBosses()

    for i, boss in ipairs(self.Bosses) do
        local bossGrid = self.BossGridList[i]
        if not bossGrid then
            local go = self["GridArchiveNpc" .. i]
            if go then
                bossGrid = XUiSameColorBossGrid.New(go, self)
                self.BossGridList[i] = bossGrid
            end
        end
        if bossGrid then
            bossGrid:SetData(boss, i)
        end
    end
end
--endregion

--region Ui - BtnListener
function XUiSameColorGameBossMain:AddBtnListener()
    self:BindHelpBtn(self.BtnHelp, self._Control:GetCfgHelpId())
    self.BtnBack.CallBack = function() self:Close() end
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end
    self.BtnTask.CallBack = function() self:OnBtnTaskClicked() end
    --self.BtnRank.CallBack = function() self:OnBtnRankClicked() end
    self.BtnStore.CallBack = function() self:OnBtnStoreClicked() end
end

function XUiSameColorGameBossMain:OnBtnTaskClicked()
    XLuaUiManager.Open("UiSameColorGameTask")
end

--function XUiSameColorGameBossMain:OnBtnRankClicked()
--    self.SameColorGameManager.RequestRankData(0, function(rankList, myRankInfo)
--        XLuaUiManager.Open("UiFubenSameColorGameRank", rankList, myRankInfo)
--    end)
--end

function XUiSameColorGameBossMain:OnBtnStoreClicked()
    self._Control:OpenShop()
end
--endregion

return XUiSameColorGameBossMain
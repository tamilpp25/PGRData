--===========================
--超级爬塔多波关卡详情
--===========================
local XUiSuperTowerSettleWin = XLuaUiManager.Register(XLuaUi, "UiSuperTowerSettleWin")
local XUiGridSettleReward = require("XUi/XUiSuperTower/Stages/Target/XUiGridSettleReward")
local XUiSuperTowerPluginGrid = require("XUi/XUiSuperTower/Plugins/XUiSuperTowerPluginGrid")
local CSTextManagerGetText = CS.XTextManager.GetText
local CSObjectInstantiate = CS.UnityEngine.Object.Instantiate
function XUiSuperTowerSettleWin:OnStart(stStage, pluginList, tempProgress, battledTeamList)
    self.STStage = stStage
    self.PluginList = pluginList
    self.TempProgress = tempProgress
    self.BattledTeamList = battledTeamList
    self.GridItemMultiList = {}
    self.GridItemSingleList = {}
    self.PanelItemInfo:GetObject("GridItemMulti").gameObject:SetActiveEx(false)
    self.PanelItemInfo:GetObject("GridItemSingle").gameObject:SetActiveEx(false)
    self:SetButtonCallBack()
    self:InitPanelPlugin()
    local endTime = XDataCenter.SuperTowerManager.GetActivityEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            XDataCenter.SuperTowerManager.HandleActivityEndTime()
        end
    end)
end

function XUiSuperTowerSettleWin:OnDestroy()

end

function XUiSuperTowerSettleWin:OnEnable()
    XUiSuperTowerSettleWin.Super.OnEnable(self)
    self:UpdatePanel()
end

function XUiSuperTowerSettleWin:OnDisable()
    XUiSuperTowerSettleWin.Super.OnDisable(self)
end

function XUiSuperTowerSettleWin:SetButtonCallBack()
    self.BtnNo.CallBack = function()
        self:OnBtnCancelClick()
    end
    self.BtnYes.CallBack = function()
        self:OnBtnGetRewardClick()
    end
    self.BtnClose.CallBack = function()
        self:OnBtnCloseClick()
    end
end

function XUiSuperTowerSettleWin:OnBtnGetRewardClick()
    local confirmCb = function()
        XDataCenter.SuperTowerManager.ConfirmTargetResultRequest(self.STStage:GetId(), function(rewardGoodsList)
            self:ClearBattledTeamPlugin()
            XUiManager.OpenUiObtain(rewardGoodsList, nil, function()
                XDataCenter.SuperTowerManager.CheckPopupWindow(function()
                    self:OnBtnCloseClick()
                end)
            end)
        end)
    end

    local desc = CSTextManagerGetText("STSettleConfirmHint")
    XLuaUiManager.Open("UiDialog", CSTextManagerGetText("TipTitle"), desc,
    XUiManager.DialogType.Normal, nil, confirmCb)
end

function XUiSuperTowerSettleWin:OnBtnCancelClick()
    local confirmCb = function()
        self:Close()
    end

    local desc = CSTextManagerGetText("STSettleCancelHint")
    XLuaUiManager.Open("UiDialog", CSTextManagerGetText("TipTitle"), desc,
    XUiManager.DialogType.Normal, nil, confirmCb)
end


function XUiSuperTowerSettleWin:OnBtnCloseClick()
    self:Close()
end

function XUiSuperTowerSettleWin:ClearBattledTeamPlugin()
    for _, team in pairs(self.BattledTeamList or {}) do
        local extraData = team:GetExtraData()
        extraData:Clear()
    end
end

function XUiSuperTowerSettleWin:InitPanelPlugin()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelPlugin:GetObject("PanelPluginScrollView"))
    self.DynamicTable:SetProxy(XUiSuperTowerPluginGrid)
    self.DynamicTable:SetDelegate(self)
    self.PanelPlugin:GetObject("GridSuperTowerCore").gameObject:SetActiveEx(false)
end

function XUiSuperTowerSettleWin:UpdatePanel()
    self:UpdateInfo()
    self:UpdatePanelItem()
    self:UpdatePanelPlugin()
end

function XUiSuperTowerSettleWin:UpdateInfo()
    self.TxtName.text = self.STStage:GetFullStageName()
    self.BtnNo.gameObject:SetActiveEx(self:IsNewProgress())
    self.BtnYes.gameObject:SetActiveEx(self:IsNewProgress())
    self.BtnClose.gameObject:SetActiveEx(not self:IsNewProgress())
end

function XUiSuperTowerSettleWin:UpdatePanelItem()
    local gridMultiObj = self.PanelItemInfo:GetObject("GridItemMulti")
    local gridSingleObj = self.PanelItemInfo:GetObject("GridItemSingle")
    local contentObj = self.PanelItemInfo:GetObject("Content")
    for index, rewardId in pairs(self.STStage:GetRewardId()) do
        local rewardState
        if index <= self.STStage:GetCurrentProgress() then
            rewardState = XDataCenter.SuperTowerManager.StageRewardState.Complete
        elseif index > self.STStage:GetCurrentProgress() and index <= self.TempProgress then
            rewardState = XDataCenter.SuperTowerManager.StageRewardState.CanGet
        else
            rewardState = XDataCenter.SuperTowerManager.StageRewardState.Lock
        end

        if self.STStage:CheckIsMultiWave() then
            self:UpdateGrid(index, rewardId, rewardState, gridMultiObj, contentObj, self.GridItemMultiList, self.STStage)
        else
            self:UpdateGrid(index, rewardId, rewardState, gridSingleObj, contentObj, self.GridItemSingleList, self.STStage)
        end
    end
end

function XUiSuperTowerSettleWin:UpdateGrid(index, rewardId, rewardState, gridObj, contentObj, gridList, IsMulti)
    local grid = gridList[index]
    if not grid then
        local obj = CSObjectInstantiate(gridObj, contentObj)
        grid = XUiGridSettleReward.New(obj)
        gridList[index] = grid
    end
    grid.GameObject:SetActiveEx(true)
    grid:UpdateGrid(self, rewardId, index, rewardState, IsMulti)
end

function XUiSuperTowerSettleWin:UpdatePanelPlugin()
    local text = CSTextManagerGetText("STFightFinishUsePluginText")
    local hint
    if self:IsNewProgress() then
        hint = CSTextManagerGetText("STFightFinishUsePluginHint")
    else
        hint = ""
    end
    self.PanelPlugin:GetObject("TxtListName").text = text
    self.PanelPlugin:GetObject("TxtListHint").text = hint
    self.PanelPlugin:GetObject("PanelPluginNone").gameObject:SetActiveEx(#self.PluginList == 0 or not self:IsNewProgress())

    self.PanelPlugin:GetObject("TxtNone").text = (self:IsNewProgress() and #self.PluginList == 0) and
    CSTextManagerGetText("STNotSelectPlugin") or CSTextManagerGetText("STNotUsePlugin")

    local dataSource = self:IsNewProgress() and self.PluginList or {}
    self.DynamicTable:SetDataSource(dataSource)
    self.DynamicTable:ReloadDataASync(1)
end

function XUiSuperTowerSettleWin:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:RefreshData(self.PluginList[index])
    end
end

function XUiSuperTowerSettleWin:IsNewProgress()
    return self.TempProgress > self.STStage:GetCurrentProgress()
end
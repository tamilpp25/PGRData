local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiDownLoadMain : XLuaUi
---@field _Control XSubPackageControl
---@field TabBtnGroup XUiButtonGroup
---@field PanelDynamic XUiPanelDynamic
local XUiDownLoadMain = XLuaUiManager.Register(XLuaUi, "UiDownLoadMain")

local XUiPanelDynamic = require("XUi/XUiSubPackage/XUiPanel/XUiPanelDynamic")

local DefaultIndex = 1

function XUiDownLoadMain:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiDownLoadMain:OnStart(groupId)
    self:InitView(groupId)
end

function XUiDownLoadMain:Close()
    self.Super.Close(self)
    XMVCA.XSubPackage:ChangeThread(true)
end

function XUiDownLoadMain:InitUi()
    -- 页签
    local tab = {}
    self.GroupIds = self._Control:GetGroupIdList()

    for idx, groupId in ipairs(self.GroupIds) do
        local btn = idx == 1 and self.BtnTab or XUiHelper.Instantiate(self.BtnTab, self.TabBtnGroup.transform)
        btn.gameObject.name = "BtnGroup" .. groupId
        btn:SetNameByGroup(0, self._Control:GetGroupName(groupId))
        table.insert(tab, btn)
    end

    self.TabBtnGroup:Init(tab, function(tabIndex)
        self:OnSelectTab(tabIndex)
    end)

    -- 动态列表
    self.GridTask.gameObject:SetActiveEx(false)
    self.PanelDynamic = XUiPanelDynamic.New(self.PanelAchvList, self, false)
    self.PanelDynamic:Open()

    -- 奖励
    self.GridCommon = XUiGridCommon.New(self, self.GridIcon)
    self.GridCommon:SetProxyClickFunc(handler(self, self.OnRewardClick))
    self.RewardEffect = self.GridIcon.transform:FindTransform("PanelEffect")
end

function XUiDownLoadMain:OnGetLuaEvents()
    return {
        XEventId.EVENT_SUBPACKAGE_MULTI_COUNT_CHANGED,
        XEventId.EVENT_SUBPACKAGE_COMPLETE,
    }
end

function XUiDownLoadMain:OnNotify(evt, ...)
    if evt == XEventId.EVENT_SUBPACKAGE_MULTI_COUNT_CHANGED then
        self:RefreshSpeedView()
    elseif evt == XEventId.EVENT_SUBPACKAGE_COMPLETE then
        self:OnSubpackageComplete()
    end
end

function XUiDownLoadMain:InitCb()

    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end

    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end

    self.BtnInfo.CallBack = function()
        self:OnBtnInfoClick()
    end

    self.BtnDownloadAll.CallBack = function()
        self:OnBtnAllClick()
    end

    self.BtnReportType.CallBack = function()
        self:OnBtnReportTypeClick()
    end

    self.BtnSpeedUp.CallBack = function()
        self:OnBtnSpeedUpClick()
    end
end

function XUiDownLoadMain:InitView(groupId)
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem,
            XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)

    self.TabBtnGroup:SelectIndex(self:GetTabIndexByGroupId(groupId))

    self:RefreshSpeedView()
    self:RefreshRewardView()
    self:OnSubpackageComplete()
end

function XUiDownLoadMain:OnSelectTab(tabIndex)
    if self.TabIndex == tabIndex then
        return
    end
    self.TabIndex = tabIndex

    self:SetupDynamicTable()
    local curGroupId = self.GroupIds[self.TabIndex]
    local isSelect = XMVCA.XSubPackage:GetWifiAutoState(curGroupId)
    self.BtnReportType:SetButtonState(isSelect and CS.UiButtonState.Select or CS.UiButtonState.Normal)
    self.PanelReward.gameObject:SetActiveEx(XMVCA.XSubPackage:IsNecessaryGroup(curGroupId))
end

function XUiDownLoadMain:SetupDynamicTable()
    local curGroupId = self.GroupIds[self.TabIndex]
    self.TxtName.text = self._Control:GetGroupName(curGroupId)
    self.TxtNameEn.text = self._Control:GetGroupNameEn(curGroupId)
    local subpackageIds = self._Control:GetSubpackageIds(curGroupId)
    self.PanelDynamic:SetupDynamicTable(subpackageIds)
end

function XUiDownLoadMain:GetTabIndexByGroupId(groupId)
    if not groupId then
        return DefaultIndex
    end

    for index, id in ipairs(self.GroupIds) do
        if id == groupId then
            return index
        end
    end

    return DefaultIndex
end

function XUiDownLoadMain:OnBtnBackClick()
    self:OnQuitSpeedUp(handler(self, self.Close))
end

function XUiDownLoadMain:OnBtnMainUiClick()
    self:OnQuitSpeedUp(XLuaUiManager.RunMain)
end

function XUiDownLoadMain:OnQuitSpeedUp(sureCb)
    if not XMVCA.XSubPackage:IsMultiThread() then
        if sureCb then sureCb() end
        return
    end
    local content = XUiHelper.GetText("PreloadUnableToExit")
    XUiManager.DialogTip(XUiHelper.GetText("TipTitle"), content, XUiManager.DialogType.Normal, nil, function()
        XMVCA.XSubPackage:ChangeThread(true)
        if sureCb then sureCb() end
    end)
end

function XUiDownLoadMain:OnBtnInfoClick()
    local title = XUiHelper.GetText("DlcDownloadTitle")
    local content = XUiHelper.ReplaceTextNewLine(XUiHelper.GetText("DlcDownloadPreviewTip"))
    XUiManager.UiFubenDialogTip(title, content)
end

function XUiDownLoadMain:OnBtnAllClick()
    if XMVCA.XSubPackage:IsPreparePause() then
        return
    end
    XMVCA.XSubPackage:DownloadAllByGroup(self.GroupIds[self.TabIndex])
end

function XUiDownLoadMain:OnBtnReportTypeClick()
    local isSelect = self.BtnReportType:GetToggleState()
    XMVCA.XSubPackage:SetWifiAutoState(self.GroupIds[self.TabIndex], isSelect)
end

function XUiDownLoadMain:OnBtnSpeedUpClick()
    self:ChangeMultiCount()
    self:RefreshSpeedView()
end

function XUiDownLoadMain:ChangeMultiCount()
    if not XMVCA.XSubPackage:IsDownloading() then
        XUiManager.TipText("DlcDownloadNoDownloadTask")
        return
    end

    local isMultiThread = XMVCA.XSubPackage:IsMultiThread()
    if isMultiThread then
        self:OnQuitSpeedUp(function()
            XMVCA.XSubPackage:ChangeThread(true)
        end)
        return
    end
    XUiManager.DialogTip(XUiHelper.GetText("TipTitle"), XUiHelper.GetText("PreloadFullDownloadTip"), XUiManager.DialogType.Normal, nil, function()
        XMVCA.XSubPackage:ChangeThread(false)
    end)
end

function XUiDownLoadMain:RefreshSpeedView()
    local isMultiThread = XMVCA.XSubPackage:IsMultiThread()
    self.AssetPanel.GameObject:SetActiveEx(not isMultiThread)
    self.BtnSpeedUp:SetButtonState(isMultiThread and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

function XUiDownLoadMain:RefreshRewardView()
    local taskId = CS.XGame.ClientConfig:GetInt("SubpackageNecessaryTaskId")
    if not taskId then
        return
    end
    local task = XTaskConfig.GetTaskCfgById(taskId)
    local rewardId = task.RewardId
    local rewardList = XRewardManager.GetRewardList(rewardId)
    local reward = rewardList and rewardList[1] or 0
    local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)
    self.GridCommon:Refresh(reward)
    self.GridCommon:SetReceived(taskData.State == XDataCenter.TaskManager.TaskState.Finish)
    self.RewardEffect.gameObject:SetActiveEx(taskData.State == XDataCenter.TaskManager.TaskState.Achieved)
    
    self:RefreshButtonRedPoint()
end

function XUiDownLoadMain:OnRewardClick()
    local taskId = CS.XGame.ClientConfig:GetInt("SubpackageNecessaryTaskId")
    if not taskId then
        return
    end
    local task = XTaskConfig.GetTaskCfgById(taskId)
    local rewardId = task.RewardId
    local rewardList = XRewardManager.GetRewardList(rewardId)
    local reward = rewardList and rewardList[1] or 0
    local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)
    if taskData.State == XDataCenter.TaskManager.TaskState.Achieved then
        XDataCenter.TaskManager.FinishTask(taskId, function(rewardGoodsList)
            if not XTool.IsTableEmpty(rewardGoodsList) then
                XUiManager.OpenUiObtain(rewardGoodsList)
            end
            self:RefreshRewardView()
        end)
        return
    end
    XLuaUiManager.Open("UiTip", reward, nil, self.Name)
end

function XUiDownLoadMain:OnSubpackageComplete()
    if XMVCA.XSubPackage:CheckNecessaryComplete() then
        XMVCA.XSubPackage:RequestNecessaryTask(function()
            self:RefreshRewardView()
        end)
    end
end

function XUiDownLoadMain:RefreshButtonRedPoint()
    for index, groupId in ipairs(self.GroupIds) do
        local btn = self.TabBtnGroup.TabBtnList[index - 1]
        if btn and XMVCA.XSubPackage:IsNecessaryGroup(groupId) then
            btn:ShowReddot(XMVCA.XSubPackage:CheckTaskRedPont())
        else
            btn:ShowReddot(false)
        end
    end
end
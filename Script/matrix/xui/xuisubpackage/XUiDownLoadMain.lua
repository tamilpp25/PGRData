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
end

function XUiDownLoadMain:InitCb()
    self:BindExitBtns()

    self.BtnInfo.CallBack = function()
        self:OnBtnInfoClick()
    end

    self.BtnDownloadAll.CallBack = function()
        self:OnBtnAllClick()
    end
    
    self.BtnReportType.CallBack = function() 
        self:OnBtnReportTypeClick()
    end
end

function XUiDownLoadMain:InitView(groupId)
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem,
            XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)

    self.TabBtnGroup:SelectIndex(self:GetTabIndexByGroupId(groupId))
    
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
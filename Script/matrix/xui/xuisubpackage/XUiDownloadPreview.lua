

---@class XUiDownloadPreview : XLuaUi
---@field _Control XSubPackageControl
local XUiDownloadPreview = XLuaUiManager.Register(XLuaUi, "UiDownloadPreview")

local XUiPanelDynamic = require("XUi/XUiSubPackage/XUiPanel/XUiPanelDynamic")

function XUiDownloadPreview:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiDownloadPreview:OnStart(subpackageIds)
    self.SubpackageIds = subpackageIds
    self:InitView()
end

function XUiDownloadPreview:InitUi()
    self.GridTask.gameObject:SetActiveEx(false)
    self.PanelDynamic = XUiPanelDynamic.New(self.PanelAchvList, self, true)
    self.PanelDynamic:Open()
end

function XUiDownloadPreview:InitCb()
    local closeCb = handler(self, self.Close)
    
    self.BtnCloseBg.CallBack = closeCb
    self.BtnTanchuangClose.CallBack = closeCb
    
    self.BtnDownloadB.CallBack = function() 
        self:OnBtnDownloadBClick()
    end
end

function XUiDownloadPreview:InitView()
    local dataList = self:GetSubpackageIds()
    self.PanelDynamic:SetupDynamicTable(dataList)
end

function XUiDownloadPreview:GetSubpackageIds()
    if not XTool.IsTableEmpty(self.SubpackageIds) then
        return self.SubpackageIds
    end
    local dataList = {}
    local groupIds = XMVCA.XSubPackage:GetNecessaryGroupIds()
    for _, groupId in pairs(groupIds) do
        local subIds = self._Control:GetSubpackageIds(groupId)
        dataList = XTool.MergeArray(dataList, subIds)
    end
    return dataList
end

function XUiDownloadPreview:OnBtnDownloadBClick()
    
    local downloadCb = function()
        local groupIds = XMVCA.XSubPackage:GetNecessaryGroupIds()
        for _, groupId in pairs(groupIds) do
            XMVCA.XSubPackage:DownloadAllByGroup(groupId)
        end
        self:Close()
    end
    
    local jumpCb = function()
        self:Close()
        XMVCA.XSubPackage:OpenUiMain()
    end
    
    XUiManager.DialogDownload("", XUiHelper.GetText("DlcDownloadInBackgroundTip"), nil, downloadCb, jumpCb)
end
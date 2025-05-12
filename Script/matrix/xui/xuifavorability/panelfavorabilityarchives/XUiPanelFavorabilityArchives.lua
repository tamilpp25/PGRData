local XUiPanelFavorabilityInfo=require("XUi/XUiFavorability/PanelFavorabilityArchives/XUiPanelFavorabilityInfo")
local XUiPanelFavorabilityRumors=require("XUi/XUiFavorability/PanelFavorabilityArchives/XUiPanelFavorabilityRumors")
local XUiPanelFavorabilityArchives=XClass(XUiNode,"XUiPanelFavorabilityArchives")

local FuncType = {
    Info = 1,
    Rumors=2,
}

function XUiPanelFavorabilityArchives:OnStart(uiroot)
    self.UiRoot=uiroot
    -- 初始化切页
    self.FavorabilityInfo = XUiPanelFavorabilityInfo.New(self.PanelFavorabilityInfo,self.Parent,uiroot)
    self.FavorabilityRumors = XUiPanelFavorabilityRumors.New(self.PanelFavorabilityRumors, self.Parent,uiroot)
    self.FavorabilityInfo:OnSelected(false)
    self.FavorabilityRumors:OnSelected(false)
    
    -- 初始化切页按钮
    self.BtnTabList = {}
    self.BtnTabList[FuncType.Info] = self.BtnInfo
    self.BtnTabList[FuncType.Rumors] = self.BtnRumors
    self.PanelBtnGroup:Init(self.BtnTabList, function(index) self:OnBtnTabListClick(index) end)
    self.CurSelectedPanel = nil
    self.LastSelectTab=nil
end

function XUiPanelFavorabilityArchives:OnEnable()
    if self.CurSelectedPanel == nil then
        local selected = self.LastSelectTab and self.LastSelectTab or FuncType.Info
        self:OnBtnTabListClick(selected)
        self.CurrentSelectTab = selected
        self.PanelBtnGroup:SelectIndex(self.CurrentSelectTab)
    end
end

function XUiPanelFavorabilityArchives:OnDisable()
    self.LastSelectTab=self.CurrentSelectTab
    self.CurSelectedPanel = nil
    self.CurrentSelectTab=nil
    self.FavorabilityInfo:Close()
    self.FavorabilityRumors:Close()
end

function XUiPanelFavorabilityArchives:SetViewActive(isActive)
    if isActive then
        self:Open()
    else
        self:Close()
    end
end

function XUiPanelFavorabilityArchives:OnBtnTabListClick(index)
    if index == self.CurrentSelectTab then
        return
    end

    self.LastSelectTab = self.CurrentSelectTab
    self.CurrentSelectTab = index

    if self.CurSelectedPanel then
        self.CurSelectedPanel:OnSelected(false)
    end

    if index == FuncType.Rumors then
        self.CurSelectedPanel = self.FavorabilityRumors
    elseif index == FuncType.Info then
        self.CurSelectedPanel = self.FavorabilityInfo
    end

    if self.CurSelectedPanel then
        self.CurSelectedPanel:OnSelected(true)
        self.UiRoot:PlayAnimation('QieHuan2')
    end
end

function XUiPanelFavorabilityArchives:OnSelected(isSelected)
    if isSelected then
        self:Open()
    else
        self:Close()
    end
end

return XUiPanelFavorabilityArchives
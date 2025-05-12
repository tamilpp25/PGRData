local XUiPanelFavorabilityAction=require("XUi/XUiFavorability/PanelFavorabilityShow/XUiPanelFavorabilityAction")
local XUiPanelFavorabilityAudio=require("XUi/XUiFavorability/PanelFavorabilityShow/XUiPanelFavorabilityAudio")
local XUiPanelFavorabilityShow=XClass(XUiNode,"XUiPanelFavorabilityShow")

local FuncType = {
    Auido = 1,
    Action=2,
}

function XUiPanelFavorabilityShow:OnStart(uiRoot)
    self.UiRoot=uiRoot
    -- 初始化切页
    self.FavorabilityAudio = XUiPanelFavorabilityAudio.New(self.PanelFavorabilityAudio, self.Parent, uiRoot)
    self.FavorabilityAction = XUiPanelFavorabilityAction.New(self.PanelFavorabilityAction, self.Parent, uiRoot)
    self.FavorabilityAudio:OnSelected(false)
    self.FavorabilityAction:OnSelected(false)

    -- 初始化切页按钮
    self.BtnTabList = {}
    self.BtnTabList[FuncType.Auido] = self.BtnAudio
    self.BtnTabList[FuncType.Action] = self.BtnAction
    self.PanelBtnGroup:Init(self.BtnTabList, function(index) self:OnBtnTabListClick(index) end)
    self.CurSelectedPanel = nil
    self.LastSelectTab=nil
end

function XUiPanelFavorabilityShow:OnEnable()
    if self.CurSelectedPanel == nil then
        local selected = self.LastSelectTab and self.LastSelectTab or FuncType.Auido
        self:OnBtnTabListClick(selected)
        self.CurrentSelectTab = selected
        self.PanelBtnGroup:SelectIndex(self.CurrentSelectTab)
    end
end

function XUiPanelFavorabilityShow:OnDisable()
    self.LastSelectTab=self.CurrentSelectTab
    self.CurSelectedPanel = nil
    self.CurrentSelectTab=nil
    self.FavorabilityAudio:Close()
    self.FavorabilityAction:Close()
end

function XUiPanelFavorabilityShow:OnBtnTabListClick(index)
    if index == self.CurrentSelectTab then
        return
    end

    self.Parent:SetCurShowFuncType(index)

    self.LastSelectTab = self.CurrentSelectTab
    self.CurrentSelectTab = index

    if self.CurSelectedPanel then
        self.CurSelectedPanel:OnSelected(false)
    end

    if index == FuncType.Auido then
        self.CurSelectedPanel = self.FavorabilityAudio
    elseif index == FuncType.Action then
        self.CurSelectedPanel = self.FavorabilityAction
    end

    if self.CurSelectedPanel then
        self.CurSelectedPanel:OnSelected(true)
        self.UiRoot:PlayAnimation('QieHuan2')
    end
end

function XUiPanelFavorabilityShow:SetViewActive(isActive)
    if isActive then
        self:Open()
    else
        self:Close()
    end
end

function XUiPanelFavorabilityShow:OnSelected(isSelected)
    if isSelected then
        self:Open()
    else
        self:Close()
    end
end

function XUiPanelFavorabilityShow:UnScheduleAudioPlay()
    if self.FavorabilityAudio and self.FavorabilityAudio:IsValidState() then
        self.FavorabilityAudio:UnScheduleAudio()
    end
end

function XUiPanelFavorabilityShow:UnScheduleActionPlay()
    if self.FavorabilityAction and self.FavorabilityAction:IsValidState()then
        self.FavorabilityAction:UnScheduleAction()
    end
end

function XUiPanelFavorabilityShow:UnSchedulePlay()
    self:UnScheduleAudioPlay()
    self:UnScheduleActionPlay()
end

return XUiPanelFavorabilityShow
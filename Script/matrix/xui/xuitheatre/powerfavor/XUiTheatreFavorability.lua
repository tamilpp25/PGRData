local XUiPanelFavorList = require("XUi/XUiTheatre/PowerFavor/XUiPanelFavorList")
local XUiPanelFavorDetail = require("XUi/XUiTheatre/PowerFavor/XUiPanelFavorDetail")

--肉鸽玩法势力好感度主界面
local XUiTheatreFavorability = XLuaUiManager.Register(XLuaUi, "UiTheatreFavorability")

function XUiTheatreFavorability:OnAwake()
    XUiHelper.NewPanelActivityAsset(XDataCenter.TheatreManager.GetAssetItemIds(), self.PanelSpecialTool)
    self:AddListener()

    self.TheatrePowerManager = XDataCenter.TheatreManager.GetPowerManager()
    self.FavorListPanel = XUiPanelFavorList.New(self.PanelFavorabilityList, handler(self, self.ShowFavorDetailPanel))
    self.FavorDetailPanel = XUiPanelFavorDetail.New(self.PanelFavorabilityDetail, self)
end

function XUiTheatreFavorability:OnEnable()
    self:Refresh()
end

function XUiTheatreFavorability:Refresh()
    self.FavorDetailPanel:Hide()
    self.FavorListPanel:Show()
end

function XUiTheatreFavorability:ShowFavorDetailPanel(powerId)
    local isUnLock = self.TheatrePowerManager:IsUnlockPower(powerId)
    if not isUnLock then
        return
    end
    self.FavorListPanel:Hide()
    self.FavorDetailPanel:Show(powerId)
end

function XUiTheatreFavorability:AddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
end

function XUiTheatreFavorability:OnBtnBackClick()
    if self.FavorDetailPanel:IsShow() then
        self:Refresh()
        return
    end
    self:Close()
end
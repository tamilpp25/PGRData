--================
--超级爬塔 爬塔关卡 结算界面
--================
local XUiStTierSettle = XLuaUiManager.Register(XLuaUi, "UiSuperTowerInfiniteSettleWin")
local PANELS_DIC = {
        Floor = 1,
        EnhanceInfo = 2,
        PluginInfo = 3,
        RoleInfo = 4,
        Score = 5
    }
local PANEL_PATH = "XUi/XUiSuperTower/Stages/Tier/XUiStTs"
function XUiStTierSettle:OnAwake()
    XTool.InitUiObject(self)
end

function XUiStTierSettle:OnStart(settleData, theme)
    self.SettleData = settleData
    self.Theme = theme or XDataCenter.SuperTowerManager.GetStageManager():GetThemeByStageId(self.SettleData.StageId)
    if self.TxtStageName then self.TxtStageName.text = self.Theme:GetTierName() end
    self:InitPanelsDic()
    self.BtnStopAnim.CallBack = function() self:OnClickStopAnim() end
    self.BtnClose.CallBack = function() self:OnClickClose() end
end

function XUiStTierSettle:InitPanelsDic()
    local script = require("XUi/XUiSuperTower/Common/XUiSTMainPage")
    self.PanelControl = script.New(self)
    self.PanelControl:RegisterChildPanels(PANELS_DIC, PANEL_PATH)
    self.PanelControl:ShowAllPanels()
end

function XUiStTierSettle:CheckPluginSyn()
    local oldList, newList = XDataCenter.SuperTowerManager.GetBagManager():GetPluginSyn()
    if oldList and newList then
        XLuaUiManager.Open("UiSuperTowerPlugUp", oldList, newList, function() self:CheckPluginSyn() end)
    end
end

function XUiStTierSettle:OnClickStopAnim()
    self.PanelControl:DoFunction(PANELS_DIC.Score, "StopTimer")
end

function XUiStTierSettle:OnClickClose()
    self:Close()
end

function XUiStTierSettle:GetPluginGetNum()
    return self.PanelControl:DoFunction(PANELS_DIC.PluginInfo, "GetPluginGetNum")
end

function XUiStTierSettle:SetCloseBtnActive(value)
    self.BtnClose.gameObject:SetActiveEx(value)
end

function XUiStTierSettle:SetStopAnimBtnActive(value)
    self.BtnStopAnim.gameObject:SetActiveEx(value)
end

function XUiStTierSettle:OnDestroy()
    self.Theme:CheckReset()
    self.PanelControl:OnDestroy()
end
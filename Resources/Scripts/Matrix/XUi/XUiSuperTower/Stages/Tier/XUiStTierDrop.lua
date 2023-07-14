--===========================
--超级爬塔 爬塔关卡掉落页面
--===========================
local XUiStTierDrop = XLuaUiManager.Register(XLuaUi, "UiSuperTowerItemTip")

local SHOW_TYPE = {
        Enhance = 1, --增益页面
        Plugin = 2, --插件掉落页面
    }
local CHILD_PANEL_PATH = "XUi/XUiSuperTower/Stages/Tier/XUiStTd"
local CHILD_PANEL = {
        Tab = 1, --页签面板
        Title = 2, --标题面板
        Info = 3, --详细信息面板
        DynamicTable = 4, --动态列表面板
    }

function XUiStTierDrop:OnAwake()
    XTool.InitUiObject(self)
    self.BtnClose.CallBack = function() self:Close() end
    self.FirstIn = true
end

function XUiStTierDrop:OnStart(theme, showType, showAll)
    self.Theme = theme
    self.ShowType = showType
    self.ShowAll = showAll
    self:InitChildPanels()
end

function XUiStTierDrop:InitChildPanels()
    local panelControlScript = require("XUi/XUiSuperTower/Common/XUiSTMainPage")
    self.PanelControl = panelControlScript.New(self)
    self.PanelControl:RegisterChildPanels(CHILD_PANEL, CHILD_PANEL_PATH)
    local showPanelsDic = {
        [CHILD_PANEL.Tab] = true, --页签面板
        [CHILD_PANEL.Title] = true, --标题面板
        [CHILD_PANEL.Info] = false, --详细信息面板
        [CHILD_PANEL.DynamicTable] = true, --动态列表面板
        }
    self.PanelControl:ShowChildPanel(showPanelsDic)
end

function XUiStTierDrop:ShowEnhance()
    self.ShowType = SHOW_TYPE.Enhance
    self.PanelControl:AllDoFunction("Refresh")
    if self.FirstIn then
        self.FirstIn = false
    else
        self:PlayAnimation("QieHuan")
    end
end

function XUiStTierDrop:ShowPlugin()
    self.ShowType = SHOW_TYPE.Plugin
    self.PanelControl:AllDoFunction("Refresh")
    if self.FirstIn then
        self.FirstIn = false
    else
        self:PlayAnimation("QieHuan")
    end
end

function XUiStTierDrop:OnSelectGrid(cfg)
    self.PanelControl:DoFunction(CHILD_PANEL.Info, "OnSelectGrid", cfg)
end
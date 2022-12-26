
local this = XLuaUiManager.Register(XLuaUi, "UiFireworksLog")
local panelRule = require("XOverseas/XUi/XUiFireworks/XUiFireworksPanelRule")
local panelRecord = require("XOverseas/XUi/XUiFireworks/XUiFireworksPanelRecord")

function this:OnAwake()
    self:AutoAddListener()
end

function this:OnStart()
    self.Panels[1].Refresh()
    self.Panels[2].Refresh()
    self.PanelTabTc:SelectIndex(1)
end

function this:AutoAddListener()

    local tabList = { self.BtnTab1, self.BtnTab2 }
    self.PanelTabTc:Init(tabList, function(index)
        self:SelectPanel(index)
    end)

    self.BtnTanchuangClose.CallBack = function() XLuaUiManager.Close("UiFireworksLog") end

    panelRule.Init(self.Panel1.gameObject)
    panelRecord.Init(self.Panel2.gameObject)

    self.Panels = { panelRule, panelRecord }
end

function this:SelectPanel(index)
    self.Panels[index].Show()
    self.Panels[3 - index].Hide()
end
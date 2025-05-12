local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiPurchaseSignTipGridDay = XClass(nil, "XUiPurchaseSignTipGridDay")

function XUiPurchaseSignTipGridDay:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.Grid = nil

    XTool.InitUiObject(self)
    self:InitComponent()
end

function XUiPurchaseSignTipGridDay:InitComponent()
    self.PanelNext.gameObject:SetActiveEx(false)
    self.PanelNow.gameObject:SetActiveEx(false)
    self.PanelHaveReceive.gameObject:SetActiveEx(false)
    self.PanelEffect.gameObject:SetActiveEx(false)
end

function XUiPurchaseSignTipGridDay:Refresh(config)
    self.Config = config
    self.TxtDay.text = string.format("%02d", config.Pre)

    local rewardList = XRewardManager.GetRewardList(config.ShowRewardId)
    if not rewardList or #rewardList <= 0 then
        return
    end

    if not self.Grid then
        self.Grid = XUiGridCommon.New(self.RootUi, self.GridCommon)
    end

    self.Grid:Refresh(rewardList[1])
    self.GameObject:SetActiveEx(true)
end

return XUiPurchaseSignTipGridDay
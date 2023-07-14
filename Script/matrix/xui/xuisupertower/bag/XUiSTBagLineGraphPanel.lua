local ChildPanel = require("XUi/XUiSuperTower/Common/XUiSTChildPanel")
local MAX_STAR = 6
--===========================
--超级爬塔容量条形图面板
--===========================
local XUiSTBagLineGraphPanel = XClass(ChildPanel, "XUiSTBagLineGraphPanel")

function XUiSTBagLineGraphPanel:InitPanel()
    self.BtnAdd.CallBack = function() self:OnClickBtnAdd() end
end

function XUiSTBagLineGraphPanel:Refresh()
    self:RefreshImgStars()
end

function XUiSTBagLineGraphPanel:RefreshImgStars()
    local amount = 0 --算累积百分比
    for i = 1, MAX_STAR do
        if self["ImgStar" .. i] then
            amount = amount + self.RootUi.BagManager:GetCapacityPercentsByStar(i)
            self["ImgStar" .. i].fillAmount = amount
        end
    end
end

function XUiSTBagLineGraphPanel:OnClickBtnAdd()
    XLuaUiManager.Open("UiTip", XDataCenter.ItemManager.ItemId.SuperTowerBagItemId)
end

function XUiSTBagLineGraphPanel:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_ST_PLUGIN_REFRESH, self.Refresh, self)
end

function XUiSTBagLineGraphPanel:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_ST_PLUGIN_REFRESH, self.Refresh, self)
end

return XUiSTBagLineGraphPanel
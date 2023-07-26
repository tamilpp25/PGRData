local BasePanel = require("XUi/XUiSuperTower/Common/XUiSTChildPanel")
--==================
--超级爬塔 爬塔 结算界面层数面板控件
--==================
local XUiStTsFloorPanel = XClass(BasePanel, "XUiStTsFloorPanel")

function XUiStTsFloorPanel:InitPanel()
    local currentT = self.RootUi.Theme:GetCurrentTier()
    local historyT = self.RootUi.Theme:GetHistoryHighestTier()
    self.TxtCurrentNum.text = currentT
    self.TxtBeforeNum.text = CS.XTextManager.GetText("STTsHistoryFloorStr", historyT)
    self.NewTag.gameObject:SetActiveEx(self.RootUi.Theme:CheckIsNewTierRecord())
end

return XUiStTsFloorPanel
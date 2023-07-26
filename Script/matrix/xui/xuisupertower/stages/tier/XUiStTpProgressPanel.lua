local Base = require("XUi/XUiSuperTower/Common/XUiSTChildPanel")
--=====================
--爬塔准备当前进度显示面板
--=====================
local XUiStTpProgressPanel = XClass(Base, "XUiStTpProgressPanel")

function XUiStTpProgressPanel:OnShowPanel()
    self.TxtProgress.text = CS.XTextManager.GetText("STTpProgress", self.RootUi.Theme:GetCurrentTier(), self.RootUi.Theme:GetMaxTier())
end

return XUiStTpProgressPanel
local Base = require("XUi/XUiSuperTower/Common/XUiSTChildPanel")
--=====================
--爬塔准备积分显示面板
--=====================
local XUiStTpScorePanel = XClass(Base, "XUiStTpScorePanel")

function XUiStTpScorePanel:OnShowPanel()
    self.TxtScore.text = self.RootUi.Theme:GetCurrentTierScore()
end

return XUiStTpScorePanel
local XUiFubenYuanXiaoMedalTips = require("XUi/XUiSpecialTrainYuanXiao/XUiFubenYuanXiaoMedalTips")

---@class XUiSpecialTrainBreakthroughMedalTips
local XUiSpecialTrainBreakthroughMedalTips =
    XLuaUiManager.Register(XUiFubenYuanXiaoMedalTips, "UiSpecialTrainBreakthroughMedalTips")

function XUiSpecialTrainBreakthroughMedalTips:OnStart()
    XUiSpecialTrainBreakthroughMedalTips.Super.OnStart(self)
    self.Text.text = XFubenSpecialTrainConfig.GetChapterSeasonName(XDataCenter.FubenSpecialTrainManager.GetOneChapterId())
end

function XUiSpecialTrainBreakthroughMedalTips:RegisterButtonClick(...)
    XUiSpecialTrainBreakthroughMedalTips.Super.RegisterButtonClick(self, ...)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
end

return XUiSpecialTrainBreakthroughMedalTips

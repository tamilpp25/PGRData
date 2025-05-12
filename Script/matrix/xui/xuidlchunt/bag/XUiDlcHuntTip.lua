local XUiTip = require("XUi/XUiTip/XUiTip")

---@class XUiDlcHuntTip:XLuaUi
local XUiDlcHuntTip = XLuaUiManager.Register(XUiTip, "UiDlcHuntTip")

function XUiDlcHuntTip:OnStart(data, hideSkipBtn, rootUiName, lackNum, showNum)
    local musicKey = self:GetAutoKey(self.BtnBack, "onClick")
    self.SpecialSoundMap[musicKey] = XLuaAudioManager.UiBasicsMusic.Return
    self.HideSkipBtn = hideSkipBtn
    self.RootUiName = rootUiName
    self.Data = data
    self.LackNum = lackNum
    self.ShowNum = showNum -- 兼容自定义数量
    --self:PlayAnimation("AnimStart")
end

return XUiDlcHuntTip
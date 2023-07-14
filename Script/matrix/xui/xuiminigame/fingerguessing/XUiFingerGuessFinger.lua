-- 出拳展示组件
local XUiFingerGuessFinger = XClass(nil, "XUiFingerGuessFinger")
local INITIAL_NUM_TEXT = "?"
function XUiFingerGuessFinger:Ctor(gameObject, fingerId)
    XTool.InitUiObjectByUi(self, gameObject)
    self:InitFinger(fingerId)
end
--================
--初始化面板
--================
function XUiFingerGuessFinger:InitFinger(fingerId)
    self:RefreshFinger(fingerId, INITIAL_NUM_TEXT)
end
--================
--刷新面板
--================
function XUiFingerGuessFinger:RefreshFinger(fingerId, text)
    if self.FingerId ~= fingerId then
        self.FingerId = fingerId
        local config = XFingerGuessingConfig.GetFingerConfigById(fingerId)
        self.ImgFingerIcon:SetSprite(config.Icon)
    end
    if type(text) ~= "number" then
        self.TxtNum.text = text
    else
        self.TxtNum.text = "<color=#2B709C>" .. text .. "</color>"
    end
end

return XUiFingerGuessFinger
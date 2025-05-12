---@class XUiSetNumber:XLuaUi
local XUiSetNumber = XLuaUiManager.Register(XLuaUi, "UiSetNumber")

function XUiSetNumber:OnAwake()
    self:RegisterUiEvents()
end

function XUiSetNumber:OnStart(minValue, maxValue, characterLimit, cb)
    self.MinValue = minValue
    self.MaxValue = maxValue
    self.CharacterLimit = characterLimit
    self.Cb = cb
end

function XUiSetNumber:OnEnable()
    self:Refresh()
end

function XUiSetNumber:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self:RegisterClickEvent(self.BtnSure, self.OnBtnSureClick)
    self:RegisterClickEvent(self.BtnCancel, self.Close)
end

function XUiSetNumber:OnBtnSureClick()
    -- 未设置值
    local text = self.InputField.text
    if not text or text == "" then
        XUiManager.TipText("SetNumberEmptyTips")
        return
    end

    -- 超出范围
    local num = tonumber(text)
    if num < self.MinValue or num > self.MaxValue then
        XUiManager.TipText("SetNumberOutRangeTips")
        return
    end
    
    local cb = self.Cb
    self:Close()

    if cb then
        cb(num)
    end
end

function XUiSetNumber:Refresh()
    if self.CharacterLimit then
        self.InputField.characterLimit = self.CharacterLimit
    end
    self.TextNum.text = string.format("(%s-%s)", self.MinValue, self.MaxValue)
end

return XUiSetNumber
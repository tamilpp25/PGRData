local XUiBubbleTip = XLuaUiManager.Register(XLuaUi, "UiBubbleTip")

function XUiBubbleTip:OnAwake()
    self.XSetBubbleTipLayout:SetParameters(self.TextBg, 400, 100)
end

function XUiBubbleTip:OnStart(pointOrTouchData, content)
    self.TxtContent.text = content
    self.XSetBubbleTipLayout:SetUiLayout(pointOrTouchData.position)
end

function XUiBubbleTip:OnEnable()
    self:PlayAnimation("AnimEnableManual")
end

function XUiBubbleTip:OnDisable()
    self.AnimEnableManual:Stop()
end
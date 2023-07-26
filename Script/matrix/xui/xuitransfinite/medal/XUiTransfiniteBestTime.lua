---@class XUiTransfiniteBestTime:XLuaUi
local XUiTransfiniteBestTime = XLuaUiManager.Register(XLuaUi, "UiTransfiniteBestTime")

function XUiTransfiniteBestTime:Ctor()
    ---@type XTransfiniteMedal
    self._Medal = false
end

function XUiTransfiniteBestTime:OnAwake()
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close)
    if not self.Text then
        self.Text = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/Text", "Text")
    end
end

---@param medal XTransfiniteMedal
function XUiTransfiniteBestTime:OnStart(medal)
    self._Medal = medal
end

function XUiTransfiniteBestTime:OnEnable()
    self:Update()
end

function XUiTransfiniteBestTime:Update()
    local medal = self._Medal
    self.RImgBadge:SetRawImage(medal:GetIcon())
    self.TxtBadge.text = medal:GetName()
    self.TxtTime.text = XUiHelper.GetTime(medal:GetTime())
    self.Text.text = medal:GetDesc()
end

return XUiTransfiniteBestTime
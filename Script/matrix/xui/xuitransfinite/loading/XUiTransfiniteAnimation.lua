local XUiTransfiniteAnimationGridEvent = require("XUi/XUiTransfinite/Loading/XUiTransfiniteAnimationGridEvent")

---@class XUiTransfiniteAnimation:XLuaUi
local XUiTransfiniteAnimation = XLuaUiManager.Register(XLuaUi, "UiTransfiniteAnimation")

function XUiTransfiniteAnimation:Ctor()
    self._Callback = false
end

function XUiTransfiniteAnimation:OnAwake()
    self:RegisterClickEvent(self.ButtonClose, self.OnClickClose)
    ---@type XUiTransfiniteAnimationGridEvent[]
    self._GridBuff = {
        XUiTransfiniteAnimationGridEvent.New(self.GridBuffBoss1),
        XUiTransfiniteAnimationGridEvent.New(self.GridBuffBoss2),
        XUiTransfiniteAnimationGridEvent.New(self.GridBuffBoss3),
    }
end

function XUiTransfiniteAnimation:OnStart(stage, callback)
    self._Callback = callback
    self:Update(stage)
    self:PlayAnimation("Enable", function()
        self:PlayAnimation("Loop")
    end)
end

---@param stage XTransfiniteStage
function XUiTransfiniteAnimation:Update(stage)
    self.TxtNameTitle.text = stage:GetName()
    local events = stage:GetFightEvent()
    for i = 1, #self._GridBuff do
        local event = events[i]
        local grid = self._GridBuff[i]
        grid:Update(event)
    end
    local time = stage:GetRewardExtraTime()
    if time > 0 then
        self.Text.text = XUiHelper.GetText("TransfiniteTimeExtra2", time)
        self.PanelCondition.gameObject:SetActiveEx(true)
    else
        self.PanelCondition.gameObject:SetActiveEx(false)
    end
end

function XUiTransfiniteAnimation:OnClickClose()
    if self._Callback then
        self._Callback()
        self._Callback = nil
    end
end

return XUiTransfiniteAnimation

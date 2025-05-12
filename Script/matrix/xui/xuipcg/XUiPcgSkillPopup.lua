---@class XUiPcgSkillPopup : XLuaUi
---@field private _Control XPcgControl
local XUiPcgSkillPopup = XLuaUiManager.Register(XLuaUi, "UiPcgSkillPopup")

function XUiPcgSkillPopup:OnAwake()
    self:RegisterUiEvents()
end

function XUiPcgSkillPopup:OnStart(cardId)
    self.CardId = cardId
end

function XUiPcgSkillPopup:OnEnable()
    self.EnableTime = CS.UnityEngine.Time.realtimeSinceStartup * 1000
    self:Refresh()
end

function XUiPcgSkillPopup:OnDisable()
    self:ClearCloseTimer()
end

function XUiPcgSkillPopup:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnBgClose, self.OnBtnCloseBgClick)
end

function XUiPcgSkillPopup:OnBtnCloseBgClick()
    -- 超过存在时间才可点击关闭
    local curTime = CS.UnityEngine.Time.realtimeSinceStartup * 1000
    if (curTime - self.EnableTime) > XEnumConst.PCG.ANIM_TIME_SLAY then
        self:Close()
    end
end

-- 刷新界面
function XUiPcgSkillPopup:Refresh()
    local characterCfgs = self._Control:GetConfigCharacter()
    for _, cfg in pairs(characterCfgs) do
        if cfg.SignatureCardId == self.CardId then
            self.RImgCharacterRole:SetRawImage(cfg.HalfIcon)
            break
        end
    end

    self:ClearCloseTimer()
    self.CloseTimer =  XScheduleManager.ScheduleForever(function()
        self:Close()
    end, XEnumConst.PCG.ANIM_TIME_SLAY)
end

function XUiPcgSkillPopup:ClearCloseTimer()
    if self.CloseTimer then
        XScheduleManager.UnSchedule(self.CloseTimer)
        self.CloseTimer = nil
    end
end

return XUiPcgSkillPopup

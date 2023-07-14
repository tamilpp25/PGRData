--===============
--新版表情控件
--===============
local XUiEmojiItemEx = XClass(nil, "XUiEmojiItemEx")
local STR_RESIDUE = CS.XTextManager.GetText("Residue")

function XUiEmojiItemEx:Ctor(uiPrefab, panel)
    XTool.InitUiObjectByUi(self, uiPrefab)
    self.OnClickEmojiCb = function(emoji) panel:OnClickEmojiItem(emoji) end
    XUiHelper.RegisterClickEvent(self, self.BtnEmoji, handler(self, self.OnClickBtnEmoji))
end

function XUiEmojiItemEx:Refresh(emoji)
    self:Reset()
    self.EmojiData = emoji
    self.RImgEmojiD:SetRawImage(self.EmojiData:GetEmojiIcon())
    local isTimeLimit = self.EmojiData:IsLimitEmoji()
    self.ObjTime.gameObject:SetActiveEx(isTimeLimit)
    self.IsOverTime = false
    if isTimeLimit then
        self:SetTimeText()
        self:SetCountDownTimer()
    end
end

function XUiEmojiItemEx:SetCountDownTimer()
    if self.TimeLimitId then return end
    self.TimeLimitId = XScheduleManager.ScheduleForever(function()
            self:SetTimeText()
        end, 1)
end

function XUiEmojiItemEx:StopCountDownTimer()
    if not self.TimeLimitId then return end
    XScheduleManager.UnSchedule(self.TimeLimitId)
    self.TimeLimitId = nil
end

function XUiEmojiItemEx:SetTimeText()
    local timeNow = XTime.GetServerNowTimestamp()
    local deltaTime = self.EmojiData:GetEmojiEndTime() - timeNow
    if deltaTime > 0 then
        if self.TxtTime then
            self.TxtTime.text = STR_RESIDUE .. XUiHelper.GetTime(deltaTime, XUiHelper.TimeFormatType.CHATEMOJITIMER)
        end
    else
        self.IsOverTime = true
        self:StopCountDownTimer()
        self.GameObject:SetActiveEx(false)
    end
end

function XUiEmojiItemEx:OnClickBtnEmoji()
    if self.IsOverTime then
        XUiManager.TipText("EmojiOverTime")
        return
    end
    if self.OnClickEmojiCb then self.OnClickEmojiCb(self.EmojiData) end
end

function XUiEmojiItemEx:Reset()
    self:StopCountDownTimer()
end

function XUiEmojiItemEx:OnDisable()
    self:StopCountDownTimer()
end

function XUiEmojiItemEx:Show()
    self.GameObject:SetActiveEx(true)
end

function XUiEmojiItemEx:Hide()
    self.GameObject:SetActiveEx(false)
end

return XUiEmojiItemEx
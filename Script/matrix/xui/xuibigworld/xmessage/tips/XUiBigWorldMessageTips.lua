---@class XUiBigWorldMessageTips : XBigWorldUi
---@field BtnClick XUiComponent.XUiButton
---@field ImgHead UnityEngine.UI.RawImage
---@field TxtTips UnityEngine.UI.Text
---@field Mask UnityEngine.CanvasGroup
---@field _Control XBigWorldMessageControl
local XUiBigWorldMessageTips = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldMessageTips")

-- region 生命周期

function XUiBigWorldMessageTips:OnAwake()
    ---@type XBWMessageData
    self._MessageData = false
    self._IsForce = false
    self._Timer = false

    self:_Init()
    self:_RegisterButtonClicks()
end

function XUiBigWorldMessageTips:OnStart()
    self:_Refresh()
end

function XUiBigWorldMessageTips:OnEnable()
    self:_PlayEnableAnimation()
    self:_RegisterSchedules()
    self:_RegisterListeners()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldMessageTips:OnDisable()
    self:_RemoveSchedules()
    self:_RemoveListeners()
end

function XUiBigWorldMessageTips:OnDestroy()
    
end

-- endregion

-- region 按钮事件

function XUiBigWorldMessageTips:OnBtnClickClick()
    local messageData = self._MessageData

    XMVCA.XBigWorldUI:Close("UiBigWorldMessageTips", function()
        if messageData then
            XMVCA.XBigWorldUI:Open("UiBigWorldPopupMessageSingle", messageData.MessageId)
        end
    end)
end

-- endregion

-- region 私有方法

function XUiBigWorldMessageTips:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self:RegisterClickEvent(self.BtnClick, self.OnBtnClickClick, true)
end

function XUiBigWorldMessageTips:_RegisterSchedules()
    -- 在此处注册定时器
    if not self._IsForce then
        self:_RemoveSchedules()
        self._Timer = XScheduleManager.ScheduleOnce(Handler(self, self._PlayDisableAnimation),
            self._Control:GetMessageTipShowTime() * XScheduleManager.SECOND)
    end
end

function XUiBigWorldMessageTips:_RemoveSchedules()
    -- 在此处移除定时器
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
end

function XUiBigWorldMessageTips:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiBigWorldMessageTips:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiBigWorldMessageTips:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiBigWorldMessageTips:_Refresh()
    if self._MessageData then
        self.ImgHead:SetRawImage(self._Control:GetContactsIconByMessageId(self._MessageData.MessageId))
    end
end

function XUiBigWorldMessageTips:_PlayEnableAnimation()
    self:PlayAnimationWithMask("Enable", function()
        self.Mask.gameObject:SetActiveEx(self._IsForce or false)
    end)
end

function XUiBigWorldMessageTips:_PlayDisableAnimation()
    self:PlayAnimationWithMask("Disable", function()
        self:Close()
    end)
end

function XUiBigWorldMessageTips:_Init()
    self._MessageData = self._Control:GetForceMessageData()

    if not self._MessageData then
        self:Close()
    end

    self._IsForce = self._Control:CheckMessageIsForcePlay(self._MessageData.MessageId)
    self.Mask.gameObject:SetActiveEx(true)
    self:ChangeInput(self._IsForce)
    self:ChangeHideFightUi(self._IsForce)
end

-- endregion

return XUiBigWorldMessageTips

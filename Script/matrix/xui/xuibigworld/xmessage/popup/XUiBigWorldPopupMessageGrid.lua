---@class XUiBigWorldPopupMessageGrid : XUiNode
---@field BtnClick XUiComponent.XUiButton
---@field ImgHead UnityEngine.UI.Image
---@field Parent XUiBigWorldPopupMessage
---@field _Control XBigWorldMessageControl
local XUiBigWorldPopupMessageGrid = XClass(XUiNode, "XUiBigWorldPopupMessageGrid")

-- region 生命周期

function XUiBigWorldPopupMessageGrid:OnStart()
    ---@type XBWMessageEntity
    self._Message = false
    self._Index = 0
    self:_RegisterButtonClicks()
end

function XUiBigWorldPopupMessageGrid:OnEnable()
    self:_RegisterSchedules()
    self:_RegisterListeners()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldPopupMessageGrid:OnDisable()
    self:_RemoveSchedules()
    self:_RemoveListeners()
end

function XUiBigWorldPopupMessageGrid:OnDestroy()

end

-- endregion

---@param message XBWMessageEntity
function XUiBigWorldPopupMessageGrid:Refresh(message, index)
    self._Index = index
    self._Message = message
    self:_RefreshContacts()
end

function XUiBigWorldPopupMessageGrid:SetSelect(isSelect)
    self.BtnClick:SetButtonState(isSelect and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

-- region 按钮事件

function XUiBigWorldPopupMessageGrid:OnBtnClickClick()
    if self._Message and not self._Message:IsNil() then
        self:SetSelect(true)
        self.Parent:RefreshChat(self._Index, self._Message)
    end
end

-- endregion

-- region 私有方法

function XUiBigWorldPopupMessageGrid:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClickClick, true)
end

function XUiBigWorldPopupMessageGrid:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldPopupMessageGrid:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldPopupMessageGrid:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiBigWorldPopupMessageGrid:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiBigWorldPopupMessageGrid:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiBigWorldPopupMessageGrid:_RefreshContacts()
    if self._Message and not self._Message:IsNil() then
        local contactsId = self._Message:GetContactsId()

        self.BtnClick:SetNameByGroup(0, self._Control:GetContactsName(contactsId))
        self.BtnClick:SetNameByGroup(1, self._Message:GetCurrentPreviewText())
        self.BtnClick:ShowReddot(not self._Message:IsComplete())
        self.ImgHead:SetRawImage(self._Control:GetContactsIcon(contactsId))
    end
end

-- endregion

return XUiBigWorldPopupMessageGrid

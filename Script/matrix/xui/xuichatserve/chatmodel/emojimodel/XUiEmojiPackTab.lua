--==============
--表情包页签
--==============
local XUiEmojiPackTab = XClass(nil, "XUiEmojiPackTab")

function XUiEmojiPackTab:Ctor(uiPrefab, index, panel)
    XTool.InitUiObjectByUi(self, uiPrefab)
    self.Index = index
    self.OnClickCallBack = function(tab) panel:OnClickTab(tab) end
    self:Init()
end

function XUiEmojiPackTab:Init()
    self.ObjTime.gameObject:SetActiveEx(false)
    XUiHelper.RegisterClickEvent(self, self.BtnEmojiPack, function()
                self:OnClickEmojiPack()
            end)
end

function XUiEmojiPackTab:Refresh(emojiPack)
    self.EmojiPack = emojiPack
    self.RImgEmojiPack:SetRawImage(self.EmojiPack:GetIcon())
    self:RefreshRedPoint()
end

function XUiEmojiPackTab:RefreshRedPoint()
    if XTool.IsTableEmpty(self.EmojiPack:GetEmojiList()) then
        return
    end

    if not self.BtnEmojiPack or XTool.UObjIsNil(self.BtnEmojiPack) then
        return
    end

    local isRed = nil
    for k, v in pairs(self.EmojiPack:GetEmojiList()) do
        if v:GetIsNew() then
            isRed = true
            break
        end
    end
    self.BtnEmojiPack:ShowReddot(isRed)
end

function XUiEmojiPackTab:SetSelect(isSelect)
    if self.IsSelect == isSelect then return end
    self.IsSelect = isSelect
    self.ImgSelect.gameObject:SetActiveEx(isSelect)
end

function XUiEmojiPackTab:OnClickEmojiPack()
    if self.IsSelect then return end
    if self.OnClickCallBack then
        self.OnClickCallBack(self)
    end
end

function XUiEmojiPackTab:Show()
    self.GameObject:SetActiveEx(true)
    XEventManager.AddEventListener(XEventId.EVENT_CHAT_EMOJI_REFRESH_RED, self.RefreshRedPoint, self)
end

function XUiEmojiPackTab:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiEmojiPackTab:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_CHAT_EMOJI_REFRESH_RED, self.RefreshRedPoint, self)
end

return XUiEmojiPackTab
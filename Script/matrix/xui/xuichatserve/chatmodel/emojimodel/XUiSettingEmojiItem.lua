--=============
--表情包排序界面表情包项控件
--=============
local XUiSettingEmojiItem = XClass(nil, "XUiSettingEmojiItem")

function XUiSettingEmojiItem:Ctor(uiPrefab, panel)
    XTool.InitUiObjectByUi(self, uiPrefab)
    self.OnClickUpCb = function(index) panel.SetTop(panel, index) end
    self:Init()
end

function XUiSettingEmojiItem:Init()
    XUiHelper.RegisterClickEvent(self, self.BtnEmojiUp, handler(self, self.OnClickEmojiUp))
end

function XUiSettingEmojiItem:Refresh(emojiPack, index)
    self.Index = index
    self.EmojiPack = emojiPack
    self.RImgEmojiD:SetRawImage(self.EmojiPack:GetIcon())
    self.TxtName.text = self.EmojiPack:GetName()
    self.TxtDescription.text = self.EmojiPack:GetDescription()
    self.BtnEmojiUp.gameObject:SetActiveEx(self.Index and self.Index > 1)
end

function XUiSettingEmojiItem:OnClickEmojiUp()
    if self.OnClickUpCb then
        self.OnClickUpCb(self.Index or 1)
    end
end

function XUiSettingEmojiItem:Show()
    self.GameObject:SetActiveEx(true)
end

function XUiSettingEmojiItem:Hide()
    self.GameObject:SetActiveEx(false)
end

return XUiSettingEmojiItem
--=======================
--以下脚本以废弃，由XUiEmojiItemEx代替
--=======================
--[[
local XUiEmojiItem = XClass(nil, "XUiEmojiItem")--表情面板里面的item

function XUiEmojiItem:Ctor(rootUi, ui)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    self:InitAutoScript()

    self.ClickCallBack = nil
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiEmojiItem:InitAutoScript()
    self.SpecialSoundMap = {}
    self:AutoAddListener()
end


function XUiEmojiItem:AutoAddListener()
    self.AutoCreateListeners = {}
    XUiHelper.RegisterClickEvent(self, self.BtnEmoji, self.OnBtnEmojiClick)
end
-- auto
function XUiEmojiItem:OnBtnEmojiClick()--发送表情
    if self.ClickCallBack then
        local content = tostring(self.EmojiId)
        self.ClickCallBack(content)
    end
end

function XUiEmojiItem:Refresh(emojiData)
    self.EmojiData = emojiData
    self.EmojiId = self.EmojiData:GetEmojiId()
    local icon = emojiData:GetEmojiIcon()
    if icon ~= nil then
        self.RImgEmojiD:SetRawImage(icon)
    end
end

function XUiEmojiItem:SetClickCallBack(cb)
    self.ClickCallBack = cb
end

function XUiEmojiItem:Show()
    if self.GameObject:Exist() then
        self.GameObject:SetActiveEx(true)
    end
end

function XUiEmojiItem:Hide()
    if self.GameObject:Exist() then
        self.GameObject:SetActiveEx(false)
        self.TimeObj.gameObject:SetActiveEx(false)
    end
end

function XUiEmojiItem:ShowTimeLabel(showStr)
    if showStr and showStr ~= "" then
        self.TimeObj.gameObject:SetActiveEx(true)
        self.TimeLable.text = showStr
    else
        self.TimeObj.gameObject:SetActiveEx(false)
    end
    
end

return XUiEmojiItem
]]
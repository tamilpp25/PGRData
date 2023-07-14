--===============
--新版表情包面板控件
--===============
local XUiPanelEmojiEx = XClass(nil, "XUiPanelEmojiEx")
local XEmojiItemEx = require("XUi/XUiChatServe/ChatModel/EmojiModel/XUiEmojiItemEx")
local XEmojiPackTab = require("XUi/XUiChatServe/ChatModel/EmojiModel/XUiEmojiPackTab")

function XUiPanelEmojiEx:Ctor(rootUi, uiPrefab)
    XTool.InitUiObjectByUi(self, uiPrefab)
    self.FirstOpenFlag = true
    self.OpenEmojiSetupFunc = function() rootUi:OpenPanelEmojiSetup() end
    self:InitPanels()
end

function XUiPanelEmojiEx:InitPanels()
    self:InitBtns()
    self:InitTabs()
    self:InitContents()
end

function XUiPanelEmojiEx:InitBtns()
    self.BtnBack.CallBack = function() self:OnClickBack() end
    XUiHelper.RegisterClickEvent(self, self.BtnSetting, handler(self, self.OnClickSetting))
end

function XUiPanelEmojiEx:InitTabs()
    self.Tabs = {}
    self.EmojiPackTab.gameObject:SetActiveEx(false)
end

function XUiPanelEmojiEx:RefreshTabs()
    local allPacks = XDataCenter.ChatManager.GetAllEmojiPacksWithAutoSort()
    local index = 1
    for _, pack in pairs(allPacks) do
        if not self.Tabs[index] then
            local tabObj = CS.UnityEngine.GameObject.Instantiate(self.EmojiPackTab.gameObject, self.TabContent)
            self.Tabs[index] = XEmojiPackTab.New(tabObj, index, self)
        end
        self.Tabs[index]:Refresh(pack)
        self.Tabs[index]:Show()
        index = index + 1
    end
    --把多余的页签隐藏
    for i = index, #self.Tabs do
        self.Tabs[i]:Hide()
        index = index + 1
    end
end

function XUiPanelEmojiEx:InitContents()
    self.Emojis = {}
    self.EmojiItem.gameObject:SetActiveEx(false)
end

function XUiPanelEmojiEx:RefreshContent(pack)
    local emojis = pack:GetEmojiList()
    local index = 1
    for _, emoji in pairs(emojis) do
        local emojiItem = self:GetEmojiByIndex(index)
        if emojiItem then
            emojiItem:Show()
            emojiItem:Refresh(emoji)
        end
        index = index + 1
    end
    --把多余的表情控件隐藏
    for i = index, #self.Emojis do
        local emojiItem = self:GetEmojiByIndex(i)
        if emojiItem then
            emojiItem:Hide()
        end
        index = index + 1
    end
end

function XUiPanelEmojiEx:GetEmojiByIndex(index)
    if self.Emojis[index] then return self.Emojis[index] end
    local gameObject = CS.UnityEngine.GameObject.Instantiate(self.EmojiItem.gameObject, self.EmojiContent)
    if gameObject ~= nil then
        self.Emojis[index] = XEmojiItemEx.New(gameObject, self)
    end
    return self.Emojis[index]
end

function XUiPanelEmojiEx:OnClickTab(tab)
    local selectIndex = tab.Index
    if self.SelectIndex == selectIndex then return end
    for _, tab in pairs(self.Tabs) do
        tab:SetSelect(tab.Index == selectIndex)
    end
    self:RefreshContent(tab.EmojiPack)
    self.SelectIndex = selectIndex
end

function XUiPanelEmojiEx:SetClickCallBack(cb)
    self.OnItemClickCallBack = cb
end

function XUiPanelEmojiEx:OnClickEmojiItem(emoji)
    local content = tostring(emoji:GetEmojiId())
    self.OnItemClickCallBack(content)
end

function XUiPanelEmojiEx:Hide()
    if XTool.UObjIsNil(self.GameObject) then return end
    self:OnDisable()
    if self.MainPanel then
        self.MainPanel.gameObject:SetActiveEx(false)
        self.GameObject:SetActiveEx(false)
    else
        self.GameObject:SetActiveEx(false)
    end
end

function XUiPanelEmojiEx:OnDisable()
    self:DisableAllEmoji()
end

function XUiPanelEmojiEx:OnDestroy()
    self:DisableAllEmoji()
end

function XUiPanelEmojiEx:DisableAllEmoji()
    for _, emojiGrid in pairs(self.Emojis) do
        emojiGrid:OnDisable()
    end
end

function XUiPanelEmojiEx:Show()
    if XTool.UObjIsNil(self.GameObject) then return end
    local _onShow = function()
        if self.MainPanel then
            self.MainPanel.gameObject:SetActiveEx(true)
            self.GameObject:SetActiveEx(true)
        else
            self.GameObject:SetActiveEx(true)
        end
        self:RefreshTabs()
        self:OnClickTab(self.Tabs[self.SelectIndex or 1])
        self.FirstOpenFlag = false
    end
    if self.FirstOpenFlag then
        XDataCenter.ChatManager.GetEmojiPackOrder(_onShow)
    else
        _onShow()
    end
end

function XUiPanelEmojiEx:OpenOrClosePanel()
    if self.GameObject == nil then
        return
    end
    if not XTool.UObjIsNil(self.GameObject) then
        if not self.GameObject.activeSelf then
            self:Show()
        else
            self:Hide()
        end
    end
end

function XUiPanelEmojiEx:OnClickBack()
    self:Hide()
end

function XUiPanelEmojiEx:OnClickSetting()
    self:Hide()
    if self.OpenEmojiSetupFunc then
        self.OpenEmojiSetupFunc()
    end
end

return XUiPanelEmojiEx
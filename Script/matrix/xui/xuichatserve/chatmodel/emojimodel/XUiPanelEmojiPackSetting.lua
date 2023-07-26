--===============
--表情包设置面板
--===============
local XUiPanelEmojiPackSetting = XClass(nil, "XUiPanelEmojiPackSetting")
local XUiSettingEmojiItem = require("XUi/XUiChatServe/ChatModel/EmojiModel/XUiSettingEmojiItem")

function XUiPanelEmojiPackSetting:Ctor(rootUi, uiPrefab)
    XTool.InitUiObjectByUi(self, uiPrefab)
    self.OpenPanelEmojiFunc = function() rootUi:OpenPanelEmoji() end
    self:Init()
end

function XUiPanelEmojiPackSetting:Init()
    self:InitBtns()
end

function XUiPanelEmojiPackSetting:InitBtns()
    self.BtnClose.CallBack = function() self:OnClickClose() end
    self.BtnBack.CallBack = function() self:OnClickBack() end
end

function XUiPanelEmojiPackSetting:InitItems()
    if self.ItemInitailFlag then return end
    self.EmojiItems = {}
    self.PackList = XDataCenter.ChatManager.GetAllEmojiPacksWithOutDefault()
    self:RefreshOrder()
    self.EmojiItem.gameObject:SetActiveEx(false)
    self.ItemInitailFlag = true
end

function XUiPanelEmojiPackSetting:GetNewItem(index)
    if self.EmojiItems[index] then
        return self.EmojiItems[index]
    end
    local go = CS.UnityEngine.GameObject.Instantiate(self.EmojiItem, self.EmojiItemContent)
    local newItem = XUiSettingEmojiItem.New(go, self)
    self.EmojiItems[index] = newItem
    return self.EmojiItems[index]
end

function XUiPanelEmojiPackSetting:OnClickClose()
    self:Hide()
    if self.OpenPanelEmojiFunc then
        self.OpenPanelEmojiFunc()
    end
end

function XUiPanelEmojiPackSetting:OnClickBack()
    self:Hide()
end

function XUiPanelEmojiPackSetting:SetTop(index)
    if index == 1 then return end
    local setPack = self.PackList[index]
    table.remove(self.PackList, index)
    table.insert(self.PackList, 1, setPack)
    self:SetCustomOrder()
    self:RefreshOrder()
end

function XUiPanelEmojiPackSetting:SetCustomOrder()
    local idList = {}
    for index, pack in pairs(self.PackList) do
        idList[index] = pack:GetId()
    end
    XDataCenter.ChatManager.SaveEmojiPackOrder(idList, function()
            XDataCenter.ChatManager.SetCustomPackOrder(idList)
        end)
end

function XUiPanelEmojiPackSetting:RefreshOrder()
    local index = 1
    for _, pack in pairs(self.PackList or {}) do
        local item = self:GetNewItem(index)
        item:Refresh(pack, index)
        item:Show()
        index = index + 1
    end
end

function XUiPanelEmojiPackSetting:Show()
    self:InitItems() --防止界面出现时就初始化比获取服务器顺序早，所以初始化在显示时才初始化
    self.GameObject:SetActiveEx(true)
end

function XUiPanelEmojiPackSetting:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelEmojiPackSetting:OnDisable()
    self:Hide()
end

function XUiPanelEmojiPackSetting:OnDestroy()
    self:Hide()
end

return XUiPanelEmojiPackSetting
local XUiGridChatChannelItem = XClass(nil, "XUiGridChatChannelItem")
local XUiButtonState = CS.UiButtonState
local isShowChannelNumber = CS.XGame.ClientConfig:GetInt("IsShowChannelNumber")

function XUiGridChatChannelItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
end

function XUiGridChatChannelItem:Init(uiRoot)
    self.UiRoot = uiRoot
end

function XUiGridChatChannelItem:SetItemData(itemData)
    self.GridChannelItem:SetNameByGroup(0, CS.XTextManager.GetText(itemData.IsRecruitChannel and "ChannelRecruit" or "ChannelLabel"))
    --特殊需求市网信办举报导致的频道5需要屏蔽显示
    local channelId = itemData.ChannelId >= 5 and (itemData.ChannelId + 1) or itemData.ChannelId
    self.GridChannelItem:SetNameByGroup(1, itemData.IsRecruitChannel and "" or tostring(channelId))

    if isShowChannelNumber == 1 then
        self.GridChannelItem:SetNameByGroup(2, CS.XTextManager.GetText("ChannelNumberLabel", itemData.PlayerNum))
    else
        self.GridChannelItem:SetNameByGroup(2, "")
    end

    local isSelectChannel = itemData.ChannelId == XDataCenter.ChatManager.GetCurrentChatChannelId()
    self.GridChannelItem:ShowTag(isSelectChannel)
    self:SetChannelSelected(itemData.IsSelected)
end

function XUiGridChatChannelItem:SetChannelSelected(isSelected)
    local btnState = isSelected and XUiButtonState.Select or XUiButtonState.Normal
    self.GridChannelItem:SetButtonState(btnState)
end

return XUiGridChatChannelItem
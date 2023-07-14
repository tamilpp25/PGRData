local XUiGridGuildLogItem = XClass(nil, "XUiGridGuildLogItem")

function XUiGridGuildLogItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.OldSizeDelta = self.Transform.sizeDelta
    XTool.InitUiObject(self)
end

function XUiGridGuildLogItem:Init(uiRoot)
    self.UiRoot = uiRoot
end

function XUiGridGuildLogItem:SetItemData(itemData, newsType)
    local newsConfig = XGuildConfig.GetGuildNewsById(itemData.MsgId)
    self.PanelContent.text = CS.XTextManager.FormatString(newsConfig.Content, itemData.Params[1], itemData.Params[2], itemData.Params[3], itemData.Params[4], itemData.Params[5])
    self.TxtInfo.text = CS.XTextManager.GetText("GuildLogItemType", XGuildConfig.NewsName[newsConfig.Group])
    self.TxtInfoTime1.text = XTime.TimestampToGameDateTimeString(itemData.Time, "HH:mm")
    self.TxtInfoTime2.text = XTime.TimestampToGameDateTimeString(itemData.Time, "MM/dd")
    self:OnResize()
end

function XUiGridGuildLogItem:OnResize()
    self.Transform.sizeDelta = CS.UnityEngine.Vector2(self.OldSizeDelta.x, self.PanelContent.preferredHeight + 30)
end

return XUiGridGuildLogItem
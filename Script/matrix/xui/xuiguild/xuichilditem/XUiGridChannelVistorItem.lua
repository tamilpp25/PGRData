local XUiGridChannelVistorItem = XClass(nil, "XUiGridChannelVistorItem")

function XUiGridChannelVistorItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.OriginSize = self.Transform.sizeDelta
    XTool.InitUiObject(self)
end

function XUiGridChannelVistorItem:Init(uiRoot)
    self.UiRoot = uiRoot
end

-- 更新数据
function XUiGridChannelVistorItem:OnRefresh(itemdata)
    if not itemdata then
        return
    end

    local nameRemark = XDataCenter.SocialManager.GetPlayerRemark(itemdata.SenderId, itemdata.NickName)
    if itemdata.MsgType == ChatMsgType.System then
        self.TxtInfo.text = string.format("<color=#00A0FFE6>%s：</color>%s", CS.XTextManager.GetText("GuildChannelTypeAll"), itemdata.Content)
    else
        self.TxtInfo.text = string.format("<color=#000000FF>【%s】：</color>%s", nameRemark, itemdata.Content)
    end

    self:Resize()
end

function XUiGridChannelVistorItem:Resize()
    self.Transform.sizeDelta = CS.UnityEngine.Vector2(self.OriginSize.x, self.TxtInfo.preferredHeight)
end
return XUiGridChannelVistorItem
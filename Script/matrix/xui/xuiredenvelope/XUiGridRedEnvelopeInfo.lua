local XUiGridRedEnvelopeInfo = XClass(nil, "XUiGridRedEnvelopeInfo")

function XUiGridRedEnvelopeInfo:Ctor(ui, parent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:InitParent(parent)
end

function XUiGridRedEnvelopeInfo:InitParent(parent)
    self.Parent = parent
end

function XUiGridRedEnvelopeInfo:Refresh(info)
    local id = info.Id
    local count = info.ItemCount
    local itemId = info.ItemId
    local isLuckyBoy = info.IsLuckyBoy

    local headIcon, headEffect, name = "", ""
    if id == self.Parent.LeaderTemplateId then
        name = XPlayer.Name
        if self.Head then
            XUiPLayerHead.InitPortrait(XPlayer.CurrHeadPortraitId, XPlayer.CurrHeadFrameId, self.Head)
        end
    else
        local config = XRedEnvelopeConfigs.GetNpcConfig(id)
        name = config.NpcName
        if self.RImgHead then
            self.RImgHead:SetRawImage(config.NpcHead) 
        end
    end

    self.TxtName.text = name
    self.TxtNum.text = count
    self.PanelLucky.gameObject:SetActiveEx(isLuckyBoy)
    self.RImgIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(itemId))
end

return XUiGridRedEnvelopeInfo
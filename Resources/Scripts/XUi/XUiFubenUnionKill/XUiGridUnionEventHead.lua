local XUiGridUnionEventHead = XClass(nil, "XUiGridUnionEventHead")

function XUiGridUnionEventHead:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
end

function XUiGridUnionEventHead:Refresh(playerInfo)
    self.GameObject:SetActiveEx(true)
    local playerHeadPortraitId = playerInfo.PlayerHeadPortraitId
    local playerHeadFrameId = playerInfo.PlayerHeadFrameId
    XUiPLayerHead.InitPortrait(playerHeadPortraitId, playerHeadFrameId, self.Head)
    self.TxtLevel.text = playerInfo.Position
end

return XUiGridUnionEventHead
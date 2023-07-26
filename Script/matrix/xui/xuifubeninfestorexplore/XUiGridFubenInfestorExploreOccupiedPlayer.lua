local XUiGridFubenInfestorExploreOccupiedPlayer = XClass(nil, "XUiGridFubenInfestorExploreOccupiedPlayer")

function XUiGridFubenInfestorExploreOccupiedPlayer:Ctor(ui, playerId)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    local name = XDataCenter.FubenInfestorExploreManager.GetPlayerName(playerId)
    self.TxtName.text = name

    local headId = XDataCenter.FubenInfestorExploreManager.GetPlayerHeadId(playerId)
    local frameId = XDataCenter.FubenInfestorExploreManager.GetPlayerHeadFrameId(playerId)
    
    XUiPLayerHead.InitPortrait(headId, frameId, self.HeadMe)
    XUiPLayerHead.InitPortrait(headId, frameId, self.HeadPeople)

    local isMe = playerId == XPlayer.Id
    self.PanelMe.gameObject:SetActiveEx(isMe)
    self.PanelPeople.gameObject:SetActiveEx(not isMe)
end

return XUiGridFubenInfestorExploreOccupiedPlayer
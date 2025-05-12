local XUiPlayerLevel = require("XUi/XUiCommon/XUiPlayerLevel")
local XUiGridInfestorExplorePlayerMessage = XClass(nil, "XUiGridInfestorExplorePlayerMessage")

function XUiGridInfestorExplorePlayerMessage:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
end

function XUiGridInfestorExplorePlayerMessage:Refresh(msg)
    local playerId = msg.Id

    local headId = XDataCenter.FubenInfestorExploreManager.GetPlayerHeadId(playerId)
    local frameId = XDataCenter.FubenInfestorExploreManager.GetPlayerHeadFrameId(playerId)
    
    XUiPlayerHead.InitPortrait(headId, frameId, self.Head)
    
    local name = XDataCenter.FubenInfestorExploreManager.GetPlayerName(playerId)
    self.TxtName.text = name

    local level = XDataCenter.FubenInfestorExploreManager.GetPlayerLevel(playerId)

    XUiPlayerLevel.UpdateLevel(level, self.TxtLevel)

    local diffName = XDataCenter.FubenInfestorExploreManager.GetPlayerDiffName(playerId)
    self.TxtRegion.text = diffName

    local diffIcon = XDataCenter.FubenInfestorExploreManager.GetPlayerDiffIcon(playerId)
    self.RImgIconRegion:SetRawImage(diffIcon)

    self.TxtMsg.text = msg.Msg
end

return XUiGridInfestorExplorePlayerMessage
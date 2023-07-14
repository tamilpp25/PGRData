local XUiGuildDormNameGrid = XClass(nil, "XUiGuildDormNameGrid")

function XUiGuildDormNameGrid:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
    self.CurrentRoom = XDataCenter.GuildDormManager.GetCurrentRoom()
    self.RLRole = nil
    self.PlayerId = nil
end

function XUiGuildDormNameGrid:SetData(rlRole, offsetHeight, playerId)
    self.RLRole = rlRole
    self.Offset = CS.UnityEngine.Vector3(0, offsetHeight, 0)
    if playerId == XPlayer.Id then
        self.TxtName.text = XPlayer.Name
    else
        local playerName = XDataCenter.GuildDormManager.GetPlayerName(playerId)
        if playerName then
            self.TxtName.text = playerName
        else
            self.TxtName.text = "unknow"
        end
    end
end

function XUiGuildDormNameGrid:UpdateTransform()
    self.CurrentRoom:SetViewPosToTransformLocalPosition(self.Transform, self.RLRole:GetTransform(), self.Offset)
end

function XUiGuildDormNameGrid:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiGuildDormNameGrid:Show(parent)
    self.GameObject:SetActiveEx(true)
    if parent then
        self.Transform:SetParent(parent, false)
    end
end

function XUiGuildDormNameGrid:SetPlayerId(value)
    self.PlayerId = value
end

function XUiGuildDormNameGrid:GetPlayerId()
    return self.PlayerId
end

return XUiGuildDormNameGrid
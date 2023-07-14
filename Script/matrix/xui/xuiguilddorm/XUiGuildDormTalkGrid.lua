local Time = CS.UnityEngine.Time
local XUiGuildDormTalkGrid = XClass(nil, "XUiGuildDormTalkGrid")

function XUiGuildDormTalkGrid:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
    self.CurrentRoom = XDataCenter.GuildDormManager.GetCurrentRoom()
    self.RLRole = nil
    self.CreateTime = 0
    self.PlayerId = nil
end

function XUiGuildDormTalkGrid:SetData(content, rlRole, offsetHeight, isEmoji)
    self.RLRole = rlRole
    self.Offset = CS.UnityEngine.Vector3(0, offsetHeight, 0)
    self.PanelText.gameObject:SetActiveEx(not isEmoji)
    self.PanelEmoji.gameObject:SetActiveEx(isEmoji)
    if isEmoji then
        self.RImgEmoji:SetRawImage(XDataCenter.ChatManager.GetEmojiIcon(content))
    else
        self.TxtDesc.text = content
    end
    self.CreateTime = Time.realtimeSinceStartup
end

function XUiGuildDormTalkGrid:GetIsArriveHideTime()
    return Time.realtimeSinceStartup - self.CreateTime >= XGuildDormConfig.GetTalkHideTime()
end

function XUiGuildDormTalkGrid:UpdateTransform()
    self.CurrentRoom:SetViewPosToTransformLocalPosition(self.Transform, self.RLRole:GetTransform(), self.Offset)
end

function XUiGuildDormTalkGrid:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiGuildDormTalkGrid:Show(parent)
    self.GameObject:SetActiveEx(true)
    if parent then
        self.Transform:SetParent(parent, false)
    end
end

function XUiGuildDormTalkGrid:SetPlayerId(value)
    self.PlayerId = value
end

function XUiGuildDormTalkGrid:GetPlayerId()
    return self.PlayerId
end

return XUiGuildDormTalkGrid
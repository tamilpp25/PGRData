local Time = CS.UnityEngine.Time
local XUiGuildDormTalkGrid = XClass(nil, "XUiGuildDormTalkGrid")

function XUiGuildDormTalkGrid:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
    self.CurrentRoom = XDataCenter.GuildDormManager.GetCurrentRoom()
    self.Entity = nil
    self.CreateTime = 0
    self.HideTime = 0
end

function XUiGuildDormTalkGrid:SetData(entity, content, isEmoji, hideTime)
    if hideTime == nil or hideTime <= 0 then hideTime = XGuildDormConfig.GetTalkHideTime() end
    self.HideTime = hideTime
    self.Entity = entity
    self.Offset = CS.UnityEngine.Vector3(0, entity:GetTalkHeightOffset(), 0)
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
    return Time.realtimeSinceStartup - self.CreateTime >= self.HideTime / 1000
end

function XUiGuildDormTalkGrid:UpdateTransform()
    self.CurrentRoom:SetViewPosToTransformLocalPosition(self.Transform, self.Entity:GetRLEntity():GetTransform(), self.Offset)
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

function XUiGuildDormTalkGrid:GetEntityId()
    return self.Entity:GetEntityId()
end


return XUiGuildDormTalkGrid
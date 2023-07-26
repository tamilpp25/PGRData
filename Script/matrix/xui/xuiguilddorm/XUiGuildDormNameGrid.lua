local XUiGuildDormNameGrid = XClass(nil, "XUiGuildDormNameGrid")

function XUiGuildDormNameGrid:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
    self.CurrentRoom = XDataCenter.GuildDormManager.GetCurrentRoom()
    self.RLEntity = nil
    self.EntityId = nil
    self.ShowDistance = 0
end

function XUiGuildDormNameGrid:SetData(rlEntity, offsetHeight)
    self.RLEntity = rlEntity
    self.Offset = CS.UnityEngine.Vector3(0, offsetHeight, 0)
end

function XUiGuildDormNameGrid:SetName(value)
    if XTool.UObjIsNil(self.TxtName) then return end
    self.TxtName.text = value or "unknow"
end

function XUiGuildDormNameGrid:SetTriangle(value)
    for i = 1, 2 do
        self["Triangle" .. i].gameObject:SetActiveEx(value == i)
    end
end

function XUiGuildDormNameGrid:SetShowDistance(value)
    self.ShowDistance = value
end

function XUiGuildDormNameGrid:UpdateTransform()
    self.CurrentRoom:SetViewPosToTransformLocalPosition(self.Transform, self.RLEntity:GetTransform(), self.Offset)
end

function XUiGuildDormNameGrid:Hide()
    if XTool.UObjIsNil(self.GameObject) then return end
    self.GameObject:SetActiveEx(false)
end

function XUiGuildDormNameGrid:Show(parent)
    self.GameObject:SetActiveEx(true)
    if parent then
        self.Transform:SetParent(parent, false)
    end
    -- 小于等于0默认显示
    if self.ShowDistance <= 0 then return end
    -- 判断一下与主要玩家的距离
    local role = self.CurrentRoom:GetRoleByPlayerId(XPlayer.Id)
    local distance = CS.XGuildDormHelper.GetDistance(self.RLEntity:GetTransform(), role:GetRLEntity():GetTransform())
    self.GameObject:SetActiveEx(distance <= self.ShowDistance)
end

function XUiGuildDormNameGrid:SetEntityId(value)
    self.EntityId = value
end

function XUiGuildDormNameGrid:GetEntityId()
    return self.EntityId
end

return XUiGuildDormNameGrid
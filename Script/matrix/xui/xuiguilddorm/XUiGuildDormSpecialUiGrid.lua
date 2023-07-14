local XUiGuildDormSpecialUiGrid = XClass(nil, "XUiGuildDormSpecialUiGrid")

function XUiGuildDormSpecialUiGrid:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
    self.CurrentRoom = XDataCenter.GuildDormManager.GetCurrentRoom()
    self.Entity = nil
    self.Offset = 0
    self.UiName = nil
    self.ShowDistance = 0
end

function XUiGuildDormSpecialUiGrid:SetData(entity, uiname)
    self.Entity = entity
    self.RLEntity = entity:GetRLEntity()
    self.UiName = uiname
end

function XUiGuildDormSpecialUiGrid:SetOffset(value)
    self.Offset = CS.UnityEngine.Vector3(0, value, 0)
end

function XUiGuildDormSpecialUiGrid:SetShowDistance(value)
    self.ShowDistance = value
end

function XUiGuildDormSpecialUiGrid:UpdateTransform()
    self.CurrentRoom:SetViewPosToTransformLocalPosition(self.Transform, self.RLEntity:GetTransform(), self.Offset)
end

function XUiGuildDormSpecialUiGrid:Hide()
    if XTool.UObjIsNil(self.GameObject) then return end
    self.GameObject:SetActiveEx(false)
end

function XUiGuildDormSpecialUiGrid:Show(parent)
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

function XUiGuildDormSpecialUiGrid:Destroy()
    XUiHelper.Destroy(self.GameObject)
end

function XUiGuildDormSpecialUiGrid:GetEntityId()
    return self.Entity:GetEntityId()
end

function XUiGuildDormSpecialUiGrid:GetUiName()
    return self.UiName
end

return XUiGuildDormSpecialUiGrid
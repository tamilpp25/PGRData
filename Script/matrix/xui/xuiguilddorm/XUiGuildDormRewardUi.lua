local XUiGuildDormRewardUi = XClass(nil, "XUiGuildDormRewardUi")

function XUiGuildDormRewardUi:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
    self.CurrentRoom = XDataCenter.GuildDormManager.GetCurrentRoom()
    self.Entity = nil
    self.Offset = 0
    self.UiName = nil
    self.ShowDistance = 0
end

function XUiGuildDormRewardUi:SetData(entity, uiname)
    self.Entity = entity
    self.RLEntity = entity:GetRLEntity()
    self.UiName = uiname
end

function XUiGuildDormRewardUi:SetOffset(value)
    self.Offset = CS.UnityEngine.Vector3(0, value, 0)
end

function XUiGuildDormRewardUi:SetShowDistance(value)
    self.ShowDistance = value
end

function XUiGuildDormRewardUi:UpdateTransform()
    self.CurrentRoom:SetViewPosToTransformLocalPosition(self.Transform, self.RLEntity:GetTransform(), self.Offset)
end

function XUiGuildDormRewardUi:Hide()
    if XTool.UObjIsNil(self.GameObject) then return end
    self.GameObject:SetActiveEx(false)
end

function XUiGuildDormRewardUi:Show(parent)
    self.GameObject:SetActiveEx(true)
    if parent then
        self.Transform:SetParent(parent, false)
    end
    -- 小于等于0默认显示
    if self.ShowDistance <= 0 then return end
    -- 判断一下与主要玩家的距离
    local role = self.CurrentRoom:GetRoleByPlayerId(XPlayer.Id)
    local distance = CS.XGuildDormHelper.GetDistance(self.RLEntity:GetTransform(), role:GetRLEntity():GetTransform())
    local condition = self.Entity.Config.RedPointCondition
    local isShow = distance <= self.ShowDistance
    if not string.IsNilOrEmpty(condition) then
        isShow = isShow and XRedPointManager.CheckConditions({ condition })
    end
    self.GameObject:SetActiveEx(isShow)
end

function XUiGuildDormRewardUi:Destroy()
    XUiHelper.Destroy(self.GameObject)
end

function XUiGuildDormRewardUi:GetEntityId()
    return self.Entity:GetEntityId()
end

function XUiGuildDormRewardUi:GetUiName()
    return self.UiName
end

return XUiGuildDormRewardUi
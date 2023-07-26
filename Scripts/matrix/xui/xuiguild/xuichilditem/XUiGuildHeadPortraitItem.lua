local XUiGuildHeadPortraitItem = XClass(nil, "XUiGuildHeadPortraitItem")

function XUiGuildHeadPortraitItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiGuildHeadPortraitItem:Init(parent)
    self.Parent = parent
end

function XUiGuildHeadPortraitItem:SetStatus(status)
    self.ImgRoleSelect.gameObject:SetActiveEx(status)
end

function XUiGuildHeadPortraitItem:OnRefresh(itemdata)
    if not itemdata then
        return
    end
    self.ItemData = itemdata
    local conditionId = itemdata.ConditionId
    local unlock, desc = true, ""
    if XTool.IsNumberValid(conditionId) then
        unlock, desc = XConditionManager.CheckCondition(conditionId)
    end
    self.GuildIcon = itemdata.Icon
    self.SelRoleHead.gameObject:SetActiveEx(unlock)
    self.LockRoleHead.gameObject:SetActiveEx(not unlock)
    local rIcon = unlock and self.UnLockImgHeadImg or self.LockImgHeadImg
    rIcon:SetRawImage(self.GuildIcon)
    
    self.GuildId = itemdata.Id
    self.GuildDescribe = itemdata.Describe
    local flag = self.Parent:IsSeleId(self.GuildId)
    self:SetStatus(flag)
    if flag then
        self.Parent:RecordFirstSeleItem(self)
    end
    self:RefreshRedPoint()
end

function XUiGuildHeadPortraitItem:RefreshRedPoint()
    self.RedPoint.gameObject:SetActiveEx(not XDataCenter.GuildManager.IsMarkHeadPortrait(self.GuildId))
end

return XUiGuildHeadPortraitItem
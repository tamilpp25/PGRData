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

    self.GuildId = itemdata.Id
    self.GuildDescribe = itemdata.Describe
    self.GuildIcon = itemdata.Icon
    self.UnLockImgHeadImg:SetRawImage(self.GuildIcon)
    local flag = self.Parent:IsSeleId(self.GuildId)
    self:SetStatus(flag)
    if flag then
        self.Parent:RecordFirstSeleItem(self)
    end
end

return XUiGuildHeadPortraitItem
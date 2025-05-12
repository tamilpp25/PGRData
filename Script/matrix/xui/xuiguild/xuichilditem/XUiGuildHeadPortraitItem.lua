local CSUnityColorWhite = CS.UnityEngine.Color.white
local CSUnityColor = CS.UnityEngine.Color

local XUiGuildHeadPortraitItem = XClass(nil, "XUiGuildHeadPortraitItem")

function XUiGuildHeadPortraitItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiGuildHeadPortraitItem:Init(parent)
    self.Parent = parent
    self.DefaultUnLockIconColor = self.UnLockImgHeadImg.color
    self.DefaultLockIconColor = self.LockImgHeadImg.color
end

function XUiGuildHeadPortraitItem:SetStatus(status)
    self.ImgRoleSelect.gameObject:SetActiveEx(status)
end

function XUiGuildHeadPortraitItem:OnRefresh(itemData)
    if not itemData then
        return
    end
    self.ItemData = itemData
    local conditionId = itemData.ConditionId
    local unlock, desc = true, ""
    if XTool.IsNumberValid(conditionId) then
        unlock, desc = XConditionManager.CheckCondition(conditionId)
    end
    self.GuildIcon = itemData.Icon
    self.IsSpecial = itemData.IsSpecial
    self.SelRoleHead.gameObject:SetActiveEx(unlock)
    self.LockRoleHead.gameObject:SetActiveEx(not unlock)
    local rIcon = unlock and self.UnLockImgHeadImg or self.LockImgHeadImg
    rIcon:SetRawImage(self.GuildIcon)
    if self.IsSpecial then
        self.UnLockImgHeadImg.color = CSUnityColorWhite
        self.LockImgHeadImg.color = CSUnityColor(1, 1, 1, self.DefaultLockIconColor.a)
        self.RImgSpecialHeadBg.gameObject:SetActiveEx(true)
        self.RImgSpecialHeadBg:SetRawImage(itemData.GuildHeadPortraitBg)
    else
        self.UnLockImgHeadImg.color = self.DefaultUnLockIconColor
        self.LockImgHeadImg.color = self.DefaultLockIconColor
        self.RImgSpecialHeadBg.gameObject:SetActiveEx(false)
    end
    
    self.GuildId = itemData.Id
    self.GuildDescribe = itemData.Describe
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
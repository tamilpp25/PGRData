local XUiGridArchive = require("XUi/XUiArchive/XUiGridArchive")
--
-- Author: wujie
-- Note: 图鉴武器格子信息
local XUiGridArchiveWeapon = XClass(XUiNode, "XUiGridArchiveWeapon")

function XUiGridArchiveWeapon:OnStart(clickCb, rootUi)
    self.RootUi = rootUi
    self.ClickCb = clickCb
    
    self.BtnClick.CallBack = function() self:OnBtnClick() end
end

function XUiGridArchiveWeapon:Refresh(templateIdList,index)
    local templateId = templateIdList and templateIdList[index]
    if not templateId then return end
    self.TemplateId = templateId
    self.TemplateIdList = templateIdList
    self.TemplateIndex = index
    local templateData = XMVCA.XEquip:GetConfigEquip(templateId)

    local isGet = XMVCA.XArchive:IsWeaponGet(templateId)
    local iconPath = XMVCA.XEquip:GetEquipBigIconPath(templateId, 0)
    if isGet then
        self.RImgIcon:SetRawImage(iconPath, nil, true)
        self.RImgIcon.gameObject:SetActiveEx(true)
        self.RImgDarkIcon.gameObject:SetActiveEx(false)
    else
        self.RImgDarkIcon:SetRawImage(iconPath, nil, true)
        self.RImgIcon.gameObject:SetActiveEx(false)
        self.RImgDarkIcon.gameObject:SetActiveEx(true)
    end

    if self.ImgQuality then
        self.RootUi:SetUiSprite(self.ImgQuality, XMVCA.XEquip:GetEquipQualityPath(templateId))
    end

    if self.TxtName then
        self.TxtName.text = XMVCA.XEquip:GetEquipName(templateId)
    end

    XRedPointManager.CheckOnce(
    self.OnCheckRedPoint,
    self,
    { XRedPointConditions.Types.CONDITION_ARCHIVE_WEAPON_GRID_NEW_TAG, XRedPointConditions.Types.CONDITION_ARCHIVE_WEAPON_SETTING_RED },
    self.TemplateId
    )
end

-----------------------------------事件相关----------------------------------------->>>
function XUiGridArchiveWeapon:OnBtnClick()
    if self.ClickCb then
        self.ClickCb(self.TemplateIdList,self.TemplateIndex, self)
    end
end

-- 有new标签时显示new标签，如果只有红点显示红点，红点和new标签同时存在则只显示new标签
function XUiGridArchiveWeapon:OnCheckRedPoint(count)
    local templateId = self.TemplateId
    if count < 0 or not templateId then
        self.PanelNewTag.gameObject:SetActiveEx(false)
        self.PanelRedPoint.gameObject:SetActiveEx(false)
    else
        local isShowTag = XMVCA.XArchive:IsNewWeapon(templateId)
        if isShowTag then
            self.PanelNewTag.gameObject:SetActiveEx(true)
            self.PanelRedPoint.gameObject:SetActiveEx(false)
        else
            self.PanelNewTag.gameObject:SetActiveEx(false)
            self.PanelRedPoint.gameObject:SetActiveEx(XMVCA.XArchive:IsNewWeaponSetting(templateId))
        end
    end
end
-----------------------------------事件相关-----------------------------------------<<<
return XUiGridArchiveWeapon
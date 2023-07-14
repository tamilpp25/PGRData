local ICON_NUM = 3

local handler = handler

local XUiGridTRPGRoleTalent = XClass(nil, "XUiGridTRPGRoleTalent")

function XUiGridTRPGRoleTalent:Ctor(ui, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.ClickCb = clickCb

    XTool.InitUiObject(self)
    self.BtnClick.CallBack = handler(self, self.OnClickBtnClick)
    self.PanelSelect2 = self.Transform:FindTransform("PanelSelect2")
end

function XUiGridTRPGRoleTalent:Refresh(roleId, talentId)
    self.RoleId = roleId
    self.TalentId = talentId

    local icon = XTRPGConfigs.GetRoleTalentIcon(roleId, talentId)
    for i = 1, ICON_NUM do
        self["RImgTalentIcon" .. i]:SetRawImage(icon)
    end

    local isActive = XDataCenter.TRPGManager.IsRoleTalentActive(roleId, talentId)
    local canActive = XDataCenter.TRPGManager.IsRoleTalentCanActive(roleId, talentId)
    self.PanelSelect.gameObject:SetActiveEx(isActive)
    self.PanelLock.gameObject:SetActiveEx(not canActive)
    self.PanelNormal.gameObject:SetActiveEx(not isActive and canActive)
end

function XUiGridTRPGRoleTalent:OnClickBtnClick()
    if self.ClickCb then
        self.ClickCb(self.RoleId, self.TalentId)
    end
end

function XUiGridTRPGRoleTalent:SetSelect(value)
    if self.PanelSelect2 then
        self.PanelSelect2.gameObject:SetActiveEx(value)
    end
end

return XUiGridTRPGRoleTalent
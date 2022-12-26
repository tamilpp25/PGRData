--虚像地平线羁绊组合详细页面: 羁绊详细项控件: 头像控件
local XUiExpeditionComboTipsHeadIcon = XClass(nil, "XUiExpeditionComboTipsHeadIcon")
function XUiExpeditionComboTipsHeadIcon:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiExpeditionComboTipsHeadIcon:Show()
    self.GameObject:SetActiveEx(true)
end

function XUiExpeditionComboTipsHeadIcon:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiExpeditionComboTipsHeadIcon:RefreshData(displayData, sampleRank)
    self.SampleRank = sampleRank
    if displayData.IsBlank then
        local BlankIconPath = CS.XGame.ClientConfig:GetString("ExpeditionNoMember")
        self.RImgRoleNor:SetRawImage(BlankIconPath)
        self.RImgRoleDis:SetRawImage(BlankIconPath)
        self.RImgRoleNor.gameObject:SetActiveEx(false)
        self.RImgRoleDis.gameObject:SetActiveEx(true)
        self.TxtDis.gameObject:SetActiveEx(true)
        self.TxtLevel.gameObject:SetActiveEx(false)
        if self.TxtName then self.TxtName.text = "" end
    else
        self.IsActive = displayData.IsActive
        self.TxtLevel.gameObject:SetActiveEx(displayData.EChara:GetIsInTeam())
        self.TxtDis.gameObject:SetActiveEx(not displayData.EChara:GetIsInTeam())
        self.RImgRoleNor:SetRawImage(displayData.EChara:GetSmallHeadIcon())
        self.RImgRoleDis:SetRawImage(displayData.EChara:GetSmallHeadIcon())
        self.RImgRoleNor.gameObject:SetActiveEx(self.IsActive)
        self.RImgRoleDis.gameObject:SetActiveEx(not self.IsActive)
        self.TxtLevel.text = displayData.EChara:GetRankStr()
        if self.TxtName then self.TxtName.text = displayData.EChara:GetCharacterTradeName() end
    end
end
return XUiExpeditionComboTipsHeadIcon
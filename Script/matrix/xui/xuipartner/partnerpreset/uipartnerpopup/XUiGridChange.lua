

local XUiGridChange = XClass(nil, "XUiGridChange")

function XUiGridChange:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
    
    self.CurrentHead = {}
    self.PresetHead = {}
    
    XTool.InitUiObjectByUi(self.CurrentHead, self.GridCurrent)
    XTool.InitUiObjectByUi(self.PresetHead, self.GridPreset)
end

function XUiGridChange:Refresh(pos, prefabTeam)
    local chrId = prefabTeam.TeamData[pos]
    local partnerPrefab = XDataCenter.TeamManager.GetPartnerPrefab(prefabTeam.TeamId)
    local partnerId = partnerPrefab and partnerPrefab:GetPartnerIdByPos(pos) or 0

    if XTool.IsNumberValid(partnerId) then
        local isSkillChange = partnerPrefab:IsSkillChangeWithPrefab2Group(partnerId)
        local partner = XDataCenter.PartnerManager.GetPartnerEntityById(partnerId)
        local currentCarriedChrId = partner:GetCharacterId()
        if isSkillChange or (currentCarriedChrId ~= chrId and XTool.IsNumberValid(currentCarriedChrId)) then
            self.GameObject:SetActiveEx(true)
            local color = XDataCenter.TeamManager.GetTeamMemberColor(pos)
            self.ImgLeftnull.color = color
            self.ImgRightnull.color = color
            color.a = self.Img01.color.a
            self.Img01.color = color
            local hasCurrent = XTool.IsNumberValid(currentCarriedChrId)
            self.RImgType.gameObject:SetActiveEx(true)
            self.PanelNone.gameObject:SetActiveEx(false)
            self.RImgType:SetRawImage(partner:GetIcon())
            self.TxtName.text = partner:GetName()
            self.TxtChange.gameObject:SetActiveEx(isSkillChange)

            self.CurrentHead.PanelEmpty.gameObject:SetActiveEx(not hasCurrent)
            self.CurrentHead.PanelNotEmpty.gameObject:SetActiveEx(hasCurrent)
            if hasCurrent then
                self.CurrentHead.RImgRoleHead:SetRawImage(XDataCenter.CharacterManager.GetCharBigHeadIcon(currentCarriedChrId))
            end

            local hasRole = XTool.IsNumberValid(chrId)
            self.PresetHead.PanelEmpty.gameObject:SetActiveEx(not hasRole)
            self.PresetHead.PanelNotEmpty.gameObject:SetActiveEx(hasRole)
            if hasRole then
                self.PresetHead.RImgRoleHead:SetRawImage(XDataCenter.CharacterManager.GetCharBigHeadIcon(chrId))
            end
        else
            self.GameObject:SetActiveEx(false)
        end
        
    else
        self.GameObject:SetActiveEx(false)
    end
    
    
end

return XUiGridChange
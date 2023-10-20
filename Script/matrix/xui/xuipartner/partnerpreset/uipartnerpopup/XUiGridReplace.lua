local XUiGridTeamPresetRole = XClass(nil, "XUiGridTeamPresetRole")

function XUiGridTeamPresetRole:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
    self.PanelPartner = {}
    XTool.InitUiObjectByUi(self.PanelPartner, self.CharacterPets)
end

function XUiGridTeamPresetRole:Refresh(pos, teamData, isPrefabTeam)
    local chrId = teamData.TeamData[pos]
    
    self.IconLeader.gameObject:SetActiveEx(teamData.CaptainPos == pos)
    self.IconFirstFight.gameObject:SetActiveEx(teamData.FirstFightPos == pos)
    
    if chrId > 0 then
        
        self.PanelHave.gameObject:SetActive(true)
        self.PanelNull.gameObject:SetActive(false)
        local character = XDataCenter.CharacterManager.GetCharacter(chrId)
        if not character then return end

        local color = XDataCenter.TeamManager.GetTeamMemberColor(pos)
        self.ImgLeftSkill.color = color
        self.ImgRightSkill.color = color

        local partnerId
        if isPrefabTeam then
            local partnerPrefab = XDataCenter.TeamManager.GetPartnerPrefab(teamData.TeamId)
            partnerId = partnerPrefab and partnerPrefab:GetPartnerIdByPos(pos) or 0
        else
            partnerId = XDataCenter.PartnerManager.GetCarryPartnerIdByCarrierId(chrId)
        end
        
        local partner = XDataCenter.PartnerManager.GetPartnerEntityById(partnerId)
        if partner then
            self.PanelPartner.RImgType.gameObject:SetActiveEx(true)
            self.PanelPartner.RImgType:SetRawImage(partner:GetIcon())
            self.PanelPartner.PanelNone.gameObject:SetActiveEx(false)
        else
            self.PanelPartner.RImgType.gameObject:SetActiveEx(false)
            self.PanelPartner.PanelNone.gameObject:SetActiveEx(true)
        end

        self.ImgIcon:SetRawImage(XDataCenter.CharacterManager.GetCharBigHeadIcon(character.Id))
        self.ImgQuality:SetSprite(XMVCA.XCharacter:GetCharacterQualityIcon(character.Quality))
    else
        self.ImgLeftnull.color = XDataCenter.TeamManager.GetTeamMemberColor(pos)
        self.ImgRightnull.color = XDataCenter.TeamManager.GetTeamMemberColor(pos)

        self.PanelHave.gameObject:SetActive(false)
        self.PanelNull.gameObject:SetActive(true)
        self.PanelPartner.RImgType.gameObject:SetActiveEx(false)
    end
end

--=========================================类分界线=========================================--


local XUiGridReplace = XClass(nil, "XUiGridReplace")

function XUiGridReplace:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
    self.PrefabTeamGrid = XUiGridTeamPresetRole.New(self.GridTeamRole1)
    self.NewTeamGrid = XUiGridTeamPresetRole.New(self.GridTeamRole2)
end

--==============================
---@oldTeam 真实的队伍 
---@newTeam 预设的队伍 
--==============================
function XUiGridReplace:Refresh(pos, newTeam, prefabTeam)
    self.PrefabTeamGrid:Refresh(pos, prefabTeam, true)
    self.NewTeamGrid:Refresh(pos, newTeam, false)
    local color = XDataCenter.TeamManager.GetTeamMemberColor(pos)
    color.a = self.Img01.color.a
    self.Img01.color = color
end


return XUiGridReplace
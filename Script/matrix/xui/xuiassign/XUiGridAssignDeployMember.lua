local XUiGridAssignDeployMember = XClass(nil, "XUiGridAssignDeployMember") -- XUiGridEchelonMember

local CONDITION_COLOR = {
    [true] = CS.UnityEngine.Color.white,
    [false] = CS.UnityEngine.Color.red,
}

--位置对应的颜色框
local MEMBER_POS_COLOR = {
    [1] = "ImgRed",
    [2] = "ImgBlue",
    [3] = "ImgYellow",
}

function XUiGridAssignDeployMember:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self:InitComponent()
    self:ResetMemberInfo()
end

function XUiGridAssignDeployMember:InitComponent()
    CsXUiHelper.RegisterClickEvent(self.BtnClick, function() self:OnMemberClick() end)
end

function XUiGridAssignDeployMember:ResetMemberInfo()
    self.ImgLeaderTag.gameObject:SetActiveEx(false)
    self.ImgFirstRole.gameObject:SetActiveEx(false)
    self.PanelEmpty.gameObject:SetActiveEx(false)
    self.PanelMember.gameObject:SetActiveEx(false)
    self.ImgBlue.gameObject:SetActiveEx(false)
    self.ImgRed.gameObject:SetActiveEx(false)
    self.ImgYellow.gameObject:SetActiveEx(false)
end

function XUiGridAssignDeployMember:Refresh(groupId, teamOrder, teamData, memberOrder)
    self.GroupId = groupId
    self.TeamOrder = teamOrder
    self.TeamData = teamData
    self.MemberOrder = memberOrder

    self.TeamId = self.TeamData:GetId()

    local memberData = teamData:GetMemberList()[memberOrder]
    self.MemberData = memberData
    self.CurCharacterId = memberData:GetCharacterId() or 0

    local index = memberData:GetIndex()
    local leaderIndex = teamData:GetLeaderIndex()
    local firstFightIndex = teamData:GetFirstFightIndex()

    self.ImgLeaderTag.gameObject:SetActiveEx(index == leaderIndex)
    self.ImgFirstRole.gameObject:SetActiveEx(index == firstFightIndex)
    self[MEMBER_POS_COLOR[index]].gameObject:SetActiveEx(true)

    self.CharacterId = memberData:GetCharacterId()
    if self.CharacterId and self.CharacterId ~= 0 then
        self.PanelNotPassCondition.gameObject:SetActiveEx(true)
        local ability = memberData:GetCharacterAbility()
        self.TxtNowAbility.color = CONDITION_COLOR[ability >= teamData:GetRequireAbility()]
        self.TxtNowAbility.text = ability

        self.RImgRoleHead:SetRawImage(XMVCA.XCharacter:GetCharSmallHeadIcon(self.CharacterId))
        self.PanelMember.gameObject:SetActiveEx(true)
        self.PanelEmpty.gameObject:SetActiveEx(false)

    else
        self.PanelNotPassCondition.gameObject:SetActiveEx(false)
        self.PanelMember.gameObject:SetActiveEx(false)
        self.PanelEmpty.gameObject:SetActiveEx(true)
    end
end

function XUiGridAssignDeployMember:OnMemberClick()
    local teamIdMap, teamOrderMap = XDataCenter.FubenAssignManager.GetCharacterTeamOderMapByGroup(self.GroupId)
    self.TeamIdMap = teamIdMap
    self.TeamOrderMap = teamOrderMap

    local teamCharIdMap = {} -- 所有已编队角色
    for i, member in ipairs(self.TeamData:GetMemberList()) do
        teamCharIdMap[i] = member:GetCharacterId() or 0
    end
    -- 其他队角色
    self.OtherCharacterMap = {}
    local memberCount = #teamCharIdMap
    local otherCharacters = XDataCenter.FubenAssignManager.GetOtherTeamCharacters(self.GroupId, self.TeamId)
    for i, v in ipairs(otherCharacters) do  -- v = {teamId, i, characterId}
        teamCharIdMap[memberCount + i] = v[3]
        self.OtherCharacterMap[memberCount + i] = v
    end

    local teamSelectPos = self.MemberOrder
    local cb = handler(self, self.OnCharacterSelected)
    local canQuitCharIdMap = {[self.CurCharacterId] = true }
    local ablityRequire = self.TeamData:GetRequireAbility()
    local curTeamOrder = self.TeamOrder
    local stageId = self.TeamId
    local characterLimitType = XFubenConfigs.GetStageCharacterLimitType(stageId)
    local limitBuffId = XFubenConfigs.GetStageCharacterLimitBuffId(stageId)
    XLuaUiManager.Open("UiAssignRoomCharacter", self.CharacterId, self.TeamId, teamSelectPos, curTeamOrder, self.GroupId, ablityRequire)
end

function XUiGridAssignDeployMember:OnCharacterSelected(teamCharIdMap)
    -- 修改本队
    local memberList = self.TeamData:GetMemberList()
    for i, _ in ipairs(memberList) do
        XDataCenter.FubenAssignManager.SetTeamMember(self.TeamId, i, teamCharIdMap[i])
    end

    -- 修改其他队
    local memberCount = #memberList
    local info
    for i = memberCount + 1, #teamCharIdMap do
        if teamCharIdMap[i] and self.OtherCharacterMap[i] then
            info = self.OtherCharacterMap[i]
            XDataCenter.FubenAssignManager.SetTeamMember(info[1], info[2], teamCharIdMap[i])
        end
    end

    CsXGameEventManager.Instance:Notify(XEventId.EVENT_ON_ASSIGN_TEAM_CHANGED)  -- TODO 细分刷新所有 还是刷新本类
end
return XUiGridAssignDeployMember
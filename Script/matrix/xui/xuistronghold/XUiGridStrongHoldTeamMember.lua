local XUiGridStrongHoldTeamMember = XClass(nil, "XUiGridStrongHoldTeamMember")

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

function XUiGridStrongHoldTeamMember:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)

    self.BtnClick.CallBack = function() self:OnMemberClick() end
end

function XUiGridStrongHoldTeamMember:Refresh(teamList, teamId, index, groupId)
    ---@type XStrongholdTeam[]
    self.TeamList = teamList
    self.TeamId = teamId
    self.MemberIndex = index
    self.GroupId = groupId
    self.Pos = index

    ---@type XStrongholdTeam
    local team = teamList[teamId]

    local leaderIndex = team:GetCaptainPos()
    self.ImgLeaderTag.gameObject:SetActiveEx(index == leaderIndex)

    local firstFightIndex = team:GetFirstPos()
    self.ImgFirstRole.gameObject:SetActiveEx(index == firstFightIndex)

    for i, goName in pairs(MEMBER_POS_COLOR) do
        self[goName].gameObject:SetActiveEx(index == i)
    end

    local member = team:GetMember(index)

    local isEmpty = member:IsEmpty()
    self.PanelEmpty.gameObject:SetActiveEx(isEmpty)
    self.PanelNotEmpty.gameObject:SetActiveEx(not isEmpty)

    local isAssitant = member:IsAssitant()
    self.PanelHelp.gameObject:SetActiveEx(isAssitant)

    local isRobot = member:IsRobot()
    self.PanelTrial.gameObject:SetActiveEx(isRobot)

    local ability = team:GetTeamMemberAbility(self.MemberIndex)
    self.TxtAbility.text = ability
    if groupId then
        local requireAbility = XDataCenter.StrongholdManager.GetGroupRequireAbility(groupId)
        self.TxtAbility.color = CONDITION_COLOR[ability >= requireAbility]
    end

    if not isEmpty then
        local headIcon = member:GetSmallHeadIcon()
        self.RImgRoleHead:SetRawImage(headIcon)
        self.RImgType:SetRawImage(member:GetElementIcon())
    end
    self.RImgRoleHead.gameObject:SetActiveEx(not isEmpty)
end

function XUiGridStrongHoldTeamMember:OnMemberClick()
    -- 走矿区自己特殊的BattleRoleRoom
    XLuaUiManager.Open("UiStrongholdBattleRoleRoom", self.TeamList, self.TeamId, self.GroupId, self.Pos)
end

return XUiGridStrongHoldTeamMember
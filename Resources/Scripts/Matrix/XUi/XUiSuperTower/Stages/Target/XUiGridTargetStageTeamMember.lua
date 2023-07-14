local XUiGridTargetStageTeamMember = XClass(nil, "XUiGridTargetStageTeamMember")

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

function XUiGridTargetStageTeamMember:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)

    self.BtnClick.CallBack = function() self:OnMemberClick() end

    self.StageId = nil
end

function XUiGridTargetStageTeamMember:Refresh(stageIndex, memberRole, memberPos, stStage)
    local stageId = stStage:GetStageId()[stageIndex]
    local team = stageId and XDataCenter.SuperTowerManager.GetTeamByStageId(stageId)
    self.MemberPos = memberPos
    self.Team = team
    self.StageId = stageId

    local leaderIndex = team:GetCaptainPos()
    self.ImgLeaderTag.gameObject:SetActiveEx(memberPos == leaderIndex)

    local firstFightIndex = team:GetFirstFightPos()
    self.ImgFirstRole.gameObject:SetActiveEx(memberPos == firstFightIndex)

    for i, goName in pairs(MEMBER_POS_COLOR) do
        self[goName].gameObject:SetActiveEx(memberPos == i)
    end

    local isEmpty = not memberRole
    self.PanelEmpty.gameObject:SetActiveEx(isEmpty)
    self.PanelNotEmpty.gameObject:SetActiveEx(not isEmpty)
    self.RImgRoleHead.gameObject:SetActiveEx(not isEmpty)
    if not isEmpty then
        local isRobot = memberRole:GetIsRobot()
        self.PanelTrial.gameObject:SetActiveEx(isRobot)

        local ability = memberRole:GetAbility()
        self.TxtAbility.text = ability

        local requireAbility = stStage:GetStageAbilityByIndex(stageIndex)
        self.TxtAbility.color = CONDITION_COLOR[ability >= requireAbility]
        
        local headIcon = memberRole:GetSmallHeadIcon()
        self.RImgRoleHead:SetRawImage(headIcon)
        
        local IsInDult = memberRole:GetIsInDult()
        self.ImgTedianyq.gameObject:SetActiveEx(IsInDult)
    end
end

function XUiGridTargetStageTeamMember:OnMemberClick()
    XLuaUiManager.Open("UiBattleRoomRoleDetail", 
        self.StageId,
        self.Team, 
        self.MemberPos, 
        require("XUi/XUiSuperTower/Room/XUiSuperTowerBattleRoomRoleDetail"))
end

return XUiGridTargetStageTeamMember
local XUiGridRiftDeployMember = XClass(nil, "XUiGridRiftDeployMember")

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

function XUiGridRiftDeployMember:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)

    self.BtnClick.CallBack = function() self:OnMemberClick() end
end

function XUiGridRiftDeployMember:Refresh(xTeam, index)
    self.XTeam = xTeam
    self.Pos = index

    local leaderIndex = xTeam:GetCaptainPos()
    self.ImgLeaderTag.gameObject:SetActiveEx(index == leaderIndex)

    local firstFightIndex = xTeam:GetFirstFightPos()
    self.ImgFirstRole.gameObject:SetActiveEx(index == firstFightIndex)

    for i, goName in pairs(MEMBER_POS_COLOR) do
        self[goName].gameObject:SetActiveEx(index == i)
    end

    local isEmpty = xTeam:CheckIsPosEmpty(index)
    self.PanelEmpty.gameObject:SetActiveEx(isEmpty)
    self.PanelNotEmpty.gameObject:SetActiveEx(not isEmpty)

    local roleId = xTeam:GetEntityIdByTeamPos(index)
    local xRole = XDataCenter.RiftManager.GetEntityRoleById(roleId)
    local isRobot = xRole and xRole:GetIsRobot()
    self.PanelTrial.gameObject:SetActiveEx(isRobot)

    local ability = xRole and xRole:GetFinalShowAbility(self.MemberIndex)
    self.TxtAbility.text = ability

    if not isEmpty then
        local headIcon = xRole and xRole:GetSmallHeadIcon()
        self.RImgRoleHead:SetRawImage(headIcon)
    end
    self.RImgRoleHead.gameObject:SetActiveEx(not isEmpty)

    self.TxtLoad.text = xRole and (xRole:GetCurrentLoad().."/"..XDataCenter.RiftManager.GetMaxLoad())
end

function XUiGridRiftDeployMember:OnMemberClick()
    XLuaUiManager.Open("UiRiftCharacter", true, self.XTeam, self.Pos)
end

return XUiGridRiftDeployMember
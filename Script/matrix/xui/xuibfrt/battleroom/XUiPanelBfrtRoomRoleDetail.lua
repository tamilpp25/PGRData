---@class XUiPanelBfrtRoomRoleDetail
local XUiPanelBfrtRoomRoleDetail = XClass(nil, "XUiPanelBfrtRoomRoleDetail")

local CONDITION_HEX_COLOR = {
    [true] = "000000FF",
    [false] = "BC0F23FF",
}

function XUiPanelBfrtRoomRoleDetail:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
    ---@type XUiGridEchelonMemberViewData
    self.ViewData = nil
    ---@type XTeam
    self.Team = nil
    XUiHelper.RegisterClickEvent(self, self.BtnTeamPrefab, self.OnBtnTeamPrefabClicked)
end

function XUiPanelBfrtRoomRoleDetail:SetData(viewData, currentEntityId, team, checkIsPassTeamEntityFunc)
    self.ViewData = viewData
    self.Team = team
    self.TxtRequireAbility.text = viewData.RequireAbility
    self.TxtEchelonName.text = XDataCenter.BfrtManager.GetEchelonNameTxt(viewData.EchelonType, viewData.EchelonIndex)
    self._CheckIsPassTeamEntityFunc = checkIsPassTeamEntityFunc
end

function XUiPanelBfrtRoomRoleDetail:Refresh(currentEntityId)
    local curCharacter = XMVCA.XCharacter:GetCharacter(currentEntityId)
    local passed = curCharacter and curCharacter.Ability >= self.ViewData.RequireAbility or false
    self.TxtRequireAbility.color = XUiHelper.Hexcolor2Color(CONDITION_HEX_COLOR[passed])
end

function XUiPanelBfrtRoomRoleDetail:OnBtnTeamPrefabClicked()
    RunAsyn(function()
        local stageId = self.ViewData.StageId
        local limitBuffId = XFubenConfigs.GetStageCharacterLimitBuffId(stageId)
        local characterLimitType = XFubenConfigs.GetStageCharacterLimitType(stageId)
        local stageInfos = XDataCenter.FubenManager.GetStageInfo(stageId)
        local stageType = stageInfos and stageInfos.Type
        XLuaUiManager.Open("UiRoomTeamPrefab", nil, nil, characterLimitType, limitBuffId, stageType, nil, nil, stageId)
        local signalCode, teamData = XLuaUiManager.AwaitSignal("UiRoomTeamPrefab", "RefreshTeamData", self)
        if signalCode ~= XSignalCode.SUCCESS then return end
        local teamEntityList = {0, 0, 0}
        for i, entityId in ipairs(teamData.TeamData) do
            if i > self.ViewData.EchelonRequireCharacterNum then
                break
            end
            if not self._CheckIsPassTeamEntityFunc(entityId) then
                self.ViewData.CharacterSwapEchelonCb(entityId, self.Team:GetEntityIdByTeamPos(i))
                teamEntityList[i] = entityId
            else
                teamEntityList[i] = self.Team:GetEntityIdByTeamPos(i)
            end
        end
        self.Team:UpdateEntityIds(teamEntityList)
        XDataCenter.BfrtManager.SetTeamCaptainPos(self.ViewData.EchelonId, teamData.CaptainPos)
        XDataCenter.BfrtManager.SetTeamFirstFightPos(self.ViewData.EchelonId, teamData.FirstFightPos)
        -- 提示与关闭
        XUiManager.TipText("SCRoleSkillUploadSuccess")
        self.ViewData.TeamResultCb(self.Team:GetEntityIds())
        XLuaUiManager.Remove("UiBattleRoomRoleDetail")
    end)
    
end

return XUiPanelBfrtRoomRoleDetail
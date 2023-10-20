---@class XUiPanelBfrtRoomRoleDetail
local XUiPanelBfrtRoomRoleDetail = XClass(nil, "XUiPanelBfrtRoomRoleDetail")

local CONDITION_HEX_COLOR = {
    [true] = "000000FF",
    [false] = "BC0F23FF",
}

function XUiPanelBfrtRoomRoleDetail:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
    self.ViewData = nil
    self.Team = nil
    XUiHelper.RegisterClickEvent(self, self.BtnTeamPrefab, self.OnBtnTeamPrefabClicked)
end

function XUiPanelBfrtRoomRoleDetail:SetData(viewData, currentEntityId, team)
    self.ViewData = viewData
    self.Team = team
    self.TxtRequireAbility.text = viewData.RequireAbility
    self.TxtEchelonName.text = XDataCenter.BfrtManager.GetEchelonNameTxt(viewData.EchelonType, viewData.EchelonIndex)
end

function XUiPanelBfrtRoomRoleDetail:Refresh(currentEntityId)
    local curCharacter = XDataCenter.CharacterManager.GetCharacter(currentEntityId)
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
        for i, entityId in ipairs(teamData.TeamData) do
            if i > self.ViewData.EchelonRequireCharacterNum then
                break
            end
            self.ViewData.CharacterSwapEchelonCb(entityId, self.Team:GetEntityIdByTeamPos(i))
            self.Team:UpdateEntityTeamPos(entityId, i, true)
        end
        XDataCenter.BfrtManager.SetTeamCaptainPos(self.ViewData.EchelonId, teamData.CaptainPos)
        XDataCenter.BfrtManager.SetTeamFirstFightPos(self.ViewData.EchelonId, teamData.FirstFightPos)
        -- 提示与关闭
        XUiManager.TipText("SCRoleSkillUploadSuccess")
        self.ViewData.TeamResultCb(self.Team:GetEntityIds())
        XLuaUiManager.Remove("UiBattleRoomRoleDetail")
    end)
    
end

return XUiPanelBfrtRoomRoleDetail
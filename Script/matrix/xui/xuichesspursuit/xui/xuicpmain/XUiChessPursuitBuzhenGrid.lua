local XUiChessPursuitBuzhenGrid = XClass(nil, "XUiChessPursuitBuzhenGrid")
local CSXTextManagerGetText = CS.XTextManager.GetText
local CSUnityEngineVector3 = CS.UnityEngine.Vector3

local ACTIVE_UI_TYPE = {
    NONE = 0,
    SELECT = 1,
    TEAM = 2,
    HURT_TXT = 3,
}

function XUiChessPursuitBuzhenGrid:Ctor(ui, uiRoot, cubeIndex, teamGridIndex, mapId)
    self.UiRoot = uiRoot
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.CubeIndex = cubeIndex
    self.TeamGridIndex = teamGridIndex
    self.MapId = mapId

    self.GameObject:SetActive(true)
    XTool.InitUiObject(self)
    self:AutoAddListener()

    self:SwitchUiType(ACTIVE_UI_TYPE.NONE)

    self.IsSetScale = false
end

function XUiChessPursuitBuzhenGrid:Dispose()
    if self.GameObject then
        CS.UnityEngine.GameObject.Destroy(self.GameObject)
    end

    self.GameObject = nil
end

--@region 点击事件

function XUiChessPursuitBuzhenGrid:AutoAddListener()
    XUiHelper.RegisterClickEvent(self, self.BtnBuzhen01, self.OnBtnBuzhen01Click)
    XUiHelper.RegisterClickEvent(self, self.BtnBuzhen02, self.OnBtnBuzhen01Click)
end

function XUiChessPursuitBuzhenGrid:OnBtnBuzhen01Click()
    local chessPursuitMapDb = XDataCenter.ChessPursuitManager.GetChessPursuitMapDb(self.MapId)
    local chessPursuitMapTemplate = chessPursuitMapDb:GetChessPursuitMapTemplate()
    local chessPursuitBoss = XChessPursuitConfig.GetChessPursuitBossTemplate(chessPursuitMapTemplate.BossId)
    local stageId = chessPursuitBoss.StageId
    local robotList = XChessPursuitConfig.GetChessPursuitTestRoleRoleIds(chessPursuitMapTemplate.TestRoleGroup[self.TeamGridIndex])
    local curTeam = XDataCenter.ChessPursuitManager.GetSaveTempTeamData(self.MapId, self.TeamGridIndex)
    if not curTeam then
        curTeam = {TeamData = {0,0,0}, CaptainPos = 1, FirstFightPos = 1}
    end
    XLuaUiManager.Open("UiNewRoomSingle", stageId, {
        ChessPursuitData = {
            RobotList = robotList,
            TeamGridIndex = self.TeamGridIndex,
            MapId = self.MapId,
            CurTeam = curTeam,
            SceneUiType = XChessPursuitCtrl.SCENE_UI_TYPE.BUZHEN,
        }
    })

end

function XUiChessPursuitBuzhenGrid:OnBtnBuzhen02Click()
    XLog.Debug(">>>>>>>>>>>>>>>> OnBtnBuzhen02Click")
end

--@endregion

function XUiChessPursuitBuzhenGrid:Init()
    self.BtnBuzhen01:SetName("0" .. self.TeamGridIndex)
    self.BtnBuzhen02:SetName("0" .. self.TeamGridIndex)
end

function XUiChessPursuitBuzhenGrid:RefreshPos()
    local chessPursuitCubes = XChessPursuitCtrl.GetChessPursuitCubes()
    local cubeTs = chessPursuitCubes[self.CubeIndex].Transform
    if self.UiType == ACTIVE_UI_TYPE.SELECT then
        local offzetY = 1.7
        self.Transform.position = XChessPursuitCtrl.WorldToUIPosition(CSUnityEngineVector3(cubeTs.position.x, cubeTs.position.y + offzetY, cubeTs.position.z))
    elseif self.UiType == ACTIVE_UI_TYPE.TEAM then
        local isCaptainCharacterId = XDataCenter.ChessPursuitManager.IsCaptainCharacterIdInTempTeamData(self.MapId, self.TeamGridIndex)
        local offzetY = isCaptainCharacterId and 1.5 or 0.5
        self.Transform.position = XChessPursuitCtrl.WorldToUIPosition(CSUnityEngineVector3(cubeTs.position.x, cubeTs.position.y + offzetY, cubeTs.position.z))
    elseif self.UiType == ACTIVE_UI_TYPE.HURT_TXT then 
        local offzetY = 0.5
        self.Transform.position = XChessPursuitCtrl.WorldToUIPosition(CSUnityEngineVector3(cubeTs.position.x, cubeTs.position.y + offzetY, cubeTs.position.z))
    end

    if not self.IsSetScale then
        self.Transform.localScale = CSUnityEngineVector3(5,5,5)
        self.IsSetScale = true
    end
end

function XUiChessPursuitBuzhenGrid:UpdateTeamHeadIconByMapDb(sceneType)
    local chessPursuitMapDb = XDataCenter.ChessPursuitManager.GetChessPursuitMapDb(self.MapId)
    local teamCharacterIds = chessPursuitMapDb:GetTeamCharacterIds(self.TeamGridIndex)

    if sceneType == XChessPursuitCtrl.SCENE_UI_TYPE.BUZHEN then
        if next(teamCharacterIds) then
            self:SwitchUiType(ACTIVE_UI_TYPE.TEAM)
        else
            self:SwitchUiType(ACTIVE_UI_TYPE.SELECT)
        end
    end

    if next(teamCharacterIds) then
        self:UpdateTeamHeadIcon(teamCharacterIds)
    end
end

function XUiChessPursuitBuzhenGrid:UpdateTeamHeadIconByTempTeam(sceneType)
    local tempTeamData = XDataCenter.ChessPursuitManager.GetSaveTempTeamData(self.MapId, self.TeamGridIndex)
    local isTeamDataHasChar = self:IsTeamDataHasChar(tempTeamData and tempTeamData.TeamData)

    if sceneType == XChessPursuitCtrl.SCENE_UI_TYPE.BUZHEN then
        if isTeamDataHasChar then
            self:SwitchUiType(ACTIVE_UI_TYPE.TEAM)
        else
            self:SwitchUiType(ACTIVE_UI_TYPE.SELECT)
        end
    end

    if isTeamDataHasChar then
        self:UpdateTeamHeadIcon(tempTeamData.TeamData, tempTeamData.CaptainPos)
    end
end

--队伍里是否有角色
function XUiChessPursuitBuzhenGrid:IsTeamDataHasChar(teamData)
    for _, charId in pairs(teamData or {}) do
        if charId and charId > 0 then
            return true
        end
    end
    return false
end

function XUiChessPursuitBuzhenGrid:UpdateTeamHeadIcon(characterIds, captainPos)
    --同步编队位置，ui上1号位中间2左边3右边
    for i, characterId in ipairs(characterIds) do
        local rawImage = self["RawImage" .. i]
        local imageAdd = self["ImageAdd" .. i]
        local labelLeader = self["LabelLeader" .. i]
        if characterId ~= 0 then
            rawImage.gameObject:SetActive(true)
            imageAdd.gameObject:SetActive(false)
            local iconpath = self:GetHeadIconUrl(characterId)
            rawImage:SetRawImage(iconpath)
            self:SetPressRImgHeadIcon(i, iconpath)
            self:SetPressImageAddActive(i, false)
        else
            rawImage.gameObject:SetActive(false)
            imageAdd.gameObject:SetActive(true)
            self:SetPressRImgHeadIcon(i)
            self:SetPressImageAddActive(i, true)
        end

        if labelLeader then
            labelLeader.gameObject:SetActiveEx(i == captainPos)
        end
    end
end

function XUiChessPursuitBuzhenGrid:SetPressImageAddActive(index, isActive)
    local pressImageAdd = self["PressImageAdd" .. index]
    if pressImageAdd then
        pressImageAdd.gameObject:SetActiveEx(isActive)
    end
end

function XUiChessPursuitBuzhenGrid:SetPressRImgHeadIcon(index, iconpath)
    local pressRImgHeadIcon = self["PressRImgHeadIcon" .. index]
    if pressRImgHeadIcon then
        if iconpath then
            pressRImgHeadIcon:SetRawImage(iconpath)
            pressRImgHeadIcon.gameObject:SetActiveEx(true)
        else
            pressRImgHeadIcon.gameObject:SetActiveEx(false)
        end
    end
end

function XUiChessPursuitBuzhenGrid:UpdateBossHurMax()
    local hurtBoss = self:GetBossHurMax()
    if hurtBoss > 0 then
        self:SwitchUiType(ACTIVE_UI_TYPE.HURT_TXT)
        self.TxtBossHurMax.text = CSXTextManagerGetText("ChessPursuitBossHurMax", string.format("%.2f%%", hurtBoss * 100))
    else
        self:SwitchUiType(ACTIVE_UI_TYPE.NONE)
    end
end

function XUiChessPursuitBuzhenGrid:GetBossHurMax()
    return XDataCenter.ChessPursuitManager.GetBossHurMax(self.MapId, self.TeamGridIndex)
end

function XUiChessPursuitBuzhenGrid:ShowSelectTeam()
    self:SwitchUiType(ACTIVE_UI_TYPE.SELECT)
end

function XUiChessPursuitBuzhenGrid:GetHeadIconUrl(characterId)
    if XRobotManager.CheckIsRobotId(characterId) then
        characterId = XRobotManager.GetCharacterId(characterId)
    end
    
    local iconpath = XDormConfig.GetCharacterStyleConfigQSIconById(characterId)
    return iconpath
end

function XUiChessPursuitBuzhenGrid:SetActive(sceneType)
    if sceneType ~= XChessPursuitCtrl.SCENE_UI_TYPE.BUZHEN then
        self:SwitchUiType(ACTIVE_UI_TYPE.HURT_TXT)
    elseif sceneType == XChessPursuitCtrl.SCENE_UI_TYPE.BUZHEN then
        self:SwitchUiType(ACTIVE_UI_TYPE.TEAM)
    else
        self:SwitchUiType(ACTIVE_UI_TYPE.NONE)
    end
end

function XUiChessPursuitBuzhenGrid:GetCubeIndex()
    return self.CubeIndex
end

function XUiChessPursuitBuzhenGrid:SwitchUiType(uiType)
    self.UiType = uiType

    self.BtnBuzhen01.gameObject:SetActive(uiType == ACTIVE_UI_TYPE.SELECT)
    self.BtnBuzhen02.gameObject:SetActive(uiType == ACTIVE_UI_TYPE.TEAM)
    self.HighestHistory.gameObject:SetActive(uiType == ACTIVE_UI_TYPE.HURT_TXT)
end

return XUiChessPursuitBuzhenGrid
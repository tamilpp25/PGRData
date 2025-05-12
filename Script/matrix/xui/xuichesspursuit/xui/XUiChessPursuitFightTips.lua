local XChessPursuitCtrl = require("XUi/XUiChessPursuit/XChessPursuitCtrl")
local XUiChessPursuitFightTips = XLuaUiManager.Register(XLuaUi, "UiChessPursuitFightTips")
local CSXTextManagerGetText = CS.XTextManager.GetText

function XUiChessPursuitFightTips:OnAwake()
    self:AutoAddListener()
end

function XUiChessPursuitFightTips:OnStart(mapId, teamGridIndex, callBack, rootUi, drawCamera)
    self.MapId = mapId
    self.TeamGridIndex = teamGridIndex
    self.CallBack = callBack
    self.RootUi = rootUi
    self.DrawCamera = drawCamera
    self.ChessPursuitMapDb = XDataCenter.ChessPursuitManager.GetChessPursuitMapDb(self.MapId)

    self:LockCamera()
    self:UpdateInfo()

    self.UpdateTimer = XScheduleManager.ScheduleForever(function()
        if XChessPursuitConfig.IsTimeOutByMapId(mapId) then
            self:Close()
        end
    end, 1)
end

function XUiChessPursuitFightTips:OnDestroy()
    self:UnLockCamera()
    if self.UpdateTimer then
        XScheduleManager.UnSchedule(self.UpdateTimer)
        self.UpdateTimer = nil
    end
end

function XUiChessPursuitFightTips:LockCamera()
    if not self.DrawCamera then
        return
    end
    self.CurrCameraState = self.DrawCamera:GetChessPursuitCameraState()
    self.DrawCamera:SwitchChessPursuitCameraState(CS.XChessPursuitCameraState.None)
end

function XUiChessPursuitFightTips:UnLockCamera()
    if not self.DrawCamera then
        return
    end
    self.DrawCamera:SwitchChessPursuitCameraState(self.CurrCameraState)
end

--@region 点击事件

function XUiChessPursuitFightTips:AutoAddListener()
    self.BtnAutoFight.CallBack = function() self:OnBtnAutoFightClick() end
    self:RegisterClickEvent(self.BtnEnterFight, self.OnBtnEnterFightClick)
    if self.BtnTeamChange then
        self:RegisterClickEvent(self.BtnTeamChange, self.OnBtnTeamChangeClick)
    end
    if self.BtnReset then
        self:RegisterClickEvent(self.BtnReset, self.OnBtnResetClick)
    end
end

function XUiChessPursuitFightTips:OnBtnTeamChangeClick()
    local curTeamData = self.ChessPursuitMapDb:GetGridTeamDbByGridId(self.TeamGridIndex)
    local chessPursuitMapTemplate = self.ChessPursuitMapDb:GetChessPursuitMapTemplate()
    local chessPursuitBoss = XChessPursuitConfig.GetChessPursuitBossTemplate(chessPursuitMapTemplate.BossId)
    local stageId = chessPursuitBoss.StageId
    local teamData = self.ChessPursuitMapDb:GetTeamCharacterIds(self.TeamGridIndex, true)
    local robotList = XChessPursuitConfig.GetChessPursuitTestRoleRoleIds(chessPursuitMapTemplate.TestRoleGroup[self.TeamGridIndex])
    local curTeam = {
        TeamData = teamData,
        CaptainPos = curTeamData.CaptainPos,
        FirstFightPos = curTeamData.FirstFightPos,
    }
    XLuaUiManager.Open("UiBattleRoleRoom", stageId)
end

function XUiChessPursuitFightTips:OnBtnResetClick()
    XUiManager.DialogTip(CSXTextManagerGetText("TipTitle"), CSXTextManagerGetText("ChessPursuitResetTipContent"), XUiManager.DialogType.Normal, nil, function()
        XDataCenter.ChessPursuitManager.RequestChessPursuitResetMapData(function ()
            self:Close()
            self.RootUi:SwtichUI(XChessPursuitCtrl.MAIN_UI_TYPE.SCENE, {
                MapId = self.MapId
            }, true)
        end, self.MapId)
    end)
end

function XUiChessPursuitFightTips:OnBtnAutoFightClick()
    local maxRatio = XDataCenter.ChessPursuitManager.GetBossHurMax(self.MapId, self.TeamGridIndex)
    maxRatio = string.format("%.2f", maxRatio * 100)

    XUiManager.DialogTip(CSXTextManagerGetText("TipTitle"), CSXTextManagerGetText("ChessPursuitAutoTipContent", maxRatio), XUiManager.DialogType.Normal, nil, function()
        if self.CallBack then
            self.CallBack()
        end
        XDataCenter.ChessPursuitManager.RequestChessPursuitAutoFightData(function ()
            self:Close()
        end)
    end)
end

function XUiChessPursuitFightTips:OnBtnEnterFightClick()
    local chessPursuitMapTemplate = self.ChessPursuitMapDb:GetChessPursuitMapTemplate()
    local chessPursuitBoss = XChessPursuitConfig.GetChessPursuitBossTemplate(chessPursuitMapTemplate.BossId)
    local stageId = chessPursuitBoss.StageId
    local stage = XDataCenter.FubenManager.GetStageCfg(stageId)
    local gridTeamDb = self.ChessPursuitMapDb:GetGridTeamDbByGridId(self.TeamGridIndex)

    local curTeam = XDataCenter.ChessPursuitManager.GetSaveTempTeamData(self.MapId, self.TeamGridIndex)
    local preFight = curTeam and {} or gridTeamDb
    if curTeam then
        local cardIds, robotIds = XDataCenter.ChessPursuitManager.ClientTeamDataChangeServer(curTeam.TeamData)
        preFight.CardIds = cardIds
        preFight.CaptainPos = curTeam.CaptainPos
        preFight.FirstFightPos = curTeam.FirstFightPos
        preFight.RobotIds = robotIds
    end

    if XDataCenter.FubenManager.CheckPreFight(stage) then
        XDataCenter.FubenManager.EnterChessPursuitFight(stage, {
            CardIds = preFight.CardIds,
            CaptainPos = preFight.CaptainPos,
            FirstFightPos = preFight.FirstFightPos,
            RobotIds = preFight.RobotIds,
            StageId = stage.StageId,
        }, function()
            if self.CallBack then
                self.CallBack()
            end
            self:Close()
        end)
    end
end

--@endregion

function XUiChessPursuitFightTips:UpdateInfo()
    local teamCharacterIds = self.ChessPursuitMapDb:GetTeamCharacterIds(self.TeamGridIndex)
    local hurtBoss = self.ChessPursuitMapDb:GetHurtBossByGridId(self.TeamGridIndex)
    local chessPursuitMapTemplate = XChessPursuitConfig.GetChessPursuitMapTemplate(self.MapId)
    local chessPursuitMapBoss = XDataCenter.ChessPursuitManager.GetChessPursuitMapBoss(chessPursuitMapTemplate.BossId)

    for i, characterId in ipairs(teamCharacterIds) do
        local gridBossAutoFight = self["GridBossAutoFight" .. i]
        if characterId ~= 0 then
            gridBossAutoFight.gameObject:SetActive(true)
            local iconpath = self:GetHeadIconUrl(characterId)
            self["RImgHead" .. i]:SetRawImage(iconpath)
            self["TxtNickName" .. i].text = XMVCA.XCharacter:GetCharacterFullNameStr(characterId)
        else
            gridBossAutoFight.gameObject:SetActive(false)
        end
    end

    local ration = hurtBoss / chessPursuitMapBoss:GetInitHp()
    self.TxtScore.text = string.format("%.2f%%", ration * 100)

    if hurtBoss >= 0 then
        self.BtnAutoFight:SetDisable(false, true)
        self:SetScoreDataIsActive(true)
    else
        self.BtnAutoFight:SetDisable(true, false)
        self:SetScoreDataIsActive(false)
    end
end

function XUiChessPursuitFightTips:SetScoreDataIsActive(isActive)
    if self.ScoreDate then
        self.ScoreDate.gameObject:SetActiveEx(isActive)
    end
end

function XUiChessPursuitFightTips:GetHeadIconUrl(characterId)
    if XRobotManager.CheckIsRobotId(characterId) then
        characterId = XRobotManager.GetCharacterId(characterId)
    end

    local fashionId = XMVCA.XCharacter:GetCharacterTemplate(characterId).DefaultNpcFashtionId
    local headIcon = XDataCenter.FashionManager.GetFashionRoundnessNotItemHeadIcon(fashionId)

    return headIcon
end

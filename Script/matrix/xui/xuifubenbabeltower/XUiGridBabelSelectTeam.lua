local CSXTextManagerGetText = CS.XTextManager.GetText
local MAX_CHARACTER_NUM = 3

local XUiGridBabelSelectTeam = XClass(nil, "XUiGridBabelSelectTeam")

function XUiGridBabelSelectTeam:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)

    self.BtnRecover.CallBack = function() self:OnClickBtnRecover() end
    self.BtnReset.CallBack = function() self:OnClickBtnReset() end
    self.BtnSelect.CallBack = function() self:OnClickBtnSelect() end
end

function XUiGridBabelSelectTeam:Refresh(stageId, teamId)
    self.StageId = stageId
    self.TeamId = teamId

    local unlockTeamNum = XDataCenter.FubenBabelTowerManager.GetStageUnlockTeamNum(stageId)
    local teamNum = unlockTeamNum + 1
    -- 解锁多编队
    local collectionInfo = XDataCenter.FubenBabelTowerManager.GetBabelTowerInfo(XFubenBabelTowerConfigs.COLLECTION_ITEM_QUALITY, nil)
    if not XTool.IsTableEmpty(collectionInfo) and teamNum < collectionInfo.MaxTeamId then
        teamNum = collectionInfo.MaxTeamId
    end
    local isLock = teamId > teamNum
    if not isLock then
        local isReset = XDataCenter.FubenBabelTowerManager.IsTeamReseted(stageId, teamId)
        local isPassed = XDataCenter.FubenBabelTowerManager.IsStageTeamHasRecord(stageId, teamId)

        self.BtnRecover.gameObject:SetActiveEx(isReset)
        self.BtnReset.gameObject:SetActiveEx(not isReset and isPassed)
        self.TxtRecord.gameObject:SetActiveEx(false)

        self.PanelNor.gameObject:SetActiveEx(true)
        self.PanelLock.gameObject:SetActiveEx(false)
    else
        self.TxtLock.text = CSXTextManagerGetText("BabelTowerTeamLock", XTool.ParseNumberString(teamId - 1), XTool.ParseNumberString(teamId))
        self.PanelNor.gameObject:SetActiveEx(false)
        self.PanelLock.gameObject:SetActiveEx(true)
    end

    local characterIds = XDataCenter.FubenBabelTowerManager.GetTeamCharacterIds(stageId, teamId)
    for i = 1, MAX_CHARACTER_NUM do
        local rImg = self["RImgRoleIcon" .. i]

        local characterId = characterIds[i]
        if characterId and characterId > 0 then
            local icon = XDataCenter.CharacterManager.GetCharSmallHeadIcon(characterId)
            rImg:SetRawImage(icon)
            rImg.gameObject:SetActiveEx(true)
        else
            rImg.gameObject:SetActiveEx(false)
        end
    end

    self.TxtTeamOrder.text = CSXTextManagerGetText("BabelTowerTeamOrder", teamId)

    local curScore = XDataCenter.FubenBabelTowerManager.GetTeamCurScore(stageId, teamId)
    self.TxtLevel.text = curScore
end

function XUiGridBabelSelectTeam:OnClickBtnReset()
    local stageId = self.StageId
    local teamId = self.TeamId

    local stageName = XFubenBabelTowerConfigs.GetStageName(stageId)
    local title = CSXTextManagerGetText("BabelTowerResetDesc")
    local content = CSXTextManagerGetText("BabelTowerIsResetDesc", stageName)
    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, function()
        XDataCenter.FubenBabelTowerManager.ResetBabelTowerStage(stageId, teamId, function()
            XUiManager.TipMsg(CSXTextManagerGetText("BabelTowerStageResetSucceed", stageName))
            self:Refresh(stageId, teamId)
        end)
    end)
end

function XUiGridBabelSelectTeam:OnClickBtnRecover()
    local stageId = self.StageId
    local teamId = self.TeamId
    XLuaUiManager.Open("UiBabelTowerAutoFight", stageId, teamId, function()
        self:Refresh(stageId, teamId)
    end)
end

function XUiGridBabelSelectTeam:OnClickBtnSelect()
    -- local teamList = XDataCenter.FubenBabelTowerManager.GetCacheTeam(self.StageId, self.TeamId)
    XLuaUiManager.Open("UiBabelTowerBase", self.StageId, self.TeamId)
end

return XUiGridBabelSelectTeam
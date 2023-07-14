local XUiGridAutoFightMember = require("XUi/XUiFubenBabelTower/XUiGridAutoFightMember")

local CSXTextManagerGetText = CS.XTextManager.GetText

local XUiBabelTowerAutoFight = XLuaUiManager.Register(XLuaUi, "UiBabelTowerAutoFight")

function XUiBabelTowerAutoFight:OnAwake()
    self.BtnBg.CallBack = function() self:OnBtnBgClick() end
    self.BtnAutoFight.CallBack = function() self:OnBtnAutoFightClik() end
    self.BtnTanchuangClose.CallBack = function() self:OnBtnBgClick() end

    self.AutoFightGrid = {}
    for i = 1, XFubenBabelTowerConfigs.MAX_TEAM_MEMBER do
        self.AutoFightGrid[i] = XUiGridAutoFightMember.New(self[string.format("GridRoleAutoFight%d", i)])
    end
end

function XUiBabelTowerAutoFight:OnStart(stageId, teamId, closeCb)
    self.StageId = stageId
    self.TeamId = teamId
    self.CloseCb = closeCb
    self.BlackList = XDataCenter.FubenBabelTowerManager.WipeOutBlackList(stageId, teamId)

    local includeReset = true
    self.CharacterIds = XDataCenter.FubenBabelTowerManager.GetTeamCharacterIds(stageId, teamId, includeReset)

    for i = 1, XFubenBabelTowerConfigs.MAX_TEAM_MEMBER do
        local characterId = self.CharacterIds[i]
        local isLock = characterId and characterId ~= 0 and self.BlackList[characterId]
        self.AutoFightGrid[i]:UpdateMember(characterId, isLock)
    end

    local curScore = XDataCenter.FubenBabelTowerManager.GetTeamCurScore(stageId, teamId, true)
    self.TxtScore.text = curScore

    self.TxtTeamId.text = CSXTextManagerGetText("BabelTowerTeamOrder", teamId)
end

function XUiBabelTowerAutoFight:OnBtnBgClick()
    self:Close()
end

function XUiBabelTowerAutoFight:OnBtnAutoFightClik()
    -- 黑名单判断
    local hasBlackListMember = false
    local blackListMemberId = 0
    for i = 1, XFubenBabelTowerConfigs.MAX_TEAM_MEMBER do
        local characterId = self.CharacterIds[i]
        if characterId ~= nil and characterId ~= 0 then
            if self.BlackList[characterId] then
                hasBlackListMember = true
                blackListMemberId = characterId
                break
            end
        end
    end
    if hasBlackListMember and blackListMemberId > 0 then
        local blackName = XCharacterConfigs.GetCharacterFullNameStr(blackListMemberId)
        XUiManager.TipMsg(CS.XTextManager.GetText("BabelTowerCharacterLock", blackName))
        return
    end

    XDataCenter.FubenBabelTowerManager.WipeOutBabelTowerStage(self.StageId, self.TeamId, function()
        local stageConfigs = XFubenBabelTowerConfigs.GetBabelStageConfigs(self.StageId)
        XUiManager.TipMsg(CS.XTextManager.GetText("BabelTowerStageWipeOutSucceed", stageConfigs.Name))
        if self.CloseCb then self.CloseCb() end
        self:Close()
    end)
end

function XUiBabelTowerAutoFight:OnDestroy()
end
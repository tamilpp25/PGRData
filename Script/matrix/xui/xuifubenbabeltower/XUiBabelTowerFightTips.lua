local CsXTextManager = CS.XTextManager
--######################## XUiBabelTowerWinPanel ########################
local XUiBabelTowerWinPanel = XClass(nil, "XUiBabelTowerWinPanel")

function XUiBabelTowerWinPanel:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.StageId = nil
    self.TeamId = nil
    XTool.InitUiObject(self)
    self:RegisterUiEvents()
    self.RImgHead.gameObject:SetActiveEx(false)
end

function XUiBabelTowerWinPanel:SetData(stageId, teamId, challengeBuffs, supportBuffs, curTeamScore, curActivityMaxScore, babelTowerSettleResult)
    self.StageId = stageId
    self.TeamId = teamId
    -- 玩家基本信息
    XUiPLayerHead.InitPortrait(XPlayer.CurrHeadPortraitId, XPlayer.CurrHeadFrameId, self.Head)
    self.TxtPlayName.text = XPlayer.Name
    self.TxtPlayerId.text = XPlayer.Id
    -- 编队基本信息
    local teamScore = XDataCenter.FubenBabelTowerManager.GetTeamCurScore(stageId, teamId)
    self.TxtTeamNumber.text = CsXTextManager.GetText("BabelTowerTeamOrder", teamId)
    self.TxtTeamLevel.text = teamScore
    local characterIds = XDataCenter.FubenBabelTowerManager.GetTeamCharacterIds(stageId, teamId)
    local headContentChild, rImgHeadIcon
    for i = 1, 3 do
        local characterViewModel = XEntityHelper.GetCharacterViewModelByEntityId(characterIds[i])
        if characterViewModel then
            if i > self.HeadContent.childCount then
                headContentChild = CS.UnityEngine.Object.Instantiate(self.RImgHead, self.HeadContent)
            else
                headContentChild = self.HeadContent:GetChild(i - 1)
            end
            headContentChild.gameObject:SetActiveEx(true)
            rImgHeadIcon = headContentChild:GetComponent("RawImage")
            rImgHeadIcon:SetRawImage(characterViewModel:GetSmallHeadIcon())
        end
    end
    -- 关卡难度
    local selectDifficult = XDataCenter.FubenBabelTowerManager.GetTeamSelectDifficult(stageId, teamId)
    local name = XFubenBabelTowerConfigs.GetStageDifficultName(stageId, selectDifficult)
    self.TxtDiffName.text = name
    -- 关卡使用的词缀
    local isHard
    local childUObj
    local buffData
    local buffContent = self.FightEventContent1
    buffContent:GetChild(0).gameObject:SetActiveEx(false)
    local buffConfig
    for i = 1, 10 do
        buffContent = i <= 5 and self.FightEventContent1 or self.FightEventContent2
        buffData = challengeBuffs[i]
        childUObj = CS.UnityEngine.Object.Instantiate(self.FightEventGrid, buffContent):GetComponent("UiObject")
        childUObj.gameObject:SetActiveEx(true)
        childUObj:GetObject("RImgNone").gameObject:SetActiveEx(buffData == nil)
        childUObj:GetObject("RImgBg").gameObject:SetActiveEx(buffData ~= nil)
        childUObj:GetObject("RImgIcon").gameObject:SetActiveEx(buffData ~= nil)
        if buffData then
            isHard = XFubenBabelTowerConfigs.IsBuffGroupHard(buffData.GroupId)
            buffConfig = XFubenBabelTowerConfigs.GetBabelBuffConfigs(buffData.BufferId)
            childUObj:GetObject("RImgRed").gameObject:SetActiveEx(isHard)
            childUObj:GetObject("RImgBlue").gameObject:SetActiveEx(not isHard)
            childUObj:GetObject("RImgIcon"):SetRawImage(buffConfig.BuffBg)
        else
            childUObj:GetObject("RImgRed").gameObject:SetActiveEx(false)
            childUObj:GetObject("RImgBlue").gameObject:SetActiveEx(false)
        end
    end
    -- 关卡号
    local stageConfig = XFubenBabelTowerConfigs.GetBabelStageConfigs(stageId)
    self.TxtStageNumber.text = "0" .. stageConfig.Number
    -- 关卡名
    self.TxtStageName.text = stageConfig.Title
    -- 完成等级
    local finishedScore = babelTowerSettleResult.FinalScore
    self.RImgLevelUp.gameObject:SetActiveEx(finishedScore > curTeamScore)
    self.TxtLevel.text = finishedScore
    -- 总等级
    self.TxtTotalLevel.text = XUiHelper.GetText("BabelTowerSettleTotalLevel", babelTowerSettleResult.OriginScore)
    -- 复活
    self.TxtTitle01.gameObject:SetActiveEx(babelTowerSettleResult.RebootSubScore > 0)
    self.TxtNumber01.text = XUiHelper.GetText("BabelTowerSettleLevelTips", babelTowerSettleResult.RebootSubScore)
    -- 超时
    self.TxtTitle02.gameObject:SetActiveEx(babelTowerSettleResult.TimeoutSubScore > 0)
    self.TxtNumber02.text = XUiHelper.GetText("BabelTowerSettleLevelTips", babelTowerSettleResult.TimeoutSubScore)
    -- 角色立绘
    local captainPos = XDataCenter.FubenBabelTowerManager.GetTeamCaptainPos(stageId, teamId)
    self.RImgRole:SetRawImage(XMVCA.XCharacter:GetCharHalfBodyBigImage(characterIds[captainPos]))
    -- 检查战斗计时器，回到活动主界面
    local currentActivityNo = XDataCenter.FubenBabelTowerManager.GetCurrentActivityNo()
    local endTime = XDataCenter.FubenBabelTowerManager.GetFightEndTime(currentActivityNo)
    self.RootUi:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            self.RootUi:StopTimer()
            XDataCenter.FunctionEventManager.UnLockFunctionEvent()
            XLuaUiManager.RunMain()
            XUiManager.TipError(CS.XTextManager.GetText("BabelTowerNoneFight"))
        end  
    end)
end

function XUiBabelTowerWinPanel:RegisterUiEvents()
    self.BtnQuit.CallBack = function() self:OnBtnQuitClicked() end
end

function XUiBabelTowerWinPanel:OnBtnQuitClicked()
    self.RootUi:StopTimer()
    self.RootUi:Close()
    XDataCenter.FunctionEventManager.UnLockFunctionEvent()
end

function XUiBabelTowerWinPanel:GetChallengePoints(buffList)
    local totalChallengePoints = 0
    local buffId
    local buffTemplates
    for _, buffInfo in pairs(buffList) do
        buffId = buffInfo.BufferId
        buffTemplates = XFubenBabelTowerConfigs.GetBabelTowerBuffTemplate(buffId)
        totalChallengePoints = totalChallengePoints + buffTemplates.ScoreAdd
    end
    local selectDifficult = XDataCenter.FubenBabelTowerManager.GetTeamSelectDifficult(self.StageId, self.TeamId)
    local ratio = XFubenBabelTowerConfigs.GetStageDifficultRatio(self.StageId, selectDifficult)
    return math.floor(totalChallengePoints * ratio)
end


--######################## XUiBabelTowerFightTips ########################
local XUiBabelTowerFightTips = XLuaUiManager.Register(XLuaUi, "UiFightBabelTower")
local XUiBabelTowerTipsItem = require("XUi/XUiFubenBabelTower/XUiBabelTowerTipsItem")

local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

local BuffShowRate = CS.XGame.ClientConfig:GetInt("BabelTowerBuffShowRate") / 10
local BuffDisapearTime = CS.XGame.ClientConfig:GetInt("BabelTowerBuffDisappearTime")
local ANIM_BEGIN_ENABLE = "AnimBeginEnable"
local ANIM_END_ENABLE = "AnimEndEnable"

function XUiBabelTowerFightTips:OnAwake()
    self.UiBabelTowerWinPanel = XUiBabelTowerWinPanel.New(self.PanelWin, self)
    self.ChallengeBuffList = {}
    self.SupportBuffList = {}

    for i = XFubenBabelTowerConfigs.START_INDEX, XFubenBabelTowerConfigs.MAX_CHALLENGE_BUFF_COUNT do
        self.ChallengeBuffList[i] = XUiBabelTowerTipsItem.New(self[string.format("Challenge%d", i)], XFubenBabelTowerConfigs.TYPE_CHALLENGE)
        self.ChallengeBuffList[i].GameObject:SetActiveEx(false)
    end

    for i = XFubenBabelTowerConfigs.START_INDEX, XFubenBabelTowerConfigs.MAX_SUPPORT_BUFF_COUNT do
        self.SupportBuffList[i] = XUiBabelTowerTipsItem.New(self[string.format("Support%d", i)], XFubenBabelTowerConfigs.TYPE_SUPPORT)
        self.SupportBuffList[i].GameObject:SetActiveEx(false)
    end

    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnPrepareMask.CallBack = function() self:OnBtnBackClick() end
end

function XUiBabelTowerFightTips:OnBtnBackClick()
    self:StopTimer()
    self:PlayAnimation("AnimEffertEnable", function()
        self:Close()
        XDataCenter.FunctionEventManager.UnLockFunctionEvent()
    end)
end


function XUiBabelTowerFightTips:OnStart(stageId, battleStatus, babelTowerSettleResult)
    self.BaseBuffGrids = {}

    self.StageId = stageId
    self.BattleStatus = battleStatus
    self.CurStageId, self.CurTeamId, self.CurStageGuideId, self.CurTeamList, self.ChallengeBuffs, self.SupportBuffs
        , self.CurCaptainPos, self.CurStageLevel, self.CurFirstFightPos, self.CurTeamScore, self.curActivityMaxScore
        = XDataCenter.FubenBabelTowerManager.GetCurStageInfo()

    if self.StageId ~= self.CurStageId then
        XLog.Error("stageId do not match...self.StageId = " .. tostring(self.StageId) .. "; self.CurStageId = " .. tostring(self.CurStageId))
        self:Close()
        return
    end
    self.PanelReady.gameObject:SetActiveEx(self.BattleStatus == XFubenBabelTowerConfigs.BattleReady)
    self.PanelWin.gameObject:SetActiveEx(self.BattleStatus == XFubenBabelTowerConfigs.BattleEnd)
    -- 如果是胜利界面，直接交给胜利界面单独处理
    if self.BattleStatus == XFubenBabelTowerConfigs.BattleEnd then
        self.UiBabelTowerWinPanel:SetData(self.CurStageId, self.CurTeamId, self.ChallengeBuffs, self.SupportBuffs, self.CurTeamScore, self.curActivityMaxScore, babelTowerSettleResult)
        self:PlayAnimation(ANIM_END_ENABLE)
        return
    end

    self:ClearFightTips()

    local animName = self.BattleStatus == XFubenBabelTowerConfigs.BattleReady and ANIM_BEGIN_ENABLE or ANIM_END_ENABLE
    self:PlayAnimation(animName, function()
        self:SetBabelTowerFightTips()
    end)

    self:SetStageBaseBuffs()
end

function XUiBabelTowerFightTips:ClearFightTips()
    self.ModeTitle2.gameObject:SetActiveEx(false)
    self.OverTitle.gameObject:SetActiveEx(false)
    self.BtnPrepareMask.gameObject:SetActiveEx(false)
    for i = 1, XFubenBabelTowerConfigs.MAX_CHALLENGE_BUFF_COUNT do
        self.ChallengeBuffList[i].GameObject:SetActiveEx(false)
    end
    for i = 1, XFubenBabelTowerConfigs.MAX_SUPPORT_BUFF_COUNT do
        self.SupportBuffList[i].GameObject:SetActiveEx(false)
    end
end

function XUiBabelTowerFightTips:GetChallengePoints(buffList)
    self.ModeTitle2.gameObject:SetActiveEx(self.BattleStatus == XFubenBabelTowerConfigs.BattleReady)
    self.OverTitle.gameObject:SetActiveEx(self.BattleStatus == XFubenBabelTowerConfigs.BattleEnd)
    local totalChallengePoints = 0
    for _, buffInfo in pairs(buffList) do
        local buffId = buffInfo.BufferId
        local buffTemplates = XFubenBabelTowerConfigs.GetBabelTowerBuffTemplate(buffId)
        totalChallengePoints = totalChallengePoints + buffTemplates.ScoreAdd
    end

    local selectDifficult = XDataCenter.FubenBabelTowerManager.GetTeamSelectDifficult(self.StageId, self.CurTeamId)
    local ratio = XFubenBabelTowerConfigs.GetStageDifficultRatio(self.StageId, selectDifficult)
    return math.floor(totalChallengePoints * ratio)
end

function XUiBabelTowerFightTips:SetBabelTowerFightTips()

    if self.BattleStatus == XFubenBabelTowerConfigs.BattleReady then
        -- local curActivityNo = XDataCenter.FubenBabelTowerManager.GetCurrentActivityNo()
        local challengePoints = self:GetChallengePoints(self.ChallengeBuffs)
        local _, difficultyTitle, difficultyStatus = XFubenBabelTowerConfigs.GetBabelTowerDifficulty(self.StageId, challengePoints)
        self.TxtStatusTitle.text = difficultyTitle
        self.TxtStatusWarning.text = difficultyStatus
    elseif self.BattleStatus == XFubenBabelTowerConfigs.BattleEnd then
        self.TxtFinishLevel.text = self:GetChallengePoints(self.ChallengeBuffs)
    end

    self:SetBattlePrepareBuff(self.ChallengeBuffs, self.SupportBuffs)
end

--展示关卡基础难度buff
function XUiBabelTowerFightTips:SetStageBaseBuffs()
    local baseBuffIds = XFubenBabelTowerConfigs.GetBaseBuffIds(self.StageId)

    for index, buffId in pairs(baseBuffIds) do
        local grid = self.BaseBuffGrids[index]
        if not grid then
            local go = index == 1 and self.GridBaseBuff or CSUnityEngineObjectInstantiate(self.GridBaseBuff, self.PanelBaseBuffs)
            grid = XTool.InitUiObjectByUi({}, go)
            self.BaseBuffGrids[index] = grid
        end

        grid.TxtBuff.text = XFubenBabelTowerConfigs.GetBaseBuffNameWithSpilt(buffId)
        grid.GameObject:SetActiveEx(true)
    end

    for index = #baseBuffIds + 1, #self.BaseBuffGrids do
        local grid = self.BaseBuffGrids[index]
        if grid then
            grid.GameObject:SetActiveEx(false)
        end
    end

end

function XUiBabelTowerFightTips:SetBattlePrepareBuff(challengeBuffs, supportBuffs)
    self.ChallengeBuffList[0].GameObject:SetActiveEx(true)
    self.SupportBuffList[0].GameObject:SetActiveEx(true)

    self:StopTimer()
    local currentShowBuffIndex = 0
    local timerGap = CS.XGame.ClientConfig:GetInt("BabelTowerBuffShowTime")
    self.Timer = XScheduleManager.ScheduleForever(function()
        if currentShowBuffIndex > #challengeBuffs and currentShowBuffIndex > #supportBuffs then
            self:StopTimer()
            if self.BattleStatus == XFubenBabelTowerConfigs.BattleReady then
                self:SetAutoCloseTimer()
            end
            return
        end
        if currentShowBuffIndex > XFubenBabelTowerConfigs.START_INDEX then
            if currentShowBuffIndex <= XFubenBabelTowerConfigs.MAX_CHALLENGE_BUFF_COUNT then
                self.ChallengeBuffList[currentShowBuffIndex].GameObject:SetActiveEx(challengeBuffs[currentShowBuffIndex] ~= nil)
                if challengeBuffs[currentShowBuffIndex] then
                    self.ChallengeBuffList[currentShowBuffIndex]:RefreshBuffInfo(challengeBuffs[currentShowBuffIndex], XFubenBabelTowerConfigs.TYPE_CHALLENGE)
                end
            end
            if currentShowBuffIndex <= XFubenBabelTowerConfigs.MAX_SUPPORT_BUFF_COUNT then
                self.SupportBuffList[currentShowBuffIndex].GameObject:SetActiveEx(supportBuffs[currentShowBuffIndex] ~= nil)
                if supportBuffs[currentShowBuffIndex] then
                    self.SupportBuffList[currentShowBuffIndex]:RefreshBuffInfo(supportBuffs[currentShowBuffIndex], XFubenBabelTowerConfigs.TYPE_SUPPORT)
                end
            end
            timerGap = timerGap * BuffShowRate
        end
        currentShowBuffIndex = currentShowBuffIndex + 1
    end, timerGap, 0)
end

function XUiBabelTowerFightTips:SetAutoCloseTimer()

    self:StopAutoCloseTimer()
    self.AutoCloseTimer = XScheduleManager.ScheduleOnce(function()
        self.BtnPrepareMask.gameObject:SetActiveEx(true)
        self:Close()
    end, BuffDisapearTime)
end

function XUiBabelTowerFightTips:StopAutoCloseTimer()
    if self.AutoCloseTimer then
        XScheduleManager.UnSchedule(self.AutoCloseTimer)
        self.AutoCloseTimer = nil
    end
end

function XUiBabelTowerFightTips:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiBabelTowerFightTips:OnEnable()
    XUiBabelTowerFightTips.Super.OnEnable(self)
    if CS.XFight.IsRunning then
        CS.XFight.Instance:Pause()
    end
end

function XUiBabelTowerFightTips:OnDisable()
    XUiBabelTowerFightTips.Super.OnDisable(self)
    if CS.XFight.Instance then
        CS.XFight.Instance:Resume()
    end
end

function XUiBabelTowerFightTips:OnDestroy()
    self:StopTimer()
    self:StopAutoCloseTimer()
end
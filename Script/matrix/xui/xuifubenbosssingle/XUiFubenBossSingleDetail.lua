local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiTabBtnGroup = require("XUi/XUiBase/XUiTabBtnGroup")
local XUiFubenBossSingleDetailGridSkill = require("XUi/XUiFubenBossSingle/XUiFubenBossSingleDetailGridSkill")
local XUiFubenBossSingleDetailAutoFight = require("XUi/XUiFubenBossSingle/XUiFubenBossSingleDetailAutoFight")
local XUiFubenBossSingleDetailTip = require("XUi/XUiFubenBossSingle/XUiFubenBossSingleDetailTip")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XUiModelUtility = require("XUi/XUiCharacter/XUiModelUtility")
---@class XUiFubenBossSingleDetail : XLuaUi
---@field GridBossLevel1 UnityEngine.UI.Button
---@field GridBossLevel2 UnityEngine.UI.Button
---@field GridBossLevel3 UnityEngine.UI.Button
---@field GridBossLevel4 UnityEngine.UI.Button
---@field GridBossLevel5 UnityEngine.UI.Button
---@field BtnStart XUiComponent.XUiButton
---@field BtnAuto XUiComponent.XUiButton
---@field TxtLevel UnityEngine.UI.Text
---@field PanelCondition UnityEngine.RectTransform
---@field ImgCondition1 UnityEngine.UI.Image
---@field ImgCondition2 UnityEngine.UI.Image
---@field TxtConditon1 UnityEngine.UI.Text
---@field TxtConditon2 UnityEngine.UI.Text
---@field TxtChangeNums UnityEngine.UI.Text
---@field TxtTimeLimit UnityEngine.UI.Text
---@field TxtMyScore UnityEngine.UI.Text
---@field PanelSkill UnityEngine.RectTransform
---@field GridBossSkill UnityEngine.RectTransform
---@field ImgNandu UnityEngine.UI.Image
---@field TxtBossName UnityEngine.UI.Text
---@field TxtBossDes UnityEngine.UI.Text
---@field ImgEffect UnityEngine.UI.Image
---@field TxtAllScore UnityEngine.UI.Text
---@field BtnClick UnityEngine.UI.Button
---@field TxtRepeatDesc UnityEngine.UI.Text
---@field PanelAutoFight UnityEngine.RectTransform
---@field TxtATNums UnityEngine.UI.Text
---@field GridBossLevel6 UnityEngine.UI.Button
---@field TxtSelectedEn UnityEngine.UI.Text
---@field TxtHideSelectedBoss UnityEngine.UI.Text
---@field TxtHideLockBoss UnityEngine.UI.Text
---@field TxtNormalEn UnityEngine.UI.Text
---@field TxtFightCharCount UnityEngine.UI.Text
---@field ImgBg UnityEngine.RectTransform
---@field ImgBgHb UnityEngine.RectTransform
---@field PanelTip UnityEngine.RectTransform
---@field ImagBossTileBg UnityEngine.RectTransform
---@field ImagBossTileBgHb UnityEngine.RectTransform
---@field PanelEffectHb UnityEngine.RectTransform
---@field GridBossLevel6Alpha UnityEngine.CanvasGroup
---@field BtnHelp XUiComponent.XUiButton
---@field PanelAsset UnityEngine.RectTransform
---@field BtnBack XUiComponent.XUiButton
---@field BtnMainUi XUiComponent.XUiButton
---@field PanelTags UnityEngine.RectTransform
---@field PanelTagsNew UnityEngine.RectTransform
---@field GridBossLevelNew1 UnityEngine.RectTransform
---@field GridBossLevelNew2 UnityEngine.RectTransform
---@field GridBossLevelNew3 UnityEngine.RectTransform
---@field BtnRank XUiComponent.XUiButton
---@field _Control XFubenBossSingleControl
local XUiFubenBossSingleDetail = XLuaUiManager.Register(XLuaUi, "UiFubenBossSingleDetail")

local IPairs = ipairs
local ONE_MINUTE_SECOND = 60

function XUiFubenBossSingleDetail:Ctor()
    ---@type XUiFubenBossSingleDetailAutoFight
    self.PanelAutoFightUi = nil
    ---@type XUiFubenBossSingleDetailTip
    self.PanelTipUi = nil
    self._BossSingleData = nil
    self._BossId = nil
    self._Index = nil
    self._TabBtnGroup = nil
    self._CurBossStageConfig = nil
    self._TweenTimer = nil
    ---@type XUiPanelRoleModel
    self.RoleModelPanelUi = nil
    ---@type XUiFubenBossSingleDetailGridSkill[]
    self._GridBossSkillUiList = {}
    ---@type UnityEngine.UI.Button[]
    self._ToggleTabList = nil
end

-- region 生命周期
function XUiFubenBossSingleDetail:OnAwake()
    XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem,
        XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self:_RegisterButtonClicks()
    self.GridBossSkill.gameObject:SetActiveEx(false)
end

function XUiFubenBossSingleDetail:OnStart(bossId)
    local sectionInfo = self._Control:GetBossSectionInfoByBossId(bossId)
    local root = self.UiModelGo.transform

    self._BossSingleData = self._Control:GetBossSingleData()
    self._BossId = bossId
    self._Index = self._Control:GetCurBossIndex(bossId)
    self._CurBossStageConfig = sectionInfo[self._Index]
    self.RoleModelPanelUi = XUiPanelRoleModel.New(root:FindTransform("PanelRoleModel"), self.Name, nil, true)
    self.PanelAutoFightUi = XUiFubenBossSingleDetailAutoFight.New(self.PanelAutoFight, self)
    self.PanelTipUi = XUiFubenBossSingleDetailTip.New(self.PanelTip, self, self._CurBossStageConfig)
    self:_InitGridLevel()
    self:_Init()
    self._Control:SetIsUseSelectIndex(false)
end

function XUiFubenBossSingleDetail:OnEnable()
    self:_SelectTabGroup()
    self:_RegisterEventListeners()
end

function XUiFubenBossSingleDetail:OnDisable()
    self:_RemoveEventListeners()
    self:_RemoveSchedules()
end

-- endregion

-- region 按钮事件
function XUiFubenBossSingleDetail:OnBtnStartClick()
    local stageId = self._CurBossStageConfig.StageId
    local stageCfg = XMVCA.XFuben:GetStageCfg(stageId)

    if not XMVCA.XFuben:CheckPreFight(stageCfg) then
        return
    end

    self._Control:SetEnterBossInfo(self._BossId, self._CurBossStageConfig.DifficultyType)
    self._Control:OnEnterNormalFight()
    XLuaUiManager.Open("UiBattleRoleRoom", stageId, self._Control:GetTeamByBossId(self._BossId),
        require("XUi/XUiFubenBossSingle/XUiBossSingleBattleRoleRoom"))
end

function XUiFubenBossSingleDetail:OnBtnAutoClick()
    if not self._CurBossStageConfig.AutoFight then
        local text = XUiHelper.GetText("BossSingleAutoFightDesc2", self._CurBossStageConfig.DifficultyDesc)

        XUiManager.TipMsg(text)
        return
    end

    local autoFightData = self._Control:CheckAutoFight(self._CurBossStageConfig.StageId)

    if not autoFightData then
        XUiManager.TipText("BossSingleAutoFightDesc1")
        return
    end

    local stageData = XMVCA.XFuben:GetStageData(self._CurBossStageConfig.StageId)
    local curScore = stageData and stageData.Score or 0
    local autoScore = math.floor(self._Control:GetAutoFightRebate() * autoFightData:GetScore() / 100)

    if curScore >= autoScore then
        XUiManager.TipText("BossSingleAutoFightDesc12")
        return
    end

    local autoFightCount = self._Control:GetAutoFightCount()
    local maxCount = autoFightCount
    local curCount = autoFightCount - self._BossSingleData:GetBossSingleAutoFightCount()

    if maxCount > 0 and curCount <= 0 then
        XUiManager.TipText("BossSingleAutoFightCount3")
        return
    end

    self.PanelAutoFightUi:Open()
    self.PanelAutoFightUi:Refresh(autoFightData, self._BossSingleData:GetBossSingleChallengeCount(),
        self._CurBossStageConfig)
    self:PlayAnimation("PanelAutoFightEnable")
end

function XUiFubenBossSingleDetail:OnBtnClickClick()

end

function XUiFubenBossSingleDetail:OnBtnRankClick()
    self._Control:OpenRankUi(self._BossSingleData:GetBossSingleLevelType(), self._BossId, true)
end

function XUiFubenBossSingleDetail:OnGridBossLevelClick(index)
    self:_RefreshBossInfo(index)
    self._Control:SetCurrentSelectIndex(index)
end

function XUiFubenBossSingleDetail:OnCheckToggleClick(index)
    return self:_CheckClick(index, true)
end

function XUiFubenBossSingleDetail:OnTweenRefresh()
    if XTool.UObjIsNil(self.Transform) or not self.GameObject.activeSelf then
        return true
    end

    local stageId = self._CurBossStageConfig.StageId
    local score = self._CurBossStageConfig.Score + self._Control:GetBaseScoreByStageId(stageId)
    local stageData = XMVCA.XFuben:GetStageData(stageId)
    local curScore = stageData and stageData.Score or 0

    self:_SetSelfScore(score, curScore)
end

function XUiFubenBossSingleDetail:OnSyncBossData()
    self._BossSingleData = self._Control:GetBossSingleData()
    self:_SelectTabGroup()
end

function XUiFubenBossSingleDetail:OnActivityEnd()
    self._Control:OnActivityEnd()
end

function XUiFubenBossSingleDetail:OnAutoFight(isTip)
    self:RefreshToggleGroup()
    self.PanelAutoFightUi:Close()
    self:_AutoFightTween(isTip)
end

-- endregion

function XUiFubenBossSingleDetail:RefreshToggleGroup()
    for i, _ in IPairs(self._TabBtnGroup.TabBtnList) do
        if self:_CheckClick(i, false) then
            self._TabBtnGroup:UnLockIndex(i)
        else
            self._TabBtnGroup:LockIndex(i)
        end
    end

    self:_SelectTabGroup()
end

-- region 私有方法
function XUiFubenBossSingleDetail:_Init()
    if self._TabBtnGroup then
        self._TabBtnGroup:Dispose()
    end

    local toggleList = {}
    local sectionInfo = self._Control:GetBossSectionInfoByBossId(self._BossId)
    local hasHideBoss = self._Control:CheckLevelHasHideBoss()
    local count = hasHideBoss and #sectionInfo or #sectionInfo - 1

    for i = 1, math.min(count, #self._ToggleTabList) do
        local grid = self._ToggleTabList[i]

        grid.gameObject:SetActiveEx(true)
        toggleList[i] = grid
    end

    self:_InitEffect()
    self:_SetHideBossActive(hasHideBoss, false)
    self.TxtSelectedEn.gameObject:SetActiveEx(hasHideBoss)
    self.TxtHideSelectedBoss.gameObject:SetActiveEx(hasHideBoss)
    self._TabBtnGroup = XUiTabBtnGroup.New(toggleList, Handler(self, self.OnGridBossLevelClick),
        Handler(self, self.OnCheckToggleClick), true)
    self.PanelTipUi:Close()

    -- 设置Toggle名字
    for i, btn in IPairs(self._TabBtnGroup.TabBtnList) do
        local bossStageCfg = self._Control:GetBossStageConfig(sectionInfo[i].StageId)

        btn:SetName(bossStageCfg.DifficultyDesc, bossStageCfg.DifficultyDescEn)

        if i ~= XEnumConst.BossSingle.DifficultyType.Experiment then
            if self:_CheckClick(i, false) then
                self._TabBtnGroup:UnLockIndex(i)
            else
                self._TabBtnGroup:LockIndex(i)
            end
        end
    end
end

function XUiFubenBossSingleDetail:_InitGridLevel()
    if self._BossSingleData:IsNewVersion() then
        local levelType = self._BossSingleData:GetBossSingleLevelType()

        self.PanelTags.gameObject:SetActiveEx(false)
        self.PanelTagsNew.gameObject:SetActiveEx(true)
        self.BtnRank.gameObject:SetActiveEx(self._Control:CheckHasRankData(levelType))
        self._ToggleTabList = {
            self.GridBossLevelNew1,
            self.GridBossLevelNew2,
            self.GridBossLevelNew3,
        }
    else
        self.PanelTags.gameObject:SetActiveEx(true)
        self.PanelTagsNew.gameObject:SetActiveEx(false)
        self.BtnRank.gameObject:SetActiveEx(false)
        self._ToggleTabList = {
            self.GridBossLevel1,
            self.GridBossLevel2,
            self.GridBossLevel3,
            self.GridBossLevel4,
            self.GridBossLevel5,
            self.GridBossLevel6,
        }
    end
end

function XUiFubenBossSingleDetail:_InitEffect()
    local root = self.UiModelGo.transform
    self.ImgEffectHuanren = root:FindTransform("ImgEffectHuanren")
    self.ImgEffectHuanrenHideBoss = root:FindTransform("ImgEffectHuanren1")
    self.ImgEffectHuanren.gameObject:SetActiveEx(false)
    self.ImgEffectHuanrenHideBoss.gameObject:SetActiveEx(false)
end

function XUiFubenBossSingleDetail:_AutoFightTween(isTip)
    local text = XUiHelper.GetText("BossSingleAutoSuccess")
    local msgType = XUiManager.UiTipType.Success

    XUiManager.TipMsg(text, msgType, function()
        if self._TweenTimer then
            XScheduleManager.UnSchedule(self._TweenTimer)
        end

        local time = CS.XGame.ClientConfig:GetFloat("BossSingleAnimaTime")

        self._TweenTimer = XUiHelper.Tween(time, Handler(self, self.OnTweenRefresh))

        if isTip then
            XUiManager.TipText("BossSignleBufenTip", XUiManager.UiTipType.Tip)
        end
    end)
end

function XUiFubenBossSingleDetail:_SelectTabGroup()
    if self._Index then
        self._TabBtnGroup:SelectIndex(self._Index)
    else
        local index = self._Control:GetCurBossIndex(self._BossId)

        self._TabBtnGroup:SelectIndex(index)
    end
end

function XUiFubenBossSingleDetail:_RefreshBossInfo(index)
    local sectionInfo = self._Control:GetBossSectionInfoByBossId(self._BossId)

    self._Index = index
    self._CurBossStageConfig = sectionInfo[index]

    local isHideBoss = self._CurBossStageConfig.DifficultyType == XEnumConst.BossSingle.DifficultyType.Hide

    if isHideBoss then
        self:PlayAnimation("BossDetailQieHuan")
    end

    self:_RefreshDesc()
    self:_RefreshInfo()
    self:_RefreshHideBoss()
    self:_RefreshModel(self._CurBossStageConfig.ModelId, isHideBoss)
    self.PanelTipUi:SetBossStageConfig(self._CurBossStageConfig)
    self.PanelTipUi:Open()
end

function XUiFubenBossSingleDetail:_RefreshDesc()
    local stageId = self._CurBossStageConfig.StageId
    local stageCfg = XMVCA.XFuben:GetStageCfg(stageId)
    local isHideBoss = self._CurBossStageConfig.DifficultyType == XEnumConst.BossSingle.DifficultyType.Hide
    local time = math.floor(stageCfg.PassTimeLimit / ONE_MINUTE_SECOND)
    local text = isHideBoss and XUiHelper.GetText("BossSingleMinuteHideBoss", time)
                     or XUiHelper.GetText("BossSingleMinute", time)
    local sectionCfg = self._Control:GetBossSectionConfigByBossId(self._BossId)
    local level = self._Control:GetProposedLevel(stageId)
    local allNums = self._Control:GetChallengeCount()
    local leftNums = allNums - self._BossSingleData:GetBossSingleChallengeCount()
    local preFullScore = self._Control:GetPreFullScore(stageId)
    local bossCurScore = self._Control:GetBossCurScore(self._BossId)
    local difficultyDesc = self._CurBossStageConfig.DifficultyDesc

    self.TxtTimeLimit.text = text
    self.TxtBossName.text = self._CurBossStageConfig.BossName
    self.TxtFightCharCount.text = isHideBoss
                                      and XUiHelper.GetText("BossSingleFightCharCountHB",
            self._CurBossStageConfig.FightCharCount)
                                      or XUiHelper.GetText("BossSingleFightCharCount",
            self._CurBossStageConfig.FightCharCount)
    self.TxtBossDes.text = sectionCfg.Desc
    self.TxtLevel.text = XUiHelper.GetText("BossSingleDetailAllScore", level)
    self.TxtATNums.text = XMVCA.XFuben:GetRequireActionPoint(stageId)
    self.TxtChangeNums.text = isHideBoss and XUiHelper.GetText("BossSingleChallgeCountHB", leftNums, allNums)
                                  or XUiHelper.GetText("BossSingleChallgeCount", leftNums, allNums)

    if preFullScore > 0 then
        self.TxtRepeatDesc.text = XUiHelper.ReplaceTextNewLine(
            XUiHelper.GetText("BossSingleScoreDesc", difficultyDesc, preFullScore))
    else
        self.TxtRepeatDesc.text = XUiHelper.ReplaceTextNewLine(XUiHelper.GetText("BossSingleRepeartDesc"))
    end

    self.TxtAllScore.text = XUiHelper.GetText("BossSingleDetailAllScore", bossCurScore)
    self.ImagBossTileBg.gameObject:SetActiveEx(not isHideBoss)
    self.ImagBossTileBgHb.gameObject:SetActiveEx(isHideBoss)
    self.PanelEffectHb.gameObject:SetActiveEx(isHideBoss)

    for i = 1, #self._CurBossStageConfig.SkillTitle do
        local grid = self._GridBossSkillUiList[i]

        if not grid then
            local ui = XUiHelper.Instantiate(self.GridBossSkill, self.PanelSkill)

            grid = XUiFubenBossSingleDetailGridSkill.New(ui, self)
            self._GridBossSkillUiList[i] = grid
        end

        grid:Open()
        grid:Refresh(self._CurBossStageConfig.SkillTitle[i], self._CurBossStageConfig.SkillDesc[i], isHideBoss)
    end

    for i = #self._CurBossStageConfig.SkillTitle + 1, #self._GridBossSkillUiList do
        self._GridBossSkillUiList[i]:Close()
    end

    if #stageCfg.ForceConditionId <= 0 then
        self.PanelCondition.gameObject:SetActiveEx(false)
    else
        self.PanelCondition.gameObject:SetActiveEx(true)

        if stageCfg.ForceConditionId[1] then
            self.ImgCondition1.gameObject:SetActiveEx(true)
            self.ImgCondition1.gameObject:SetActiveEx(false)
            self.TxtConditon1.text = XConditionManager.GetConditionTemplate(stageCfg.ForceConditionId[1]).Desc
        else
            self.TxtConditon1.text = ""
        end

        if stageCfg.ForceConditionId[2] then
            self.ImgCondition1.gameObject:SetActiveEx(false)
            self.ImgCondition2.gameObject:SetActiveEx(true)
            self.TxtConditon2.text = XConditionManager.GetConditionTemplate(stageCfg.ForceConditionId[2]).Desc
        else
            self.TxtConditon2.text = ""
        end
    end
end

function XUiFubenBossSingleDetail:_RefreshInfo()
    local stageId = self._CurBossStageConfig.StageId
    local score = self._CurBossStageConfig.Score + self._Control:GetBaseScoreByStageId(stageId)
    local stageData = XMVCA.XFuben:GetStageData(stageId)
    local curScore = stageData and stageData.Score or 0
    local autoFightCount = self._Control:GetAutoFightCount()
    -- 设置自动按钮状态
    local maxCount = autoFightCount
    local curCount = autoFightCount - self._BossSingleData:GetBossSingleAutoFightCount()
    local autoFightData = self._Control:CheckAutoFight(self._CurBossStageConfig.StageId)

    self:_SetSelfScore(score, curScore)
    self.ImgEffect.gameObject:SetActiveEx(self._Index > XEnumConst.BossSingle.DifficultyType.Knight)

    if maxCount > 0 then
        self.BtnAuto:SetName(XUiHelper.GetText("BossSingleAutoFightCount2", curCount, maxCount))
    else
        self.BtnAuto:SetName(XUiHelper.GetText("BossSingleAutoFightCount1"))
    end
    self.BtnAuto.gameObject:SetActiveEx(self._CurBossStageConfig.AutoFight)

    if autoFightData then
        local autoScore = math.floor(self._Control:GetAutoFightRebate() * autoFightData:GetScore() / 100)

        if curScore >= autoScore then
            self.BtnAuto:SetButtonState(CS.UiButtonState.Disable)
        else
            self.BtnAuto:SetButtonState(CS.UiButtonState.Normal)
        end
    else
        self.BtnAuto:SetButtonState(CS.UiButtonState.Disable)
    end
end

function XUiFubenBossSingleDetail:_RefreshHideBoss()
    local hasHideBoss = self._Control:CheckLevelHasHideBoss()

    if not hasHideBoss then
        self:_SetHideBossActive(false, false)
        self.TxtSelectedEn.gameObject:SetActiveEx(true)
        self.TxtHideSelectedBoss.gameObject:SetActiveEx(false)

        return
    end

    local isHideOpen, desc = self._Control:CheckHideBossOpenByBossId(self._BossId)

    if not isHideOpen then
        if self._CurBossStageConfig.DifficultyType == XEnumConst.BossSingle.DifficultyType.Hell then
            self.TxtSelectedEn.gameObject:SetActiveEx(false)
            self.TxtNormalEn.gameObject:SetActiveEx(false)
            self.TxtHideSelectedBoss.gameObject:SetActiveEx(true)
            self:_SetHideBossActive(true, true)
            self.TxtHideLockBoss.gameObject:SetActiveEx(true)
            self.TxtHideLockBoss.text = desc

            local stageData = XMVCA.XFuben:GetStageData(self._CurBossStageConfig.StageId)
            local time = stageData and stageData.BestRecordTime or 0

            if time > 0 then
                self.TxtHideSelectedBoss.text = XUiHelper.GetText("BossSingleNameHidePassDesc1", time)
            else
                self.TxtHideSelectedBoss.text = XUiHelper.GetText("BossSingleNameHidePassDesc2")
            end
        else
            self:_SetHideBossActive(false, false)
        end
    else
        self.TxtSelectedEn.gameObject:SetActiveEx(true)
        self.TxtNormalEn.gameObject:SetActiveEx(true)
        self.TxtHideSelectedBoss.gameObject:SetActiveEx(false)
        self.TxtHideLockBoss.gameObject:SetActiveEx(false)
        self:_SetHideBossActive(true, false)
    end
end

function XUiFubenBossSingleDetail:_RefreshModel(modelId, isHideBoss)
    XUiModelUtility.UpdateMonsterBossModel(self.RoleModelPanelUi, modelId, XModelManager.MODEL_UINAME.XUiBossSingle)

    if isHideBoss then
        self.ImgEffectHuanrenHideBoss.gameObject:SetActiveEx(false)
        self.ImgEffectHuanrenHideBoss.gameObject:SetActiveEx(true)
    else
        self.ImgEffectHuanren.gameObject:SetActiveEx(false)
        self.ImgEffectHuanren.gameObject:SetActiveEx(true)
    end
end

function XUiFubenBossSingleDetail:_CheckClick(index, isLogTip)
    local isPassed = self._Control:CheckStagePassed(self._BossId, index)
    local sectionInfo = self._Control:GetBossSectionInfoByBossId(self._BossId)
    local isOpen, desc = self._Control:CheckBossOpen(sectionInfo[index])

    if (not isPassed or not isOpen) and isLogTip then
        local text = isOpen and XUiHelper.GetText("FubenBossPreStage") or desc

        XUiManager.TipError(text)
    end

    return isPassed and isOpen
end

function XUiFubenBossSingleDetail:_SetSelfScore(score, curScore)
    local isHideBoss = false

    if self._CurBossStageConfig then
        isHideBoss = self._CurBossStageConfig.DifficultyType == XEnumConst.BossSingle.DifficultyType.Hide
    end

    local text = isHideBoss and XUiHelper.GetText("BossSingleBossScoreHb", curScore, score)
                     or XUiHelper.GetText("BossSingleBossScore", curScore, score)

    self.TxtMyScore.text = text
    self.ImgBg.gameObject:SetActiveEx(not isHideBoss)
    self.ImgBgHb.gameObject:SetActiveEx(isHideBoss)
end

function XUiFubenBossSingleDetail:_SetHideBossActive(isActive, isNeedAnimation)
    if not isNeedAnimation then
        self.GridBossLevel6.gameObject:SetActiveEx(isActive)
        return
    end

    if not self.GridBossLevel6.gameObject.activeSelf then
        self.GridBossLevel6Alpha.alpha = isActive and 0 or 1
        self.GridBossLevel6.gameObject:SetActiveEx(isActive)
    end
end

function XUiFubenBossSingleDetail:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)
    self:BindHelpBtn(self.BtnHelp, "BossSingle")
    self:RegisterClickEvent(self.BtnStart, self.OnBtnStartClick, true)
    self:RegisterClickEvent(self.BtnAuto, self.OnBtnAutoClick, true)
    self:RegisterClickEvent(self.BtnClick, self.OnBtnClickClick, true)
    self:RegisterClickEvent(self.BtnRank, self.OnBtnRankClick, true)
end

function XUiFubenBossSingleDetail:_RemoveSchedules()
    if self._TweenTimer then
        XScheduleManager.UnSchedule(self._TweenTimer)
        self._TweenTimer = nil
    end
end

function XUiFubenBossSingleDetail:_RegisterEventListeners()
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_SYNC, self.OnSyncBossData, self)
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_RESET, self.OnActivityEnd, self)
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_AUTO_FIGHT, self.OnAutoFight, self)
end

function XUiFubenBossSingleDetail:_RemoveEventListeners()
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_SYNC, self.OnSyncBossData, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_RESET, self.OnActivityEnd, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_AUTO_FIGHT, self.OnAutoFight, self)
end

-- endregion

return XUiFubenBossSingleDetail

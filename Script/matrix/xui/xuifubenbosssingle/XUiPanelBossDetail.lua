local XUiPanelBossDetail = XClass(nil, "XUiPanelBossDetail")
local XUiGridBossSkill = require("XUi/XUiFubenBossSingle/XUiGridBossSkill")
local XUiPanelAutoFight = require("XUi/XUiFubenBossSingle/XUiPanelAutoFight")
local XUiPanelBossDetailTip = require("XUi/XUiFubenBossSingle/XUiPanelBossDetailTip")

local ONE_MINUTE_SECOND = 60

function XUiPanelBossDetail:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.SkillGridList = {}
    XTool.InitUiObject(self)
    self:AutoAddListener()
    self.ToggleTabList = {
        self.GridBossLevel1,
        self.GridBossLevel2,
        self.GridBossLevel3,
        self.GridBossLevel4,
        self.GridBossLevel5,
        self.GridBossLevel6,
    }
    self.HideBossBtnGrid = self.GridBossLevel6
    self.GridBossSkill.gameObject:SetActiveEx(false)
    self:InitAutoFight()
    self:InitDetailTip()
end

function XUiPanelBossDetail:OnShow()
    self:OnBtnClickClick()
end

function XUiPanelBossDetail:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiPanelBossDetail:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiPanelBossDetail:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiPanelBossDetail:AutoAddListener()
    self:RegisterClickEvent(self.BtnStart, self.OnBtnStartClick)
    self:RegisterClickEvent(self.BtnClick, self.OnBtnClickClick)
    self:RegisterClickEvent(self.BtnAuto, self.OnBtnAutoClick)
end

function XUiPanelBossDetail:HidePanel()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelBossDetail:InitAutoFight()
    self.PanelAutoFight = XUiPanelAutoFight.New(self.PanelAutoFight, self.RootUi, function(isTip)
        local text = CS.XTextManager.GetText("BossSingleAutoSuccess")
        local msgType = XUiManager.UiTipType.Success
        XUiManager.TipMsg(text, msgType, function()
            local time = CS.XGame.ClientConfig:GetFloat("BossSingleAnimaTime")
            XUiHelper.Tween(time, function()
                if XTool.UObjIsNil(self.Transform) or not self.GameObject.activeSelf then
                    return
                end

                local score = self.CurBossStageCfg.Score
                local stageData = XDataCenter.FubenManager.GetStageData(self.CurBossStageCfg.StageId)
                local curScore = stageData and stageData.Score or 0
                self:SetMyScore(score, curScore)
            end)

            if isTip then
                XUiManager.TipText("BossSignleBufenTip", XUiManager.UiTipType.Tip)
            end
        end)
    end)
    self.PanelAutoFight:Close()
end

function XUiPanelBossDetail:InitDetailTip()
    self.PanelBossDetailTip = XUiPanelBossDetailTip.New(self.RootUi, self.PanelTip)
    self.PanelBossDetailTip:HidePanel()
end

function XUiPanelBossDetail:ShowPanel(bossSingleData, bossId)
    self.Index = nil
    if bossId then
        self.BossId = bossId
    end

    if bossSingleData then
        self.BossSingleData = bossSingleData
    end

    self.LastBossIsHide = false
    self:SetToggle()
    self.GameObject:SetActiveEx(true)
    self.RootUi:PlayAnimation("AnimDeatilEnable")
end

function XUiPanelBossDetail:Refresh(bossSingleData)
    self.BossSingleData = bossSingleData
    -- 刷新分数
    if not self.CurBossStageCfg then
        return
    end

    -- 刷新挑战次数
    local isHideBoss = self.CurBossStageCfg.DifficultyType == XFubenBossSingleConfigs.DifficultyType.Hide
    self.TxtAllScore.text = isHideBoss and CS.XTextManager.GetText("BossSingleLevelHideBoss", XDataCenter.FubenBossSingleManager.GetBossCurScore(self.BossId))
    or CS.XTextManager.GetText("BossSingleLevel", XDataCenter.FubenBossSingleManager.GetBossCurScore(self.BossId))
    local allNums = XDataCenter.FubenBossSingleManager.GetChallengeCount()
    local leftNums = allNums - self.BossSingleData.ChallengeCount
    self.TxtChangeNums.text = isHideBoss and CS.XTextManager.GetText("BossSingleChallgeCountHB", leftNums, allNums)
    or CS.XTextManager.GetText("BossSingleChallgeCount", leftNums, allNums)

    local score = self.CurBossStageCfg.Score
    local stageData = XDataCenter.FubenManager.GetStageData(self.CurBossStageCfg.StageId)
    local curScore = stageData and stageData.Score or 0
    self:SetMyScore(score, curScore)
end

function XUiPanelBossDetail:SetMyScore(score, curScore)
    local isHideBoss = false
    if self.CurBossStageCfg then
        isHideBoss = self.CurBossStageCfg.DifficultyType == XFubenBossSingleConfigs.DifficultyType.Hide
    end

    local text = isHideBoss and CS.XTextManager.GetText("BossSingleBossScoreHb", curScore, score)
    or CS.XTextManager.GetText("BossSingleBossScore", curScore, score)
    self.TxtMyScore.text = text
    self.ImgBg.gameObject:SetActiveEx(not isHideBoss)
    self.ImgBgHb.gameObject:SetActiveEx(isHideBoss)
end

function XUiPanelBossDetail:SetToggle()
    if self.TabBtnGroup then
        self.TabBtnGroup:Dispose()
    end
    self.TabBtnGroup = nil
    self.BtnTabList = {}
    local sectionInfo = XDataCenter.FubenBossSingleManager.GetBossSectionInfo(self.BossId)
    local hasHideBoss = XDataCenter.FubenBossSingleManager.CheckLevelHasHideBoss()
    local count = hasHideBoss and #sectionInfo or #sectionInfo - 1
    if hasHideBoss then
        self:HideBossGridEnable()
    else
        self:HideBossGridDisable()
    end

    self.TxtSelectedEn.gameObject:SetActiveEx(hasHideBoss)
    self.TxtHideSelectedBoss.gameObject:SetActiveEx(hasHideBoss)

    for i = 1, count do
        local grid = self.ToggleTabList[i]
        grid.gameObject:SetActiveEx(true)
        table.insert(self.BtnTabList, grid)
    end

    -- 设置Togge按钮
    self.TabBtnGroup = XUiTabBtnGroup.New(self.BtnTabList, function(index)
        self:RefrshBossInfo(index)
    end, function(index)
        return self:CheckClick(index, true)
    end, true)

    -- 设置Toggle名字
    for k, btn in ipairs(self.TabBtnGroup.TabBtnList) do
        local bossStageCfg = XDataCenter.FubenBossSingleManager.GetBossStageCfg(sectionInfo[k].StageId)
        btn:SetName(bossStageCfg.DifficultyDesc, bossStageCfg.DifficultyDescEn)

        if k ~= XFubenBossSingleConfigs.DifficultyType.experiment then
            if self:CheckClick(k, false) then
                self.TabBtnGroup:UnLockIndex(k)
            else
                self.TabBtnGroup:LockIndex(k)
            end
        end
    end

    -- 设置默认Toggle
    if self.Index then
        self.TabBtnGroup:SelectIndex(self.Index)
    else
        local index = XDataCenter.FubenBossSingleManager.GetCurBossIndex(self.BossId)
        self.TabBtnGroup:SelectIndex(index)
    end
end

function XUiPanelBossDetail:RefrshBossInfo(index)
    self.Index = index
    local sectionInfo = XDataCenter.FubenBossSingleManager.GetBossSectionInfo(self.BossId)
    self.CurBossStageCfg = sectionInfo[index]
    local isHideBoss = self.CurBossStageCfg.DifficultyType == XFubenBossSingleConfigs.DifficultyType.Hide
    if isHideBoss then
        self.LastBossIsHide = true
        self.RootUi:PlayAnimation("BossDetailQieHuan")
    else
        if self.LastBossIsHide then
            self.BossDetailDisable.gameObject:SetActiveEx(true)
            self.RootUi:PlayAnimation("BossDetailDisable", function()
                self.BossDetailDisable.gameObject:SetActiveEx(false)
            end)
        else
            self.RootUi:PlayAnimation("AnimQieHuan")
        end
        self.LastBossIsHide = false
    end
    self:RefreshDesc()
    self:RefreshInfo()
    self:RefreshHideBoss()
    self.PanelBossDetailTip:ShowBossTip(self.CurBossStageCfg)
    self.RootUi:RefreshModel(self.CurBossStageCfg.ModelId, isHideBoss)
end

function XUiPanelBossDetail:RefreshDesc()
    local stageId = self.CurBossStageCfg.StageId
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
    local isHideBoss = self.CurBossStageCfg.DifficultyType == XFubenBossSingleConfigs.DifficultyType.Hide

    local time = math.floor(stageCfg.PassTimeLimit / ONE_MINUTE_SECOND)
    local text = isHideBoss and CS.XTextManager.GetText("BossSingleMinuteHideBoss", time) or CS.XTextManager.GetText("BossSingleMinute", time)
    local sectionCfg = XDataCenter.FubenBossSingleManager.GetBossSectionCfg(self.BossId)
    local level = XDataCenter.FubenBossSingleManager.GetProposedLevel(stageId)
    self.TxtTimeLimit.text = text
    self.TxtBossName.text = self.CurBossStageCfg.BossName
    self.TxtFightCharCount.text = isHideBoss and CS.XTextManager.GetText("BossSingleFightCharCountHB", self.CurBossStageCfg.FightCharCount)
    or CS.XTextManager.GetText("BossSingleFightCharCount", self.CurBossStageCfg.FightCharCount)
    self.TxtBossDes.text = sectionCfg.Desc
    self.TxtLevel.text = isHideBoss and CS.XTextManager.GetText("BossSingleLevelHideBoss", level) or CS.XTextManager.GetText("BossSingleLevel", level)
    self.TxtATNums.text = XDataCenter.FubenManager.GetRequireActionPoint(stageId)

    local allNums = XDataCenter.FubenBossSingleManager.GetChallengeCount()
    local leftNums = allNums - self.BossSingleData.ChallengeCount
    self.TxtChangeNums.text = isHideBoss and CS.XTextManager.GetText("BossSingleChallgeCountHB", leftNums, allNums)
    or CS.XTextManager.GetText("BossSingleChallgeCount", leftNums, allNums)

    local preFullScore = XDataCenter.FubenBossSingleManager.GetPreFullScore(stageId)
    if preFullScore > 0 then
        self.TxtRepeatDesc.text = string.gsub(CS.XTextManager.GetText("BossSingleScoreDesc", self.CurBossStageCfg.DifficultyDesc, preFullScore),
        "\\n", "\n")
    else
        self.TxtRepeatDesc.text = string.gsub(CS.XTextManager.GetText("BossSingleRepeartDesc"), "\\n", "\n")
    end

    self.TxtAllScore.text = isHideBoss and CS.XTextManager.GetText("BossSingleLevelHideBoss", XDataCenter.FubenBossSingleManager.GetBossCurScore(self.BossId))
    or CS.XTextManager.GetText("BossSingleLevel", XDataCenter.FubenBossSingleManager.GetBossCurScore(self.BossId))
    self.ImagBossTileBg.gameObject:SetActiveEx(not isHideBoss)
    self.ImagBossTileBgHb.gameObject:SetActiveEx(isHideBoss)
    self.PanelEffectHb.gameObject:SetActiveEx(isHideBoss)

    for i = 1, #self.CurBossStageCfg.SkillTitle do
        local grid = self.SkillGridList[i]
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridBossSkill)
            grid = XUiGridBossSkill.New(ui)
            grid.Transform:SetParent(self.PanelSkill, false)
            self.SkillGridList[i] = grid
        end

        grid:Refresh(self.CurBossStageCfg.SkillTitle[i], self.CurBossStageCfg.SkillDesc[i], isHideBoss)
        grid.GameObject:SetActiveEx(true)
    end

    for i = #self.CurBossStageCfg.SkillTitle + 1, #self.SkillGridList do
        self.SkillGridList[i].GameObject:SetActiveEx(false)
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

function XUiPanelBossDetail:RefreshInfo()
    local score = self.CurBossStageCfg.Score
    local stageData = XDataCenter.FubenManager.GetStageData(self.CurBossStageCfg.StageId)
    local curScore = stageData and stageData.Score or 0
    --local text = CS.XTextManager.GetText("BossSingleBossScore", curScore, score)
    self:SetMyScore(score, curScore)
    self.ImgEffect.gameObject:SetActiveEx(self.Index > XFubenBossSingleConfigs.DifficultyType.kinght)

    -- 设置自动按钮状态
    local maxCount = XFubenBossSingleConfigs.AUTO_FIGHT_COUNT
    local curCount = XFubenBossSingleConfigs.AUTO_FIGHT_COUNT - self.BossSingleData.AutoFightCount

    if maxCount > 0 then
        self.BtnAuto:SetName(CS.XTextManager.GetText("BossSingleAutoFightCount2", curCount, maxCount))
    else
        self.BtnAuto:SetName(CS.XTextManager.GetText("BossSingleAutoFightCount1"))
    end

    self.BtnAuto.gameObject:SetActiveEx(self.CurBossStageCfg.AutoFight)
    local autoFightData = XDataCenter.FubenBossSingleManager.CheckAtuoFight(self.CurBossStageCfg.StageId)


    if autoFightData then
        local autoScore = math.floor(XFubenBossSingleConfigs.AUTO_FIGHT_REBATE * autoFightData.Score / 100)
        if curScore >= autoScore then
            self.BtnAuto:SetButtonState(CS.UiButtonState.Disable)
        else
            self.BtnAuto:SetButtonState(CS.UiButtonState.Normal)
        end
    else
        self.BtnAuto:SetButtonState(CS.UiButtonState.Disable)
    end
end

-- 设置隐藏Boss相关信息
function XUiPanelBossDetail:RefreshHideBoss()
    local hasHideBoss = XDataCenter.FubenBossSingleManager.CheckLevelHasHideBoss()
    if not hasHideBoss then
        self:HideBossGridDisable()
        self.TxtSelectedEn.gameObject:SetActiveEx(true)
        self.TxtHideSelectedBoss.gameObject:SetActiveEx(false)
        return
    end

    local isHideOpen, desc = XDataCenter.FubenBossSingleManager.CheckHideBossOpenByBossId(self.BossId)
    if not isHideOpen then
        if self.CurBossStageCfg.DifficultyType == XFubenBossSingleConfigs.DifficultyType.hell then
            self.TxtSelectedEn.gameObject:SetActiveEx(false)
            self.TxtNormalEn.gameObject:SetActiveEx(false)
            self.TxtHideSelectedBoss.gameObject:SetActiveEx(true)
            self:HideBossGridEnable(true)
            self.TxtHideLockBoss.gameObject:SetActiveEx(true)

            self.TxtHideLockBoss.text = desc

            local stageData = XDataCenter.FubenManager.GetStageData(self.CurBossStageCfg.StageId)
            local time = stageData and stageData.BestRecordTime or 0
            if time > 0 then
                self.TxtHideSelectedBoss.text = CS.XTextManager.GetText("BossSingleNameHidePassDesc1", time)
            else
                self.TxtHideSelectedBoss.text = CS.XTextManager.GetText("BossSingleNameHidePassDesc2")
            end
        else
            self:HideBossGridDisable()
        end
        return
    end

    self.TxtSelectedEn.gameObject:SetActiveEx(true)
    self.TxtNormalEn.gameObject:SetActiveEx(true)
    self.TxtHideSelectedBoss.gameObject:SetActiveEx(false)
    self:HideBossGridEnable()
    self.TxtHideLockBoss.gameObject:SetActiveEx(false)
end

function XUiPanelBossDetail:HideBossGridEnable(needAnim)
    if not needAnim then
        self.HideBossBtnGrid.gameObject:SetActiveEx(true)
        return
    end

    if not self.HideBossBtnGrid.gameObject.activeSelf then
        self.GridBossLevel6Alpha.alpha = 0
        self.HideBossBtnGrid.gameObject:SetActiveEx(true)
    end

    self.RootUi:PlayAnimation("GridBossLevel6Enable")
end

function XUiPanelBossDetail:HideBossGridDisable(needAnim)
    if not needAnim then
        self.HideBossBtnGrid.gameObject:SetActiveEx(false)
        return
    end

    if not self.HideBossBtnGrid.gameObject.activeSelf then
        self.GridBossLevel6Alpha.alpha = 1
        self.HideBossBtnGrid.gameObject:SetActiveEx(true)
    end

    self.RootUi:PlayAnimation("GridBossLevel6Disable", function()
        self.HideBossBtnGrid.gameObject:SetActiveEx(false)
    end)
end

function XUiPanelBossDetail:CheckClick(index, isLogTip)
    local isPassed = XDataCenter.FubenBossSingleManager.CheckStagePassed(self.BossId, index)
    local sectionInfo = XDataCenter.FubenBossSingleManager.GetBossSectionInfo(self.BossId)
    local isOpen, desc = XDataCenter.FubenBossSingleManager.CheckBossOpen(sectionInfo[index])

    if (not isPassed or not isOpen) and isLogTip then
        local text
        if not isOpen then
            text = desc
        else
            text = CS.XTextManager.GetText("FubenBossPreStage")
        end
        XUiManager.TipError(text)
    end

    return isPassed and isOpen
end

function XUiPanelBossDetail:OnBtnStartClick()
    local stageId = self.CurBossStageCfg.StageId
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
    local teamBuffId = XFubenBossSingleConfigs.GetBossSectionTeamBuffId(self.BossId)
    local data = {TeamBuffId = teamBuffId}
    if not XDataCenter.FubenManager.CheckPreFight(stageCfg) then
        return
    end

    if XTool.USENEWBATTLEROOM then
        XLuaUiManager.Open("UiBattleRoleRoom", stageId
        , XDataCenter.TeamManager.GetXTeamByTypeId(CS.XGame.Config:GetInt("TypeIdBossSingle"))
        , require("XUi/XUiFubenBossSingle/XUiBossSingleBattleRoleRoom"))
    else
        XDataCenter.FubenManager.OpenRoomSingle(stageCfg, data)
    end
    
    XDataCenter.FubenBossSingleManager.SetEnterBossInfo(self.BossId, self.CurBossStageCfg.DifficultyType)
end

function XUiPanelBossDetail:OnBtnClickClick()
    -- TODO::播放模型动画
end

function XUiPanelBossDetail:OnBtnAutoClick()
    if not self.CurBossStageCfg.AutoFight then
        local text = CS.XTextManager.GetText("BossSingleAutoFightDesc2", self.CurBossStageCfg.DifficultyDesc)
        XUiManager.TipMsg(text)
        return
    end

    local autoFightData = XDataCenter.FubenBossSingleManager.CheckAtuoFight(self.CurBossStageCfg.StageId)
    if not autoFightData then
        XUiManager.TipText("BossSingleAutoFightDesc1")
        return
    end

    local stageData = XDataCenter.FubenManager.GetStageData(self.CurBossStageCfg.StageId)
    local curScore = stageData and stageData.Score or 0
    local autoScore = math.floor(XFubenBossSingleConfigs.AUTO_FIGHT_REBATE * autoFightData.Score / 100)
    if curScore >= autoScore then
        XUiManager.TipText("BossSingleAutoFightDesc12")
        return
    end

    local maxCount = XFubenBossSingleConfigs.AUTO_FIGHT_COUNT
    local curCount = XFubenBossSingleConfigs.AUTO_FIGHT_COUNT - self.BossSingleData.AutoFightCount

    if maxCount > 0 and curCount <= 0 then
        XUiManager.TipText("BossSingleAutoFightCount3")
        return
    end

    self.AutoFightOpen = true
    self.PanelAutoFight:Open(autoFightData, self.BossSingleData.ChallengeCount, self.CurBossStageCfg, function()
        for k, _ in ipairs(self.TabBtnGroup.TabBtnList) do
            if self:CheckClick(k, false) then
                self.TabBtnGroup:UnLockIndex(k)
            else
                self.TabBtnGroup:LockIndex(k)
            end
        end

        self:SetAutoFightClose()

        if self.Index then
            self.TabBtnGroup:SelectIndex(self.Index)
        else
            local index = XDataCenter.FubenBossSingleManager.GetCurBossIndex(self.BossId)
            self.TabBtnGroup:SelectIndex(index)
        end

    end)
    self.RootUi:PlayAnimation("PanelAutoFightEnable")
end

function XUiPanelBossDetail:CheckAutoFightOpen()
    return self.AutoFightOpen
end

function XUiPanelBossDetail:SetAutoFightClose()
    self.AutoFightOpen = false
end

return XUiPanelBossDetail
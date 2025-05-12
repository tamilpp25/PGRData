local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiPracticeBossDetail = XLuaUiManager.Register(XLuaUi, "UiPracticeBossDetail")
local CSTextManager = CS.XTextManager.GetText
local Select_Tag_Type = -- 选择tag类型
{
    Matter = 1,
    Hard = 2,
    Mechanism = 3,
}
local Operate_Type = -- 操作类型
{
    Add = 1,
    Minus = 2
}
local Monster_Type = -- 怪物类型
{
    Boss = 1,
    Elite = 2
}
local Hard_Type = { -- 难度类型
    Common = 1, 
    Advance = 2, 
    Difficult = 3, 
    Kill = 4,
}
local UiCount = 3

function XUiPracticeBossDetail:OnAwake()
    self:InitViews()
    self:InitObj()
    self:AddBtnsListeners()
end

function XUiPracticeBossDetail:OnStart(parent)
    self.Parent = parent
end

function XUiPracticeBossDetail:OnEnable()
    self:StartTimer()

    -- 重新显示技能视频
    if self.SelectTag == Select_Tag_Type.Mechanism then
        self:RefreshSkill()
    end
end

function XUiPracticeBossDetail:OnDisable()
    self:ClearTimer()
    self:StopSkillVideo()
end

function XUiPracticeBossDetail:OpenRefresh(stageId, selectTag)
    self.StageId = stageId
    self.SelectTag = selectTag or 1
    self.ArchiveId = XPracticeConfigs.GetSimulateTrainArchiveIdByStageId(stageId)
    self.MaxPeriod = XPracticeConfigs.GetSimulateTrainMonsterMaxPeriod(self.ArchiveId)
    self.BtnGroupType:SelectIndex(self.SelectTag)

    local saveSettingData = XDataCenter.PracticeManager.LoadBossStageSettingLocal(self.StageId)
    local saveAtk = 0
    local saveHp = 0
    local savePeriod = 0
    local saveHard = 0
    local maxPeriod = XPracticeConfigs.GetSimulateTrainMonsterMaxPeriod(self.ArchiveId)
    if XTool.IsTableEmpty(saveSettingData) then
        saveAtk = XPracticeConfigs.GetSimulateTrainMonsterDefaultAtkLevel(self.ArchiveId)
        saveHp = XPracticeConfigs.GetSimulateTrainMonsterDefaultHpLevel(self.ArchiveId)
        savePeriod = maxPeriod
        saveHard = 1
    else
        saveAtk = saveSettingData.atk
        saveHp = saveSettingData.hp
        savePeriod = saveSettingData.period
        if savePeriod > maxPeriod then savePeriod = maxPeriod end  -- 存在策划后续删除2阶
        saveHard = saveSettingData.hard
    end
    self:SetAtkAdjust(saveAtk)
    self:SetHpAdjust(saveHp)
    self.BtnGroupHard:SelectIndex(saveHard)
    if XTool.IsNumberValid(maxPeriod) then
        for i = 1, UiCount do
            if i <= maxPeriod then
                self["Tog" .. i].gameObject:SetActiveEx(true)
            else
                self["Tog" .. i].gameObject:SetActiveEx(false)
            end
        end
        self.BtnGroupStage:SelectIndex(savePeriod)
    end

    -- 刷新训练强度显示
    local maxStageLevel = XPracticeConfigs.GetSimulateTrainMonsterMaxStageLevel(self.ArchiveId)
    for i, btn in ipairs(self.BtnHardList) do
        btn.transform.parent.gameObject:SetActiveEx(i <= maxStageLevel)
    end
    -- 难度4是否开启
    local impasseTimeId = XPracticeConfigs.GetSimulateTrainMonsterImpasseTimeId(self.ArchiveId)
    local impasseInTime = XFunctionManager.CheckInTimeByTimeId(impasseTimeId)
    if not impasseInTime then
        self.BtnKill.transform.parent.gameObject:SetActiveEx(false)
    end

    -- 解锁图鉴
    XMVCA.XArchive:UnlockArchiveMonster(self.ArchiveId)
end

function XUiPracticeBossDetail:AddBtnsListeners()
    self:RegisterClickEvent(self.BtnEnter, self.OnBtnEnterClick)
    self:RegisterClickEvent(self.BtnSimulatedTrain, self.OnBtnSimulatedTrainClick)
    self:RegisterClickEvent(self.BtnLeft, self.OnBtnLeftClick)
    self:RegisterClickEvent(self.BtnRight, self.OnBtnRightClick)

    self.BtnHardList = {self.BtnCommon, self.BtnAdvance, self.BtnDifficult, self.BtnKill}
    self.BtnGroupHard:Init(self.BtnHardList, function(index)
        self:OnSelectHard(index)
    end)

    self.BtnStageList = {self.BtnStage1, self.BtnStage2, self.BtnStage3}
    self.BtnGroupStage:Init(self.BtnStageList, function(index)
        self:OnSelectStage(index)
    end)

    self.BtnTypeList = {self.BtnMatter, self.BtnHard, self.BtnMechanism}
    self.BtnGroupType:Init(self.BtnTypeList, function(index)
        self:Refresh(index)
    end)

    self.BtnAtkMinus.CallBack = function()
        self:AtkAdjust(Operate_Type.Minus)
    end

    self.BtnAtkAdd.CallBack = function()
        self:AtkAdjust(Operate_Type.Add)
    end

    self.BtnLifeMinus.CallBack = function()
        self:HpAdjust(Operate_Type.Minus)
    end

    self.BtnLifeAdd.CallBack = function()
        self:HpAdjust(Operate_Type.Add)
    end
end

function XUiPracticeBossDetail:InitViews()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem,
        XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.GridList = {}
    self.GridListTag = {}
end

function XUiPracticeBossDetail:OnBtnEnterClick()
    if XMain.IsEditorDebug and self.SelectStage > self.MaxPeriod then
        XLog.Error("当前选中敌人数据阶级为" .. tostring(self.SelectStage) .. " 超出最大阶级数" .. tostring(self.MaxPeriod))
    end

    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)

    if XDataCenter.FubenManager.CheckPreFight(stageCfg) then
        local monsterId = XPracticeConfigs.GetSimulateTrainMonsterId(self.StageId)
        local dangerPower = self:GetDangerPower()
        local data = {
            SimulateTrainInfo = {
                BossId = monsterId,                 -- 活动对应monsterId
                Period = self.SelectStage,          -- BOSS阶段
                AtkLevel = self.AtkNum,             -- 攻击属性等级
                HpLevel = self.HpNum,               -- 生命属性等级
                Difficulty = self.SelectHard,       -- BOSS难度
                DangerCoefficient = dangerPower,    -- 危险系数
            }
        }
        XDataCenter.PracticeManager.SaveKeyBossStageSetting(self.StageId, self.SelectHard, self.SelectStage,
            self.AtkNum, self.HpNum)

        local team = XDataCenter.PracticeManager.LoadBossTeamLocal()
        for index, id in pairs(team.TeamData) do
            --清库之后本地缓存角色失效
            if not XMVCA.XCharacter:IsOwnCharacter(id) and not XRobotManager.CheckIsRobotId(id) then
                team.TeamData[index] = 0
            end
        end
        local xTeam = XDataCenter.TeamManager.CreateTeam(team.TeamId)
        xTeam:UpdateAutoSave(true)
        xTeam:UpdateLocalSave(false)
        xTeam:Clear()
        xTeam:UpdateFromTeamData(team)
        xTeam:UpdateSaveCallback(function(inTeam)
            XDataCenter.PracticeManager.SaveBossTeamLocal(inTeam:SwithToOldTeamData())
        end)
        XLuaUiManager.Open("UiBattleRoleRoom", self.StageId, xTeam, {
            -- 处理自己进入战斗的逻辑
            EnterFight = function(proxy, team, stageId, challengeCount, isAssist)
                local teamData = team:SwithToOldTeamData()
                if teamData.TeamData[teamData.CaptainPos] == nil or teamData.TeamData[teamData.CaptainPos] <= 0 then
                    XUiManager.TipText("TeamManagerCheckCaptainNil")
                    return
                end
                if teamData.TeamData[teamData.FirstFightPos] == nil or teamData.TeamData[teamData.FirstFightPos] <= 0 then
                    XUiManager.TipText("TeamManagerCheckFirstFightNil")
                    return
                end
                local stage = XDataCenter.FubenManager.GetStageCfg(stageId)
                XDataCenter.FubenManager.EnterPracticeBoss(stage, teamData, data.SimulateTrainInfo)
            end,
            GetRoleDetailProxy = function()
                return require("XUi/XUiFubenPractice/XUiPracticeRoleDetailProxy")
            end,
        })
        self:Close()
    end
end

function XUiPracticeBossDetail:OnBtnSimulatedTrainClick()
    local isInActivity, tips = XMVCA.XSimulateTrain:IsActivityOpen()
    if not isInActivity then
        XUiManager.TipError(tips)
        return
    end

    local monsterId = XPracticeConfigs.GetSimulateTrainMonsterId(self.StageId)
    self:Close()
    XMVCA.XSimulateTrain:OpenBossDetailUi(monsterId)
end

function XUiPracticeBossDetail:OnBtnLeftClick()
    if self.SkillIndex > 1 then
        self.SkillIndex = self.SkillIndex - 1
    else
        self.SkillIndex = #self.SkillIds
    end
    self:RefreshSkill()
end

function XUiPracticeBossDetail:OnBtnRightClick()
    local skillCnt = #self.SkillIds
    if self.SkillIndex < skillCnt then
        self.SkillIndex = self.SkillIndex + 1
    else
        self.SkillIndex = 1
    end
    self:RefreshSkill()
end

function XUiPracticeBossDetail:InitObj()
    local maxAtkLevel = XPracticeConfigs.GetSimulateTrainAtkLength()
    if not self.AtkBlue then
        self.AtkBlue = {}
    end
    for i = 1, maxAtkLevel do
        self.AtkBlue[i] = self["TogAtkBlock" .. i]:FindTransform("Blue").gameObject
    end

    if not self.HpBlue then
        self.HpBlue = {}
    end
    local maxHpLevel = XPracticeConfigs.GetSimulateTrainHpLength()
    for i = 1, maxHpLevel do
        self.HpBlue[i] = self["TogLifeBlock" .. i]:FindTransform("Blue").gameObject
    end
end

function XUiPracticeBossDetail:OnSelectHard(index)
    local lastSelectHard = self.SelectHard
    self.SelectHard = index
    
    -- 背景
    if index == Hard_Type.Kill then
        -- 敌人数据
        self.LastSelectStage = self.SelectStage
        self.BtnGroupStage:SelectIndex(self.MaxPeriod)
        -- 攻击
        self.LastAtkNum = self.AtkNum
        local maxAtk = XPracticeConfigs.GetSimulateTrainAtkLength()
        self:SetAtkAdjust(maxAtk)
        
        self.RImgKillBg.gameObject:SetActiveEx(true)
        self.BtnAtkMinus:SetDisable(true)
        self.BtnAtkAdd:SetDisable(true)
        for i, btn in ipairs(self.BtnStageList) do
            btn:SetDisable(i == self.MaxPeriod)
        end
    elseif lastSelectHard == Hard_Type.Kill then
        self:SetAtkAdjust(self.LastAtkNum)
        self.RImgKillBg.gameObject:SetActiveEx(false)
        self.BtnAtkMinus:SetDisable(false)
        self.BtnAtkAdd:SetDisable(false)
        for _, btn in ipairs(self.BtnStageList) do
            btn:SetDisable(false)
        end
        self.BtnGroupStage:SelectIndex(self.LastSelectStage or 1)
    end

    self:RefreshRecommendedPower()
end

function XUiPracticeBossDetail:OnSelectStage(index)
    if self.SelectStage == index then return end
    -- 秒杀模式固定最高阶不可切换
    if self.SelectHard == Hard_Type.Kill and index ~= self.MaxPeriod then
        self["BtnStage"..index]:SetButtonState(CS.UiButtonState.Normal)
        return 
    end
    
    self.SelectStage = index
    self:RefreshRecommendedPower()
end

function XUiPracticeBossDetail:SetAtkAdjust(num)
    self.AtkNum = num
    self:RefreshAtk()
end

function XUiPracticeBossDetail:SetHpAdjust(num)
    self.HpNum = num
    self:RefreshHp()
end

function XUiPracticeBossDetail:AtkAdjust(operateType)
    -- 秒杀模式固定最高攻击不可切换
    if  self.SelectHard == Hard_Type.Kill then return end
    
    if operateType == Operate_Type.Add then
        self.AtkNum = (self.AtkNum or 0) + 1
    elseif operateType == Operate_Type.Minus then
        self.AtkNum = (self.AtkNum or 0) - 1
    end
    self.AtkNum = XMath.Clamp(self.AtkNum, 1, XPracticeConfigs.GetSimulateTrainAtkLength())
    self:RefreshAtk()
    self:RefreshRecommendedPower()
end

function XUiPracticeBossDetail:HpAdjust(operateType)
    if operateType == Operate_Type.Add then
        self.HpNum = (self.HpNum or 0) + 1
    elseif operateType == Operate_Type.Minus then
        self.HpNum = (self.HpNum or 0) - 1
    end
    self.HpNum = XMath.Clamp(self.HpNum, 1, XPracticeConfigs.GetSimulateTrainHpLength())
    self:RefreshHp()
    self:RefreshRecommendedPower()
end

function XUiPracticeBossDetail:Refresh(selectTag)
    self.SelectTag = selectTag
    self.PanelDetails.gameObject:SetActiveEx(false)
    self.PanelAdjustHard.gameObject:SetActiveEx(false)
    self.PanelMechanism.gameObject:SetActiveEx(false)
    local isShowMechanism = self:IsShowPanelMechanism()
    self.BtnMechanism.gameObject:SetActiveEx(isShowMechanism)
    if self.SelectTag == Select_Tag_Type.Matter then
        self.PanelDetails.gameObject:SetActiveEx(true)
        self:UpdateCommon()
        self:UpdateReward()
    elseif self.SelectTag == Select_Tag_Type.Hard then
        self.PanelAdjustHard.gameObject:SetActiveEx(true)
        self:RefreshHardName()
        self:RefreshAdjustHardPanel()
    elseif self.SelectTag == Select_Tag_Type.Mechanism then
        self.PanelMechanism.gameObject:SetActiveEx(true)
        self:InitPanelMechanism()
    end
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    self.TxtTitle.text = stageCfg.Name
    
    self:RefreshSimulatedTrainBtn()
end

-- 刷新活动按钮
function XUiPracticeBossDetail:RefreshSimulatedTrainBtn()
    local monsterId = XPracticeConfigs.GetSimulateTrainMonsterId(self.StageId)
    local isInActivity = XMVCA.XSimulateTrain:IsMonsterInActivity(monsterId)
    self.BtnSimulatedTrain.gameObject:SetActiveEx(isInActivity)
    if isInActivity then
        local bossId = XMVCA.XSimulateTrain:GetBossIdByMonsterId(monsterId)
        local isRed = XMVCA.XSimulateTrain:IsShowBossRedPoint(bossId)
        self.BtnSimulatedTrain:ShowReddot(isRed)
    end
end

function XUiPracticeBossDetail:RefreshHardName()
    local stageName = XPracticeConfigs.GetSimulateTrainMonsterStageName(self.ArchiveId)
    for i = 1, UiCount do
        self["TxtCommon" .. i].text = stageName[i]
    end
end

function XUiPracticeBossDetail:UpdateCommon()
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    local nanDuIcon = XDataCenter.FubenManager.GetDifficultIcon(self.StageId)
    self.RImgNandu:SetRawImage(nanDuIcon)
    for i = 1, UiCount do
        self[string.format("TxtActive%d", i)].text = stageCfg.StarDesc[i]
    end
end

function XUiPracticeBossDetail:CloseWithAnimation(isNotPlayAnima)
    if isNotPlayAnima then
        self:Close()
        return
    end
    
    self:PlayAnimationWithMask("AnimDisableEnd", function()
        self:Close()
    end)
end

function XUiPracticeBossDetail:UpdateReward()
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.StageId)
    local stageLevelControl = XDataCenter.FubenManager.GetStageLevelControl(self.StageId)

    local rewardId = stageLevelControl and stageLevelControl.FirstRewardShow or stageCfg.FirstRewardShow

    if rewardId == 0 then
        for i = 1, #self.GridList do
            self.GridList[i].GameObject:SetActive(false)
        end
        return
    end

    local rewards = XRewardManager.GetRewardList(rewardId)
    if rewards then
        for i, item in ipairs(rewards) do
            local grid
            if self.GridList[i] then
                grid = self.GridList[i]
            else
                local ui = CS.UnityEngine.Object.Instantiate(self.GridCommon)
                grid = XUiGridCommon.New(self, ui)
                grid.Transform:SetParent(self.PanelDropContent, false)
                self.GridList[i] = grid
                self.GridListTag[i] = grid.Transform:Find("Received")
            end
            grid:Refresh(item)
            grid.GameObject:SetActive(true)
            if self.GridListTag[i] then
                self.GridListTag[i].gameObject:SetActive(stageInfo.Passed)
            end
        end
    end
    self.PanelDropList.gameObject:SetActiveEx(not stageInfo.Passed)

    for i = #rewards + 1, #self.GridList do
        self.GridList[i].GameObject:SetActive(false)
    end
end

function XUiPracticeBossDetail:RefreshAdjustHardPanel()
    self:RefreshShowPeriod()
    self:RefreshAtk()
    self:RefreshHp()
    self:RefreshRecommendedPower()
end

function XUiPracticeBossDetail:RefreshShowPeriod()
    local type = XPracticeConfigs.GetSimulateTrainMonsterType(self.ArchiveId)
    if type == Monster_Type.Boss then
        self.PanelStage.gameObject:SetActiveEx(true)
    elseif type == Monster_Type.Elite then
        self.PanelStage.gameObject:SetActiveEx(false)
    else
        self.PanelStage.gameObject:SetActiveEx(false)
    end
end

function XUiPracticeBossDetail:RefreshAtk()
    local maxAtkLevel = XPracticeConfigs.GetSimulateTrainAtkLength()
    for i = 1, maxAtkLevel do
        if i <= self.AtkNum then
            self.AtkBlue[i]:SetActiveEx(true)
        else
            self.AtkBlue[i]:SetActiveEx(false)
        end
    end
end

function XUiPracticeBossDetail:RefreshHp()
    local maxHpLevel = XPracticeConfigs.GetSimulateTrainHpLength()
    for i = 1, maxHpLevel do
        if i <= self.HpNum then
            self.HpBlue[i]:SetActiveEx(true)
        else
            self.HpBlue[i]:SetActiveEx(false)
        end
    end
end

function XUiPracticeBossDetail:GetDangerPower()
    local basic = XPracticeConfigs.GetSimulateTrainMonsterStageBasicCe(self.ArchiveId)
    local atkAddPercent = XPracticeConfigs.GetSimulateTrainAtkAtkAddPercent(self.AtkNum or 1)
    local atkCe = XPracticeConfigs.GetSimulateTrainAtkAtkAttributeCe(self.AtkNum or 1)
    local hpAddPercent = XPracticeConfigs.GetSimulateTrainHpHpAddPercent(self.HpNum or 1)
    local hpCe = XPracticeConfigs.GetSimulateTrainHpHpAttributeCe(self.HpNum or 1)
    local stageRatioCe = XPracticeConfigs.GetSimulateTrainMonsterStageRatioCe(self.ArchiveId)
    local dangerPower = math.floor((basic[self.SelectHard] * 10000 + atkCe * atkAddPercent + hpCe * hpAddPercent) * stageRatioCe[self.SelectHard] / 10000)
    return dangerPower
end

function XUiPracticeBossDetail:RefreshRecommendedPower()
    local dangerPower = self:GetDangerPower()
    self.TxtATNums.text = CSTextManager("PracticeBossDangerous", dangerPower)
end

-- 是否显示机制介绍
function XUiPracticeBossDetail:IsShowPanelMechanism()
    local monsterId = XPracticeConfigs.GetSimulateTrainMonsterId(self.StageId)
    self.SkillIds = XPracticeConfigs.GetSimulateTrainMonsterSkillIds(monsterId)
    return #self.SkillIds > 0
end

-- 初始化机制介绍面板
function XUiPracticeBossDetail:InitPanelMechanism()
    -- 点列表
    local isMult = #self.SkillIds > 1
    self.PanelDot.gameObject:SetActiveEx(isMult)
    self.BtnLeft.gameObject:SetActiveEx(isMult)
    self.BtnRight.gameObject:SetActiveEx(isMult)
    if isMult then
        self.GridDots = self.GridDots or {}
        for _, dot in ipairs(self.GridDots) do
            dot.gameObject:SetActiveEx(false)
        end
        local CSInstantiate = CS.UnityEngine.Object.Instantiate
        self.GridDot.gameObject:SetActiveEx(false)
        for i, _ in ipairs(self.SkillIds) do
            local dot = self.GridDots[i]
            if not dot then
                local go = CSInstantiate(self.GridDot.gameObject, self.PanelDot.transform)
                dot = go:GetComponent("UiObject")
                self.GridDots[i] = dot
            end
            dot.gameObject:SetActiveEx(true)
        end
    end
    
    -- 刷新当前选中技能
    self.SkillIndex = 1
    self:RefreshSkill()
end

-- 刷新当前选中技能
function XUiPracticeBossDetail:RefreshSkill()
    local skillId =  self.SkillIds[self.SkillIndex]
    local skillCfg = XMVCA.XSimulateTrain:GetConfigSkill(skillId)
    
    -- 描述
    self.TxtMechanismName.text = skillCfg.Name
    self.TxtMechanismlDetail.text = skillCfg.Desc

    -- 视频
    self:StopSkillVideo()
    self.VideoComponent = XUiHelper.Instantiate(self.VideoPlayer, self.VideoPlayer.transform.parent)
    self.VideoComponent.gameObject:SetActiveEx(true)
    self.VideoComponent:SetVideoFromRelateUrl(skillCfg.VideoUrl)
    self.VideoComponent:Play()

    -- 点列表
    if #self.SkillIds > 1 then
        for i, _ in ipairs(self.SkillIds) do
            local dot = self.GridDots[i]
            local isSelect = i == self.SkillIndex
            dot:GetObject("ImgOn").gameObject:SetActiveEx(isSelect)
            dot:GetObject("ImgOff").gameObject:SetActiveEx(not isSelect)
        end
    end
end

function XUiPracticeBossDetail:StopSkillVideo()
    if self.VideoComponent then
        self.VideoComponent:Stop()
        self.VideoComponent.gameObject:SetActiveEx(false)
        CS.UnityEngine.Object.Destroy(self.VideoComponent.gameObject)
        self.VideoComponent = nil
    end
end

function XUiPracticeBossDetail:StartTimer()
    self:ClearTimer()
    self.Timer = XScheduleManager.ScheduleForever(function()
        self:OnTimerRefresh()
    end, XScheduleManager.SECOND)
end

function XUiPracticeBossDetail:OnTimerRefresh()
    self:RefreshSimulatedTrainBtn()
end

function XUiPracticeBossDetail:ClearTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

return XUiPracticeBossDetail

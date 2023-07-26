local XUiPracticeBossDetail = XLuaUiManager.Register(XLuaUi, "UiPracticeBossDetail")
local CSTextManager = CS.XTextManager.GetText
local Select_Tag_Type = -- 选择tag类型
{
    Matter = 1,
    Hard = 2
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
local UiCount = 3

function XUiPracticeBossDetail:OnAwake()
    self:InitViews()
    self:InitObj()
    self:AddBtnsListeners()
end

function XUiPracticeBossDetail:OnStart(parent)
    self.Parent = parent
end

function XUiPracticeBossDetail:OpenRefresh(stageId, selectTag)
    self.StageId = stageId
    self.ArchiveId = XPracticeConfigs.GetSimulateTrainArchiveIdByStageId(stageId)
    selectTag = selectTag or 1
    self.BtnGroupType:SelectIndex(selectTag)
end

function XUiPracticeBossDetail:AddBtnsListeners()
    self:RegisterClickEvent(self.BtnEnter, self.OnBtnEnterClick)

    self.BtnHardList = {self.BtnCommon, self.BtnAdvance, self.BtnDifficult}
    self.BtnGroupHard:Init(self.BtnHardList, function(index)
        self:OnSelectHard(index)
    end)

    self.BtnStageList = {self.BtnStage1, self.BtnStage2, self.BtnStage3}
    self.BtnGroupStage:Init(self.BtnStageList, function(index)
        self:OnSelectStage(index)
    end)

    self.BtnTypeList = {self.BtnMatter, self.BtnHard}
    self.BtnGroupType:Init(self.BtnTypeList, function(index)
        self:Refresh(nil, index)
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
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)

    if XDataCenter.FubenManager.CheckPreFight(stageCfg) then
        local data = {
            SimulateTrainInfo = {
                Period = self.SelectStage,  --BOSS阶段
                AtkLevel = self.AtkNum,     --攻击属性等级
                HpLevel = self.HpNum,       --生命属性等级
                Difficulty = self.SelectHard    --BOSS难度
            }
        }
        XDataCenter.PracticeManager.SaveKeyBossStageSetting(self.StageId, self.SelectHard, self.SelectStage,
            self.AtkNum, self.HpNum)
        if XTool.USENEWBATTLEROOM then
            local team = XDataCenter.PracticeManager.LoadBossTeamLocal()
            for index, id in pairs(team.TeamData) do
                --清库之后本地缓存角色失效
                if not XDataCenter.CharacterManager.IsOwnCharacter(id) and not XRobotManager.CheckIsRobotId(id) then
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
                end
            })
        else
            XLuaUiManager.Open("UiNewRoomSingle", self.StageId, data)
        end
        self:Close()
    end
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
    self.SelectHard = index
    self:RefreshRecommendedPower()
end

function XUiPracticeBossDetail:OnSelectStage(index)
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

function XUiPracticeBossDetail:Refresh(stageId, selectTag)
    self.StageId = stageId or self.StageId
    self.SelectTag = selectTag or self.SelectTag
    self.ArchiveId = XPracticeConfigs.GetSimulateTrainArchiveIdByStageId(self.StageId)
    local saveSettingData = XDataCenter.PracticeManager.LoadBossStageSettingLocal(self.StageId)
    local saveAtk = 0
    local saveHp = 0
    local savePeriod = 0
    local saveHard = 0
    if XTool.IsTableEmpty(saveSettingData) then
        saveAtk = XPracticeConfigs.GetSimulateTrainMonsterDefaultAtkLevel(self.ArchiveId)
        saveHp = XPracticeConfigs.GetSimulateTrainMonsterDefaultHpLevel(self.ArchiveId)
        savePeriod = XPracticeConfigs.GetSimulateTrainMonsterMaxPeriod(self.ArchiveId)
        saveHard = 1
    else
        saveAtk = saveSettingData.atk
        saveHp = saveSettingData.hp
        savePeriod = saveSettingData.period
        saveHard = saveSettingData.hard
    end
    self:SetAtkAdjust(saveAtk)
    self:SetHpAdjust(saveHp)
    self.BtnGroupHard:SelectIndex(saveHard)
    local maxPeriod = XPracticeConfigs.GetSimulateTrainMonsterMaxPeriod(self.ArchiveId)
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
    if self.SelectTag == Select_Tag_Type.Matter then
        self.PanelDetails.gameObject:SetActiveEx(true)
        self.PanelAdjustHard.gameObject:SetActiveEx(false)
        self:UpdateCommon()
        self:UpdateReward()
    elseif self.SelectTag == Select_Tag_Type.Hard then
        self.PanelDetails.gameObject:SetActiveEx(false)
        self.PanelAdjustHard.gameObject:SetActiveEx(true)
        self:RefreshHardName()
        self:RefreshAdjustHardPanel()
    end
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.StageId)
    self.TxtTitle.text = stageCfg.Name
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
    
    self:PlayAnimation("AnimDisableEnd", function()
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

function XUiPracticeBossDetail:RefreshRecommendedPower()
    local basic = XPracticeConfigs.GetSimulateTrainMonsterStageBasicCe(self.ArchiveId)
    local atkAddPercent = XPracticeConfigs.GetSimulateTrainAtkAtkAddPercent(self.AtkNum or 1)
    local atkCe = XPracticeConfigs.GetSimulateTrainAtkAtkAttributeCe(self.AtkNum or 1)
    local hpAddPercent = XPracticeConfigs.GetSimulateTrainHpHpAddPercent(self.HpNum or 1)
    local hpCe = XPracticeConfigs.GetSimulateTrainHpHpAttributeCe(self.HpNum or 1)
    local stageRatioCe = XPracticeConfigs.GetSimulateTrainMonsterStageRatioCe(self.ArchiveId)
    local dangerIndex = math.floor((basic[self.SelectHard] + atkCe / atkAddPercent + hpCe * hpAddPercent) *
                                       stageRatioCe[self.SelectHard])
    self.TxtATNums.text = CSTextManager("PracticeBossDangerous", dangerIndex)
end

local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiBossInshotMain:XLuaUi
---@field private _Control XBossInshotControl
local XUiBossInshotMain = XLuaUiManager.Register(XLuaUi, "UiBossInshotMain")

function XUiBossInshotMain:OnAwake()
    self.Grid256New.gameObject:SetActiveEx(false)
    self.PanelBossDetail.gameObject:SetActiveEx(false)
    
    self.ActivityId = self._Control:GetActivityId()
    if self.ActivityId == 0 then return end

    self.BossIds = self._Control:GetActivityBossIds(self.ActivityId)
    self.BossIndex = 1 -- 选中Boss下标
    self.PANEL_STATE_TYPE = { MAIN = 1, DETAIL = 2 }
    self.EFFECT_NAME = {
        EFFECT_SWITCH = "EffectSwitch",
        EFFECT_Appear = "EffectAppear",
    }
    self.PanelState = self.PANEL_STATE_TYPE.MAIN

    self:RegisterUiEvents()
    self:InitBossBtns()
    self:InitCameraDic()
    self:InitBossEffect()
    self:InitActivityTimer()
end

function XUiBossInshotMain:OnStart()
    self.IsPlayStartAnim = true
end

function XUiBossInshotMain:OnEnable()
    self:RefreshSceneSetting()
    if self.ActivityId == 0 then
        self:Close()
        return 
    end

    if self.PanelState == self.PANEL_STATE_TYPE.MAIN then
        if self.IsPlayStartAnim then
            self.IsPlayStartAnim = false
            -- UI动画
            self:PlayAnimation("Enable")
            -- 场景动画
            local sceneAnim = self.UiModelGo.transform:Find("Animation/Enable")
            sceneAnim:PlayTimelineAnimation()
        end
    elseif self.PanelState == self.PANEL_STATE_TYPE.DETAIL then
        self:PlayAnimation("PanelBossDetailEnable")
    end
    
    self:Refresh()
    
    -- 加载boss模型
    self:LoadBossModel()

    -- 加载特效
    self:HideAllBossEffect()

    -- 检测新天赋解锁
    self:CheckNewTalentUnlock()
end

function XUiBossInshotMain:OnRelease()
    self:ClearActivityTimer()
    self:ClearBossEffectTimer()
    self:ClearSceneSettingTimer()
    
    self.BossIds = nil
    self.StageIds = nil
    self.PANEL_STATE_TYPE = nil
    self.EFFECT_NAME = nil
    self.Items = nil
    self.CameraDic = nil
end

function XUiBossInshotMain:OnReleaseInst()
    return {self.PanelState, self.BossIndex, self.DifficultyIndex, self.SkillIndex}
end

function XUiBossInshotMain:OnResume(value)
    self.PanelState = value[1]
    self.BossIndex = value[2]
    self.DifficultyIndex = value[3]
    self.SkillIndex = value[4]
end

function XUiBossInshotMain:CacheDifficultyIndexAndSkillIndex(difficultyIndex, skillIndex)
    self.DifficultyIndex = difficultyIndex
    self.SkillIndex = skillIndex
end

function XUiBossInshotMain:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnRank, self.OnBtnRankClick)
    self:RegisterClickEvent(self.BtnTask, self.OnBtnTaskClick)
    self:RegisterClickEvent(self.BtnSelect, self.OnBtnSelectClick)
    self:BindHelpBtn(self.BtnHelp, "BossInshotHelp")

    local btns = { self.BtnBoss1, self.BtnBoss2, self.BtnBoss3 }
    self.PanelBoss:Init(btns, function(index)
        self:OnBtnBossClick(index)
    end)
end

function XUiBossInshotMain:OnBtnBackClick()
    if self.PanelState == self.PANEL_STATE_TYPE.DETAIL then
        self:SwitchPanel(self.PANEL_STATE_TYPE.MAIN)
        return
    end

    self:Close()
end

function XUiBossInshotMain:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiBossInshotMain:OnBtnRankClick()
    XLuaUiManager.Open("UiBossInshotRank")
end

function XUiBossInshotMain:OnBtnTaskClick()
    XLuaUiManager.Open("UiBossInshotTask")
end

function XUiBossInshotMain:OnBtnSelectClick()
    -- 播放动画过程中不能切换界面
    if self.BossEffectTimer then return end
    
    local isInTime = XFunctionManager.CheckInTimeByTimeId(self.BossOpenTimeId, true)
    if isInTime then
        self:SwitchPanel(self.PANEL_STATE_TYPE.DETAIL)
    end
end

function XUiBossInshotMain:OnBtnBossClick(index)
    if self.BossIndex == index or self.BossEffectTimer then
        self:RefreshBtnSelectState()
        return
    end
    
    self.BossIndex = index
    self:RefreshBtnSelectState()
    self:RefreshBossInfo()
    self:ShowBossEffect(self.EFFECT_NAME.EFFECT_SWITCH, true)
    self:ClearBossEffectTimer()
    self.BossEffectTimer = XScheduleManager.ScheduleOnce(function()
        self.BossEffectTimer = nil
        self:LoadBossModel()
        self:ShowBossEffect(self.EFFECT_NAME.EFFECT_Appear, true)

        self.RoleModel.GameObject:SetActiveEx(false)
        XScheduleManager.ScheduleOnce(function()
            self.RoleModel.GameObject:SetActiveEx(true)
            local effectGo = self.EffectDic[self.EFFECT_NAME.EFFECT_Appear]
            effectGo.gameObject:SetActive(false)
            effectGo.gameObject:SetActive(true)
        end, 10)
    end, 350)
    
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.BossInshotSwitchBoss)
end

-- 刷新按钮选中状态
function XUiBossInshotMain:RefreshBtnSelectState()
    local CSNormal = CS.UiButtonState.Normal
    local CSSelect = CS.UiButtonState.Select
    for i, _ in ipairs(self.BossIds) do
        local state = i == self.BossIndex and CSSelect or CSNormal
        local btn = self["BtnBoss" .. i]
        btn:SetButtonState(state)
    end
end

-- 初始化Boss按钮
function XUiBossInshotMain:InitBossBtns()
    for i, bossId in ipairs(self.BossIds) do
        local icon = self._Control:GetBossHeadIcon(bossId)
        local btn = self["BtnBoss" .. i]
        btn:SetRawImage(icon)
    end
end

-- 初始化摄像机引用
function XUiBossInshotMain:InitCameraDic()
    self.CameraDic = {}
    local root = self.UiModelGo.transform
    for i, _ in ipairs(self.BossIds) do
        local farName = string.format("UiModeCamFarMain%02d", i)
        local farCamera = root:FindTransform(farName)
        self.CameraDic[farName] = farCamera or 0

        local nearName = string.format("UiModeCamNearMain%02d", i)
        local nearCamera = root:FindTransform(nearName)
        self.CameraDic[nearName] = nearCamera or 0

        local farDetailName = string.format("UiModeCamFarDetail%02d", i)
        local farDetailCamera = root:FindTransform(farDetailName)
        self.CameraDic[farDetailName] = farDetailCamera or 0

        local nearDetailName = string.format("UiModeCamNearDetail%02d", i)
        local nearDetailCamera = root:FindTransform(nearDetailName)
        self.CameraDic[nearDetailName] = nearDetailCamera or 0
    end
end

-- 初始化Boss特效
function XUiBossInshotMain:InitBossEffect()
    self.EffectDic = {}
    for _, effectName in pairs(self.EFFECT_NAME) do
        self.EffectDic[effectName] = self.UiModelGo.transform:FindTransform(effectName)
    end
end

-- 初始化活动定时器
function XUiBossInshotMain:InitActivityTimer()
    self.EndTime = self._Control:GetActivityEndTime(self.ActivityId)
    self:ClearActivityTimer()
    self.ActivityTimer = XScheduleManager.ScheduleForever(function()
        local gameTime = self.EndTime - XTime.GetServerNowTimestamp()
        if gameTime <= 0 then
            self:ClearActivityTimer()
            self._Control:HandleActivityEnd()
        else
            self:RefreshTime()
            self:RefreshBossOpenTime()
        end
    end, 1000)
end

function XUiBossInshotMain:ClearActivityTimer()
    if self.ActivityTimer then
        XScheduleManager.UnSchedule(self.ActivityTimer)
        self.ActivityTimer = nil
    end
end

function XUiBossInshotMain:Refresh()
    self:RefreshBtnSelectState()
    
    -- 主界面
    self.PanelMain.gameObject:SetActiveEx(self.PanelState == self.PANEL_STATE_TYPE.MAIN)
    if self.PanelState == self.PANEL_STATE_TYPE.MAIN then
        self:RefreshPanelMain()
    end

    -- Boss详情
    if self.PanelState == self.PANEL_STATE_TYPE.DETAIL then
        if not self.UiBossDetail then
            local XUiBossInshotBossDetail = require("XUi/XUiBossInshot/XUiBossInshotBossDetail")
            self.UiBossDetail = XUiBossInshotBossDetail.New(self.PanelBossDetail, self)
        end
        self.UiBossDetail:Open()
        local bossId = self.BossIds[self.BossIndex]
        self.UiBossDetail:Refresh(bossId, self.DifficultyIndex, self.SkillIndex)
        self.DifficultyIndex = nil
        self.SkillIndex = nil
    else
        if self.UiBossDetail then
            self.UiBossDetail:Close()
        end
    end
end

-- 刷新主界面
function XUiBossInshotMain:RefreshPanelMain()
    self:RefreshTime()
    self:RefreshBossInfo()
    self:RefreshBtnTask()
end

function XUiBossInshotMain:RefreshTime()
    local gameTime = self.EndTime - XTime.GetServerNowTimestamp()
    self.TxtTimeNum.text = XUiHelper.GetTime(gameTime, XUiHelper.TimeFormatType.ACTIVITY)
end

function XUiBossInshotMain:RefreshBossInfo()
    local bossId = self.BossIds[self.BossIndex]
    self.StageIds = self._Control:GetBossStageIds(bossId)
    local btn = self["BtnBoss" .. tostring(self.BossIndex)]

    -- 摄像机镜头
    self:SwitchCamera("UiModeCamFarMain", "UiModeCamNearMain")

    -- 进度
    local isClear = true
    local passCnt = 0
    local allCnt = #self.StageIds
    for i, inshotStageId in ipairs(self.StageIds) do
        local stageId = self._Control:GetStageStageId(inshotStageId)
        local stageData = self._Control:GetPassStageData(stageId)
        if stageData then
            passCnt = passCnt + 1
        else
            isClear = false
        end
    end
    local bossName = self._Control:GetBossName(bossId)
    local progress = XUiHelper.GetText("BossInshotBossProgress", passCnt, allCnt)
    btn:SetNameByGroup(0, bossName)
    btn:SetNameByGroup(2, progress)
    btn:ShowTag(isClear)

    -- 开放时间
    self.BossOpenTimeId = self._Control:GetBossOpenTimeId(bossId)
    self:RefreshBossOpenTime()
end

function XUiBossInshotMain:RefreshBossOpenTime()
    local isInTime = XFunctionManager.CheckInTimeByTimeId(self.BossOpenTimeId, true)
    local timeTips = ""
    if not isInTime then
        local gameTime = XFunctionManager.GetStartTimeByTimeId(self.BossOpenTimeId) - XTime.GetServerNowTimestamp()
        timeTips = XUiHelper.GetText("BossInshotBossUnlockTips", XUiHelper.GetTime(gameTime, XUiHelper.TimeFormatType.ACTIVITY))
    end
    local btn = self["BtnBoss" .. tostring(self.BossIndex)]
    btn:SetNameByGroup(1, timeTips)
    self.BtnSelect:SetDisable(not isInTime)
end

-- 切换界面
function XUiBossInshotMain:SwitchPanel(state)
    if state == self.PANEL_STATE_TYPE.MAIN then
        self:PlayAnimation("PanelMainEnable")
    elseif state == self.PANEL_STATE_TYPE.DETAIL then
        self:PlayAnimation("PanelBossDetailEnable")
    end
    
    self.PanelState = state
    self:Refresh()
end

-- 切换摄像机
function XUiBossInshotMain:SwitchCamera(farName, nearName)
    farName = string.format(farName .. "%02d", self.BossIndex)
    nearName = string.format(nearName .. "%02d", self.BossIndex)

    for _, camera in pairs(self.CameraDic) do
        camera.gameObject:SetActiveEx(false)
    end
    self.CameraDic[farName].gameObject:SetActiveEx(true)
    self.CameraDic[nearName].gameObject:SetActiveEx(true)
end

-- 刷新任务按钮
function XUiBossInshotMain:RefreshBtnTask()
    local isShowRed = self._Control:IsShowTaskRed()
    self.BtnTask:ShowReddot(isShowRed)

    local rewardId = self._Control:GetActivityPreviewTaskRewardId(self.ActivityId)
    local rewardItems = XRewardManager.GetRewardList(rewardId)
    self.Items = self.Items or {}
    XUiHelper.CreateTemplates(self, self.Items, rewardItems, XUiGridCommon.New, self.Grid256New, self.Grid256New.transform.parent, function(grid, data)
        grid:Refresh(data, nil, nil, false)
    end)
end

-- 检测新天赋解锁
function XUiBossInshotMain:CheckNewTalentUnlock()
    -- 重新战斗时不弹天赋解锁
    if self._Control:GetAgainFight() then
        self._Control:SetAgainFight(false)
        return
    end
    
    local result = self._Control:GetNewUnlockTalentIds()
    for characterId, newTalentIds in pairs(result) do
        XLuaUiManager.Open("UiBossInshotUnlockTalent", characterId, newTalentIds)
    end
end

-- 加载当前Boss模型
function XUiBossInshotMain:LoadBossModel()
    if not self.RoleModel then
        local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
        local linkGo = self.UiModelGo.transform:FindTransform("ModelPos")
        ---@type XUiPanelRoleModel
        self.RoleModel = XUiPanelRoleModel.New(linkGo, XModelManager.MODEL_UINAME.UiBossInshot, nil, true)
    end
    
    local bossId = self.BossIds[self.BossIndex]
    local modelId = self._Control:GetBossModelId(bossId)
    local XUiModelUtility = require("XUi/XUiCharacter/XUiModelUtility")
    XUiModelUtility.UpdateMonsterBossModel(self.RoleModel, modelId, XModelManager.MODEL_UINAME.UiBossInshot)
    self.RoleModel:SetRoleTransform(XModelManager.MODEL_UINAME.UiBossInshot)
end

-- 显示Boss特效
function XUiBossInshotMain:ShowBossEffect(effectName, isShow)
    local effectGo = self.EffectDic[effectName]
    if not isShow then
        effectGo.gameObject:SetActiveEx(false)
        return
    end

    self.RoleModel:BindEffect(effectGo.gameObject)

    local renders = self.RoleModel.Transform:GetComponentsInChildren(typeof(CS.UnityEngine.Renderer))
    for i = 1, renders.Length do
        renders[i - 1].enabled = false
    end
    
    effectGo.gameObject:SetActive(false)
    effectGo.gameObject:SetActive(true)
end

function XUiBossInshotMain:HideAllBossEffect()
    for _, name in pairs(self.EFFECT_NAME) do
        local effectGo = self.EffectDic[name]
        effectGo.gameObject:SetActiveEx(false)
    end
end

function XUiBossInshotMain:ClearBossEffectTimer()
    if self.BossEffectTimer then
        XScheduleManager.UnSchedule(self.BossEffectTimer)
        self.BossEffectTimer = nil
    end
end

-- 重新刷新XSceneSetting.cs，解决战斗回来场景变暗、战斗回放回来场景变亮
function XUiBossInshotMain:RefreshSceneSetting()
    local sceneGo = self.UiSceneInfo.Transform.gameObject
    local sceneSetting = sceneGo:GetComponent("XSceneSetting")
    local customLightmap = sceneGo:GetComponent("XCustomLightmap")
    if sceneSetting then
        sceneSetting.enabled = false
        customLightmap.enabled = false
        self:ClearSceneSettingTimer()
        self.SceneSettingTimer = XScheduleManager.ScheduleOnce(function()
            self.SceneSettingTimer = nil
            sceneSetting.enabled = true
            customLightmap.enabled = true
        end, 50)
    end
end

function XUiBossInshotMain:ClearSceneSettingTimer()
    if self.SceneSettingTimer then 
        XScheduleManager.UnSchedule(self.SceneSettingTimer)
        self.SceneSettingTimer = nil
    end
end

return XUiBossInshotMain
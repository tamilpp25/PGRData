---@class XUiBossInshotBossDetail:XLuaUi
---@field private _Control XBossInshotControl
local XUiBossInshotBossDetail = XClass(XUiNode, "XUiBossInshotBossDetail")

function XUiBossInshotBossDetail:OnStart()
    self.VideoPlayerUgui.gameObject:SetActiveEx(false)
    self.GridDots = { self.GridDot }
    self:RegisterUiEvents()
end

function XUiBossInshotBossDetail:OnDisable()
    self:StopSkillVideo()
end

function XUiBossInshotBossDetail:OnDestroy()
    self:StopSkillVideo()
    self.SkillIds = nil
    self.StageIds = nil
    self.GridDots = nil
end

function XUiBossInshotBossDetail:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnPlayback, self.OnBtnPlaybackClick, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnTeaching, self.OnBtnTeachingClick, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnFightTeach, self.OnBtnTeachingClick, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnFight, self.OnBtnFightClick, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnLeft, self.OnBtnLeftClick, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnRight, self.OnBtnRightClick, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnPractice, self.OnBtnPracticeClick, nil, true)
    local btns = { self.BtnDifficulty1, self.BtnDifficulty2, self.BtnDifficulty3 }
    self.PanelDifficulty:Init(btns, function(index)
        self:OnBtnDifficultyClick(index)
    end)
end

function XUiBossInshotBossDetail:OnBtnPlaybackClick()
    XLuaUiManager.Open("UiBossInshotPlayback", self.BossId)
end


function XUiBossInshotBossDetail:OnBtnTeachingClick()
    local activityId = self._Control:GetActivityId()
    local stageId = self._Control:GetActivityTeachStageId(activityId)
    local proxy = require("XUi/XUiBossInshot/XUiBossInshotBattleRoleRoom")
    XLuaUiManager.Open("UiBattleRoleRoom", stageId, nil, proxy)
end

function XUiBossInshotBossDetail:OnBtnFightClick()
    -- 教学关未完成
    local isTeachPass = self._Control:IsTeachStagePass()
    if not isTeachPass then
        -- 二次确认前往教学关
        local txtTitle = XUiHelper.GetText("TipTitle")
        local txtContent = XUiHelper.GetText("BossInshotFightTips")
        XUiManager.DialogTip(txtTitle, txtContent, XUiManager.DialogType.Normal, nil, function()
            self:OnBtnTeachingClick()
        end)
        return
    end
    self:EnterBattleRoleRoom()
end

-- 进入战斗房间界面
function XUiBossInshotBossDetail:EnterBattleRoleRoom()
    self.Parent:CacheDifficultyIndexAndSkillIndex(self.DifficultyIndex, self.SkillIndex)

    local difficultyStageId = self.StageIds[self.DifficultyIndex]
    local stageId = self._Control:GetStageStageId(difficultyStageId)
    local team = self._Control:GetTeam()
    local proxy = require("XUi/XUiBossInshot/XUiBossInshotBattleRoleRoom")
    XLuaUiManager.Open("UiBattleRoleRoom", stageId, team, proxy)
end

function XUiBossInshotBossDetail:OnBtnDifficultyClick(index)
    -- 所选难度关卡未解锁
    local stageId = self.StageIds[index]
    local isUnlock, desc = self._Control:IsStageUnlock(stageId)
    if not isUnlock then
        XUiManager.TipError(desc)
        return
    end

    -- 刷新选中状态
    local Select = CS.UiButtonState.Select
    local Normal = CS.UiButtonState.Normal
    local Disable = CS.UiButtonState.Disable
    for i, sId in ipairs(self.StageIds) do
        local state = Disable
        local isUnlock, desc = self._Control:IsStageUnlock(sId)
        if isUnlock then
            state = i == index and Select or Normal
        end
        self["BtnDifficulty" .. tostring(i)]:SetButtonState(state)
    end
    self.DifficultyIndex = index
end

function XUiBossInshotBossDetail:OnBtnLeftClick()
    if self.SkillIndex > 1 then
        self.SkillIndex = self.SkillIndex - 1
    else
        self.SkillIndex = #self.SkillIds
    end
    self:RefreshSkillInfo()
    self.Parent:PlayAnimation("QieHuan")
end

function XUiBossInshotBossDetail:OnBtnRightClick()
    local skillCnt = #self.SkillIds
    if self.SkillIndex < skillCnt then
        self.SkillIndex = self.SkillIndex + 1
    else
        self.SkillIndex = 1
    end
    self:RefreshSkillInfo()
    self.Parent:PlayAnimation("QieHuan")
end

function XUiBossInshotBossDetail:OnBtnPracticeClick()
    local skillId = self.SkillIds[self.SkillIndex]
    local skillCfg = self._Control:GetConfigBossInshotSkill(skillId)
    if skillCfg.PracticeStageId ~= 0 then
        self.Parent:CacheDifficultyIndexAndSkillIndex(self.DifficultyIndex, self.SkillIndex)
        XMVCA.XBossInshot:BossInshotSelectSkillRequest(skillCfg.PracticeStageId, skillCfg.FightEventId)
        local team = self._Control:GetTeam()
        local proxy = require("XUi/XUiBossInshot/XUiBossInshotBattleRoleRoom")
        XLuaUiManager.Open("UiBattleRoleRoom", skillCfg.PracticeStageId, team, proxy)
    end
end

function XUiBossInshotBossDetail:Refresh(bossId, difficultyIndex, skillIndex)
    self.BossId = bossId
    self.StageIds = self._Control:GetBossStageIds(bossId)
    self.DifficultyIndex = difficultyIndex or 1
    self.SkillIds = self._Control:GetBossSkillIds(bossId)
    self.SkillIndex = skillIndex or 1

    -- 摄像机镜头
    self.Parent:SwitchCamera("UiModeCamFarDetail", "UiModeCamNearDetail")
    
    -- 回放按钮
    local isShowPlayback = self._Control:GetIsShowPlayback()
    self.BtnPlayback.gameObject:SetActiveEx(isShowPlayback)
    
    -- 挑战和教学按钮
    local isTeachPass = self._Control:IsTeachStagePass()
    self.BtnTeaching.gameObject:SetActiveEx(isTeachPass)
    self.BtnFight.gameObject:SetActiveEx(isTeachPass)
    self.BtnFightTeach.gameObject:SetActiveEx(not isTeachPass)
    
    -- Boss名称
    self.TxtBossNameDetail.text = self._Control:GetBossName(bossId)

    -- 技能
    self:RefreshSkillInfo()

    -- 难度列表
    local Select = CS.UiButtonState.Select
    local Normal = CS.UiButtonState.Normal
    local Disable = CS.UiButtonState.Disable
    for i, inshotStageId in ipairs(self.StageIds) do
        local btn = self["BtnDifficulty".. i]
        local stageName = self._Control:GetStageName(inshotStageId)
        btn:SetNameByGroup(0, stageName)

        local state = Disable
        local isUnlock, desc = self._Control:IsStageUnlock(inshotStageId)
        if isUnlock then
            state = i == self.DifficultyIndex and Select or Normal
        end
        btn:SetButtonState(state)

        -- 关卡评分
        local stageId = self._Control:GetStageStageId(inshotStageId)
        local stageData = self._Control:GetPassStageData(stageId)
        btn:SetRawImageVisible(stageData ~= nil)
        if stageData then
            local difficulty = self._Control:GetStageDifficulty(inshotStageId)
            local levelIcon = self._Control:GetScoreLevelIcon(difficulty, stageData.MaxScore)
            btn:SetRawImage(levelIcon)
            btn:SetNameByGroup(1, stageData.MaxScore)
        else
            btn:SetNameByGroup(1, "")
        end
    end
end

-- 刷新技能信息
function XUiBossInshotBossDetail:RefreshSkillInfo()
    -- 技能描述
    local skillId = self.SkillIds[self.SkillIndex]
    self.TxtSkillName.text = self._Control:GetSkillName(skillId)
    self.TxtSkillTips.text = self._Control:GetSkillTips(skillId)
    self.TxtSkillDetail.text = self._Control:GetSkillDesc(skillId)

    -- 技能视频
    self:StopSkillVideo()
    local videoUrl = self._Control:GetSkillVideoUrl(skillId)
    self.VideoComponent = XUiHelper.Instantiate(self.VideoPlayerUgui, self.VideoPlayerUgui.transform.parent)
    self.VideoComponent.gameObject:SetActiveEx(true)
    self.VideoComponent:SetVideoFromRelateUrl(videoUrl)
    self.VideoComponent:Play()

    -- 点列表
    local isShowDot = #self.SkillIds > 1
    self.PanelDot.gameObject:SetActiveEx(isShowDot)
    if isShowDot then
        for _, dot in ipairs(self.GridDots) do
            dot.gameObject:SetActiveEx(false)
        end
        local CSInstantiate = CS.UnityEngine.Object.Instantiate
        for i, _ in ipairs(self.SkillIds) do
            local dot = self.GridDots[i]
            if not dot then
                local go = CSInstantiate(self.GridDot.gameObject, self.PanelDot.transform)
                dot = go:GetComponent("UiObject")
                self.GridDots[i] = dot
            end
            dot.gameObject:SetActiveEx(true)
            local isSelect = i == self.SkillIndex
            dot:GetObject("ImgOn").gameObject:SetActiveEx(isSelect)
            dot:GetObject("ImgOff").gameObject:SetActiveEx(not isSelect)
        end
    end
    
    -- 练习关按钮
    local practiceStageId = self._Control:GetSkillPracticeStageId(skillId)
    local isShowPractice = practiceStageId ~= 0
    self.BtnPractice.gameObject:SetActiveEx(isShowPractice)
end

function XUiBossInshotBossDetail:StopSkillVideo()
    if self.VideoComponent then
        self.VideoComponent:Stop()
        self.VideoComponent.gameObject:SetActiveEx(false)
        CS.UnityEngine.Object.Destroy(self.VideoComponent.gameObject)
        self.VideoComponent = nil 
    end
end

return XUiBossInshotBossDetail
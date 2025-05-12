local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiMaverick3PopupChapterDetail : XLuaUi 孤胆枪手关卡详情
---@field _Control XMaverick3Control
local XUiMaverick3PopupChapterDetail = XLuaUiManager.Register(XLuaUi, "UiMaverick3PopupChapterDetail")

function XUiMaverick3PopupChapterDetail:OnAwake()
    self._GridCommons = {}
    self.BtnClose.CallBack = handler(self, self.Close)
    self.BtnStory.CallBack = handler(self, self.OnBtnStoryClick)
    self.BtnAgain.CallBack = handler(self, self.OnBtnAgainClick)
    self.BtnEnter.CallBack = handler(self, self.OnBtnEnterClick)
    self.BtnContinue.CallBack = handler(self, self.OnBtnContinueClick)
end

function XUiMaverick3PopupChapterDetail:OnStart(stageId)
    self._StageId = stageId
    self._StageConfig = self._Control:GetStageById(stageId)
    self._Star = self._Control:GetStageStar(stageId)
    self._IsPassed = self._Control:IsStageFinish(stageId)
    self._SaveData = self._Control:GetStageSavedData(stageId)
    ---@type XUiGridMaverick3Ornaments
    self._GridRecordOrnaments = require("XUi/XUiMaverick3/Grid/XUiGridMaverick3Ornaments").New(self.GridRecordOrnaments, self)
    ---@type XUiGridMaverick3Slay
    self._GridRecordSlay = require("XUi/XUiMaverick3/Grid/XUiGridMaverick3Slay").New(self.GridRecordSlay, self)

    local endTime = self._Control:GetActivityGameEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end, nil, 0)
end

function XUiMaverick3PopupChapterDetail:OnEnable()
    self._IsPlaying = self._Control:IsStagePlaying(self._StageId)
    self:UpdateStageInfo()
    self:UpdateSaveData()
end

function XUiMaverick3PopupChapterDetail:OnDisable()
    self._GridRecordOrnaments:Close()
    self._GridRecordSlay:Close()
end

function XUiMaverick3PopupChapterDetail:UpdateStageInfo()
    self.TxtTitle.text = self._StageConfig.Name
    self.TxtTips.text = self._StageConfig.Desc
    -- 剧情按钮
    if XTool.IsNumberValid(self._StageConfig.StoryId) then
        self._HasStory = self._Control:GetStoryById(self._StageConfig.StoryId).IsEnd ~= 1
    else
        self._HasStory = false
    end
    self.BtnStory.gameObject:SetActiveEx(self._HasStory)
    -- 关卡目标
    XUiHelper.RefreshCustomizedList(self.GridStageStar.parent, self.GridStageStar, #self._StageConfig.StarConditions, function(i, go)
        local uiObject = {}
        XUiHelper.InitUiClass(uiObject, go)
        uiObject.PanelUnActive.gameObject:SetActiveEx(self._Star < i)
        uiObject.PanelActive.gameObject:SetActiveEx(self._Star >= i)
        uiObject.TxtUnActive.text = self._StageConfig.StarDesc[i]
        uiObject.TxtActive.text = self._StageConfig.StarDesc[i]
    end)
    -- 关卡奖励
    local totalRewards = {}
    if XTool.IsNumberValid(self._StageConfig.FinishRewardId) then
        totalRewards = XRewardManager.GetRewardList(self._StageConfig.FinishRewardId)
    else
        local rewards = XRewardManager.GetRewardList(self._StageConfig.FirstRewardId)
        for _, v in ipairs(rewards) do
            table.insert(totalRewards, {
                TemplateId = v.TemplateId,
                Count = v.Count,
                ShowReceived = self._IsPassed,
                IsFirstReward = true,
            })
        end
    end
    XUiHelper.RefreshCustomizedList(self.Grid256New.parent, self.Grid256New, #totalRewards, function(i, go)
        ---@type XUiGridCommon
        local grid = self._GridCommons[i]
        if not grid then
            grid = XUiGridCommon.New(self, go)
            self._GridCommons[i] = grid
        end
        grid:Refresh(totalRewards[i])
        grid:SetPanelFirst(totalRewards[i].IsFirstReward)
    end)
    self.BtnAgain.gameObject:SetActiveEx(self._IsPlaying)
    self.BtnContinue.gameObject:SetActiveEx(self._IsPlaying)
    self.BtnEnter.gameObject:SetActiveEx(not self._IsPlaying)
end

function XUiMaverick3PopupChapterDetail:UpdateSaveData()
    if not self._Control:IsStagePlaying(self._StageId) then
        self.PanelProgress.gameObject:SetActiveEx(false)
        return
    end
    
    self.PanelProgress.gameObject:SetActiveEx(true)
    self.TxtNum.text = string.format("%s%%", self._SaveData.StageProgress)
    self.RImgHeadIcon:SetRawImage(XRobotManager.GetRobotSmallHeadIcon(self._Control:GetRobotById(self._SaveData.RobotId).RobotId))
    self.ImgBar.fillAmount = XTool.IsNumberValid(self._SaveData.MaxHp) and self._SaveData.Hp / self._SaveData.MaxHp or 0
    self.TxtHpNum.text = string.format("%s/%s", self._SaveData.Hp, self._SaveData.MaxHp)
    self._GridRecordOrnaments:Open()
    self._GridRecordOrnaments:SetData(self._SaveData.Hangings)
    self._GridRecordSlay:Open()
    self._GridRecordSlay:SetData(self._SaveData.UltimateSkill)
    self.TxtRevive.text = self._SaveData.DeadCount
    -- 首位是普攻 没子弹限制 要去掉
    local robot = self._Control:GetRobotById(self._SaveData.RobotId)
    local datas = {}
    for i = 2, #robot.SkillIds do
        table.insert(datas, robot.SkillIds[i])
    end
    XUiHelper.RefreshCustomizedList(self.GridRecordSkill.parent, self.GridRecordSkill, #datas, function(i, go)
        local uiObject = {}
        local skillId = datas[i]
        local skillCfg = self._Control:GetSkillById(skillId)
        XUiHelper.InitUiClass(uiObject, go)
        uiObject.RImgIcon:SetRawImage(skillCfg.Icon)
        uiObject.TxtNum.text = self._SaveData.BulletCount[i] or 0
    end)
end

function XUiMaverick3PopupChapterDetail:OnBtnStoryClick()
    if XTool.IsNumberValid(self._StageConfig.StoryId) then
        XLuaUiManager.Open("UiMaverick3PoupuStoryDetail", self._StageConfig.StoryId)
    end
end

-- 重新挑战
function XUiMaverick3PopupChapterDetail:OnBtnAgainClick()
    XUiManager.DialogTip(nil, XUiHelper.GetText("Maverick3GiveUp"), nil, nil, function()
        self._Control:RequestMaverick3ExitStage(self._StageId, function()
            XLuaUiManager.Open("UiMaverick3Character", self._StageId)
        end)
    end)
end

-- 开始战斗
function XUiMaverick3PopupChapterDetail:OnBtnEnterClick()
    local storyId = self._StageConfig.StoryId
    if self._HasStory and self._Control:IsAutoPlayStory(storyId) then
        XDataCenter.UiQueueManager.Open("UiMaverick3PoupuStoryDetail", storyId)
        XDataCenter.UiQueueManager.Open("UiMaverick3Character", self._StageId)
    else
        XLuaUiManager.Open("UiMaverick3Character", self._StageId)
    end
end

-- 继续挑战
function XUiMaverick3PopupChapterDetail:OnBtnContinueClick()
    XMVCA.XFuben:EnterFightByStageId(self._StageId, nil, false, 1, nil)
end

return XUiMaverick3PopupChapterDetail
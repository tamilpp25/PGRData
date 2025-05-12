local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiPanelCharacterFileMainBase = require('XUi/XUiCharacterFiles/Base/XUiPanelCharacterFileMainBase')
--- 试玩角色主界面的实际控制代码默认版本
--- 后续若有增量功能可直接在这里加。如果要改结构建议派生解决
---@class XUiPanelCharacterFileMain: XUiPanelCharacterFileMainBase
---@field Parent XUiCharacterFileMainRoot
local XUiPanelCharacterFileMain = XClass(XUiPanelCharacterFileMainBase, 'XUiPanelCharacterFileMain')

--region 生命周期
function XUiPanelCharacterFileMain:OnStart(cfg)
    self.ActivityCfg = cfg
    self.Id = self.ActivityCfg.Id
    self.ActivityEndTime = XFunctionManager.GetEndTimeByTimeId(self.ActivityCfg.TimeId)
    self:InitButtons()
    self:InitReddot()
    self._StartRun = true

    self:PlayAnimationWithMask("AnimEnable1", function()
        self:PlayAnimation("Loop",nil,nil, CS.UnityEngine.Playables.DirectorWrapMode.Loop)
    end)
end

function XUiPanelCharacterFileMain:OnEnable()
    self:CheckRedPoint()
    self:RefreshMainTask()

    if self._StartRun then
        self._StartRun = nil
    else
        self:PlayAnimation("Loop",nil,nil,CS.UnityEngine.Playables.DirectorWrapMode.Loop)
    end
end


function XUiPanelCharacterFileMain:OnDisable()

end
--endregion

--region 初始化
function XUiPanelCharacterFileMain:InitButtons()
    self.BtnTeaching.CallBack = handler(self, self.OnBtnTeachingClick)
    self.BtnChallenge.CallBack = handler(self, self.OnBtnChallengeClick)

    if self.BtnArchives then
        self.BtnArchives.CallBack = handler(self, self.OnBtnDetailsClick)
    end

    if self.BtnExchange then
        self.BtnExchange.CallBack = handler(self, self.OnBtnCultivateClick)
    end

    if self.BtnObtain then
        self.BtnObtain.CallBack = handler(self, self.OnBtnObtainClick)
    end

    if self.BtnCoating then
        -- 涂装跳转入口有时间限制
        local isShow = XFunctionManager.CheckSkipInDuration(self.ActivityCfg.SkipIdSkin, true)
        self.BtnCoating.gameObject:SetActiveEx(isShow)

        if isShow then
            self.BtnCoating.CallBack = handler(self, self.OnBtnSkinClick)
        end
    end

    if self.BtnResearch then
        -- 研发跳转入口有时间限制
        local isShow = XFunctionManager.CheckSkipInDuration(self.ActivityCfg.SkipIdDraw, true)
        self.BtnResearch.gameObject:SetActiveEx(isShow)

        if isShow then
            self.BtnResearch.CallBack = handler(self, self.OnBtnResearchClick)
        end
    end

    if self.BtnAchievement then
        self.BtnAchievement.CallBack=function() self.Parent.TaskPanel:Open() end
    end

    if self.BtnTreasure then
        XUiHelper.RegisterClickEvent(self,self.BtnTreasure,function() self.Parent.TaskPanel:Open() end)
    end

    if self.BtnStory then
        self.BtnStory.CallBack = handler(self, self.OnBtnStoryClick)
    end
end

function XUiPanelCharacterFileMain:InitReddot()
    self.RedPointBtnAchievementId=self:AddRedPointEvent(self.BtnAchievement,self.RefreshBtnTaskRedDot,self,{
        XRedPointConditions.Types.CONDITION_NEWCHARACTIVITYTASK,
    }, self.Id)
    self.RedPointBtnTeachingId = self:AddRedPointEvent(self.BtnTeaching, self.RefreshBtnTeachingRedDot, self, {
        XRedPointConditions.Types.CONDITION_KOROMCHARACTIVITYTEACHINGRED,
    }, self.Id)
    self.RedPointBtnChallengeId = self:AddRedPointEvent(self.BtnChallenge, self.RefreshBtnChallengeRedDot, self, {
        XRedPointConditions.Types.CONDITION_KOROMCHARACTIVITYCHALLENGERED,
    }, self.Id)
end
--endregion

--region 界面刷新
--- 刷新主界面的任务相关内容
function XUiPanelCharacterFileMain:RefreshMainTask()
    local actCfg = XFubenNewCharConfig.GetActTemplates()[self.Id]
    local rewardId = 0
    if XTool.IsNumberValid(actCfg.ShowRewardId) then --显示配置的数据
        rewardId = actCfg.ShowRewardId
    else --采用原逻辑按顺序显示
        XLog.Error('任务奖励入口显示未配置固定显示，执行按优先级筛选显示逻辑--2.8版本显示需求')
        local treasureId, isAllFinish = XDataCenter.FubenNewCharActivityManager.GetShowTaskId(self.Id)
        if not XTool.IsNumberValid(treasureId) then
            self.PanelTips.gameObject:SetActiveEx(false)
            return
        end
        local config = XFubenNewCharConfig.GetTreasureCfg(treasureId)
        rewardId = config.RewardId
    end
    self.PanelTips.gameObject:SetActiveEx(true)
    self.GridMainTaskReward = self.GridMainTaskReward or {}
    local rewards=XRewardManager.GetRewardListNotCount(rewardId)
    local rewardsNum = #rewards
    for i = 1, rewardsNum do
        local grid = self.GridMainTaskReward[i]
        if not grid then
            local go = i == 1 and self.Grid256New or XUiHelper.Instantiate(self.Grid256New, self.PanelItem)
            grid = XUiGridCommon.New(nil, go)
            self.GridMainTaskReward[i] = grid
        end
        grid:Refresh(rewards[i])
        grid.GameObject:SetActiveEx(true)
    end
    for i = rewardsNum + 1, #self.GridMainTaskReward do
        self.GridMainTaskReward[i].GameObject:SetActiveEx(false)
    end

    self:RefreshStarProgress()
end

--- 刷新星级收集进度
function XUiPanelCharacterFileMain:RefreshStarProgress()
    local curStars
    local totalStars
    curStars, totalStars = XDataCenter.FubenNewCharActivityManager.GetProcess(self.Id)

    self.ImgJindu.fillAmount = totalStars > 0 and curStars / totalStars or 0
    self.ImgJindu.gameObject:SetActiveEx(true)

    local received = true
    local cfg = XFubenNewCharConfig.GetActTemplates()[self.Id]
    for _, v in pairs(cfg.TreasureId) do
        if not XDataCenter.FubenNewCharActivityManager.IsTreasureGet(v) then
            received = false
            break
        end
    end
    self.ImgLingqu.gameObject:SetActiveEx(received)

end
--endregion

--region 事件
function XUiPanelCharacterFileMain:OnBtnTeachingClick()
    self.Parent:SwitchPanelStage(XFubenNewCharConfig.KoroPanelType.Teaching)
end

function XUiPanelCharacterFileMain:OnBtnChallengeClick()
    if XTool.IsNumberValid(self.ActivityCfg.ChallengeCondition) then
        local isOpen,desc = XConditionManager.CheckCondition(self.ActivityCfg.ChallengeCondition)
        if not isOpen then
            XUiManager.TipMsg(desc)
            return
        end
    end

    self.Parent:SwitchPanelStage(XFubenNewCharConfig.KoroPanelType.Challenge)
end

function XUiPanelCharacterFileMain:OnBtnDetailsClick()
    XLuaUiManager.Open("UiCharacterDetail", self.ActivityCfg.CharacterId)
end

function XUiPanelCharacterFileMain:OnBtnCultivateClick()
    XFunctionManager.SkipInterface(self.ActivityCfg.SkipIdChar)
end

function XUiPanelCharacterFileMain:OnBtnObtainClick()
    XFunctionManager.SkipInterface(self.ActivityCfg.SkipGet)
end

function XUiPanelCharacterFileMain:OnBtnSkinClick()
    XFunctionManager.SkipInterface(self.ActivityCfg.SkipIdSkin)
end

function XUiPanelCharacterFileMain:OnBtnResearchClick()
    XFunctionManager.SkipInterface(self.ActivityCfg.SkipIdDraw)
end

function XUiPanelCharacterFileMain:OnBtnStoryClick()
    local result = XMVCA.XFavorability:OpenUiStory(self.ActivityCfg.CharacterId, XEnumConst.Favorability.FavorabilityStoryEntranceType.CharacterFile)

    if result == -2 then
        XLog.Error('配置的角色Id无效, TeachingActivity配置 Id:'..tostring(self.ActivityCfg.Id))
    end
end
--endregion

--region 红点
function XUiPanelCharacterFileMain:CheckRedPoint()
    XRedPointManager.Check(self.RedPointBtnAchievementId)
    XRedPointManager.Check(self.RedPointBtnTeachingId)
    XRedPointManager.Check(self.RedPointBtnChallengeId)
end

function XUiPanelCharacterFileMain:RefreshBtnChallengeRedDot(count)
    self.BtnChallenge:ShowReddot(count >= 0)
end

function XUiPanelCharacterFileMain:RefreshBtnTeachingRedDot(count)
    self.BtnTeaching:ShowReddot(count >= 0)
end

function XUiPanelCharacterFileMain:RefreshBtnTaskRedDot(count)
    self.BtnAchievement:ShowReddot(count>=0)
end
--endregion

return XUiPanelCharacterFileMain
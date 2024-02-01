local tableInsert = table.insert
local CsXTextManager = CS.XTextManager
local CsXScheduleManager = XScheduleManager

local XUiGridActivityBossSingle = require("XUi/XUiActivityBossSingle/XUiGridActivityBossSingle")
local XUiActivityBossSingle = XLuaUiManager.Register(XLuaUi, "UiActivityBossSingle")

local StageCount = 5
local StarDescCount = 3

function XUiActivityBossSingle:OnStart(sectionId)
    self.SectionId = sectionId
    self:AutoAddListener()
    self.StageIds = XDataCenter.FubenActivityBossSingleManager.GetSectionStageIdList(self.SectionId)
    self.GridList = {}
    self:InitPanel()
end

function XUiActivityBossSingle:OnEnable()
    self.PanelDetail.gameObject:SetActiveEx(false)
    self.AnimBgLoop.gameObject:SetActiveEx(true)
    self:RefreshPanel()
    self:CheckAndPlayEnableAnimation()
end

function XUiActivityBossSingle:OnDisable()
    self:DestroyActivityTimer()
    XRedPointManager.RemoveRedPointEvent(self.StoryRedPoint)
end

--初始化面板
function XUiActivityBossSingle:InitPanel()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    --不显示描述按钮
    self.BtnActDesc.gameObject:SetActiveEx(false)
    --初始化选项卡
    self:InitStageCapter()
    self:InitStarDesc()
    self:CreateActivityTimer()
    self:InitStoryInfo()
    --标记首次进入
    XDataCenter.FubenActivityBossSingleManager.MarkFirstPlay()
end

function XUiActivityBossSingle:CreateActivityTimer()
    self:DestroyActivityTimer()

    local time = XTime.GetServerNowTimestamp()
    local fightEndTime = XDataCenter.FubenActivityBossSingleManager.GetFightEndTime()
    local activityEndTime = XDataCenter.FubenActivityBossSingleManager.GetActivityEndTime()
    local shopStr = CsXTextManager.GetText("ActivityBranchShopLeftTime")
    local fightStr = CsXTextManager.GetText("ActivityBranchFightLeftTime")

    if XDataCenter.FubenActivityBossSingleManager.IsStatusEqualFightEnd() then
        self.TxtResetDesc.text = shopStr
        self.TxtLeftTime.text = XUiHelper.GetTime(activityEndTime - time, XUiHelper.TimeFormatType.ACTIVITY)
        if self.TxtLeftTimeMirror then
            self.TxtLeftTimeMirror.text = XUiHelper.GetTime(activityEndTime - time, XUiHelper.TimeFormatType.ACTIVITY)
        end
    else
        self.TxtResetDesc.text = fightStr
        self.TxtLeftTime.text = XUiHelper.GetTime(fightEndTime - time, XUiHelper.TimeFormatType.ACTIVITY)
        if self.TxtLeftTimeMirror then
            self.TxtLeftTimeMirror.text = XUiHelper.GetTime(fightEndTime - time, XUiHelper.TimeFormatType.ACTIVITY)
        end
    end

    self.ActivityTimer = CsXScheduleManager.ScheduleForever(function()
            if XTool.UObjIsNil(self.TxtLeftTime) then
                self:DestroyActivityTimer()
                return
            end

            time = time + 1

            if time >= activityEndTime then
                self:DestroyActivityTimer()
                XDataCenter.FubenActivityBossSingleManager.OnActivityEnd()
            elseif fightEndTime <= time then
                local leftTime = activityEndTime - time
                if leftTime > 0 then
                    self.TxtResetDesc.text = shopStr
                    self.TxtLeftTime.text = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
                    if self.TxtLeftTimeMirror then
                        self.TxtLeftTimeMirror.text = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
                    end
                end
            else
                local leftTime = fightEndTime - time
                if leftTime > 0 then
                    self.TxtResetDesc.text = fightStr
                    self.TxtLeftTime.text = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
                    if self.TxtLeftTimeMirror then
                        self.TxtLeftTimeMirror.text = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
                    end
                else
                    self:DestroyActivityTimer()
                    self:CreateActivityTimer()
                end
            end
        end, CsXScheduleManager.SECOND, 0)
end

function XUiActivityBossSingle:DestroyActivityTimer()
    if self.ActivityTimer then
        CsXScheduleManager.UnSchedule(self.ActivityTimer)
        self.ActivityTimer = nil
    end
end

--初始化副本选择卡,选择卡是定死的，不使用滑动条
function XUiActivityBossSingle:InitStageCapter()
    self.ChapterGrids = {}
    
    for i = 1, StageCount do
        if  i > #self.StageIds then
            if self["PanelImg"..i] then
                self["PanelImg" .. i].gameObject:SetActiveEx(false)
            end
        else
            if self["PanelImg"..i] then
                local chapterGrid = XUiGridActivityBossSingle.New(self, self["PanelImg" .. i])
                tableInsert(self.ChapterGrids, chapterGrid)
            end
        end
    end
end

function XUiActivityBossSingle:RefreshPanel()
    self:RefreshSchedule()
    self:RefreshTreasureInfo()
    self:RefreshStoryInfo()
    --统一进行刷新,根据stageId
    for gridIndex = 1, #self.ChapterGrids do
        self.ChapterGrids[gridIndex]:Refresh(self.StageIds[gridIndex], gridIndex)
    end
end

--检查并播放界面启动动画 根据情况播放关卡解锁动画
function XUiActivityBossSingle:CheckAndPlayEnableAnimation()
    local playStage = XDataCenter.FubenActivityBossSingleManager.GetNeedPlayUnlockAnimeStage()
    if playStage == -1 then 
        self:PlayEnableAnim()
    return end
    --播放动画
    self:PlayAnimationWithMask("PanelImg"..playStage.."Enable")
    XDataCenter.FubenActivityBossSingleManager.OnStageUnlockAnimePlayed()
end

--初始化详细信息面板的挑战目标
function XUiActivityBossSingle:InitStarDesc()
    self.GridStarList = {}
    for i = 1, StarDescCount do
        local ui = self["GridStageStar" .. i]
        ui.gameObject:SetActiveEx(true)
        local grid = XUiGridStageStar.New(ui)
        self.GridStarList[i] = grid
    end
end

--初始化左下角故事入口
function XUiActivityBossSingle:InitStoryInfo()
    local storyCount=XFubenActivityBossSingleConfigs.GetStoryCount(self.SectionId)
    if self.PanelStory then
        if storyCount==nil or storyCount<=0 then
            self.PanelStory.gameObject:SetActiveEx(false)
        else
            self.PanelStory.gameObject:SetActiveEx(true)
        end
        self.StoryRedPoint=XRedPointManager.AddRedPointEvent(self.PanelStory,self.OnStoryRedPointCheck,self,{XRedPointConditions.Types.CONDITION_ACTIVITY_BOSS_SINGLE_NEW},nil,false)
    end 
end

--刷新收集进度条显示
function XUiActivityBossSingle:RefreshSchedule()
    local curStarsCount = XDataCenter.FubenActivityBossSingleManager.GetCurStarsCount()
    local totalStarsCount = XDataCenter.FubenActivityBossSingleManager.GetAllStarsCount()
    if totalStarsCount ~= 0 then
        self.ImgSchedule.fillAmount = curStarsCount / totalStarsCount
    end

    self.TxtSchedule.text = CsXTextManager.GetText("ActivityBossSingleSchedule", curStarsCount, totalStarsCount)
end

--刷新左下角奖励信息
function XUiActivityBossSingle:RefreshTreasureInfo()
    local starsTotalCount = XDataCenter.FubenActivityBossSingleManager.GetAllStarsCount()
    local starsCurCount = XDataCenter.FubenActivityBossSingleManager.GetCurStarsCount()

    self.ImgJindu.fillAmount = starsTotalCount > 0 and starsCurCount / starsTotalCount or 0
    self.ImgJindu.gameObject:SetActiveEx(true)

    --设置是否全部领取完成
    local isAllFinish = XDataCenter.FubenActivityBossSingleManager.CheckIsAllFinish()
    self.BtnTreasure.gameObject:SetActiveEx(true)
    self.ImgLingqu.gameObject:SetActiveEx(isAllFinish)

    --红点
    local isShowRedPoint = XDataCenter.FubenActivityBossSingleManager.CheckRedPoint()
    self.BtnTreasure:ShowReddot(isShowRedPoint)
end

--刷新左下角故事入口信息
function XUiActivityBossSingle:RefreshStoryInfo()
    if self.StoryRedPoint then
        XRedPointManager.Check(self.StoryRedPoint)
    end
end

--点击副本卡的时候回调
function XUiActivityBossSingle:SelectStageCallBack(index)
    self:PlayAnimationWithMask("FuBenImg" .. index .. "Up", function()
        local animLoopName = "AnimFuBenImg" .. index .. "Loop"
        if self[animLoopName] then
            self[animLoopName].gameObject:SetActiveEx(true)
        end
        self:PlayAnimation("FuBenImg" .. index .. "Loop", nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.Loop)
    end)
    --标记正在显示详细信息
    self.IsInDetail = true
    self.CurrentSelectIndex = index
    self.CurrentSelectStageId = self.StageIds[index]

    self:InitStageDetailInfo(self.CurrentSelectStageId)
    self:PlayAnimation("DetailEnable")
    self.PanelDetail.gameObject:SetActiveEx(true)
    self.PanelLeftTreasure.gameObject:SetActiveEx(false)
end

--初始化副本的详细信息
function XUiActivityBossSingle:InitStageDetailInfo(stageId)
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
    local starsMap = XDataCenter.FubenActivityBossSingleManager.GetStageStarMap(stageId)

    --加载特效
    local effectPath = XFubenActivityBossSingleConfigs.GetBossChallengeEffectPath(stageId)
    self.PanelEffectDetail.gameObject:LoadUiEffect(effectPath)

    --刷新消耗数量
    self.TxtATNums.text = XDataCenter.FubenManager.GetRequireActionPoint(stageId)

    --TODO  显示挑战目标
    for i = 1, StarDescCount do
        self.GridStarList[i]:Refresh(stageCfg.StarDesc[i], starsMap[i])
    end

    --标题
    self.ImgBt:SetRawImage(stageCfg.Icon)

    --显示奖励,根据stageCfg
    local rewardId = 0
    local isFirst = false
    local cfg = XDataCenter.FubenManager.GetStageLevelControl(stageCfg.StageId)
    if not XDataCenter.FubenActivityBossSingleManager.IsChallengePassedByStageId(stageCfg.StageId) then
        rewardId = cfg and cfg.FirstRewardShow or stageCfg.FirstRewardShow
        if cfg and cfg.FirstRewardShow > 0 or stageCfg.FirstRewardShow > 0 then
            isFirst = true
        end
    end
    self.TxtFirstDrop.gameObject:SetActiveEx(isFirst)
    self.TxtDrop.gameObject:SetActiveEx(not isFirst)
    if rewardId == 0 then
        rewardId = cfg and cfg.FinishRewardShow or stageCfg.FinishRewardShow
    end
    if rewardId == 0 then
        for j = 1, #self.GridList do
            self.GridList[j].GameObject:SetActive(false)
        end
        return
    end

    local rewards = isFirst and XRewardManager.GetRewardList(rewardId) or XRewardManager.GetRewardListNotCount(rewardId)
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
            end
            grid:Refresh(item)
            grid.GameObject:SetActive(true)
        end
    end

    local rewardsCount = 0
    if rewards then
        rewardsCount = #rewards
    end

    for j = 1, #self.GridList do
        if j > rewardsCount then
            self.GridList[j].GameObject:SetActive(false)
        end
    end
end

--打开详细信息的时候先退回副本选择卡界面，并刷新一次界面
function XUiActivityBossSingle:OnBtnBackClick()
    if self.IsInDetail == true then
        self.IsInDetail = false
        self:PlayEnableAnim()
        self.PanelDetail.gameObject:SetActiveEx(false)
        local animLoopName = "AnimFuBenImg" .. self.CurrentSelectIndex .. "Loop"
        if self[animLoopName] then
            self[animLoopName].gameObject:SetActiveEx(false)
        end
        self:RefreshPanel()
        return
    end

    self:Close()
end

function XUiActivityBossSingle:AutoAddListener()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
    self.BtnEnter.CallBack = function()
        self:OnBtnEnterClick()
    end
    self.BtnTreasure.CallBack = function()
        self:OnBtnTreasureClick()
    end
    self.BtnNote.CallBack = function()
        self:OnBtnNoteClick()
    end
    self.PanelStory.CallBack=function() 
        self:OnBtnStoryClick()
    end
end

--作战准备按钮点击
function XUiActivityBossSingle:OnBtnEnterClick()
    self.IsInDetail = false
    self.PanelDetail.gameObject:SetActiveEx(false)
    XDataCenter.FubenActivityBossSingleManager.JumpToRoleRoom(self.CurrentSelectStageId)
end

function XUiActivityBossSingle:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiActivityBossSingle:OnBtnTreasureClick()
    XLuaUiManager.Open("UiActivityBossSingleReward", self.SectionId, function()
        self:RefreshTreasureInfo()
    end)
end

function XUiActivityBossSingle:OnBtnStoryClick()
    XLuaUiManager.Open("UiActivityBossSingleStory")
end

--点击描述按钮显示的注意事项
function XUiActivityBossSingle:OnBtnNoteClick()
    local attentionDesc = XFubenActivityBossSingleConfigs.GetStageAttention(self.StageIds[self.CurrentSelectIndex])
    local attentionDescTitle = XFubenActivityBossSingleConfigs.GetStageAttentionTitle(self.StageIds[self.CurrentSelectIndex])
    local title = CsXTextManager.GetText("ActivityBossSingleAttention")
    XLuaUiManager.Open("UiAttentionDesc", title, attentionDesc, attentionDescTitle)
end

function XUiActivityBossSingle:PlayEnableAnim()
    self:PlayAnimationWithMask("AnimEnableManually")
end

---region 红点
function XUiActivityBossSingle:OnStoryRedPointCheck(count)
    self.PanelStory:ShowReddot(count>=0)
end
---endregion
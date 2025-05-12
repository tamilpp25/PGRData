local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
--- 超难关默认的主界面控制脚本
---@class XUiPanelBossSingleMainNormal: XUiNode
local XUiPanelBossSingleMainNormal = XClass(XUiNode, 'XUiPanelBossSingleMainNormal')
local XUiGridActivityBossSingle = require("XUi/XUiActivityBossSingle/XUiGridActivityBossSingle")

local tableInsert = table.insert
local CsXTextManager = CS.XTextManager
local CsXScheduleManager = XScheduleManager

local StageCount = 6

function XUiPanelBossSingleMainNormal:OnStart(sectionId, isResume)
    self.SectionId = sectionId
    self:InitButtons()

    self.StageIds = XDataCenter.FubenActivityBossSingleManager.GetSectionStageIdList(self.SectionId)
    self.GridList = {}

    self:InitPanel()

    if not isResume then
        self:PlayAnimation("Start")
    end
end

function XUiPanelBossSingleMainNormal:OnEnable()
    self:PlayAnimationWithMask("DarkEnable")
    self:RefreshPanel()
    self:CheckAndPlayEnableAnimation()
end

function XUiPanelBossSingleMainNormal:OnDisable()
    self:DestroyActivityTimer()
    XRedPointManager.RemoveRedPointEvent(self.StoryRedPoint)
end

--region 初始化
function XUiPanelBossSingleMainNormal:InitButtons()
    self.BtnBack.CallBack = handler(self.Parent, self.Parent.Close)
    
    self.BtnMainUi.CallBack = XLuaUiManager.RunMain
    
    self.BtnTreasure.CallBack = handler(self, self.OnBtnTreasureClick)
end

function XUiPanelBossSingleMainNormal:InitPanel()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    --不显示描述按钮
    self.BtnActDesc.gameObject:SetActiveEx(false)
    --初始化选项卡
    self:InitStageCapter()
    self:CreateActivityTimer()
    self:InitStoryInfo()
    --标记首次进入
    XDataCenter.FubenActivityBossSingleManager.MarkFirstPlay()
end

--初始化副本选择卡,选择卡是定死的，不使用滑动条
function XUiPanelBossSingleMainNormal:InitStageCapter()
    self.ChapterGrids = {}
    
    for i = 1, StageCount do
        if  i > #self.StageIds then
            if self["UiActivityBossSingleGridStage"..i] then
                self["UiActivityBossSingleGridStage" .. i].transform.parent.gameObject:SetActiveEx(false)
            end
        else
            local stageGrid =  self["UiActivityBossSingleGridStage"..i]
            if stageGrid then
                local chapterGrid = XUiGridActivityBossSingle.New(stageGrid, self)
                chapterGrid:Open()
                tableInsert(self.ChapterGrids, chapterGrid)
            end
        end
    end
end

--初始化左下角故事入口
function XUiPanelBossSingleMainNormal:InitStoryInfo()
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

--endregion

--region 界面刷新
function XUiPanelBossSingleMainNormal:RefreshPanel()
    self:RefreshSchedule()
    self:RefreshStoryInfo()
    --统一进行刷新,根据stageId
    for gridIndex = 1, #self.ChapterGrids do
        self.ChapterGrids[gridIndex]:Refresh(self.StageIds[gridIndex], gridIndex)
    end
end

--刷新收集进度条显示
function XUiPanelBossSingleMainNormal:RefreshSchedule()
    local curStarsCount = XDataCenter.FubenActivityBossSingleManager.GetCurStarsCount()
    local totalStarsCount = XDataCenter.FubenActivityBossSingleManager.GetAllStarsCount()
    if totalStarsCount ~= 0 then
        self.ImgSchedule.fillAmount = curStarsCount / totalStarsCount
    end

    self.TxtSchedule.text = CsXTextManager.GetText("ActivityBossSingleSchedule", curStarsCount, totalStarsCount)
    
    --红点
    local isShowRedPoint = XDataCenter.FubenActivityBossSingleManager.CheckRedPoint()
    self.BtnTreasure:ShowReddot(isShowRedPoint)
end

--刷新左下角故事入口信息
function XUiPanelBossSingleMainNormal:RefreshStoryInfo()
    if self.StoryRedPoint then
        XRedPointManager.Check(self.StoryRedPoint)
    end
end

--检查并播放界面启动动画 根据情况播放关卡解锁动画
function XUiPanelBossSingleMainNormal:CheckAndPlayEnableAnimation()
    local playStage = XDataCenter.FubenActivityBossSingleManager.GetNeedPlayUnlockAnimeStage()
    if playStage == -1 then
        return end
    --播放动画

    if not XTool.IsTableEmpty(self.ChapterGrids) then
        for i, v in pairs(self.ChapterGrids) do
            if v.Index == playStage then
                v:PlayAnimation("Unlock")
                XDataCenter.FubenActivityBossSingleManager.OnStageUnlockAnimePlayed()
                break
            end
        end
    end
    
end

--endregion

--region 事件回调

function XUiPanelBossSingleMainNormal:OnBtnTreasureClick()
    XLuaUiManager.Open("UiActivityBossSingleReward", self.SectionId, function()
        self:RefreshSchedule()
    end)
end

function XUiPanelBossSingleMainNormal:OnBtnStoryClick()
    XLuaUiManager.Open("UiActivityBossSingleStory")
end
--endregion

--region 定时器
function XUiPanelBossSingleMainNormal:CreateActivityTimer()
    self:DestroyActivityTimer()

    local time = XTime.GetServerNowTimestamp()
    local fightEndTime = XDataCenter.FubenActivityBossSingleManager.GetFightEndTime()
    local activityEndTime = XDataCenter.FubenActivityBossSingleManager.GetActivityEndTime()

    if XDataCenter.FubenActivityBossSingleManager.IsStatusEqualFightEnd() then
        self.TxtLeftTime.text = XUiHelper.GetTime(activityEndTime - time, XUiHelper.TimeFormatType.ACTIVITY)
        if self.TxtLeftTimeMirror then
            self.TxtLeftTimeMirror.text = XUiHelper.GetTime(activityEndTime - time, XUiHelper.TimeFormatType.ACTIVITY)
        end
    else
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
                self.TxtLeftTime.text = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
                if self.TxtLeftTimeMirror then
                    self.TxtLeftTimeMirror.text = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
                end
            end
        else
            local leftTime = fightEndTime - time
            if leftTime > 0 then
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

function XUiPanelBossSingleMainNormal:DestroyActivityTimer()
    if self.ActivityTimer then
        CsXScheduleManager.UnSchedule(self.ActivityTimer)
        self.ActivityTimer = nil
    end
end
--endregion

return XUiPanelBossSingleMainNormal
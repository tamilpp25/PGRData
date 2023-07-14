local XUiFubenFashionStory = XLuaUiManager.Register(XLuaUi, "UiFubenFashionStory")

local XUiFashionStoryChapter = require("XUi/XUiFubenFashionStory/XUiFashionStoryChapter")
local XUiGridFashionStoryTrial = require("XUi/XUiFubenFashionStory/XUiGridFashionStoryTrial")

local FIGHT_DETAIL = "UiFashionStoryStageFightDetail"
local STORY_DETAIL = "UiFashionStoryStageStoryDetail"
local TRIAL_DETAIL = "UiFashionStoryStageTrialDetail"

local CurrentSchedule

function XUiFubenFashionStory:OnAwake()
    self.BtnSkipList = {}
    self.TimerFunctions = {}
    self.MoveToLast = true

    self:InitComponent()
    self:AddListener()
end

function XUiFubenFashionStory:OnStart(activityId,trialStageId)
    self.TrialStageId = trialStageId
    self:LoadActivity(activityId)
end

function XUiFubenFashionStory:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_FASHION_STORY_CHAPTER_REFRESH, self.Refresh, self)
    XEventManager.AddEventListener(XEventId.EVENT_FASHION_STORY_TRIAL_REFRESH, self.RefreshTrial, self)

    XEventManager.AddEventListener(XEventId.EVENT_FASHION_STORY_OPEN_STAGE_DETAIL, self.OpenStageDetail, self)
    XEventManager.AddEventListener(XEventId.EVENT_FASHION_STORY_CLOSE_STAGE_DETAIL, self.CloseStageDetail, self)
    XEventManager.AddEventListener(XEventId.EVENT_FASHION_STORY_OPEN_TRIAL_DETAIL, self.OpenTrialDetail, self)

    self:Refresh(self.MoveToLast)
    self:RefreshLeftTime()
end

function XUiFubenFashionStory:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_FASHION_STORY_CHAPTER_REFRESH, self.Refresh, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FASHION_STORY_TRIAL_REFRESH, self.RefreshTrial, self)

    XEventManager.RemoveEventListener(XEventId.EVENT_FASHION_STORY_OPEN_STAGE_DETAIL, self.OpenStageDetail, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FASHION_STORY_CLOSE_STAGE_DETAIL, self.CloseStageDetail, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FASHION_STORY_OPEN_TRIAL_DETAIL, self.OpenTrialDetail, self)

    self:RemoveTimerFun(self.ActivityId)

    -- 首次打开界面、通关关卡时才会自动移动到最后一关
    self.MoveToLast = false
end

function XUiFubenFashionStory:OnDestroy()
    self.Type = nil
    self.Mode = nil
    self.ActivityId = nil
    self:DestroyTimer()
end

function XUiFubenFashionStory:InitComponent()
    self.BtnCloseDetail.gameObject:SetActiveEx(false)
    self.GridTrial.gameObject:SetActiveEx(false)

    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset,
            XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)

    -- 保存章节关的跳转按钮
    local index = 1
    while true do
        local btnSkip = self[string.format("BtnSkip%s", tostring(index))]
        if not btnSkip then
            break
        end
        btnSkip = btnSkip.transform:GetComponent("Button")
        self.BtnSkipList[index] = btnSkip
        index = index + 1
    end

    self:InitDynamicTable()
    self:StartTimer()
end

function XUiFubenFashionStory:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTrialList)
    self.DynamicTable:SetProxy(XUiGridFashionStoryTrial, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiFubenFashionStory:AddListener()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
    self.BtnCloseDetail.CallBack = function()
        self:CloseStageDetail()
    end
end

function XUiFubenFashionStory:OnBtnBackClick()
    if XLuaUiManager.IsUiShow(FIGHT_DETAIL) or XLuaUiManager.IsUiShow(STORY_DETAIL) then
        self:CloseStageDetail()
    else
        if self.Mode == XFashionStoryConfigs.Mode.Chapter then
            self:OnBtnSwitchClick(XFashionStoryConfigs.Mode.Trial)
        else
            self:Close()
        end
    end

end

function XUiFubenFashionStory:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiFubenFashionStory:OnBtnSwitchClick(mode)
    self:SetMode(mode)
    self:Refresh(false)
end


------------------------------------------------------初始化加载----------------------------------------------------------

---
--- 加载 'activityId' 活动，并设置类型与初始模式
function XUiFubenFashionStory:LoadActivity(activityId)
    self.ActivityId = activityId

    local type = XDataCenter.FashionStoryManager.GetType(activityId)
    self:SetType(type)

    local initMode
    if type == XFashionStoryConfigs.Type.OnlyTrial or type == XFashionStoryConfigs.Type.Both then
        initMode = self.Mode or XFashionStoryConfigs.Mode.Trial
    elseif type == XFashionStoryConfigs.Type.OnlyChapter then
        initMode = self.Mode or XFashionStoryConfigs.Mode.Chapter
    else
        XLog.Error(string.format("XUiFubenFashionStory.LoadActivity函数错误，没有类型：%d的处理逻辑", type))
        return
    end

    self:LoadChapter()
    self:SetMode(initMode)
end

---
--- 设置活动类型，并设置模式切换按钮的显隐
function XUiFubenFashionStory:SetType(type)
    self.Type = type
    local isBothMode = type == XFashionStoryConfigs.Type.Both
    local isOnlyTrial = type == XFashionStoryConfigs.Type.OnlyTrial
    self.PanelTrialLeftTime.gameObject:SetActiveEx(not isOnlyTrial)
end

---
--- 加载章节关
function XUiFubenFashionStory:LoadChapter()
    -- 处理跳转按钮
    local skipList = XFashionStoryConfigs.GetSkipIdList(self.ActivityId)
    if not XTool.IsTableEmpty(skipList) then
        for i, skipId in ipairs(skipList) do

            -- 是否有对应的跳转按钮
            local btn = self.BtnSkipList[i]
            if not btn then
                XLog.Error(string.format("XUiFubenFashionStory.LoadChapter函数错误，FashionStory:%s 预制界面的跳转按钮不足，第%s个跳转:%s 与后面配置的跳转无法生效",
                        tostring(self.ActivityId), tostring(i), tostring(skipId)))
                break
            end

            -- 添加跳转逻辑
            btn.CallBack = function()
                XFunctionManager.SkipInterface(skipId)
            end
            btn.gameObject:SetActiveEx(true)
            btn:SetName(XFunctionConfig.GetExplain(skipId))
        end
    end

    -- 隐藏多余的跳转按钮
    if #self.BtnSkipList > #skipList then
        for i = #skipList + 1, #self.BtnSkipList do
            self.BtnSkipList[i].gameObject:SetActiveEx(false)
        end
    end

    -- 预制体
    local prefabPath = XFashionStoryConfigs.GetChapterPrefab(self.ActivityId)
    if prefabPath then
        local go = self.PanelChapterContent:LoadPrefab(prefabPath)
        self.ChapterContent = XUiFashionStoryChapter.New(go, self.ActivityId)
    end
end


------------------------------------------------------切换模式------------------------------------------------------------

---
--- 切换到 'mode' 模式，显示对应模式的面板
function XUiFubenFashionStory:SetMode(mode)
    if (self.Type == XFashionStoryConfigs.Type.OnlyChapter and mode == XFashionStoryConfigs.Mode.Trial)
            or (self.Type == XFashionStoryConfigs.Type.OnlyTrial and mode == XFashionStoryConfigs.Mode.Chapter) then
        XLog.Error(string.format("XUiFubenFashionStory.SetMode函数错误，Type：%d与Mode：%s冲突", self.Type, mode))
        return
    end
    self.Mode = mode
    self:ShowPanelByMode()
end

---
--- 根据Self.Mode显示对应的面板
function XUiFubenFashionStory:ShowPanelByMode()
    local bg
    if self.Mode == XFashionStoryConfigs.Mode.Chapter then
        self.PanelChapter.gameObject:SetActiveEx(true)
        self.PanelTrial.gameObject:SetActiveEx(false)
        bg = XFashionStoryConfigs.GetChapterBg(self.ActivityId)
    elseif self.Mode == XFashionStoryConfigs.Mode.Trial then
        self.PanelChapter.gameObject:SetActiveEx(false)
        self.PanelTrial.gameObject:SetActiveEx(true)
        bg = XFashionStoryConfigs.GetTrialBg(self.ActivityId)
    else
        XLog.Error(string.format("XUiFubenFashionStory.ShowPanelByMode函数错误，没有模式：%d的处理逻辑", self.Mode))
        return
    end

    if bg then
        self.RImgFestivalBg:SetRawImage(bg)
    end
end


-------------------------------------------------------界面刷新-----------------------------------------------------------

---
--- 根据self.Mode刷新对应面板， 'moveToLast' 是否移动到最后一关
function XUiFubenFashionStory:Refresh(moveToLast)
    if self.Mode == XFashionStoryConfigs.Mode.Chapter then
        -- 通关进度
        local passNum, totalNum = XDataCenter.FashionStoryManager.GetChapterProgress(self.ActivityId)
        self.TxtCurProgress.text = passNum
        self.TxtTotalProgress.text = totalNum
        -- 章节预制
        if self.ChapterContent then
            self.ChapterContent:Refresh(moveToLast)
        end
    elseif self.Mode == XFashionStoryConfigs.Mode.Trial then
        self:RefreshTrial()
    else
        XLog.Error(string.format("XUiFubenFashionStory.Refresh函数错误，没有模式：%s的处理逻辑", tostring(self.Mode)))
        return
    end
end

---
--- 刷新试玩关
function XUiFubenFashionStory:RefreshTrial()
    self.DataSource = XDataCenter.FashionStoryManager.GetActiveTrialStage(self.ActivityId)

    if XDataCenter.FashionStoryManager.IsStoryInTime(self.ActivityId) then
        -- 剧情模式处于开放时间，插入模式入口
        table.insert(self.DataSource, 1, XFashionStoryConfigs.StoryEntranceId)
    end

    for i, v in pairs(self.DataSource) do
        if self.TrialStageId == v then
            self.SelectIndex = i
			break
        end
    end
    self.DynamicTable:SetDataSource(self.DataSource)
    self.DynamicTable:ReloadDataSync(self.SelectIndex)
end

---
--- 动态列表事件
function XUiFubenFashionStory:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self.DataSource[index] == XFashionStoryConfigs.StoryEntranceId then
            grid:Refresh(self.DataSource[index], self.ActivityId, function()
                self:OnBtnSwitchClick(XFashionStoryConfigs.Mode.Chapter)
                self:PlayAnimation("PanelChapterEnable")
            end)
        else
            grid:Refresh(self.DataSource[index])
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        grid:OnClick()
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:OnRecycle()
    end
end

---
--- 刷新活动剩余时间
function XUiFubenFashionStory:RefreshLeftTime()
    local leftTimeStamp = XDataCenter.FashionStoryManager.GetLeftTimeStamp(self.ActivityId)
    local refreshFunc = function()
        leftTimeStamp = leftTimeStamp > 0 and leftTimeStamp or 0
        local timeStr = XUiHelper.GetTime(leftTimeStamp, XUiHelper.TimeFormatType.ACTIVITY)
        if self.TxtTrialLeftTime and self.TxtChapterLeftTime then
            self.TxtTrialLeftTime.text = timeStr
            self.TxtChapterLeftTime.text = timeStr
        end

        if leftTimeStamp <= 0 then
            XUiManager.TipMsg(CSXTextManagerGetText("FashionStoryActivityEnd"))
            self:RemoveTimerFun(self.ActivityId)
            self:Close()
        end
    end
    refreshFunc()

    -- 活动已结束
    if leftTimeStamp <= 0 then
        return
    end
    self:RegisterTimerFun(self.ActivityId, function()
        leftTimeStamp = leftTimeStamp - 1
        refreshFunc()
    end)
end


-------------------------------------------------------计时器------------------------------------------------------------

function XUiFubenFashionStory:StartTimer()
    self:DestroyTimer()
    CurrentSchedule = XScheduleManager.ScheduleForever(function()
        self:UpdateTimer()
    end, 1000)
end

function XUiFubenFashionStory:UpdateTimer()
    if next(self.TimerFunctions) then
        for _, timerFun in pairs(self.TimerFunctions) do
            if timerFun then
                timerFun()
            end
        end
    end
end

function XUiFubenFashionStory:RegisterTimerFun(id, fun)
    self.TimerFunctions[id] = fun
end

function XUiFubenFashionStory:RemoveTimerFun(id)
    self.TimerFunctions[id] = nil
end

function XUiFubenFashionStory:DestroyTimer()
    if CurrentSchedule then
        XScheduleManager.UnSchedule(CurrentSchedule)
        CurrentSchedule = nil
        self.TimerFunctions = {}
    end
end


-------------------------------------------------------关卡相关-----------------------------------------------------------

---
--- 打开章节关卡详情
function XUiFubenFashionStory:OpenStageDetail(stageId)
    -- 选择关卡
    self.ChapterContent:SelectStage(stageId)

    local detailType
    local stageType = XFubenConfigs.GetStageType(stageId)
    if stageType == XFubenConfigs.STAGETYPE_FIGHT or stageType == XFubenConfigs.STAGETYPE_FIGHTEGG
            or stageType == XFubenConfigs.STAGETYPE_COMMON then
        detailType = FIGHT_DETAIL
    elseif stageType == XFubenConfigs.STAGETYPE_STORY or stageType == XFubenConfigs.STAGETYPE_STORYEGG then
        detailType = STORY_DETAIL
    else
        XLog.Error(string.format("XUiPartnerTeachingChapter.OpenStageDetail函数错误，没有对应StageType的处理逻辑，关卡：%s，StageType：%s",
                stageId, stageType))
        return
    end
    self:OpenOneChildUi(detailType, handler(self, self.Close))
    self:FindChildUiObj(detailType):Refresh(stageId, self.ActivityId)
    self.BtnCloseDetail.gameObject:SetActiveEx(true)
end

---
--- 关闭章节关卡详情
function XUiFubenFashionStory:CloseStageDetail()
    -- 取消关卡选择
    self.ChapterContent:CancelSelectStage()

    if XLuaUiManager.IsUiShow(FIGHT_DETAIL) then
        self:FindChildUiObj(FIGHT_DETAIL):CloseDetailWithAnimation()
    end
    if XLuaUiManager.IsUiShow(STORY_DETAIL) then
        self:FindChildUiObj(STORY_DETAIL):CloseDetailWithAnimation()
    end

    self.BtnCloseDetail.gameObject:SetActiveEx(false)
end

---
--- 打开试玩关卡详情
function XUiFubenFashionStory:OpenTrialDetail(stageId)
    self:OpenOneChildUi(TRIAL_DETAIL, handler(self, self.Close),handler(self,self.CloseTrialDetailCb))
    self:FindChildUiObj(TRIAL_DETAIL):Refresh(self.ActivityId, stageId)
    self.PanelEffect.gameObject:SetActiveEx(false)
end

function XUiFubenFashionStory:CloseTrialDetailCb()
    self.PanelEffect.gameObject:SetActiveEx(true)
end

function XUiFubenFashionStory:OnReleaseInst()
    return self.Mode
end

function XUiFubenFashionStory:OnResume(mode)
    self.Mode = mode
end
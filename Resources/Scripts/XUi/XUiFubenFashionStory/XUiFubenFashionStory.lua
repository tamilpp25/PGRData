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

    -- ?????????????????????????????????????????????????????????????????????
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

    -- ??????????????????????????????
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


------------------------------------------------------???????????????----------------------------------------------------------

---
--- ?????? 'activityId' ???????????????????????????????????????
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
        XLog.Error(string.format("XUiFubenFashionStory.LoadActivity??????????????????????????????%d???????????????", type))
        return
    end

    self:LoadChapter()
    self:SetMode(initMode)
end

---
--- ?????????????????????????????????????????????????????????
function XUiFubenFashionStory:SetType(type)
    self.Type = type
    local isBothMode = type == XFashionStoryConfigs.Type.Both
    local isOnlyTrial = type == XFashionStoryConfigs.Type.OnlyTrial
    self.PanelTrialLeftTime.gameObject:SetActiveEx(not isOnlyTrial)
end

---
--- ???????????????
function XUiFubenFashionStory:LoadChapter()
    -- ??????????????????
    local skipList = XFashionStoryConfigs.GetSkipIdList(self.ActivityId)
    if not XTool.IsTableEmpty(skipList) then
        for i, skipId in ipairs(skipList) do

            -- ??????????????????????????????
            local btn = self.BtnSkipList[i]
            if not btn then
                XLog.Error(string.format("XUiFubenFashionStory.LoadChapter???????????????FashionStory:%s ???????????????????????????????????????%s?????????:%s ????????????????????????????????????",
                        tostring(self.ActivityId), tostring(i), tostring(skipId)))
                break
            end

            -- ??????????????????
            btn.CallBack = function()
                XFunctionManager.SkipInterface(skipId)
            end
            btn.gameObject:SetActiveEx(true)
            btn:SetName(XFunctionConfig.GetExplain(skipId))
        end
    end

    -- ???????????????????????????
    if #self.BtnSkipList > #skipList then
        for i = #skipList + 1, #self.BtnSkipList do
            self.BtnSkipList[i].gameObject:SetActiveEx(false)
        end
    end

    -- ?????????
    local prefabPath = XFashionStoryConfigs.GetChapterPrefab(self.ActivityId)
    if prefabPath then
        local go = self.PanelChapterContent:LoadPrefab(prefabPath)
        self.ChapterContent = XUiFashionStoryChapter.New(go, self.ActivityId)
    end
end


------------------------------------------------------????????????------------------------------------------------------------

---
--- ????????? 'mode' ????????????????????????????????????
function XUiFubenFashionStory:SetMode(mode)
    if (self.Type == XFashionStoryConfigs.Type.OnlyChapter and mode == XFashionStoryConfigs.Mode.Trial)
            or (self.Type == XFashionStoryConfigs.Type.OnlyTrial and mode == XFashionStoryConfigs.Mode.Chapter) then
        XLog.Error(string.format("XUiFubenFashionStory.SetMode???????????????Type???%d???Mode???%s??????", self.Type, mode))
        return
    end
    self.Mode = mode
    self:ShowPanelByMode()
end

---
--- ??????Self.Mode?????????????????????
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
        XLog.Error(string.format("XUiFubenFashionStory.ShowPanelByMode??????????????????????????????%d???????????????", self.Mode))
        return
    end

    if bg then
        self.RImgFestivalBg:SetRawImage(bg)
    end
end


-------------------------------------------------------????????????-----------------------------------------------------------

---
--- ??????self.Mode????????????????????? 'moveToLast' ???????????????????????????
function XUiFubenFashionStory:Refresh(moveToLast)
    if self.Mode == XFashionStoryConfigs.Mode.Chapter then
        -- ????????????
        local passNum, totalNum = XDataCenter.FashionStoryManager.GetChapterProgress(self.ActivityId)
        self.TxtCurProgress.text = passNum
        self.TxtTotalProgress.text = totalNum
        -- ????????????
        if self.ChapterContent then
            self.ChapterContent:Refresh(moveToLast)
        end
    elseif self.Mode == XFashionStoryConfigs.Mode.Trial then
        self:RefreshTrial()
    else
        XLog.Error(string.format("XUiFubenFashionStory.Refresh??????????????????????????????%s???????????????", tostring(self.Mode)))
        return
    end
end

---
--- ???????????????
function XUiFubenFashionStory:RefreshTrial()
    self.DataSource = XDataCenter.FashionStoryManager.GetActiveTrialStage(self.ActivityId)

    if XDataCenter.FashionStoryManager.IsStoryInTime(self.ActivityId) then
        -- ???????????????????????????????????????????????????
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
--- ??????????????????
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
--- ????????????????????????
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

    -- ???????????????
    if leftTimeStamp <= 0 then
        return
    end
    self:RegisterTimerFun(self.ActivityId, function()
        leftTimeStamp = leftTimeStamp - 1
        refreshFunc()
    end)
end


-------------------------------------------------------?????????------------------------------------------------------------

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


-------------------------------------------------------????????????-----------------------------------------------------------

---
--- ????????????????????????
function XUiFubenFashionStory:OpenStageDetail(stageId)
    -- ????????????
    self.ChapterContent:SelectStage(stageId)

    local detailType
    local stageType = XFubenConfigs.GetStageType(stageId)
    if stageType == XFubenConfigs.STAGETYPE_FIGHT or stageType == XFubenConfigs.STAGETYPE_FIGHTEGG
            or stageType == XFubenConfigs.STAGETYPE_COMMON then
        detailType = FIGHT_DETAIL
    elseif stageType == XFubenConfigs.STAGETYPE_STORY or stageType == XFubenConfigs.STAGETYPE_STORYEGG then
        detailType = STORY_DETAIL
    else
        XLog.Error(string.format("XUiPartnerTeachingChapter.OpenStageDetail???????????????????????????StageType???????????????????????????%s???StageType???%s",
                stageId, stageType))
        return
    end
    self:OpenOneChildUi(detailType, handler(self, self.Close))
    self:FindChildUiObj(detailType):Refresh(stageId, self.ActivityId)
    self.BtnCloseDetail.gameObject:SetActiveEx(true)
end

---
--- ????????????????????????
function XUiFubenFashionStory:CloseStageDetail()
    -- ??????????????????
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
--- ????????????????????????
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
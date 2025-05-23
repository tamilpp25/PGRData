local CSXTextManagerGetText = CS.XTextManager.GetText
local DefaultType = 1
local tableInsert = table.insert
local BtnActivityEntryMaxCount = 4
local CsXUGuiDragProxy = CS.XUguiDragProxy

local MinDragYDistance = CS.XGame.ClientConfig:GetFloat("MinDragYDistance")

local XUiMainPanelBase = require("XUi/XUiMain/XUiMainPanelBase")
---@class XUiMainRightMid:XUiMainPanelBase
local XUiMainRightMid = XClass(XUiMainPanelBase, "XUiMainRightMid")

local SubPanelState = "SubPanelState"

--主界面会频繁打开，采用常量缓存
local RedPointConditionGroup = {
    --任务
    Task = { 
        XRedPointConditions.Types.CONDITION_MAIN_TASK 
    },
    --宿舍
    Dorm = {
        XRedPointConditions.Types.CONDITION_DORM_RED
    },
    --公会
    Guild = {
        XRedPointConditions.Types.CONDITION_GUILD_APPLYLIST,
        XRedPointConditions.Types.CONDITION_GUILD_ACTIVEGIFT,
        XRedPointConditions.Types.CONDITION_GUILD_NEWS,
        XRedPointConditions.Types.CONDITION_GUILDBOSS_BOSSHP,
        XRedPointConditions.Types.CONDITION_GUILDBOSS_SCORE,
        XRedPointConditions.Types.CONDITION_GUILDWAR_Main,
        XRedPointConditions.Types.CONDITION_GUILD_SIGN_REWARD,
        --XRedPointConditions.Types.CONDITION_GUILDWAR_SUPPLY,
        --XRedPointConditions.Types.CONDITION_GUILDWAR_ASSISTANT,
    },
    --辅助机
    Partner = {
        XRedPointConditions.Types.CONDITION_PARTNER_COMPOSE_RED,
        XRedPointConditions.Types.CONDITION_PARTNER_NEWSKILL_RED,
    },
    --成员
    Member = {
        XRedPointConditions.Types.CONDITION_MAIN_MEMBER
    },
    --充值采购
    Recharge = {
        XRedPointConditions.Types.CONDITION_PURCHASE_RED
    },
    --背包
    Bag = {
        -- XRedPointConditions.Types.CONDITION_ITEM_COLLECTION_ENTRANCE
    },
    --展开按钮
    Open = {
        XRedPointConditions.Types.CONDITION_DORM_RED,
        XRedPointConditions.Types.CONDITION_GUILD_APPLYLIST,
        XRedPointConditions.Types.CONDITION_GUILD_ACTIVEGIFT,
        XRedPointConditions.Types.CONDITION_GUILD_NEWS,
        XRedPointConditions.Types.CONDITION_GUILDBOSS_BOSSHP,
        XRedPointConditions.Types.CONDITION_GUILDBOSS_SCORE,
        XRedPointConditions.Types.CONDITION_GUILDWAR_TASK,
        XRedPointConditions.Types.CONDITION_GUILDWAR_SUPPLY,
        XRedPointConditions.Types.CONDITION_GUILDWAR_ASSISTANT,
        XRedPointConditions.Types.CONDITION_GUILD_SIGN_REWARD,
        XRedPointConditions.Types.CONDITION_PARTNER_COMPOSE_RED,
        XRedPointConditions.Types.CONDITION_PARTNER_NEWSKILL_RED,
        -- XRedPointConditions.Types.CONDITION_ITEM_COLLECTION_ENTRANCE,
    },
}

function XUiMainRightMid:OnStart(rootUi)
    self.RootUi = rootUi
    
    self.IsShowSubPanel = false
    -- self.Transform = rootUi.PanelRightMid.gameObject.transform
    -- XTool.InitUiObject(self)
    --ClickEvent
    self.BtnFight.CallBack = function() self:OnBtnFight() end
    self.BtnTask.CallBack = function() self:OnBtnTask() end
    self.BtnBuilding.CallBack = function() self:OnBtnBuilding() end
    self.BtnReward.CallBack = function() self:OnBtnReward() end
    --self.BtnSkipTask.CallBack = function() self:OnBtnSkipTask() end
    self.BtnActivityBrief.CallBack = function() self:OnBtnActivityBrief() end
    self.BtnPartner.CallBack = function() self:OnBtnPartner() end
    self.BtnGuild.CallBack = function() self:OnBtnGuildClick() end
    self.BtnOpen.CallBack = function() self:OnBtnOpenClick() end
    self.BtnClose.CallBack = function() self:OnBtnCloseClick() end
    self.BtnMember.CallBack = function() self:OnBtnMember() end
    self.BtnRecharge.CallBack = function() self:OnBtnRecharge() end
    self.BtnEquipGuide.CallBack = function() XDataCenter.EquipGuideManager.OpenEquipGuideDetail() end
    self.BtnBag.CallBack = function() self:OnBtnBag() end
    self.BtnStore.CallBack = function() self:OnBtnStore() end
    
    self.BtnGuild.gameObject:SetActiveEx(true)

    if XUiManager.IsHideFunc then
        self.BtnActivityBrief.gameObject:SetActiveEx(false)
        self.BtnGuild.gameObject:SetActiveEx(false)
        self.BtnBuilding.gameObject:SetActiveEx(false)
        self.BtnReward.gameObject:SetActiveEx(false)
    end

    --Filter
    self:CheckFilterFunctions()
    self:InitBtnActivityEntry()
    self:InitDragProxy()
end

function XUiMainRightMid:OnEnable()
    
    -- 充值红点
    XDataCenter.PurchaseManager.LBInfoDataReq()
    XRedPointManager.CheckByNode(self.BtnMember.ReddotObj)
    
    self:CheckRedPoint()
    
    XEventManager.AddEventListener(XEventId.EVENT_DRAW_ACTIVITYCOUNT_CHANGE, self.CheckDrawTag, self)
    XEventManager.AddEventListener(XEventId.EVENT_EQUIP_GUIDE_REFRESH_TARGET_STATE, self.OnCheckMemberTag, self)
    XEventManager.AddEventListener(XEventId.EVENT_DAYLY_REFESH_RECHARGE_BTN, self.OnCheckRechargeNews, self)
    
    self:RefreshFubenProgress()
    self:UpdateBtnActivityBrief()
    self:UpdateBtnActivityEntry()
    self:CheckDrawTag()

    local livingQuarters = XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Dorm)
    local drawCard = XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.DrawCard)
    local partner = XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Partner)
    --初始化是否锁定
    self.BtnBuilding:SetDisable(not livingQuarters)
    self.BtnReward:SetDisable(not drawCard)
    self.BtnPartner:SetDisable(not partner)

    self:CheckGuildOpen()
    XDataCenter.DormManager.StartDormRedTimer() -- 优化

    self:CheckStartActivityEntryTimer()
    self:CheckBtnActivityEntryRedPoint()
    --免费抽卡红点需要先获取抽卡信息 然后根据抽卡信息的时间去判断当前是否需要显示红点
    if drawCard then
        -- 有功能开放标记时才显示免费标签
        if XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.DrawCard) then
            XDataCenter.DrawManager.GetDrawGroupList(function()
                self:AddRedPointEvent(self.BtnReward, self.OnCheckDrawFreeTicketTag, self, { XRedPointConditions.Types.CONDITION_DRAW_FREE_TAG, XRedPointConditions.Types.CONDITION_DEVILMAYCRY_CAN_RECEIVE_CHARACTER })
            end)
        end
    else
        self:OnCheckDrawFreeTicketTag(-1)
    end
    
    self:CheckDevilMayCryTag()
    self:OnCheckMemberTag()
    self:OnCheckRechargeNews()
    self:OnCheckStore()
    self:RefreshSubPanelState(self:GetSubPanelState())
end

function XUiMainRightMid:CheckRedPoint() 
    self:AddRedPointEvent(self.BtnTask.ReddotObj, self.OnCheckTaskNews, self, RedPointConditionGroup.Task)
    self:AddRedPointEvent(self.BtnBuilding.ReddotObj, self.OnCheckBuildingNews, self, RedPointConditionGroup.Dorm)
    self:AddRedPointEvent(self.ImgBuldingRedDot, self.OnCheckGuildRedPoint, self, RedPointConditionGroup.Guild)

    self:AddRedPointEvent(self.BtnPartner, self.OnCheckPartnerRedPoint, self, RedPointConditionGroup.Partner)

    self:AddRedPointEvent(self.BtnMember.ReddotObj, self.OnCheckMemberNews, self, RedPointConditionGroup.Member)
    self:AddRedPointEvent(self.BtnRecharge.ReddotObj, self.OnCheckRechargeNews, self, RedPointConditionGroup.Recharge)

    self:AddRedPointEvent(self.BtnBag, self.OnCheckBagNews, self, RedPointConditionGroup.Bag)

    self:AddRedPointEvent(self.BtnOpen, self.OnCheckOpenRedPoint, self, RedPointConditionGroup.Open)
end

function XUiMainRightMid:CheckGuildOpen()
    if XUiManager.IsHideFunc then return end

    local guildOpen = XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Guild)
    self.BtnGuild:SetDisable(not guildOpen)

    -- PS: 这里因为删除XFunctionManager.IsDuringTime方法，因此直接设置为true
    local guildIsDuringTime = true -- XFunctionManager.IsDuringTime(XFunctionManager.FunctionName.Guild)
    self.BtnGuild.gameObject:SetActiveEx(guildIsDuringTime)
end

function XUiMainRightMid:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_DRAW_ACTIVITYCOUNT_CHANGE, self.CheckDrawTag, self)
    --XEventManager.RemoveEventListener(XEventId.EVENT_TASKFORCE_INFO_NOTIFY, self.SetupDispatch, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_EQUIP_GUIDE_REFRESH_TARGET_STATE, self.OnCheckMemberTag, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DAYLY_REFESH_RECHARGE_BTN, self.OnCheckRechargeNews, self)
    

    if self.guildTimer then
        XScheduleManager.UnSchedule(self.guildTimer)
        self.guildTimer = nil
    end
    
    XDataCenter.DormManager.StopDormRedTimer()
    self:StopActivityEntryTimer()
end

function XUiMainRightMid:OnNotify(evt)
    if evt == XEventId.EVENT_TASKFORCE_INFO_NOTIFY then
        --更新派遣
        self:SetupDispatch()
    end
end

function XUiMainRightMid:CheckFilterFunctions()
    self.BtnStore.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.ShopCommon)
    and not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.ShopActive))
    self.BtnBag.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Bag))
    self.BtnRecharge.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Deposit))
    self.BtnMember.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Character))
    self.BtnTask.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Task))
    --self.BtnSkipTask.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.TaskStory))
    if self.BtnSkipTask then
        self.BtnSkipTask.gameObject:SetActiveEx(false)
    end
    self.BtnPartner.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Partner) and not XUiManager.IsHideFunc)
    if not XUiManager.IsHideFunc then
        self.BtnBuilding.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Dorm))
        self.BtnReward.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.DrawCard))
        self.BtnActivityBrief.gameObject:SetActiveEx(not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.ActivityBrief))
    end
end

--副本入口
function XUiMainRightMid:OnBtnFight()
    local dict = {}
    dict["ui_first_button"] = XGlobalVar.BtnBuriedSpotTypeLevelOne.BtnUiMainBtnFight
    dict["role_level"] = XPlayer.GetLevel()
    CS.XRecord.Record(dict, "200004", "UiOpen")
    if XFubenConfigs.DebugOpenOldMainUi then
        XLuaUiManager.Open("UiFuben")
    else
        XLuaUiManager.Open("UiNewFuben")
    end
end

--任务入口
function XUiMainRightMid:OnBtnTask()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Task) then
        return
    end
    XUiHelper.RecordBuriedSpotTypeLevelOne(XGlobalVar.BtnBuriedSpotTypeLevelOne.BtnUiMainBtnTask)
    XLuaUiManager.Open("UiTask")
end

--任务跳转按钮点击
function XUiMainRightMid:OnBtnSkipTask()
    if not self.ShowTaskId or self.ShowTaskId <= 0 then
        XLuaUiManager.Open("UiTask", XDataCenter.TaskManager.TaskType.Story)
    else
        local taskData = XDataCenter.TaskManager.GetTaskDataById(self.ShowTaskId)
        local needSkip = taskData and taskData.State < XDataCenter.TaskManager.TaskState.Achieved
        if needSkip then
            if XDataCenter.RoomManager.RoomData ~= nil then
                local title = CSXTextManagerGetText("TipTitle")
                local cancelMatchMsg = CSXTextManagerGetText("OnlineInstanceQuitRoom")
                XUiManager.DialogTip(title, cancelMatchMsg, XUiManager.DialogType.Normal, nil, function()
                    XLuaUiManager.RunMain()
                    local skipId = XDataCenter.TaskManager.GetTaskTemplate(self.ShowTaskId).SkipId
                    XFunctionManager.SkipInterface(skipId)
                end)
            else
                local skipId = XDataCenter.TaskManager.GetTaskTemplate(self.ShowTaskId).SkipId
                XFunctionManager.SkipInterface(skipId)
            end
        else
            XLuaUiManager.Open("UiTask", XDataCenter.TaskManager.TaskType.Story)
        end
    end
end

--宿舍入口
function XUiMainRightMid:OnBtnBuilding()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Dorm) then
        return
    end
    XUiHelper.RecordBuriedSpotTypeLevelOne(XGlobalVar.BtnBuriedSpotTypeLevelOne.BtnUiMainBtnBuilding)
    --self.RootUi:ChangeLowPowerState(self.RootUi.LowPowerState.None)
    XHomeDormManager.EnterDorm()
end

--研发入口
function XUiMainRightMid:OnBtnReward()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.DrawCard) then
        return
    end
    XUiHelper.RecordBuriedSpotTypeLevelOne(XGlobalVar.BtnBuriedSpotTypeLevelOne.BtnUiMainBtnDrawMain)
    XDataCenter.DrawManager.MarkActivityDraw()
    XDataCenter.DrawManager.OpenDrawUi(DefaultType)
end

--伙伴入口
function XUiMainRightMid:OnBtnPartner()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Partner) then
        return
    end
    XUiHelper.RecordBuriedSpotTypeLevelOne(XGlobalVar.BtnBuriedSpotTypeLevelOne.BtnUiMainBtnPartner)
    XDataCenter.PartnerManager.OpenUiPartnerMain(false, DefaultType)
end

function XUiMainRightMid:CheckDrawTag()
    self:OnCheckDrawActivityTag(XDataCenter.DrawManager.CheckDrawActivityCount())
end

--副本入口进度更新
function XUiMainRightMid:RefreshFubenProgress()
    -- 主线
    local isClear = self:RefreshMainLineProgress()
    if not isClear then return end

    -- 提审服屏蔽主线外的关卡
    if XUiManager.IsHideFunc then return end
    
    -- 外篇旧闻
    isClear = self:RefreshExtraProgress()
    if not isClear then return end

    -- 主线与外章普通全部完成，据点战未完成时，显示据点战
    if XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.FubenNightmare) then
        local chapterId = XDataCenter.BfrtManager.GetActiveChapterId()
        if chapterId then
            local passCount = XDataCenter.BfrtManager.GetChapterPassCount(chapterId)
            local stageCount = XDataCenter.BfrtManager.GetChapterGroupCount(chapterId)
            if passCount < stageCount then
                local chapterCfg = XDataCenter.BfrtManager.GetChapterCfg(chapterId)
                self.TxtCurChapter.text = chapterCfg.ChapterEn
                self.TxtCurDifficult.text = CSXTextManagerGetText("BfrtStateNotPassed")
                return
            end
        end
    end
end

-- 刷新主线进度
function XUiMainRightMid:RefreshMainLineProgress()
    local isFindViewModel = false
    local isLastChapter = false -- 是否是最后一章
    local chapterViewModel = nil

    local groupCfgs = XDataCenter.FubenMainLineManager:ExGetChapterGroupConfigs()
    for i, config in ipairs(groupCfgs) do
        local chapterViewModels = XDataCenter.FubenMainLineManager:ExGetChapterViewModels(config.Id, XDataCenter.FubenManager.DifficultNormal)
        for j, viewModel in ipairs(chapterViewModels) do
            -- 遍历到上锁，直接结束
            if viewModel:GetIsLocked() then
                isFindViewModel = true
                break

            -- 解锁
            elseif not viewModel:GetIsLocked() then
                chapterViewModel = viewModel
                isLastChapter = i == #groupCfgs and j == #chapterViewModels
                if not viewModel:CheckIsPassed() then
                    isFindViewModel = true
                    break
                end
            end
        end

        if isFindViewModel then
            break
        end
    end

    -- 刷新主线进度
    local progress, difficult = chapterViewModel:GetUiMainProgress()
    if not progress then
        local extralData = chapterViewModel:GetExtralData()
        if extralData.MainId == XDataCenter.FubenMainLineManager.TRPGChapterId then
            progress = chapterViewModel:GetName()
        else
            progress = tostring(extralData.OrderId) .. "-" .. tostring(chapterViewModel:GetNormalChapterNextStageOrderId())
        end
        difficult = CSXTextManagerGetText("DifficultMode") .. CSXTextManagerGetText("Difficult" .. XDataCenter.FubenManager.DifficultNormal)
    end
    self.TxtCurChapter.text = progress
    self.TxtCurDifficult.text = difficult
    
    local isClear = isLastChapter and chapterViewModel:CheckIsPassed()
    return isClear
end

-- 刷新外篇旧闻进度
function XUiMainRightMid:RefreshExtraProgress()
    local clearData = XDataCenter.ExtraChapterManager.GetChapterClearData()
    local extraClear = clearData and clearData.ChapterId and clearData.IsClear and clearData.AllChapterClear
    if not extraClear then
        self.TxtCurChapter.text = clearData.StageTitle .. "-" .. clearData.LastStageOrder
        self.TxtCurDifficult.text = CSXTextManagerGetText("DifficultMode") .. CSXTextManagerGetText("Difficult" .. XDataCenter.FubenManager.DifficultNormal)
    end
    return extraClear
end

function XUiMainRightMid:IsMainLineClear(curChapterOrderId, progressOrder, curStageCount, chapterListTotal)
    if curChapterOrderId == XDataCenter.FubenMainLineManager.TRPGChapterId then
        return XDataCenter.TRPGManager.IsTRPGClear()
    else
        return curChapterOrderId == chapterListTotal and progressOrder == curStageCount
    end
end

-------------活动简介 Begin-------------------
function XUiMainRightMid:UpdateBtnActivityBrief()
    local isOpen = XDataCenter.ActivityBriefManager.CheckActivityBriefOpen()
    isOpen = isOpen and not XUiManager.IsHideFunc
    self.BtnActivityBrief.gameObject:SetActiveEx(isOpen)
end

function XUiMainRightMid:OnBtnActivityBrief()
    if not XMVCA.XSubPackage:CheckSubpackage() then
        return
    end
    local dict = {}
    dict["ui_first_button"] = XGlobalVar.BtnBuriedSpotTypeLevelOne.BtnUiMainBtnActivityBrief
    dict["role_level"] = XPlayer.GetLevel()
    CS.XRecord.Record(dict, "200004", "UiOpen")
    XLuaUiManager.Open("UiActivityBriefBase")
end
-------------活动简介 End-------------------
-------------活动入口 Begin-------------------
function XUiMainRightMid:InitBtnActivityEntry()
    self:SetBtnActivityEntryHide()
    self:InitBtnActivityEntryRedPointEventIds()
    if XUiManager.IsHideFunc then return end

    local configs = XDataCenter.ActivityBriefManager.GetNowActivityEntryConfig()
    for index, config in ipairs(configs) do
        local btn = self["BtnActivityEntry" .. index]
        if btn then
            btn:SetSprite(config.Bg)
            btn.CallBack = function() self:OnClickBtnActivityEntry(config.Id, index) end
            btn.gameObject:SetActiveEx(true)
            local redPointConditions = XActivityBriefConfigs.GetRedPointConditionsBySkipId(config.SkipId)
            local redPointParam = XActivityBriefConfigs.GetRedPointParamBySkipId(config.SkipId)
            if redPointConditions then
                local redPointEventId = self:AddRedPointEvent(btn, function(_, count) self:OnCheckActivityEntryRedPointByIndex(index, count) end, self, redPointConditions, redPointParam)
                tableInsert(self.BtnActivityEntryRedPointEventIds, redPointEventId)
            else
                btn:ShowReddot(false)
            end
        end
    end
end

function XUiMainRightMid:InitBtnActivityEntryRedPointEventIds()
    for _, redPointId in pairs(self.BtnActivityEntryRedPointEventIds or {}) do
        self:RemoveRedPointEvent(redPointId)
    end
    self.BtnActivityEntryRedPointEventIds = {}
end

function XUiMainRightMid:UpdateBtnActivityEntry()
    local isNewActivity = XDataCenter.ActivityBriefManager.CheckIsNewSpecialActivityOpen()
    if isNewActivity then
        self:InitBtnActivityEntry()
    end
end

function XUiMainRightMid:SetBtnActivityEntryHide()
    for index = 1, BtnActivityEntryMaxCount do
        self["BtnActivityEntry" .. index].gameObject:SetActiveEx(false)
    end
end

function XUiMainRightMid:OnClickBtnActivityEntry(id, index)
    if not XMVCA.XSubPackage:CheckSubpackage(XEnumConst.SUBPACKAGE.ENTRY_TYPE.MAIN_RIGHT_TOP_ACTIVITY, id) then
        return
    end
    local dict = {}
    dict["ui_first_button"] = XGlobalVar.BtnBuriedSpotTypeLevelOne["BtnUiMainBtnActivityEntry" .. index]
    dict["role_level"] = XPlayer.GetLevel()
    CS.XRecord.Record(dict, "200004", "UiOpen")
    local skipId = XActivityBriefConfigs.GetActivityEntrySkipId(id)
    XFunctionManager.SkipInterface(skipId)
end

function XUiMainRightMid:CheckBtnActivityEntryRedPoint()
    for _, redPointEventId in ipairs(self.BtnActivityEntryRedPointEventIds) do
        XRedPointManager.Check(redPointEventId)
    end
end

function XUiMainRightMid:OnCheckActivityEntryRedPointByIndex(index, count)
    local btn = self["BtnActivityEntry"..index]
    if not btn then
        return
    end
    btn:ShowReddot(count >= 0)
end

function XUiMainRightMid:CheckStartActivityEntryTimer()
    self:StopActivityEntryTimer()
    local serverTimestamp
    local endTimeStamp = XDataCenter.ActivityBriefManager.GetSpecialActivityMaxEndTime()
    self.ActivityEntryTimer = XScheduleManager.ScheduleForever(function()
        serverTimestamp = XTime.GetServerNowTimestamp()
        self:UpdateBtnActivityEntry()
        self:UpdateBtnActivityBrief()
        self:CheckBtnActivityEntryRedPoint()
        if endTimeStamp <= serverTimestamp then
            self:StopActivityEntryTimer()
        end
    end, XScheduleManager.SECOND)
end

function XUiMainRightMid:StopActivityEntryTimer()
    if self.ActivityEntryTimer then
        XScheduleManager.UnSchedule(self.ActivityEntryTimer)
        self.ActivityEntryTimer = nil
    end
end
-------------活动入口 End-------------------
-------------回归活动入口 Begin-------------

function XUiMainRightMid:InitDragProxy()
    if not self.PanelFirst then
        return
    end
    
    local dragProxy = self.PanelFirst:GetComponent(typeof(CsXUGuiDragProxy))
    if not dragProxy then
        dragProxy = self.PanelFirst.gameObject:AddComponent(typeof(CsXUGuiDragProxy))
    end
    dragProxy:RegisterHandler(handler(self, self.OnDragSwitch))
end

function XUiMainRightMid:OnDragSwitch(state, eventData)
    if state == CsXUGuiDragProxy.BEGIN_DRAG then
        self.DragY = eventData.position.y
    elseif state == CsXUGuiDragProxy.END_DRAG then
        local tmpY = eventData.position.y
        local subY = tmpY - self.DragY
        if math.abs(subY) < MinDragYDistance then
            return
        end
        local isShow = tmpY > self.DragY
        self:RefreshSubPanelState(isShow)

        -- 埋点
        if isShow then
            XUiHelper.RecordBuriedSpotTypeLevelOne(XGlobalVar.BtnBuriedSpotTypeLevelOne.DragAnimPanelRightMidSecond)
        else
            XUiHelper.RecordBuriedSpotTypeLevelOne(XGlobalVar.BtnBuriedSpotTypeLevelOne.DragAnimPanelRightMid)
        end
    end
end

function XUiMainRightMid:OnBtnOpenClick()
    self:RefreshSubPanelState(true)
    XUiHelper.RecordBuriedSpotTypeLevelOne(XGlobalVar.BtnBuriedSpotTypeLevelOne.ClickAnimPanelRightMidSecond)
end

function XUiMainRightMid:OnBtnCloseClick()
    self:RefreshSubPanelState(false)
    XUiHelper.RecordBuriedSpotTypeLevelOne(XGlobalVar.BtnBuriedSpotTypeLevelOne.ClickAnimPanelRightMid)
end

function XUiMainRightMid:RefreshSubPanelState(show)
    if self.IsShowSubPanel == show then
        return
    end
    self:UpdateSubPanelState(show)
    self.IsShowSubPanel = show
    local animName = show and "AnimPanelRightMidSecond" or "AnimPanelRightMid"
    self.RootUi:PlayAnimationWithMask(animName)
end

function XUiMainRightMid:GetSubPanelState()
    local key = string.format("UiMain_%s_%s", SubPanelState, XPlayer.Id)
    local state = XSaveTool.GetData(key)
    if state == nil then
        return false
    end
    return state
end

function XUiMainRightMid:UpdateSubPanelState(state)
    local key = string.format("UiMain_%s_%s", SubPanelState, XPlayer.Id)
    XSaveTool.SaveData(key, state)
end

--商店入口
function XUiMainRightMid:OnBtnStore()
    if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon)
            or XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopActive) then
        XUiHelper.RecordBuriedSpotTypeLevelOne(XGlobalVar.BtnBuriedSpotTypeLevelOne.BtnUiMainBtnStore)
        XLuaUiManager.Open("UiShop", XShopManager.ShopType.Common)
    end
end

--商店开启状态
function XUiMainRightMid:OnCheckStore()
    local isOpen = XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.ShopCommon)
            or XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.ShopActive)
    self.BtnStore:SetDisable(not isOpen)
end

--仓库入口
function XUiMainRightMid:OnBtnBag()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Bag) then
        return
    end
    XUiHelper.RecordBuriedSpotTypeLevelOne(XGlobalVar.BtnBuriedSpotTypeLevelOne.BtnUiMainBtnBag)
    XLuaUiManager.Open("UiBag")
end

--充值入口
function XUiMainRightMid:OnBtnRecharge()
    XUiHelper.RecordBuriedSpotTypeLevelOne(XGlobalVar.BtnBuriedSpotTypeLevelOne.BtnUiMainBtnRecharge)
    XLuaUiManager.Open("UiPurchase", XPurchaseConfigs.TabsConfig.Recommend)
end

--成员入口
function XUiMainRightMid:OnBtnMember()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Character) then
        return
    end
    XUiHelper.RecordBuriedSpotTypeLevelOne(XGlobalVar.BtnBuriedSpotTypeLevelOne.BtnUiMainBtnMember)

    --region 【v2.8，主干】【联机邀请提示】在主界面收到好友邀请后进入成员界面，邀请弹窗会有残留
    XEventManager.DispatchEvent(XEventId.EVENT_ARENA_HIDE_INVITATION)
    XEventManager.DispatchEvent(XEventId.EVENT_DLC_HIDE_INVITE)
    --endregion
    XLuaUiManager.Open("UiCharacterSystemV2P6")
end

-- 公会
function XUiMainRightMid:OnBtnGuildClick()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Guild) then
        return
    end
    XUiHelper.RecordBuriedSpotTypeLevelOne(XGlobalVar.BtnBuriedSpotTypeLevelOne.BtnUiMainBtnGuild)
    --self.RootUi:ChangeLowPowerState(self.RootUi.LowPowerState.None)
    XDataCenter.GuildDormManager.EnterGuildDorm()
end

function XUiMainRightMid:OnCheckGuildRedPoint(count)
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Guild) then
        self.ImgBuldingRedDot.gameObject:SetActiveEx(false)
        return
    end
    self.ImgBuldingRedDot.gameObject:SetActiveEx(count >= 0)
end
-------------回归活动入口 End-------------

--伙伴红点
function XUiMainRightMid:OnCheckPartnerRedPoint(count)
    self.BtnPartner:ShowReddot(count >= 0)
end

--任务红点
function XUiMainRightMid:OnCheckTaskNews(count)
    self.BtnTask:ShowReddot(count >= 0)
end

--宿舍红点
function XUiMainRightMid:OnCheckBuildingNews(count)
    self.BtnBuilding:ShowReddot(count >= 0)
end

--活动简介红点
function XUiMainRightMid:OnCheckActivityBriefRedPoint(count)
    self.BtnActivityBrief:ShowReddot(count >= 0)
end

--研发红点
function XUiMainRightMid:OnCheckARewardNews(count)
    self.BtnReward:ShowReddot(count >= 0)
end

--成员红点
function XUiMainRightMid:OnCheckMemberNews(count)
    self.BtnMember:ShowReddot(count >= 0)
end

--成员装备推荐Tag
function XUiMainRightMid:OnCheckMemberTag()
    local isSetEquipTarget = XDataCenter.EquipGuideManager.IsSetEquipTarget()
    self.BtnMember:ShowTag(isSetEquipTarget)
    if not isSetEquipTarget then
        return
    end
    local strongerWeapon = XDataCenter.EquipGuideManager.CheckHasStrongerWeapon()
    local hasEquipCanEquip = XDataCenter.EquipGuideManager.CheckEquipCanEquip()
    self.BtnEquipGuide.ReddotObj.gameObject:SetActiveEx(strongerWeapon or hasEquipCanEquip)
end

function XUiMainRightMid:SetBtnEquipGuideState(state)
    self.BtnEquipGuide.enabled = state
end

--充值红点
function XUiMainRightMid:OnCheckRechargeNews()
    local isShowRedPoint = XDataCenter.PurchaseManager.FreeLBRed() or XDataCenter.PurchaseManager.AccumulatePayRedPoint() or XDataCenter.PurchaseManager.CheckYKContinueBuy()
            or XDataCenter.PurchaseManager.GetRecommendManager():GetIsShowRedPoint()
    if self.BtnRecharge then
        self.BtnRecharge:ShowReddot(isShowRedPoint)
    end
end

--研发活动标签
--鬼泣五联动卡池可领取红点
function XUiMainRightMid:CheckDevilMayCryTag()
    local devilMayCryTag = XUiHelper.TryGetComponent(self.BtnReward.transform, "Tab3", nil)
    -- todo 服务端方案
    -- devilMayCryTag.gameObject:SetActiveEx()
end

function XUiMainRightMid:OnCheckDrawActivityTag(IsShow)
    if XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.DrawCard) then
        self.BtnReward:ShowTag(IsShow)
    else
        self.BtnReward:ShowTag(false)
    end
end

function XUiMainRightMid:OnCheckDrawFreeTicketTag(isShow)
    local freeTag = XUiHelper.TryGetComponent(self.BtnReward.transform, "Tab2", nil)
    if not freeTag then
        return
    end
    if XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.DrawCard) then
        freeTag.gameObject:SetActiveEx(isShow >= 0)
    else
        freeTag.gameObject:SetActiveEx(false)
    end
end

--展开按钮红点
function XUiMainRightMid:OnCheckOpenRedPoint(count)
    self.BtnOpen:ShowReddot(count >= 0)
end

--仓库红点
function XUiMainRightMid:OnCheckBagNews(count)
    self.BtnBag:ShowReddot(count >= 0)
end

return XUiMainRightMid
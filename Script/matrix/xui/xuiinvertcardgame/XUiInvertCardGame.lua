local tableInsert = table.insert
local tablepack = table.pack
local tableUnpack = table.unpack
local CSXTextManagerGetText = CS.XTextManager.GetText

local XUiInvertCardGame = XLuaUiManager.Register(XLuaUi, "UiInvertCardGame")

local XUiInvertCardGamePanel = require("XUi/XUiInvertCardGame/XUiInvertCardGamePanel")
local XUiInvertCardRewardPanel = require("XUi/XUiInvertCardGame/XUiInvertCardRewardPanel")

function XUiInvertCardGame:OnAwake()
    if not XDataCenter.InvertCardGameManager.CheckHasServerData() then
        XUiManager.TipText("InvertCardGameNotHaveSeverData")
        self:Close()
    end

    self.GamePanel = XUiInvertCardGamePanel.New(self, self.PanelGame)
    self.RewardPanel = XUiInvertCardRewardPanel.New(self, self.PanelReward)
end

function XUiInvertCardGame:OnStart()
    self.RedPointIds = {}
    self:AutoRegisterBtn()
    self.ItemId = XDataCenter.InvertCardGameManager.GetConsumeItemId()
    self.AssetPanel = XUiHelper.NewPanelActivityAsset({ self.ItemId }, self.PanelActivityAsset)
    self:InitBtnGroup()
    self:RefreshBtnTab()
    local defaultSelectIdx = XDataCenter.InvertCardGameManager.FindDefaultSelectTabIndex()
    if defaultSelectIdx and defaultSelectIdx ~= 0 then
        self.BtnGroup:SelectIndex(defaultSelectIdx)
    end
    self:InitSKipRedPoint()
    XEventManager.AddEventListener(XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX..self.ItemId, self.OnCoinCountChange, self)
end

function XUiInvertCardGame:OnEnable()
    self:StartActivityTimer()
    self:CheckHitFaceHelp()
end

function XUiInvertCardGame:OnDisable()
    self:StopActivityTimer()
end

function XUiInvertCardGame:OnDestroy()
    self:RemoveRedPoints()
    XEventManager.RemoveEventListener(XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX..self.ItemId, self.OnCoinCountChange, self)
end

function XUiInvertCardGame:OnGetEvents()
    return {
        XEventId.EVENT_INVERT_CARD_GAME_CARD_CHANGED,
        XEventId.EVENT_INVERT_CARD_GAME_GET_REWARD,
    }
end

function XUiInvertCardGame:OnNotify(evt, ...)
    local args = tablepack(...)
    local stageEntity = args[1]
    if evt == XEventId.EVENT_INVERT_CARD_GAME_CARD_CHANGED then
        self.AssetPanel:Refresh({ XDataCenter.InvertCardGameManager.GetConsumeItemId() })
        self.GamePanel:PlayCardsChangedAnimation(args[1], args[2], args[3], args[4])
        XRedPointManager.Check(self.SkipRedPointId)
    elseif evt == XEventId.EVENT_INVERT_CARD_GAME_GET_REWARD then
        self.RewardPanel:Refresh(stageEntity)
    end
end

--==============================
 ---@desc 货币数量发生变化
 ---@id 物品Id 
 ---@count 数量 
--==============================
function XUiInvertCardGame:OnCoinCountChange(id, count)
    self.GamePanel:RefreshMessagePanel()
end

function XUiInvertCardGame:AutoRegisterBtn()
    self.BtnBack.CallBack = function () self:Close() end
    self.BtnMainUi.CallBack = function () XLuaUiManager.RunMain() end
    self.BtnStart.CallBack = function () self:OnBtnStartClick() end
    local skipId = XDataCenter.InvertCardGameManager.GetStorySkipId()
    if skipId and skipId ~= 0 then
        self.BtnStory.gameObject:SetActiveEx(true)
        self.BtnStory.CallBack = function () XFunctionManager.SkipInterface(skipId) end
    else
        self.BtnStory.gameObject:SetActiveEx(false)
    end
    self:RegisterHelpBtn()
end

function XUiInvertCardGame:RegisterHelpBtn()
    local helpId = XDataCenter.InvertCardGameManager.GetHelpId()
    local template = XHelpCourseConfig.GetHelpCourseTemplateById(helpId)
    self:BindHelpBtn(self.BtnHelp, template.Function)
end

function XUiInvertCardGame:OnBtnStartClick()
    XDataCenter.InvertCardGameManager.SetStartStage(self.CurStage)
    self:SetStartCoverActiveEx(false)
    self:SetFullCoverActiveEx(true)
    local status = self.CurStage:GetStatus()
    if status == XInvertCardGameConfig.InvertCardGameStageStatusType.Finish then
        return 
    end
    self.GamePanel:PlayStartAnimation()
end

function XUiInvertCardGame:InitBtnGroup()
    local togBtns = {}
    for i = 1, 4 do
        if self["BtnTog"..i] then
            tableInsert(togBtns, self["BtnTog"..i])
        end
    end
    self.BtnTabs = {}
    local stageIds = XDataCenter.InvertCardGameManager.GetStageEntityList()
    for i=1, #togBtns, 1 do
        if i <= #stageIds then
            togBtns[i].gameObject:SetActiveEx(true)
            tableInsert(self.BtnTabs, togBtns[i])
        else
            togBtns[i].gameObject:SetActiveEx(false)
        end
    end
    self.BtnGroup:Init(self.BtnTabs, function (index) self:OnBtnTabClick(index) end)
    for index, togBtn in ipairs(self.BtnTabs) do
        local redId = XRedPointManager.AddRedPointEvent(togBtn.ReddotObj, nil, nil, {XRedPointConditions.Types.CONDITION_INVERTCARDGAME_TOG}, index, true)
        tableInsert(self.RedPointIds, redId)
    end
end

function XUiInvertCardGame:OnBtnTabClick(index)
    if index == self.CurrentSelectIndex then
        return
    end

    local stageList = XDataCenter.InvertCardGameManager.GetStageEntityList()
    if XDataCenter.InvertCardGameManager.CheckStageIsOpen(index) then
        self.CurrentSelectIndex = index
        local curStage = XDataCenter.InvertCardGameManager.GetStageEntityList()[index]
        if curStage then
            self.CurStage = curStage
            self.RewardPanel:Refresh(curStage)
            self.GamePanel:Refresh(curStage)
            self:RefreshStartCover(curStage)
            self:PlayAnimation("QieHuan")
        end
    else
        self.BtnGroup:SelectIndex(self.CurrentSelectIndex)
        if stageList[index-1] then
            XUiManager.TipError(CSXTextManagerGetText("InvertCardGameStageNotOpen", stageList[index-1]:GetName()))
        end
    end
end

function XUiInvertCardGame:RefreshBtnTab()
    local stageList = XDataCenter.InvertCardGameManager.GetStageEntityList()

    for index, btnTab in pairs(self.BtnTabs) do
        if stageList[index] then
            btnTab:SetNameByGroup(0, stageList[index]:GetName())
            local isOpen = XDataCenter.InvertCardGameManager.CheckStageIsOpen(index)
            btnTab:SetDisable(not isOpen)
            local isFinish = stageList[index]:GetStatus() == XInvertCardGameConfig.InvertCardGameStageStatusType.Finish
            btnTab:ShowTag(isFinish)
            if self.CurrentSelectIndex and self.CurrentSelectIndex == index then
                btnTab:SetButtonState(XUiButtonState.Select)
            end
        end
    end
end

function XUiInvertCardGame:RefreshRewardProcess()
    local takeNum, count = XDataCenter.CoupletGameManager.GetRewardProcess()
    self.TxtRewardPorcess.text = string.format("%s%s%s", takeNum, "/", count)
end

function XUiInvertCardGame:CheckHitFaceHelp()
    local hitFaceData = XSaveTool.GetData(string.format( "%s%s%s", XInvertCardGameConfig.INVERT_CARD_GAME_HELP_HIT_KEY, XPlayer.Id, XDataCenter.InvertCardGameManager.ActId))
    if not hitFaceData or hitFaceData == XInvertCardGameConfig.HitFaceHelpState.NotHit then
        local helpId = XDataCenter.InvertCardGameManager.GetHelpId()
        local template = XHelpCourseConfig.GetHelpCourseTemplateById(helpId)
        XUiManager.ShowHelpTip(template.Function)
        XSaveTool.SaveData(string.format( "%s%s%s", XInvertCardGameConfig.INVERT_CARD_GAME_HELP_HIT_KEY, XPlayer.Id, XDataCenter.InvertCardGameManager.ActId), XInvertCardGameConfig.HitFaceHelpState.Hited)
    end
end

function XUiInvertCardGame:InitSKipRedPoint()
    local curSkipId = XDataCenter.InvertCardGameManager.GetStorySkipId()
    if not curSkipId or curSkipId == 0 then
        return
    end
    local skipTemplate = XFunctionConfig.GetSkipList(curSkipId)
    local redId = XRedPointManager.AddRedPointEvent(self.BtnStory.ReddotObj, nil, nil, {XRedPointConditions.Types.CONDITION_MOVIE_ASSEMBLE_RED}, skipTemplate.CustomParams[1], true)
    self.SkipRedPointId = redId
    tableInsert(self.RedPointIds, redId)
end

function XUiInvertCardGame:RefreshStartCover(stageEntity)
    local startState = XDataCenter.InvertCardGameManager.GetStartStage(stageEntity)
    if not startState or startState == XInvertCardGameConfig.InvertCardGameStartStage.NotStart then
        self:SetStartCoverActiveEx(true)
    else
        self:SetStartCoverActiveEx(false)
    end
end

function XUiInvertCardGame:SetStartCoverActiveEx(bool)
    self.StartCover.gameObject:SetActiveEx(bool)
    self.BtnStart.gameObject:SetActiveEx(bool)
end

function XUiInvertCardGame:SetFullCoverActiveEx(bool)
    self.FullCover.gameObject:SetActiveEx(bool)
end

function XUiInvertCardGame:RemoveRedPoints()
    if self.RedPointIds and next(self.RedPointIds) then
        for _, redId in ipairs(self.RedPointIds) do
            XRedPointManager.RemoveRedPointEvent(redId)
        end
    end
end

function XUiInvertCardGame:StartActivityTimer()
    local timeId = XDataCenter.InvertCardGameManager.GetActivityTimeId()
    local startTime, endTime = XFunctionManager.GetTimeByTimeId(timeId)
    local nowTime = XTime.GetServerNowTimestamp()
    self.TxtTime.text = XUiHelper.GetTime(endTime - nowTime, XUiHelper.TimeFormatType.ACTIVITY)
    if nowTime < startTime then
        XUiManager.TipText("InvertCardGameTimeNotOpen")
        self:Close()
    elseif nowTime > endTime then
        XUiManager.TipText("InvertCardGameTimeEnd")
        self:Close()
    else
        self.ActivityTimer = XScheduleManager.ScheduleForever(function()
            local time = XTime.GetServerNowTimestamp()
            if time > endTime then
                XUiManager.TipError(CSXTextManagerGetText("InvertCardGameTimeEnd"))
                self:StopActivityTimer()
                XLuaUiManager.RunMain()
                return
            end
            self.TxtTime.text = XUiHelper.GetTime(endTime - time, XUiHelper.TimeFormatType.ACTIVITY)
        end, XScheduleManager.SECOND, 0)
    end
end

function XUiInvertCardGame:StopActivityTimer()
    if self.ActivityTimer then
        XScheduleManager.UnSchedule(self.ActivityTimer)
        self.ActivityTimer = nil
    end
end
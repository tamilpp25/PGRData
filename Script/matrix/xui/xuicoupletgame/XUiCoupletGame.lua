local XUiPanelActivityAsset = require("XUi/XUiShop/XUiPanelActivityAsset")
local tableInsert = table.insert
local CSXTextManagerGetText = CS.XTextManager.GetText

local XUiCoupletGame = XLuaUiManager.Register(XLuaUi, "UiCoupletGame")

local XUiCoupletStageCtrlPanel = require("XUi/XUiCoupletGame/XUiCoupletStageCtrlPanel")
local XUiCoupletRollPanel = require("XUi/XUiCoupletGame/XUiCoupletRollPanel")

function XUiCoupletGame:OnAwake()
    if not XDataCenter.CoupletGameManager.CheckHasServerData() then
        self:Close()
    end
    self.PanelCoupletStageCtrl = XUiCoupletStageCtrlPanel.New(self, self.PanelStageCtrl)
    self.PanelCoupletRoll = XUiCoupletRollPanel.New(self, self.PanelRoll)
end

function XUiCoupletGame:OnStart()
    self:AutoRegisterBtn()
    self.AssetPanel = XUiPanelActivityAsset.New(self.PanelAsset, self, true)
    self.AssetPanel:Refresh({ XDataCenter.CoupletGameManager.GetConsumeItemId() })
    self:InitBtnGroup()
    self:InitRedPoint()
end

function XUiCoupletGame:OnEnable()
    self:RefreshBtnTab()
    self:StartActivityTimer()
    self:RefreshTitle()
    self:RefreshRewardProcess()
    local defaultTabIndex = XDataCenter.CoupletGameManager.FindDefaultSelectTabIndex()
    self.PanelLamp:SelectIndex(defaultTabIndex)
    self.CurrentSelectIndex = defaultTabIndex
    if self.CurrentSelectIndex and self.CurrentSelectIndex ~= 0 then
        self.PanelLamp:SelectIndex(self.CurrentSelectIndex)
    end

    self:CheckHitFaceVideo()
end

function XUiCoupletGame:OnDisable()
    self:StopActivityTimer()
end

function XUiCoupletGame:OnDestroy()

end

function XUiCoupletGame:OnGetEvents()
    return {
        XEventId.EVENT_COUPLET_GAME_GET_WORD,
        XEventId.EVENT_COUPLET_GAME_COMPLETE,
        XEventId.EVENT_COUPLET_GAME_CHANGE_WORD,
        XEventId.EVENT_COUPLET_GAME_FINISH_TASK,
        XEventId.EVENT_COUPLET_GAME_PLAYED_VIDEO,
        XEventId.EVENT_COUPLET_GAME_SENTENCE_ERROR,
    }
end

function XUiCoupletGame:OnNotify(evt, ...)
    local coupletId = XDataCenter.CoupletGameManager.GetCoupletTemplateByIndex(self.CurrentSelectIndex).Id
    if evt == XEventId.EVENT_COUPLET_GAME_COMPLETE then
        self:RefreshBtnTab()
        self.PanelCoupletStageCtrl:Refresh(coupletId, true)
        self.PanelCoupletRoll:Refresh(coupletId, true)
    elseif evt == XEventId.EVENT_COUPLET_GAME_GET_WORD then
        self.PanelCoupletStageCtrl:Refresh(coupletId, true)
        self.PanelCoupletRoll:RefreshDownWords(coupletId, false, ...)
        self.AssetPanel:Refresh({ XDataCenter.CoupletGameManager.GetConsumeItemId() })
    elseif evt == XEventId.EVENT_COUPLET_GAME_CHANGE_WORD then
        self.PanelCoupletRoll:RefreshDownWords(coupletId)
    elseif evt == XEventId.EVENT_COUPLET_GAME_FINISH_TASK then
        self:RefreshRewardProcess()
    elseif evt == XEventId.EVENT_COUPLET_GAME_PLAYED_VIDEO then
        self:RefreshBtnTab()
    elseif evt == XEventId.EVENT_COUPLET_GAME_SENTENCE_ERROR then
        self.PanelCoupletRoll:ShowWordEffectError()
    end
end

function XUiCoupletGame:AutoRegisterBtn()
    self.BtnBack.CallBack = function () self:Close() end
    self.BtnMainUi.CallBack = function () XLuaUiManager.RunMain() end
    self.BtnBox.CallBack = function () self:OnBtnRewardClick() end
    self:RegisterHelpBtn()
end

function XUiCoupletGame:RegisterHelpBtn()
    local helpId = XDataCenter.CoupletGameManager.GetHelpId()
    local template = XHelpCourseConfig.GetHelpCourseTemplateById(helpId)
    self:BindHelpBtn(self.BtnHelp, template.Function)
end

function XUiCoupletGame:InitBtnGroup()
    local tmpBtnTabs = {self.BtnLamp1, self.BtnLamp2, self.BtnLamp3, self.BtnLamp4, self.BtnLamp5}
    self.BtnTabs = {}
    local coupletTemplates = XDataCenter.CoupletGameManager.GetCoupletTemplates()
    for i=1, #tmpBtnTabs, 1 do
        if i <= #coupletTemplates then
            tmpBtnTabs[i].gameObject:SetActiveEx(true)
            tableInsert(self.BtnTabs, tmpBtnTabs[i])
        else
            tmpBtnTabs[i].gameObject:SetActiveEx(false)
        end
    end
    self.PanelLamp:Init(self.BtnTabs, function (index) self:OnBtnTabClick(index) end)
end

function XUiCoupletGame:OnBtnTabClick(index)
    if index == self.CurrentSelectIndex then
        return
    end

    if XDataCenter.CoupletGameManager.CheckCoupletIsOpen(index) then
        local coupletTemplate = XDataCenter.CoupletGameManager.GetCoupletTemplateByIndex(index)
        self.PanelCoupletStageCtrl:Refresh(coupletTemplate.Id)
        self.PanelCoupletRoll:Refresh(coupletTemplate.Id)
        self.CurrentSelectIndex = index
        self:PlayAnimation("QieHuan")
    else
        local lastCoupletName = XDataCenter.CoupletGameManager.GetLastCoupletName(index)
        XUiManager.TipError(CSXTextManagerGetText("CoupletGameNotOpen", lastCoupletName))
    end
end

function XUiCoupletGame:RefreshBtnTab()
    local coupletTemplates = XDataCenter.CoupletGameManager.GetCoupletTemplates()

    for index, btnTab in pairs(self.BtnTabs) do
        btnTab:SetNameByGroup(0, coupletTemplates[index].TitleName)
        local isOpen = XDataCenter.CoupletGameManager.CheckCoupletIsOpen(index)
        btnTab:SetDisable(not isOpen)

        local isNeedRedPoint = XDataCenter.CoupletGameManager.CheckPlayVideoRedPoint(coupletTemplates[index].Id)
        btnTab:ShowReddot(isNeedRedPoint)

        if self.CurrentSelectIndex and self.CurrentSelectIndex == index then
            btnTab:SetButtonState(XUiButtonState.Select)
        end
    end
end

function XUiCoupletGame:RefreshTitle()
    local title, titleEn = XDataCenter.CoupletGameManager.GetActivityTitle()
    self.TxtTitle.text = title
    self.TxtTitleEn.text = titleEn
end

function XUiCoupletGame:OnBtnRewardClick()
    self:OpenChildUi("UiCoupletAward")
end

function XUiCoupletGame:RefreshRewardProcess()
    local takeNum, count = XDataCenter.CoupletGameManager.GetRewardProcess()
    self.TxtRewardPorcess.text = string.format("%s%s%s", takeNum, "/", count)
end

function XUiCoupletGame:CheckHitFaceHelp()
    local hitFaceData = XSaveTool.GetData(string.format( "%s%s", XCoupletGameConfigs.COUPLET_GAME_HELP_HIT_KEY, XPlayer.Id))
    if not hitFaceData or hitFaceData == XCoupletGameConfigs.HitFaceHelpState.NotHit then
        local helpId = XDataCenter.CoupletGameManager.GetHelpId()
        local template = XHelpCourseConfig.GetHelpCourseTemplateById(helpId)
        XUiManager.ShowHelpTip(template.Function)
        XSaveTool.SaveData(string.format( "%s%s", XCoupletGameConfigs.COUPLET_GAME_HELP_HIT_KEY, XPlayer.Id), XCoupletGameConfigs.HitFaceHelpState.Hited)
    end
end

function XUiCoupletGame:CheckHitFaceVideo()
    local hitFaceVideoData = XSaveTool.GetData(string.format( "%s%s", XCoupletGameConfigs.COUPLET_GAME_VIDEO_HIT_KEY, XPlayer.Id))
    if not hitFaceVideoData or hitFaceVideoData == XCoupletGameConfigs.HitFaceVideoState.UnPlay then
        local hitFaceStoryId = XDataCenter.CoupletGameManager.GetHitFaceStoryId()
        if hitFaceStoryId and hitFaceStoryId ~= "" then
            XDataCenter.MovieManager.PlayMovie(hitFaceStoryId, function ()
                XSaveTool.SaveData(string.format( "%s%s", XCoupletGameConfigs.COUPLET_GAME_VIDEO_HIT_KEY, XPlayer.Id), XCoupletGameConfigs.HitFaceVideoState.Played)
                self:CheckHitFaceHelp()
            end)
        end
    end
end

function XUiCoupletGame:InitRedPoint()
    self.RewardRedPointId = XRedPointManager.AddRedPointEvent(self.BtnBox, self.OnCheckBtnBoxRedPoint, self, { XRedPointConditions.Types.CONDITION_COUPLET_GAME_REWARD_TASK }, nil, true)
end

function XUiCoupletGame:OnCheckBtnBoxRedPoint(count)
    self.BtnBox:ShowReddot(count >= 0)    
end

function XUiCoupletGame:StartActivityTimer()
    local timeId = XDataCenter.CoupletGameManager.GetActivityTimeId()
    local startTime, endTime = XFunctionManager.GetTimeByTimeId(timeId)
    local nowTime = XTime.GetServerNowTimestamp()
    self.TxtTime.text = XUiHelper.GetTime(endTime - nowTime, XUiHelper.TimeFormatType.ACTIVITY)
    if nowTime < startTime then
        self.TxtTime.text = CSXTextManagerGetText("CoupletGameActivityNotOpen")
    elseif nowTime > endTime then
        self.TxtTime.text = CSXTextManagerGetText("CoupletGameActivityEnd")
    else
        self.ActivityTimer = XScheduleManager.ScheduleForever(function()
            local time = XTime.GetServerNowTimestamp()
            if time > endTime then
                XUiManager.TipError(CSXTextManagerGetText("CoupletGameActivityEnd"))
                self:StopActivityTimer()
                XLuaUiManager.RunMain()
                return
            end
            self.TxtTime.text = XUiHelper.GetTime(endTime - time, XUiHelper.TimeFormatType.ACTIVITY)
        end, XScheduleManager.SECOND, 0)
    end
end

function XUiCoupletGame:StopActivityTimer()
    if self.ActivityTimer then
        XScheduleManager.UnSchedule(self.ActivityTimer)
        self.ActivityTimer = nil
    end
end
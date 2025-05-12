local XUiPanelActivityAsset = require("XUi/XUiShop/XUiPanelActivityAsset")
local tableInsert = table.insert
local CSXTextManagerGetText = CS.XTextManager.GetText

local XUiFubenActivityPuzzle = XLuaUiManager.Register(XLuaUi, "UiFubenActivityPuzzle")

local XUiFubenActivityPuzzleRewardPanel = require("XUi/XUiFubenActivityPuzzle/XUiFubenActivityPuzzleRewardPanel")
local XUiFubenActivityPuzzleGamePanel = require("XUi/XUiFubenActivityPuzzle/XUiFubenActivityPuzzleGamePanel")
local XUiFubenActivityPuzzlePasswordRewardPanel = require("XUi/XUiFubenActivityPuzzle/XUiFubenActivityPuzzlePasswordRewardPanel")

function XUiFubenActivityPuzzle:OnAwake()
    self.PanelReward = XUiFubenActivityPuzzleRewardPanel.New(self, self.LeftAwardPanel)
    self.PanelGame = XUiFubenActivityPuzzleGamePanel.New(self, self.GamePanel)
    self.PanelPasswordReward = XUiFubenActivityPuzzlePasswordRewardPanel.New(self, self.LeftAwardPassWordPanel)
end

function XUiFubenActivityPuzzle:OnStart()
    self.RedPointIdArr = {}
    self:AutoRegisterBtn()
    self.AssetPanel = XUiPanelActivityAsset.New(self.PanelAsset, self, true)
    self:InitBtnGroup()
end

function XUiFubenActivityPuzzle:OnEnable()
    self.AssetPanel:Refresh({ XDataCenter.FubenActivityPuzzleManager.GetActivityInfo().ItemId })
    self:RefreshBtnTab()
    self:StartActivityTimer()
    local defaultTabIndex = XDataCenter.FubenActivityPuzzleManager.FindDefaultSelectTabIndex()
    self.isEnable = true
    self.PanelTab:SelectIndex(defaultTabIndex)
    self.CurrentSelectIndex = defaultTabIndex
    self:CheckHelpHitFace()
end

function XUiFubenActivityPuzzle:OnDisable()
    self:StopActivityTimer()
end

function XUiFubenActivityPuzzle:OnDestroy()
    self:RemoveAllRedPoints()
    self.PanelGame:OnRelease()
end

function XUiFubenActivityPuzzle:OnGetEvents()
    return {
        XEventId.EVENT_DRAG_PUZZLE_GAME_GET_PIECE,
        XEventId.EVENT_DRAG_PUZZLE_GAME_PUZZLE_CHANGED,
        XEventId.EVENT_DRAG_PUZZLE_GAME_GOT_REWARD,
        XEventId.EVENT_DRAG_PUZZLE_GAME_PUZZLE_COMPLETE,
        XEventId.EVENT_DRAG_PUZZLE_GAME_PUZZLE_DECRYPTION,
        XEventId.EVENT_DRAG_PUZZLE_GAME_PUZZLE_CHECK_WORD_ERROR,
    }
end

function XUiFubenActivityPuzzle:OnNotify(evt, ...)
    local puzzleTemplate = XDataCenter.FubenActivityPuzzleManager.GetPuzzleTemplateByIndex(self.CurrentSelectIndex)
    if evt == XEventId.EVENT_DRAG_PUZZLE_GAME_GET_PIECE then
        self.AssetPanel:Refresh({ XDataCenter.FubenActivityPuzzleManager.GetActivityInfo().ItemId })
        self.PanelGame:RefreshChipPanel(...)
        self.PanelGame:ShowSwitchPieceEffect()
    elseif evt == XEventId.EVENT_DRAG_PUZZLE_GAME_PUZZLE_CHANGED then
        self.PanelGame:RefreshPuzzlePanel(...)
        self:RefreshLeftPanelByPuzzleType(puzzleTemplate.PuzzleType, ...)
    elseif evt == XEventId.EVENT_DRAG_PUZZLE_GAME_GOT_REWARD then
        self.PanelGame:RefreshPanel(...)
        self:RefreshLeftPanelByPuzzleType(puzzleTemplate.PuzzleType, ...)
        self:PlayVideoBtnAnimation(...)
    elseif evt == XEventId.EVENT_DRAG_PUZZLE_GAME_PUZZLE_COMPLETE then
        self:SetTabDisable()
        XRedPointManager.Check(self.PanelGame.RedPointId)
        self.PanelGame:SetComplete()
        self.PanelGame:ShowPuzzleCompleteEffect()
        self:RefreshLeftPanelByPuzzleType(puzzleTemplate.PuzzleType, ...)
        self:PlayAnimation("Line")
        self:ShowCompleteHintText(...)
        if puzzleTemplate.PuzzleType == XFubenActivityPuzzleConfigs.PuzzleType.Decryption then
            self:PlayAnimation("BgQieHuan", function ()
                self.PanelGame.PuzzleImgBigPassword.gameObject:SetActiveEx(false)
            end, function ()
                self.PanelGame.PuzzleImgBigPassword.gameObject:SetActiveEx(true)
            end)
        end
    elseif evt == XEventId.EVENT_DRAG_PUZZLE_GAME_PUZZLE_DECRYPTION then
        self.PanelGame:SetDecryption()
        self:RefreshLeftPanelByPuzzleType(puzzleTemplate.PuzzleType, ...)
        XUiManager.TipText("DragPuzzleActivityTryDercyption")
    elseif evt == XEventId.EVENT_DRAG_PUZZLE_GAME_PUZZLE_CHECK_WORD_ERROR then
        self:RefreshLeftPanelByPuzzleType(puzzleTemplate.PuzzleType, ...)
    end
end

function XUiFubenActivityPuzzle:AutoRegisterBtn()
    self.BtnBack.CallBack = function () self:Close() end
    self.BtnMainUi.CallBack = function ()
        XLuaUiManager.RunMain()
    end
    self:RegisterHelpBtn()
end

function XUiFubenActivityPuzzle:RegisterHelpBtn()
    local helpId = XDataCenter.FubenActivityPuzzleManager.GetActivityInfo().HelpId
    local template = XHelpCourseConfig.GetHelpCourseTemplateById(helpId)
    self:BindHelpBtn(self.BtnHelp, template.Function)
end

function XUiFubenActivityPuzzle:InitBtnGroup()
    local tmpBtnTabs = {self.BtnTab1, self.BtnTab2, self.BtnTab3, self.BtnTab4,}
    self.BtnTabs = {}
    local puzzleTemplates = XDataCenter.FubenActivityPuzzleManager.GetPuzzleTemplates()
    for i=1, #tmpBtnTabs, 1 do
        if i <= #puzzleTemplates then
            tmpBtnTabs[i].gameObject:SetActiveEx(true)
            tableInsert(self.BtnTabs, tmpBtnTabs[i])
            local redPointId = XRedPointManager.AddRedPointEvent(tmpBtnTabs[i].ReddotObj, nil, nil, {XRedPointConditions.Types.CONDITION_DRAG_PUZZLE_GAME_TAB}, i, true)
            tableInsert(self.RedPointIdArr, redPointId)
        else
            tmpBtnTabs[i].gameObject:SetActiveEx(false)
        end
    end
    self.PanelTab:Init(self.BtnTabs, function (index) self:OnBtnTabClick(index) end)
end

function XUiFubenActivityPuzzle:OnBtnTabClick(index)
    if XDataCenter.FubenActivityPuzzleManager.CheckPuzzleIsOpen(index) then
        local puzzleTemplate = XDataCenter.FubenActivityPuzzleManager.GetPuzzleTemplateByIndex(index)
        self:PlayAnimation("Refresh")
        local puzzleId = XDataCenter.FubenActivityPuzzleManager.GetPuzzleTemplateByIndex(index).Id
        self:RefreshLeftPanelByPuzzleType(puzzleTemplate.PuzzleType, puzzleId)
        self.PanelGame:RefreshPanel(puzzleId)
        if self.isEnable then
            self.CGImage:SetRawImage(puzzleTemplate.BgUrl)
            self.isEnable = false
        else
            self:PlayAnimation("Bgloading1", function ()
            -- 切换背景
                self.CGImage:SetRawImage(puzzleTemplate.BgUrl)
                self:PlayAnimation("Bgloading2")
            end)
        end
        self.CurrentSelectIndex = index
    else
        XUiManager.TipError(CSXTextManagerGetText("DragPuzzleActivityPuzzleNotOpen"))
    end
end

function XUiFubenActivityPuzzle:RefreshBtnTab()
    local puzzleTemplates = XDataCenter.FubenActivityPuzzleManager.GetPuzzleTemplates()
    for index, btnTab in pairs(self.BtnTabs) do
        btnTab:SetNameByGroup(0, string.format("%02d", index))
        btnTab:SetNameByGroup(1, puzzleTemplates[index].SubName)
        btnTab:SetNameByGroup(2, puzzleTemplates[index].Name)
    end
    self:SetTabDisable()
end

function XUiFubenActivityPuzzle:SetTabDisable()
    for index, btnTab in pairs(self.BtnTabs) do
        local isOpen = XDataCenter.FubenActivityPuzzleManager.CheckPuzzleIsOpen(index)
        btnTab:SetDisable(not isOpen)
    end
    if self.CurrentSelectIndex and self.CurrentSelectIndex ~= 0 then
        self.PanelTab:SelectIndex(self.CurrentSelectIndex)
    end
end

function XUiFubenActivityPuzzle:ShowCompleteHintText(puzzleId)
    local puzzleTemplate = XFubenActivityPuzzleConfigs.GetPuzzleTemplateById(puzzleId)
    if puzzleTemplate then
        if puzzleTemplate.CompleteHintText and puzzleTemplate.CompleteHintText ~= "" then
            XUiManager.TipMsg(puzzleTemplate.CompleteHintText)
        end
    end
end

function XUiFubenActivityPuzzle:PlayVideoBtnAnimation(...)
    local gotCompleteRewardState = XDataCenter.FubenActivityPuzzleManager.CheckCompleteRewardIsGot(...)
    local isGotCompleteReward = gotCompleteRewardState == XFubenActivityPuzzleConfigs.CompleteRewardState.Rewarded
    if isGotCompleteReward then self:PlayAnimation("PlayVideoBtnGroupEnable") end
end

function XUiFubenActivityPuzzle:RefreshLeftPanelByPuzzleType(puzzleType, puzzleId)
    self.PanelReward:SetActiveEx(puzzleType == XFubenActivityPuzzleConfigs.PuzzleType.Define)
    self.PanelPasswordReward:SetActiveEx(puzzleType == XFubenActivityPuzzleConfigs.PuzzleType.Decryption)

    if puzzleType == XFubenActivityPuzzleConfigs.PuzzleType.Define then
        self.PanelReward:RefreshPanel(puzzleId)
    elseif puzzleType == XFubenActivityPuzzleConfigs.PuzzleType.Decryption then
        self.PanelPasswordReward:RefreshPanel(puzzleId)
    end
end

function XUiFubenActivityPuzzle:CheckHelpHitFace()
    local helpId = XDataCenter.FubenActivityPuzzleManager.GetActivityInfo().HelpId
    local helpTemplate = XHelpCourseConfig.GetHelpCourseTemplateById(helpId)
    local key = XFubenActivityPuzzleConfigs.HELP_HIT_FACE_KEY..helpId..XPlayer.Id
    local hitFaceData = XSaveTool.GetData(key)
    if not hitFaceData or hitFaceData == XFubenActivityPuzzleConfigs.HelpHitFaceState.UnHit then
        XUiManager.ShowHelpTip(helpTemplate.Function)
        XSaveTool.SaveData(key, XFubenActivityPuzzleConfigs.HelpHitFaceState.Hited)
    end
end

function XUiFubenActivityPuzzle:StartActivityTimer()
    local timeId = XDataCenter.FubenActivityPuzzleManager.GetActivityInfo().TimeId
    local startTime, endTime = XFunctionManager.GetTimeByTimeId(timeId)
    local nowTime = XTime.GetServerNowTimestamp()
    self.TxtDay.text = XUiHelper.GetTime(endTime - nowTime, XUiHelper.TimeFormatType.ACTIVITY)
    if nowTime < startTime then
        XUiManager.TipText("DragPuzzleActivityNotOpen")
        self:Close()
    elseif nowTime > endTime then
        XUiManager.TipText("DragPuzzleActivityEnd")
        self:Close()
    else
        self.ActivityTimer = XScheduleManager.ScheduleForever(function()
            local time = XTime.GetServerNowTimestamp()
            if time > endTime then
                self:Close()
                XUiManager.TipError(CS.XTextManager.GetText("DragPuzzleActivityEnd"))
                self:StopActivityTimer()
                return
            end
            self.TxtDay.text = XUiHelper.GetTime(endTime - time, XUiHelper.TimeFormatType.ACTIVITY)
        end, XScheduleManager.SECOND, 0)
    end
end

function XUiFubenActivityPuzzle:StopActivityTimer()
    if self.ActivityTimer then
        XScheduleManager.UnSchedule(self.ActivityTimer)
        self.ActivityTimer = nil
    end
end

function XUiFubenActivityPuzzle:RemoveAllRedPoints()
    for _, redPointId in ipairs(self.RedPointIdArr) do
        XRedPointManager.RemoveRedPointEvent(redPointId)
    end
end
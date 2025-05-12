local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XViewModelMaze = require("XEntity/XMaze/XViewModelMaze")

---@class XUiMazeMain:XLuaUi
local XUiMazeMain = XLuaUiManager.Register(XLuaUi, "UiMazeMain")

function XUiMazeMain:Ctor()
    ---@type XViewModelMaze
    self._ViewModel = XViewModelMaze.New()
    self._Timer = false
    self._TimerEndActivity = false
    self._IsPlayingAnimationOnEnable = false
    self._IsPlayingMovie = false
end

function XUiMazeMain:OnAwake()
    local uiNearRootObj = self.UiModel.UiNearRoot
    local cameraNearChoose = XUiHelper.TryGetComponent(uiNearRootObj, "UiMazeRoleRoomChoose", "Transform")
    local cameraNearRoom = XUiHelper.TryGetComponent(uiNearRootObj, "UiMazeRoleRoom", "Transform")
    cameraNearChoose.gameObject:SetActiveEx(false)
    cameraNearRoom.gameObject:SetActiveEx(false)

    local uiFarRootObj = self.UiModel.UiFarRoot
    local cameraFarChoose = XUiHelper.TryGetComponent(uiFarRootObj, "UiMazeRoleRoomChoose", "Transform")
    local cameraFarRoom = XUiHelper.TryGetComponent(uiFarRootObj, "UiMazeRoleRoom", "Transform")
    cameraFarChoose.gameObject:SetActiveEx(false)
    cameraFarRoom.gameObject:SetActiveEx(false)

    self._TimerEndActivity = XScheduleManager.ScheduleForever(function()
        self:CheckActivityEnd()
    end, 5 * XScheduleManager.SECOND)
    
    local componentPlayMusic = self.Transform:GetComponent("XPlayMusic")
    if componentPlayMusic then
        componentPlayMusic.enabled = false
    end
end

function XUiMazeMain:OnStart()
    self:BindExitBtns()
    self:RegisterClickEvent(self.BtnEnter, self.OnClickRoom)
    self:RegisterClickEvent(self.BtnArchiveStory, self.OnClickStory)
    self:RegisterClickEvent(self.BtnTask, self.OnClickTask)
    self:RegisterClickEvent(self.PanelClick, self.OnClickTicket)
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XMazeConfig.GetTicketItemId())
    self:BindHelpBtn(self.BtnHelp, XMazeConfig.GetHelpKey())
    self._IsPlayingAnimationOnEnable = true
    self:PlayAnimation("AnimEnable1", function()
        self._IsPlayingAnimationOnEnable = false
        self:PlayAnimation("UiLoop", nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.Loop)
        self:AutoRequestGetTicket()
    end)
end

function XUiMazeMain:OnEnable()
    if not self._IsPlayingAnimationOnEnable then
        self:PlayAnimation("UiLoop")
    end
    XEventManager.AddEventListener(XEventId.EVENT_MOVIE_END, self.AutoRequestGetTicket, self)

    if self._ViewModel:IsPlayMovie() then
        self:PlayMovie()
    else
        self:PlayBgm()
    end

    if not self._Timer then
        self:UpdateTimeActivity()
        self:UpdateTimeTicket()
        self._Timer = XScheduleManager.ScheduleForever(function()
            self:UpdateTimeActivity()
            self:UpdateTimeTicket()
            self:AutoRequestGetTicket()
        end, XScheduleManager.SECOND)
    end

    self:Update()
end

function XUiMazeMain:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_MOVIE_END, self.AutoRequestGetTicket, self)
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
end

function XUiMazeMain:OnDestroy()
    XScheduleManager.UnSchedule(self._TimerEndActivity)
end

function XUiMazeMain:PlayMovie()
    local movieId = self._ViewModel:GetStoryId()
    if movieId then
        self._ViewModel:SetHasPlayMovie()
        self._IsPlayingMovie = true
        XDataCenter.MovieManager.PlayMovie(movieId, function()
            XDataCenter.GuideManager.HandleUiOpen(self.Name)
            self:PlayBgm()
            self._IsPlayingMovie = false
        end, function()
            XDataCenter.GuideManager.HandleUiOpen(self.Name)
            self:PlayBgm()
            self._IsPlayingMovie = false
        end, nil, false)
        return true
    end
    return false
end

function XUiMazeMain:AutoRequestGetTicket()
    if self._IsPlayingAnimationOnEnable then
        return
    end
    if self._IsPlayingMovie then
        return
    end
    XDataCenter.MazeManager.AutoRequestGetTicket()
end

function XUiMazeMain:OnClickRoom()
    XLuaUiManager.Open("UiMazeRoleRoom")
end

function XUiMazeMain:OnClickStory()
    XLuaUiManager.Open("UiMazeArchiveStory")
end

function XUiMazeMain:OnClickTask()
    XLuaUiManager.Open("UiMazeTask")
end

function XUiMazeMain:Update()
    local taskProgress, taskAmount = self._ViewModel:GetTaskProgress()
    self.BtnTask:SetNameByGroup(1, string.format("<i>%d/%d</i>", taskProgress, taskAmount))

    if self.Red then
        self.Red.gameObject:SetActiveEx(self._ViewModel:IsShowTaskRedDot())
    end
end

function XUiMazeMain:UpdateTimeActivity()
    local remainTime = self._ViewModel:GetRemainTimeActivity()
    local timeStr = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.ACTIVITY)
    self.TxtTime.text = timeStr
end

function XUiMazeMain:CheckActivityEnd()
    local remainTime = self._ViewModel:GetRemainTimeActivity()
    if remainTime <= 0 then
        XLuaUiManager.RunMain()
        XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
    end
end

function XUiMazeMain:UpdateTimeTicket()
    local remainTime = self._ViewModel:GetRemainTimeTicket()
    local timeStr = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.DAY_HOUR)
    self.TxtTicketTime.text = timeStr
end

function XUiMazeMain:OnClickTicket()
    if XViewModelMaze:IsGetTicket() then
        XUiManager.TipText("MazeHasGetTicket")
        return
    end
    self:AutoRequestGetTicket()
end

function XUiMazeMain:PlayBgm()
    local componentPlayMusic = self.Transform:GetComponent("XPlayMusic")
    if componentPlayMusic then
        componentPlayMusic.enabled = true
    end
end

return XUiMazeMain
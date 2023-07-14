local tableInsert = table.insert
local CSXTextManagerGetText = CS.XTextManager.GetText
local TipSkipTitle = CSXTextManagerGetText("MovieSkipTipTitle")
local TipSkipContent = CSXTextManagerGetText("MovieSkipTipContent")
local XUiGridMovieActor = require("XUi/XUiMovie/XUiGridMovieActor")

local XUiMovie = XLuaUiManager.Register(XLuaUi, "UiMovie")

function XUiMovie:OnAwake()
    self:AddListener()
end

function XUiMovie:OnStart(hideSkipBtn)
    self:InitView()

    self.BtnSkip.gameObject:SetActiveEx(not hideSkipBtn)
    XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_UI_OPEN, self)
end

function XUiMovie:OnEnable()
    XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_BREAK_BLOCK)
end

function XUiMovie:OnDestroy()
    XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_UI_DESTROY)
end

function XUiMovie:InitView()
    self.FullScreenDialogUsingIndex = 1
    self.FullScreenDialogGrids = {}
    self.AnimPrefabDic = {}
    self.EffectGoDic = {}
    self.PanelEffects = {
        self.EffectBg,
        self.EffectCha,
        self.EffectFull,
    }
    self.Actors = {}
    for actorIndex = 1, XMovieConfigs.MAX_ACTOR_NUM do
        tableInsert(self.Actors, XUiGridMovieActor.New(self, actorIndex))
    end

    self.PanelElement.gameObject:SetActiveEx(true)
    self.PanelDialog.gameObject:SetActiveEx(false)
    self.PanelFullScreenDialog.gameObject:SetActiveEx(false)
    self.PanelSelectableDialog.gameObject:SetActiveEx(false)
    self.PanelTheme.gameObject:SetActiveEx(false)
    self.PanelSummer.gameObject:SetActiveEx(false)
    self.PanelSelectableDialog.gameObject:SetActiveEx(false)
    self.PanelMask.gameObject:SetActiveEx(false)
    self.PanelStaff.gameObject:SetActiveEx(false)
end

function XUiMovie:AddListener()
    self.BtnSkip.CallBack = function() self:OnClickBtnSkip() end
    self.BtnReview.CallBack = function() self:OnClickBtnReview() end
    self.BtnAuto.CallBack = function() self:OnClickBtnAuto() end
    self.BtnTurn.CallBack = function() self:OnClickBtnTurn() end
    self.BtnHide.CallBack = function() self:OnClickBtnHide() end
    self.PanelMaskInputHandler:AddPointerClickListener(handler(self, self.OnClickBtnPause))
    self.PanelHideMaskInputHandler:AddPointerClickListener(handler(self,self.OnClickHideMask))
end

function XUiMovie:OnClickBtnSkip()
    local description = XDataCenter.MovieManager.GetMovieDescription()
    local closeCb = function() 
        XDataCenter.MovieManager.StopMovie()
    end
    if description and description ~= "" then
        XLuaUiManager.Open("UiStorySkipDialog", description, closeCb)
    else
        XUiManager.SystemDialogTip(TipSkipTitle, TipSkipContent, XUiManager.DialogType.Normal, nil, closeCb)
    end
end

function XUiMovie:OnClickBtnReview()
    self:OpenChildUi("UiMovieReview")
    self:ResetAutoPlay()
end

function XUiMovie:OnClickHideMask()
    self.PanelHideMask.gameObject:SetActiveEx(false)
    self.PanelDialogCanvasGroup.alpha = 1
    self.TopBtnCanvasGroup.alpha = 1
end

function XUiMovie:OnClickBtnHide()
    self.PanelHideMask.gameObject:SetActiveEx(true)
    self.PanelDialogCanvasGroup.alpha = 0
    self.TopBtnCanvasGroup.alpha = 0
    self:ResetAutoPlay()
end

function XUiMovie:OnClickBtnPause()
    if not XDataCenter.MovieManager.IsAutoPlay() then
        return
    end
    XDataCenter.MovieManager.SwitchMovieState()
    local isMoviePause = XDataCenter.MovieManager.IsMoviePause()
    if isMoviePause then
        self:PlayAnimation("ImgPauseIconEnable")
    else
        self:PlayAnimation("ImgPauseIconDisable")
    end
    self.ImgPauseIcon.gameObject:SetActiveEx(isMoviePause)
end
function XUiMovie:OnClickBtnAuto()
    XDataCenter.MovieManager.SwitchAutoPlay()

    if XDataCenter.MovieManager.IsMoviePause() then
        XDataCenter.MovieManager.SetMoviePause(false)
    end
    local isAutoPlay = XDataCenter.MovieManager.IsAutoPlay()
    self.BtnTurn:SetDisable(isAutoPlay, not isAutoPlay)
    self.PanelMask.gameObject:SetActiveEx(isAutoPlay)
    self.ImgPauseIcon.gameObject:SetActiveEx(false)
end

function XUiMovie:OnClickBtnTurn()
    XDataCenter.MovieManager.BackToLastAction()
end

function XUiMovie:ResetAutoPlay()
    if XDataCenter.MovieManager.IsAutoPlay() then
        self.BtnAuto:SetButtonState(XUiButtonState.Normal)
        self:OnClickBtnAuto()
    end
end

function XUiMovie:GetActor(actorIndex)
    local actor = self.Actors[actorIndex]
    if not actor then
        XLog.Error("XUiMovie:GetActor error:ActorIndex is not match, actorIndex is " .. actorIndex)
    end
    return actor
end

function XUiMovie:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiMovie:Show()
    self.GameObject:SetActiveEx(true)
end
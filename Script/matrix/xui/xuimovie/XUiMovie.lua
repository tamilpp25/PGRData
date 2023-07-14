local tableInsert = table.insert
local CSXTextManagerGetText = CS.XTextManager.GetText
local TipSkipTitle = CSXTextManagerGetText("MovieSkipTipTitle")
local TipSkipContent = CSXTextManagerGetText("MovieSkipTipContent")
local XUiGridMovieActor = require("XUi/XUiMovie/XUiGridMovieActor")
local XUiGridMovieSpineActor = require("XUi/XUiMovie/XUiGridMovieSpineActor")
local XUiPanelMovie3D = require("XUi/XUiMovie/XUiPanelMovie3D")
local XUiMovie = XLuaUiManager.Register(XLuaUi, "UiMovie")

local InsertDirection = {
    Left = 1,
    Right = 2
}

local InsertPanelEnableAnimationDic = {
    [InsertDirection.Left] = "PanelinsertLeftEnable",
    [InsertDirection.Right] = "PanelinsertRightEnable"
}

local InsertPanelDisableAnimationDic = {
    [InsertDirection.Left] = "PanelinsertLeftDisable",
    [InsertDirection.Right] = "PanelinsertRightDisable"
}


function XUiMovie:OnAwake()

    self:AddListener()
end

function XUiMovie:OnStart(hideSkipBtn)
    self:InitView()
    self:OnInitScene()
    self.BtnSkip.gameObject:SetActiveEx(not hideSkipBtn)
    XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_UI_OPEN, self)
end

function XUiMovie:OnEnable()
    self.LastOperationType = CS.XInputManager.CurOperationType
    CS.XInputManager.SetCurOperationType(CS.XOperationType.System)
    XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_BREAK_BLOCK)
end

function XUiMovie:SelectPanelShowing()
    return self.PanelSelectableDialog.gameObject.activeSelf;
end

function XUiMovie:OnDisable()
    CS.XInputManager.SetCurOperationType(self.LastOperationType)
end

function XUiMovie:OnDestroy()
    XDataCenter.MovieManager.RestSpeed()
    for _, actor in pairs(self.ActorDic) do
        if not XTool.UObjIsNil(actor) then
            actor:Destroy()
        end
    end
    self.ActorDic = {}

    for _, camera in pairs(self.CameraDic) do
        if not XTool.UObjIsNil(camera) then
            CS.UnityEngine.GameObject.Destroy(camera.gameObject)
        end
    end
    self.CameraDic = {}

    for _, timeline in pairs(self.TimelineDic) do
        if not XTool.UObjIsNil(timeline) then
            CS.UnityEngine.GameObject.Destroy(timeline.gameObject)
        end
    end
    self.TimelineDic = {}

    XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_UI_DESTROY)
    self:ReleaseResource()
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
        tableInsert(self.Actors, XUiGridMovieActor.New(self,self["PanelActor" .. actorIndex], actorIndex))
    end
    self.SpineActors = {}
    for actorIndex = 1, XMovieConfigs.MAX_SPINE_ACTOR_NUM do
        tableInsert(self.SpineActors, XUiGridMovieSpineActor.New(self, self["PanelSpineActor" .. actorIndex], actorIndex))
    end
    
    self.PanelRole.gameObject:SetActiveEx(true)
    self.PanelRole2.gameObject:SetActiveEx(true)
    self.PanelDialogRole.gameObject:SetActiveEx(true)
    self.PanelSpineRole.gameObject:SetActiveEx(true)
    self.PanelDialog.gameObject:SetActiveEx(false)
    self.PanelFullScreenDialog.gameObject:SetActiveEx(false)
    self.PanelSelectableDialog.gameObject:SetActiveEx(false)
    self.PanelTheme.gameObject:SetActiveEx(false)
    self.PanelSummer.gameObject:SetActiveEx(false)
    self.PanelSelectableDialog.gameObject:SetActiveEx(false)
    self.PanelMask.gameObject:SetActiveEx(false)
    self.BtnScreenSpeed.gameObject:SetActiveEx(false)
    self.BtnScreenSpeed.ExitCheck = false
    self.PanelStaff.gameObject:SetActiveEx(false)
    self.PanelCenterTip.gameObject:SetActiveEx(false)
    self.Panel3D = XUiPanelMovie3D.New(self.Panel3d, self)
    self:InitSpeedGroup()
end

function XUiMovie:OnInitScene()
    self.CameraDic = {}
    self.ActorDic = {}
    self.TimelineDic = {}

    ---@type UnityEngine.Transform
    local root = self.UiModelGo.transform
    self.CameraRoot = root:FindTransform("CameraRoot")
    self.ActorRoot = root:FindTransform("ActorRoot")
    ---@type Cinemachine.CinemachineBrain
    self.CineMachineBrain = root:FindTransform("UiNearCamera"):GetComponent(typeof(CS.Cinemachine.CinemachineBrain))
    self.DefaultBlendDefine = self.CineMachineBrain.m_DefaultBlend
    self.CutBlendDefine = CS.Cinemachine.CinemachineBlendDefinition()
    
    self.TimelineRoot = root:FindTransform("TimelineRoot")
    self.MixRoot = root.parent.parent:FindTransform("MixRoot")
    self.MixActorRoot = self.MixRoot:FindTransform("MixActorRoot")
    ---@type UnityEngine.UI.RawImage
    self.MixBg = self.MixRoot:FindTransform("Bg"):GetComponent(typeof(CS.UnityEngine.UI.RawImage))
    ---@type UnityEngine.Camera
    self.MixUiCamera = self.MixRoot:FindTransform("MixUiCamera"):GetComponent(typeof(CS.UnityEngine.Camera))
    self.MixCanvas = self.MixRoot:FindTransform("MixCanvas")
    self:AutoResizeMixCanvas()
end

function XUiMovie:AddListener()
    self.BtnSkip.CallBack = function() self:OnClickBtnSkip() end
    self.BtnReview.CallBack = function() self:OnClickBtnReview() end
    self.BtnAuto.CallBack = function() self:OnClickBtnAuto() end
    self.BtnTurn.CallBack = function() self:OnClickBtnTurn() end
    self.BtnHide.CallBack = function() self:OnClickBtnHide() end
    XUiHelper.RegisterClickEvent(self, self.BtnScreenSpeed, self.OnClickBtnScreenSpeed)
    self.PanelMaskInputHandler:AddPointerClickListener(handler(self, self.OnClickBtnPause))
    self.PanelHideMaskInputHandler:AddPointerClickListener(handler(self, self.OnClickHideMask))
end

function XUiMovie:OnClickBtnSkip()
    if self:SelectPanelShowing() then
        return
    end
    local description = XDataCenter.MovieManager.GetMovieDescription()
    local closeCb = function()
        local dict = {}
        dict["story_id"] = XDataCenter.MovieManager.GetCurPlayingMovieId()
        dict["role_level"] = XPlayer.GetLevel()
        CS.XRecord.Record(dict, "200003", "StorylineSkip")
        XDataCenter.MovieManager.StopMovie()
    end
    if description and description ~= "" then
        XLuaUiManager.Open("UiStorySkipDialog", description, closeCb)
    else
        XLuaUiManager.Open("UiDialogCanvasDialog", TipSkipTitle, TipSkipContent, XUiManager.DialogType.Normal, nil, closeCb)
    end
end

function XUiMovie:OnClickBtnReview()
    if self:SelectPanelShowing() then
        return
    end
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
    if self:SelectPanelShowing() then
        return
    end
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
    if self:SelectPanelShowing() then
        return
    end

    local isAutoPlay = not XDataCenter.MovieManager.IsAutoPlay()
    self.BtnTurn:SetDisable(isAutoPlay, not isAutoPlay)
    self.PanelMask.gameObject:SetActiveEx(isAutoPlay)
    self.ImgPauseIcon.gameObject:SetActiveEx(false)

    -- 显示倍速
    self.BtnScreenSpeed.gameObject:SetActiveEx(isAutoPlay)
    if isAutoPlay then
        self:ShowSpeedList(false)
        self.BtnAuto.ButtonState = CS.UiButtonState.Select
    else
        self.BtnAuto.ButtonState = CS.UiButtonState.Normal
    end

    XDataCenter.MovieManager.SwitchAutoPlay()
    if XDataCenter.MovieManager.IsMoviePause() then
        XDataCenter.MovieManager.SetMoviePause(false)
    end
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

function XUiMovie:OnClickBtnScreenSpeed()
    local isShow = not self.IsShowSpeedList
    self:ShowSpeedList(isShow)
end

function XUiMovie:ShowSpeedList(isShow)
    self.IsShowSpeedList = isShow
    self.PanelSpeedGroup.gameObject:SetActiveEx(isShow)
    local state = isShow and XUiButtonState.Select or XUiButtonState.Normal
    self.BtnScreenSpeed:SetButtonState(state)
end

function XUiMovie:GetActor(actorIndex)
    local actor = self.Actors[actorIndex]
    if not actor then
        XLog.Error("XUiMovie:GetActor error:ActorIndex is not match, actorIndex is " .. actorIndex)
    end
    return actor
end

function XUiMovie:GetSpineActor(actorIndex)
    local actor = self.SpineActors[actorIndex]
    if not actor then
        XLog.Error("XUiMovie:GetSpineActor error:ActorIndex is not match, actorIndex is " .. actorIndex)
    end
    return actor
end

function XUiMovie:GetTipActor(actorIndex)
    local actor = self.InsertActors[actorIndex]
    if not actor then
        XLog.Error("XUiMovie:GetTipActor error:ActorIndex is not match, actorIndex is " .. actorIndex)
    end
    return actor
end

function XUiMovie:GetModelActor(roleId)
    local actor = self.ActorDic[roleId]
    if not actor then
        XLog.Debug("XUiMovie:GetModelActor error:ActorIndex is not match, actorIndex is " .. roleId)
    end
    return actor
end

function XUiMovie:AddModelActor(roleId, transform, isShow)
    --todo  aafasou 加载角色模型
    if self.ActorDic[roleId] then
        XLog.Error("XUiMovie:LoadModelActor,重复载入角色,roleId", roleId)
        return
    end
    local proxy = CS.Movie.XMovie3DManager.Get3DRoleProxy(roleId)
    proxy:Show(transform.Position, transform.Rotation)
    proxy.transform.parent = self.ActorRoot
    self.ActorDic[roleId] = proxy
end

function XUiMovie:AddTimeline(path, name, position, rotation)
    if self.TimelineDic[name] then
        return
    end
    local timelineObj = CS.LoadHelper.InstantiateGameObject(path)
    timelineObj.transform.parent = self.TimelineRoot
    timelineObj.transform.position = position
    timelineObj.transform.localEulerAngles = rotation
    ---@type UnityEngine.Playables.PlayableDirector
    local timelineHelper = timelineObj:GetTimelineHelper()
    if timelineHelper then
        self.TimelineDic[name] = timelineHelper
    else
        XLog.Error(" XUiMovie:AddTimeline 添加的资源不带有PlayableDirector，请检查对应预制体,Path:", path)
    end
end

function XUiMovie:GetTimeline(name)
    if self.TimelineDic[name] then
        return self.TimelineDic[name]
    else
        XLog.Error("XUiMovie:GetTimeline 对应Timeline资源尚未加载 name:", name)
    end
end

function XUiMovie:AddCamera(name,cameraPath,transform)
    if not cameraPath then
        return
    end
    if self.CameraDic[name] then
        return
    end
    local container = CS.UnityEngine.GameObject()
    container.name = name
    container.transform.parent = self.CameraRoot
    
    local obj = container:LoadPrefab(cameraPath)
    obj.transform.localPosition = transform.Position
    obj.transform.localEulerAngles = transform.Rotation
    self.CameraDic[name] = container
    container.gameObject:SetActiveEx(false)
end

function XUiMovie:SwitchCamera(name,time)
    ---@type UnityEngine.GameObject
    local camera = self.CameraDic[name]
    if not camera then
        XLog.Error("XUiMovie:PlayCameraAnimation:没有加载对应的Camera动画,name:", name)
        return
    end
    for _, obj in pairs(self.CameraDic) do
        obj.gameObject:SetActiveEx(false)
    end
    local define = self.CineMachineBrain.m_DefaultBlend
    define.m_Time = time
    self.CineMachineBrain.m_DefaultBlend = define
    camera.gameObject:SetActiveEx(true)
end

function XUiMovie:Switch3DMovie()
    self.Bg.gameObject:SetActiveEx(false)
    self.RImgBg1.gameObject:SetActiveEx(false)
    self.TopBtn.gameObject:SetActiveEx(false)
    self.Panel3d.gameObject:SetActiveEx(true)
end

function XUiMovie:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiMovie:Show()
    self.GameObject:SetActiveEx(true)
end

function XUiMovie:SetMixBg(path)
    if not string.IsNilOrEmpty(path) then
        self.MixBg:SetRawImage(path)
        self.MixBg.gameObject:SetActiveEx(true)
    end
end

function XUiMovie:AutoResizeMixCanvas()
    local v = self.MixCanvas.transform.position - self.MixUiCamera.transform.position
    local offset = CS.UnityEngine.Vector3.Project(v, self.MixUiCamera.transform.position)
    self.MixCanvas.transform.position = self.MixCanvas.transform.position + offset
    
    local height = self.MixUiCamera.orthographicSize * 2
    local width = height * self.MixUiCamera.aspect
    ---@type UnityEngine.RectTransform
    local rectTransform = self.MixCanvas:GetComponent(typeof(CS.UnityEngine.RectTransform))
    rectTransform.sizeDelta = CS.UnityEngine.Vector2(width, height)
end

function XUiMovie:SwitchMixPanel()
    self.MixRoot.gameObject:SetActiveEx(true)
    self:Switch3DMovie()
end

function XUiMovie:ShowInsertTips()
    self.Panelinsert02.gameObject:SetActiveEx(true)
    self:PlayAnimation("Panelinsert02Enable")
end 

function XUiMovie:HideInsertTips()
    self:PlayAnimation("Panelinsert02Disable",function()
        self.Panelinsert02.gameObject:SetActiveEx(false)
    end)
end

function XUiMovie:SetInsertBg(bgPath)
    if not string.IsNilOrEmpty(bgPath) then
        self.InsertBg:SetRawImage(bgPath)
    end
end

function XUiMovie:GetInsertBgActor(direction)
    local actor = self.InsertBgActor[direction]
    if not actor then
        XLog.Error("XUiMovie:GetInsertBgActor error:ActorIndex is not match, actorIndex is " .. direction)
        return
    end
    return actor
end

function XUiMovie:SetInsertPanelBg(bgPath,direction)
    if not string.IsNilOrEmpty(bgPath) then
        if direction == InsertDirection.Left then
            self.RImgLeftBg:SetRawImage(bgPath)
        elseif direction == InsertDirection.Right then
            self.RImgRightBg:SetRawImage(bgPath)    
        end
    end
end

function XUiMovie:PlayInsertPanelEnableAnimation(direction)
    self:PlayAnimation(InsertPanelEnableAnimationDic[direction])
end 

function XUiMovie:PlayInsertPanelDisableAnimation(direction)
    self:PlayAnimation(InsertPanelDisableAnimationDic[direction])
end

-- 初始化倍速选项
function XUiMovie:InitSpeedGroup()
    self.SpeedBtns = {}
    local configs = XMovieConfigs.GetMovieSpeedConfig()
    for i, config in ipairs(configs) do
        local go = self.BtnSpeed.gameObject
        if i > 1 then
            go = CS.UnityEngine.Object.Instantiate(self.BtnSpeed.gameObject, self.PanelSpeedGroup.transform)
        end

        local uiButton = go:GetComponent("XUiButton")
        uiButton:SetName(config.Name)
        table.insert(self.SpeedBtns, uiButton)
    end

    self.PanelSpeedGroup:Init(self.SpeedBtns, function(tabIndex) self:OnClickSpeedButtonCallBack(tabIndex) end)
    local defaultIndex = #configs
    self.PanelSpeedGroup:SelectIndex(defaultIndex)
end

-- 选中速度按钮回调
function XUiMovie:OnClickSpeedButtonCallBack(index)
    -- 关闭倍速列表
    self:ShowSpeedList(false)

    if self.SpeedIndex == index then 
        return
    end

    self.SpeedIndex = index
    local curSpeed = XDataCenter.MovieManager.GetSpeed()
    local config = XMovieConfigs.GetMovieSpeedConfig(self.SpeedIndex)
    local selectSpeed = config.Speed / 1000
    if selectSpeed ~= curSpeed then 
        XDataCenter.MovieManager.SetSpeed(selectSpeed)
    end

    local config = XMovieConfigs.GetMovieSpeedConfig(index)
    local desc = XUiHelper.GetText("MovieSpeed", config.Name)
    self.BtnScreenSpeed:SetName(desc)
end

-- 加载资源，所有action均走这个接口
function XUiMovie:LoadResource(path)
    if not self.ResourceDic then
        self.ResourceDic = {}
    end

    local resource = self.ResourceDic[path]
    if not resource then
        resource = CS.XResourceManager.Load(path)
        self.ResourceDic[path] = resource
    end
    return resource
end

-- 释放资源
function XUiMovie:ReleaseResource()
    if self.ResourceDic then
        for _, resource in pairs(self.ResourceDic) do
            CS.XResourceManager.Unload(resource)
        end
        self.ResourceDic = nil
    end
end
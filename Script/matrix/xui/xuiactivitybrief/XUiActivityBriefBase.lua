--[[    活动界面的功能相关和各版本的界面临时代码写在这里
    XUiActivityBriefRefreshButton.lua：活动按钮相关的代码（按钮的点击、刷新，红点显示、跳转）
    XActivityBrieIsOpen.lua：管理各按钮的开放条件与显示日期的代码
    XActivityBrieButton.lua：按钮的交互逻辑代码
]]
local XUiActivityBriefBase = XLuaUiManager.Register(XLuaUi, "UiActivityBriefBase")
local OpMovieId = CS.XGame.ClientConfig:GetInt("ActivityBriefMovie")
local XUiActivityBriefRefreshButton = require("XUi/XUiActivityBrief/XUiActivityBriefRefreshButton")

local Vector2 = CS.UnityEngine.Vector2

function XUiActivityBriefBase:OnAwake()
    self:AutoAddListener()
end

function XUiActivityBriefBase:OnStart(type)
    self.IsFromMain = true
    self.PanelType = type or XActivityBriefConfigs.PanelType.Main
    ---@type Spine.Unity.SkeletonAnimation[]|Spine.Unity.SkeletonGraphic[]
    self.LoadSpineObjListDir = {}
    ---@type Spine.Unity.SkeletonAnimation[]|Spine.Unity.SkeletonGraphic[]
    self.UiSpineObjListDir = {}

    self.UiActivityBriefRefreshButton = XUiActivityBriefRefreshButton.New(self, self.PanelType)
    self.BgType = XActivityBriefConfigs.GetActivityBgType(self.PanelType)
    
    self:InitSpineObj()

    -- 加载界面
    self:Refresh()

    -- 播放入场动画
    if self.PanelType == XActivityBriefConfigs.PanelType.Main then
        local firstOpen = XDataCenter.ActivityBriefManager.IsShowEnterAni(self.PanelType)
        if firstOpen then
            if OpMovieId ~= 0 then
                self:PlayMovie(function()
                    self:PlaySpecialEnterAnim()
                end)
            else
                self:PlaySpecialEnterAnim(function() self.UiActivityBriefRefreshButton:CheckBtnUnlockAnim() end)
            end
        else
            self:PlayEnterAnim(function() self.UiActivityBriefRefreshButton:CheckBtnUnlockAnim() end)
        end
    end
end

function XUiActivityBriefBase:OnEnable()
    local firstOpen = XDataCenter.ActivityBriefManager.IsShowEnterAni(self.PanelType)
    if firstOpen then
        XDataCenter.ActivityBriefManager.SetDontShowEnterAni(self.PanelType)
    else
        if not self.IsFromMain and self.PanelType == XActivityBriefConfigs.PanelType.Main then
            -- 避免跳转玩法界面后有进入剧情Ui等会造成程序Ui容器清空的情况返回活动面板主界面后动画播放不正确
            -- AnimEnable2不在播放状态且播放时长小于总时长
            if self.AnimEnable2.state ~= CS.Playable.PlayState.Playing and self.AnimEnable2.time <= self.AnimEnable2.duration then
                self.AnimEnable2:Play()
                self.AnimEnable2.time = self.AnimEnable2.duration
            end
            self:PlayLoopAnim()
        end
    end
    self.IsFromMain = false
    self.UiActivityBriefRefreshButton:Refresh()
end

function XUiActivityBriefBase:OnDisable()
    self:StopVideoSound()
end

function XUiActivityBriefBase:OnDestroy()
end


--region 监听事件

function XUiActivityBriefBase:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnBackSecond, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnMainUiSecond, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnVideo, self.OnClickBtnVideo)
    self:RegisterClickEvent(self.BtnNotice, self.OnClickBtnDetail)
    self:RegisterClickEvent(self.BtnNoticeSecond, self.OnClickBtnDetail)
    if self.BtnShield then
        self:RegisterClickEvent(self.BtnShield, self.OnClickSkip)
    end
end

function XUiActivityBriefBase:OnBtnBackClick()
    self:Close()
end

function XUiActivityBriefBase:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiActivityBriefBase:OnClickBtnDetail()
    XLuaUiManager.Open("UiWelfare")
end

function XUiActivityBriefBase:OnClickBtnVideo()
    self:PlayMovie(function()
        self:PlayAnimationWithMask("AnimEnable2")
    end)
end

--endregion


--region 通用函数

function XUiActivityBriefBase:PlayMovie(cbFunc)
    --此处不用self:SetActive, 由于self:SetActive会把uiModel的也隐藏导致无法播放下面的动画
    self.GameObject:SetActiveEx(false)

    XDataCenter.VideoManager.PlayMovie(OpMovieId, function()
        self.GameObject:SetActiveEx(true)
        if cbFunc then
            cbFunc()
        end
    end)
end

function XUiActivityBriefBase:Refresh()
    self:RefreshDefaultSkipBtn()
    if self.BgType == XActivityBriefConfigs.BgType.Spine then
        self:RefreshSpinePanel()
    elseif self.BgType == XActivityBriefConfigs.BgType.Scene then
        self:RefreshScene()
    elseif self.BgType == XActivityBriefConfigs.BgType.Video then
        self:RefreshVideoPanel()
    end
end

function XUiActivityBriefBase:RefreshDefaultSkipBtn()
    if self.BtnShield then
        if XDataCenter.ActivityBriefManager.GetIsSkipAnim(self.PanelType) then
            self.BtnShield.ButtonState = CS.UiButtonState.Select
        else
            self.BtnShield.ButtonState = CS.UiButtonState.Normal
        end
    end
end

function XUiActivityBriefBase:OnClickSkip()
    local isSkip = XDataCenter.ActivityBriefManager.GetIsSkipAnim(self.PanelType)
    XDataCenter.ActivityBriefManager.SetIsSkipAnim(self.PanelType, not isSkip)
    self:RefreshDefaultSkipBtn()
end

---特殊入场动画播放(特殊入场 + 循环动画)
function XUiActivityBriefBase:PlaySpecialEnterAnim(cb)
    self:PlayAnimationWithMask("AnimEnable2", cb)
    if self.BgType == XActivityBriefConfigs.BgType.Spine then
        self:PlaySpineSpecialEnterAnim()
    elseif self.BgType == XActivityBriefConfigs.BgType.TimeLine then
        self:PlayTimelineSpecialEnterAnim()
    elseif self.BgType == XActivityBriefConfigs.BgType.Scene then
        self:PlaySceneSpecialEnterAnim()
    elseif self.BgType == XActivityBriefConfigs.BgType.Video then
        self:PlayVideoSpecialEnterAnim()
    end
    XDataCenter.ActivityBriefManager.SetDontShowEnterAni(self.PanelType)
end

---入场动画播放(普通入场 + 循环动画)
function XUiActivityBriefBase:PlayEnterAnim(cb)
    if not XDataCenter.ActivityBriefManager.CheckIsFirstReadedAnim(self.PanelType) or not XDataCenter.ActivityBriefManager.GetIsSkipAnim(self.PanelType) then
        if self.BgType == XActivityBriefConfigs.BgType.Spine then
            self:PlayAnimationWithMask("AnimEnable2", cb)
            self:PlaySpineEnterAnim()
        elseif self.BgType == XActivityBriefConfigs.BgType.TimeLine then
            self:PlayAnimationWithMask("AnimEnable2", cb)
            self:PlayTimelineEnterAnim()
        elseif self.BgType == XActivityBriefConfigs.BgType.Scene then
            self:PlayAnimationWithMask("AnimEnable2", cb)
            self:PlaySceneEnterAnim()
        elseif self.BgType == XActivityBriefConfigs.BgType.Video then
            self:PlayVideoEnterAnim()
        end
    else
        self:PlayLoopAnim(cb)
    end
    XDataCenter.ActivityBriefManager.SetDontShowEnterAni(self.PanelType)
end

function XUiActivityBriefBase:PlayLoopAnim(cb)
    self:PlayAnimationWithMask("AnimEnable1", cb)
    if self.BgType == XActivityBriefConfigs.BgType.Spine then
        self:PlaySpineLoopAnim()
    elseif self.BgType == XActivityBriefConfigs.BgType.TimeLine then
        self:PlayTimelineLoopAnim()
    elseif self.BgType == XActivityBriefConfigs.BgType.Scene then
        self:PlaySceneLoopAnim()
    elseif self.BgType == XActivityBriefConfigs.BgType.Video then
        self:PlayVideoLoopAnim()
    end
end

---特殊动画需求,可能插入与各处，由需求而定
function XUiActivityBriefBase:PlaySpecialAnim()
    --v2.3 有个按钮的图片优化需要由动效动画
    --self:PlayAnimation("UiLoop",nil,nil,CS.UnityEngine.Playables.DirectorWrapMode.Loop)
end

--endregion


--region Spine背景相关
function XUiActivityBriefBase:RefreshSpinePanel()
    self:SetVideoPanelActive(false)
    if self.PanelType == XActivityBriefConfigs.PanelType.Main then
        self.PanelActivity1.gameObject:SetActiveEx(true)
        self.PanelActivity2.gameObject:SetActiveEx(false)
        self.PanelActivityInfo1.gameObject:SetActiveEx(true)
        self.PanelActivityInfo2.gameObject:SetActiveEx(false)
    elseif self.PanelType == XActivityBriefConfigs.PanelType.Second then
        self.PanelActivity1.gameObject:SetActiveEx(false)
        self.PanelActivity2.gameObject:SetActiveEx(true)
        self.PanelActivityInfo1.gameObject:SetActiveEx(false)
        self.PanelActivityInfo2.gameObject:SetActiveEx(true)
    end
    self:SpineAutoFit()
end

function XUiActivityBriefBase:InitSpineObj()
    if self.BgType ~= XActivityBriefConfigs.BgType.Spine then
        return
    end
    for i = 1, 3 do
        local spinePanelName = "PanelSpine"..i
        if self[spinePanelName] and not XTool.UObjIsNil(self[spinePanelName]) then
            local SkeletonAnimationCSArray = self[spinePanelName].transform:GetComponentsInChildren(typeof(CS.Spine.Unity.SkeletonAnimation))
            local SkeletonGraphicCSArray = self[spinePanelName].transform:GetComponentsInChildren(typeof(CS.Spine.Unity.SkeletonGraphic))
            if SkeletonAnimationCSArray.Length ~= 0 or SkeletonGraphicCSArray.Length ~= 0 then
                local spineObjList = {}
                for j = 0, SkeletonAnimationCSArray.Length - 1, 1 do
                    spineObjList[#spineObjList + 1] = SkeletonAnimationCSArray[j]
                end
                for j = 0, SkeletonGraphicCSArray.Length - 1, 1 do
                    spineObjList[#spineObjList + 1] = SkeletonGraphicCSArray[j]
                end
                if not XTool.IsTableEmpty(spineObjList) then
                    self.UiSpineObjListDir[#self.UiSpineObjListDir + 1] = spineObjList
                end
            end
        end
    end
end

---设置Spine背景显隐
function XUiActivityBriefBase:SetSpinePanelActive(active)
    self.PanelActivity1.gameObject:SetActiveEx(active)
    self.PanelActivity2.gameObject:SetActiveEx(active)
end

---返回加载的动态骨骼组(因为可能存在加载多个SkeletonAnimation集合成的一个预制体，所以返回的是table)
function XUiActivityBriefBase:LoadSpine(transform, index)
    -- 根据主副面板加载动画
    local path = XActivityBriefConfigs.GetSpinePathByType(self.PanelType, index)
    if not string.IsNilOrEmpty(path) then
        transform.gameObject:SetActiveEx(true)
        local spine = transform:LoadSpinePrefab(path)
        local obj = spine:GetComponent("SkeletonAnimation")
        if not obj or XTool.UObjIsNil(obj) then
            obj = spine:GetComponent("SkeletonGraphic")
        end
        local spines = {}
        -- 收集所有的spine控件
        if not XTool.UObjIsNil(obj) then
            table.insert(spines, obj)
        else
            local objList = spine.transform:GetComponentsInChildren(typeof(CS.Spine.Unity.SkeletonAnimation))
            if objList.Length == 0 then
                objList = spine.transform:GetComponentsInChildren(typeof(CS.Spine.Unity.SkeletonGraphic))
            end
            for i = 0, objList.Length - 1, 1 do
                table.insert(spines, objList[i])
            end
        end
        return spines
    end
end

---spine动画底边对齐适配
function XUiActivityBriefBase:SpineAutoFit()
    local transform = self.ActivitySpineLogin
    if XTool.UObjIsNil(transform) then return end
    local rate = transform.localScale.y / 60
    transform.anchoredPosition = Vector2(transform.anchoredPosition.x, transform.anchoredPosition.y * rate)
end

---spine对象播放动画
function XUiActivityBriefBase:_PlaySpineObjAnimation(spineObject, fromAnim, toAnim)
    if XTool.UObjIsNil(spineObject) then return end

    -- 判断Spine是否存在动画轨道
    local isHaveFrom = fromAnim and spineObject.skeletonDataAsset:GetSkeletonData(false):FindAnimation(fromAnim)
    local isHaveTo = toAnim and spineObject.skeletonDataAsset:GetSkeletonData(false):FindAnimation(toAnim)
    if isHaveFrom then
        --Delegate += 操作Lua写法
        local cb
        cb = function(track)
            if track.Animation.Name == fromAnim and isHaveTo then
                spineObject.AnimationState:SetAnimation(0, toAnim, true)
                spineObject.AnimationState:Complete('-', cb)
            end
        end
        spineObject.AnimationState:Complete('+', cb)
        -- 没有toAnim则fromAnim循环
        spineObject.AnimationState:SetAnimation(0, fromAnim, not isHaveTo)
    elseif isHaveTo then
        spineObject.AnimationState:SetAnimation(0, toAnim, true)
    end
end

---Spine对象组播放动画
function XUiActivityBriefBase:_PlaySpineAnimation(fromAnim, toAnim)
    if self.PanelType ~= XActivityBriefConfigs.PanelType.Main then
        return
    end
    -- 根据配置遍历播放
    for index, _ in pairs(XActivityBriefConfigs.GetSpinePathList(self.PanelType)) do
        local spineObjName = "PanelSpine"..(index + #self.UiSpineObjListDir)
        if not XTool.UObjIsNil(self[spineObjName]) then
            self.LoadSpineObjListDir[index] = self:LoadSpine(self[spineObjName], index)
            for _, spineObj in pairs(self.LoadSpineObjListDir[index]) do
                if toAnim then
                    self:_PlaySpineObjAnimation(spineObj, fromAnim, toAnim)
                else
                    self:_PlaySpineObjAnimation(spineObj, fromAnim)
                end
            end
        end
    end
    for _, uiSpineObjList in pairs(self.UiSpineObjListDir) do
        for _, uiSpineObj in ipairs(uiSpineObjList) do
            if toAnim then
                self:_PlaySpineObjAnimation(uiSpineObj, fromAnim, toAnim)
            else
                self:_PlaySpineObjAnimation(uiSpineObj, fromAnim)
            end
        end
    end
end

---Spine特殊入场动画
function XUiActivityBriefBase:PlaySpineSpecialEnterAnim()
    local enterName = XActivityBriefConfigs.GetSpecialEnterAnimName(self.PanelType)
    local loopName = XActivityBriefConfigs.GetLoopAnimName(self.PanelType)
    self:_PlaySpineAnimation(enterName, loopName)
end

---Spine入场动画
function XUiActivityBriefBase:PlaySpineEnterAnim()
    local enterName = XActivityBriefConfigs.GetEnterAnimName(self.PanelType)
    local loopName = XActivityBriefConfigs.GetLoopAnimName(self.PanelType)
    self:_PlaySpineAnimation(enterName, loopName)
end

---Spine循环动画
function XUiActivityBriefBase:PlaySpineLoopAnim()
    local loopName = XActivityBriefConfigs.GetLoopAnimName(self.PanelType)
    self:_PlaySpineAnimation(loopName)
end

--endregion


--region TimeLine背景相关 - (动画说之后可以用TimeLine控制Spine，因此预留此块功能)

function XUiActivityBriefBase:RefreshTimelineBg()
    self:SetSpinePanelActive(false)
    self:SetVideoPanelActive(false)

    self.PanelActivityInfo1.gameObject:SetActiveEx(self.PanelType == XActivityBriefConfigs.PanelType.Main)
    self.PanelActivityInfo2.gameObject:SetActiveEx(not (self.PanelType == XActivityBriefConfigs.PanelType.Main))
end

---播放TimeLine背景入场动画
function XUiActivityBriefBase:PlayTimelineSpecialEnterAnim()
    local specialEnterAnim = XActivityBriefConfigs.GetSpecialEnterAnimName(self.PanelType)
    local loopAnim = XActivityBriefConfigs.GetLoopAnimName(self.PanelType)
    self:PlayAnimationWithMask(specialEnterAnim, function ()
        self:PlayAnimation(loopAnim)
    end)
end

---播放TimeLine背景入场动画
function XUiActivityBriefBase:PlayTimelineEnterAnim()
    local enterAnim = XActivityBriefConfigs.GetEnterAnimName(self.PanelType)
    local loopAnim = XActivityBriefConfigs.GetLoopAnimName(self.PanelType)
    if string.IsNilOrEmpty(enterAnim) then
        self:PlayAnimation(loopAnim)
    else
        self:PlayAnimationWithMask(enterAnim, function ()
            self:PlayAnimation(loopAnim)
        end)
    end
end

function XUiActivityBriefBase:PlayTimelineLoopAnim()
    local loopAnim = XActivityBriefConfigs.GetLoopAnimName(self.PanelType)
    self:PlayAnimation(loopAnim)
end

--endregion


--region Scene背景相关

function XUiActivityBriefBase:RefreshScene()
    self:SetSpinePanelActive(false)
    self:SetVideoPanelActive(false)
    -- 加载3D场景
    self:LoadUiScene(XDataCenter.ActivityBriefManager.GetActivityMain3DBg(self.PanelType), XActivityBriefConfigs.GetMain3DBgModelPath(self.PanelType), nil, false)

    --self:SetGameObject()

    self.PanelActivityInfo1.gameObject:SetActiveEx(self.PanelType == XActivityBriefConfigs.PanelType.Main)
    self.PanelActivityInfo2.gameObject:SetActiveEx(not (self.PanelType == XActivityBriefConfigs.PanelType.Main))
end

---播放3D场景预设上的Timeline
function XUiActivityBriefBase:ScenePlayTimelineAnim(animName, cbFunc)
    local root = self.UiModelGo.transform
    local transform = root:FindTransform(animName)

    if transform then
        transform:PlayTimelineAnimation(cbFunc)
    end
end

---播放3D场景入场动画
function XUiActivityBriefBase:PlaySceneSpecialEnterAnim()
    self:ScenePlayTimelineAnim(
        XActivityBriefConfigs.GetSpecialEnterAnimName(self.PanelType),
        function() self:ScenePlayTimelineAnim(XActivityBriefConfigs.GetLoopAnimName(self.PanelType)) end)
end

---播放3D场景入场动画
function XUiActivityBriefBase:PlaySceneEnterAnim()
    local enterAnim = XActivityBriefConfigs.GetEnterAnimName(self.PanelType)
    if string.IsNilOrEmpty(enterAnim) then
        self:ScenePlayTimelineAnim(XActivityBriefConfigs.GetLoopAnimName(self.PanelType))
    else
        self:ScenePlayTimelineAnim(
            XActivityBriefConfigs.GetEnterAnimName(self.PanelType),
            function() self:ScenePlayTimelineAnim(XActivityBriefConfigs.GetLoopAnimName(self.PanelType)) end)
    end
end

---播放3D场景入场动画
function XUiActivityBriefBase:PlaySceneLoopAnim()
    self:ScenePlayTimelineAnim(XActivityBriefConfigs.GetLoopAnimName(self.PanelType))
end

--endregion


--region 视频背景相关

function XUiActivityBriefBase:RefreshVideoPanel()
    self:SetSpinePanelActive(false)
    self:SetVideoPanelActive(true)
end

function XUiActivityBriefBase:SetVideoPanelActive(active)
    if self.VideoPlayerEnter then
        self.VideoPlayerEnter.gameObject:SetActive(active)
    end
    if self.VideoPlayerLoop then
        self.VideoPlayerLoop.gameObject:SetActive(active)
    end
end

function XUiActivityBriefBase:PlayVideo(isLoop, videoUrl, cbFunc)
    self.VideoPlayerEnter.gameObject:SetActive(not isLoop)
    self:PlayVideoSound(isLoop)
    if not isLoop then
        self.VideoPlayerEnter:SetVideoFromRelateUrl(videoUrl)
        self.VideoPlayerEnter:Prepare()

        -- 加载Loop视频动画防止动画衔接时存在一帧黑屏
        self.VideoPlayerLoop:SetVideoFromRelateUrl(XActivityBriefConfigs.GetLoopAnimName(self.PanelType))
        self.VideoPlayerLoop:Prepare()
        self.VideoPlayerLoop:Pause()

        if cbFunc then
            local cb
            cb = function ()
                cbFunc()
                self.VideoPlayerEnter.ActionEnded = nil
                self.VideoPlayerEnter.gameObject:SetActive(false)
            end
            self.VideoPlayerEnter.ActionEnded = cb
        end
    else
        if self.VideoPlayerLoop.VideoPlayerInst.player:IsPaused() then
            self.VideoPlayerLoop:Resume()
        elseif self.VideoPlayerLoop:IsPlaying() then    -- 跳转玩法后返回动画重播
            self.VideoPlayerLoop:Stop()
            self.VideoPlayerLoop:SetVideoFromRelateUrl(videoUrl)
            self.VideoPlayerLoop:Prepare()
            XScheduleManager.ScheduleOnce(function ()
                self.VideoPlayerLoop:Play()
            end, 0)
        else    -- 既没有特殊入场也没有入场
            self.VideoPlayerLoop:SetVideoFromRelateUrl(videoUrl)
            self.VideoPlayerLoop:Prepare()
        end
    end
end

---播放视频音效
function XUiActivityBriefBase:PlayVideoSound(isLoop)
    local enterCueId = XActivityBriefConfigs.GetVideoEnterSoundCueId(self.PanelType)
    local loopCurId = XActivityBriefConfigs.GetVideoLoopSoundCueId(self.PanelType)
    if isLoop then
        if XTool.IsNumberValid(loopCurId) then
            XSoundManager.PlaySoundByType(loopCurId, XSoundManager.SoundType.Sound)
        end
    else
        if XTool.IsNumberValid(enterCueId) then
            XSoundManager.PlaySoundByType(enterCueId, XSoundManager.SoundType.Sound)
        end
    end
end

function XUiActivityBriefBase:StopVideoSound()
    local enterCueId = XActivityBriefConfigs.GetVideoEnterSoundCueId(self.PanelType)
    local loopCurId = XActivityBriefConfigs.GetVideoLoopSoundCueId(self.PanelType)
    if XTool.IsNumberValid(loopCurId) then XSoundManager.Stop(loopCurId) end
    if XTool.IsNumberValid(enterCueId) then XSoundManager.Stop(enterCueId) end
end

---播放视频入场动画
function XUiActivityBriefBase:PlayVideoSpecialEnterAnim()
    self:PlayVideo(
        false,
        XActivityBriefConfigs.GetSpecialEnterAnimName(self.PanelType),
        function() self:PlayVideo(true, XActivityBriefConfigs.GetLoopAnimName(self.PanelType)) end)
end

---播放视频入场动画
function XUiActivityBriefBase:PlayVideoEnterAnim()
    local enterAnim = XActivityBriefConfigs.GetEnterAnimName(self.PanelType)
    if string.IsNilOrEmpty(enterAnim) then
        self:PlayVideoLoopAnim()
    else
        self:RefreshDefaultSkipBtn()
        self:PlayAnimationWithMask("AnimEnableLong")
        self:PlayVideo(
            false,
            XActivityBriefConfigs.GetEnterAnimName(self.PanelType),
            function() self:PlayVideoLoopAnim() end)
    end
end

function XUiActivityBriefBase:PlayVideoLoopAnim()
    self:PlayVideo(true, XActivityBriefConfigs.GetLoopAnimName(self.PanelType))
end

--endregion
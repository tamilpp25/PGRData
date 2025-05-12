local XUiFightTutorialDynamicGrid = XClass(nil, "XUiFightTutorialDynamicGrid")

function XUiFightTutorialDynamicGrid:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
    XTool.InitUiObject(self)
    self:InitLoadVideoPrefab()
    self.IsDestroy = nil
    self.GridIndex = nil
    self.OpenCallback = nil
end

local TempV2 = Vector2(0, 0)
function XUiFightTutorialDynamicGrid:InitLoadVideoPrefab()
    if not XTool.UObjIsNil(self.Video) then
        return
    end
    self.Video = XDataCenter.VideoManager.LoadVideoPlayerUguiWithPrefab(self.VideoRoot)
    local rect = self.Video:GetComponent("RectTransform")
    
    -- 设置锚点为 Center (0.5, 0.5)
    TempV2.x = 0.5
    TempV2.y = 0.5
    rect.anchorMin = TempV2
    rect.anchorMax = TempV2

    -- 设置尺寸
    TempV2.x = 600
    TempV2.y = 300
    rect.sizeDelta = TempV2

    -- 设置位置
    TempV2.x = 0
    TempV2.y = 0
    rect.anchoredPosition = TempV2

    self.Video.DestroyOnPlayEnd = true
    self.Video.DestroyOnDisable = true
    self.Video.ControlBgMusicWhenPlaying = false
    self.Video.ActionStopWithoutLanguagePreparing = function ()
        self.ImagePlay.gameObject:SetActiveEx(true)
    end
    self.Video.ActionDestroyed = function ()
        self.ImagePlay.gameObject:SetActiveEx(true)
        self.Video = nil
    end
end

function XUiFightTutorialDynamicGrid:SetData(index, data)
    self.GridIndex = index
    self.Data = data
    self.TxtTitle.text = XUiHelper.ReplaceTextNewLine(data.Title)
    self.TxtContent.text = XUiHelper.ReplaceTextNewLine(data.Content)

    if self.Data.AssetType == 1 then
        self.VisualImage.gameObject:SetActiveEx(false)
        self.VisualVideo.gameObject:SetActiveEx(true)
        self.Video.VideoPlayingControl = 3

        self.VideoBtn.CallBack = function() self:Play() end
        self.Video.ActionEnded = function() self:Stop() end

        local movieId = tonumber(self.Data.AssetPath)
        local config = XVideoConfig.GetMovieById(movieId)
        local width = config.Width and config.Width or 0
        local height = config.Height and config.Height or 0
        if width ~= 0 and height ~= 0 then
            self.Video:SetAspectRatio(width / height)
        else
            self.Video:SetAspectRatio(2)    
        end
    elseif self.Data.AssetType == 2 then
        self.VisualImage.gameObject:SetActiveEx(true)
        self.VisualVideo.gameObject:SetActiveEx(false)
        local callback = Handler(self, self.SetRawImageAspectRatio)
        self.VisualImage:SetRawImage(self.Data.AssetPath, callback)
        self.VideoBtn.CallBack = nil
        self.Video.ActionEnded = nil
    end
end

function XUiFightTutorialDynamicGrid:SetIsSelected(isSelected)
    if isSelected then
        self:InitLoadVideoPrefab()
        self:_PlayAnim(self.QieHuan)
    else
        self:_ResetAnim(self.QieHuan)
    end
end

function XUiFightTutorialDynamicGrid:Play()
    self:InitLoadVideoPrefab()
    if self.Data.AssetType == 1 then
        if self.Video:IsPlaying() then
            if self.Video:IsPaused() then
                self.Video:Resume()
                self.IsPause = false
                self.ImagePlay.gameObject:SetActiveEx(false)
            else
                self.Video:Pause()
                self.IsPause = true
                self.ImagePlay.gameObject:SetActiveEx(true)
            end
        else
            self.ImagePlay.gameObject:SetActiveEx(false)

            local movieId = tonumber(self.Data.AssetPath)
            self.Video:SetInfoByVideoId(movieId)

            self.ScheduleId = XScheduleManager.ScheduleNextFrame(function()
                self.ScheduleId = nil
                self.Video:Play()
            end)
        end
    end
end

function XUiFightTutorialDynamicGrid:Stop()
    self:InitLoadVideoPrefab()
    if self.Data.AssetType == 1 then
        if self.Video:IsPlaying() then
            if self.ScheduleId then
                XScheduleManager.UnSchedule(self.ScheduleId)
                self.ScheduleId = nil
            end

            self.Video:Stop()
        end
    end
end

function XUiFightTutorialDynamicGrid:_PlayAnim(playableDirector, directorWrapMode)
    if not playableDirector then
        return
    end

    if not directorWrapMode then
        directorWrapMode = CS.UnityEngine.Playables.DirectorWrapMode.Hold
    end
    if playableDirector.extrapolationMode ~= directorWrapMode then
        playableDirector.extrapolationMode = directorWrapMode
    end
    
    playableDirector:Stop()
    playableDirector:Evaluate()
    playableDirector:Play()
end

function XUiFightTutorialDynamicGrid:_ResetAnim(playableDirector)
    if not playableDirector then
        return
    end

    playableDirector.time = 0
    playableDirector:Evaluate()
    playableDirector:Stop()
end

function XUiFightTutorialDynamicGrid:SetOpenCallback(cb)
    self.OpenCallback = cb
end

function XUiFightTutorialDynamicGrid:OnDestroy()
    self:Stop()
end

function XUiFightTutorialDynamicGrid:SetRawImageAspectRatio()
    self.VisualImage:SetRawImageAspectRatio()
end

return XUiFightTutorialDynamicGrid
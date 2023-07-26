local XUiGridFubenChapter = XClass(nil, "XUiGridFubenChapter")

function XUiGridFubenChapter:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
    self.IsDestroy = nil
    self.GridIndex = nil
    local sideX = self.Transform.sizeDelta.x / 2 - self.UseGrid.sizeDelta.x / 2
    self.CenterPosition = self.UseGrid.transform.localPosition
    self.LeftPosition = CS.UnityEngine.Vector3(-sideX, self.CenterPosition.y, self.CenterPosition.z)
    self.RightPosition = CS.UnityEngine.Vector3(sideX, self.CenterPosition.y, self.CenterPosition.z)
    self.RawWeight = self.UseGrid.sizeDelta
    self.OpenWeight = CS.UnityEngine.Vector2(self.Transform.sizeDelta.x, self.UseGrid.sizeDelta.y)
    self.OpenDuration = self.Big.duration
    self.MoveTimerId = nil
    self.OpenCallback = nil
end

function XUiGridFubenChapter:SetData(index, viewModel)
    self.GridIndex = index
    if self.ImgSelect then
        self.ImgSelect.transform.parent.gameObject:SetActiveEx(false) -- 每次刷新默认把聚焦物体关闭先(避免格子换数据)
    end
end

function XUiGridFubenChapter:SetOpenCallback(cb)
    self.OpenCallback = cb
end

function XUiGridFubenChapter:ResetPosition()
    self.GridChapter.transform.localPosition = self.CenterPosition
end

function XUiGridFubenChapter:PlayOpenAnim(isAnim, rootUi)
    if self.OpenCallback then 
        self.OpenCallback(self.GridIndex)
    end
    if isAnim == nil then isAnim = true end
    if not isAnim then
        self.TimerOpen1 = XScheduleManager.ScheduleOnce(function()
            self.Big:Stop()
            self.Small:Stop()
            self.HoldBig:Play()
        end, 1)
        return
    end
    rootUi.Mask.gameObject:SetActiveEx(true) -- 只要播放动画就开遮罩
    self.TimerOpen2 = XScheduleManager.ScheduleOnce(function() 
        self.Small:Stop()
        if self.Big.gameObject.activeInHierarchy then
            self.Big.transform:PlayTimelineAnimation(function ()
                rootUi.Mask.gameObject:SetActiveEx(false)
            end)
        end
    end, 1)
end

function XUiGridFubenChapter:PlayCloseAnim(isAnim, rootUi)
    if isAnim == nil then isAnim = true end
    if not isAnim then 
        self.TimerClose1 = XScheduleManager.ScheduleOnce(function()
            self.Big:Stop()
            self.Small:Stop()
            self.HoldSmall:Play()
        end, 1)
        return
    end
    self.TimerClose2 = XScheduleManager.ScheduleOnce(function() 
        self.Big:Stop()
        self.Small:Play()
        rootUi.Mask.gameObject:SetActiveEx(true) -- 只要播放动画就开遮罩
    end, 1)
end

function XUiGridFubenChapter:PlayCenterAnim(isAnim, isRight, isOpen)
    if isAnim == nil then isAnim = true end
    if not isAnim then
        self.GridChapter.localPosition = self.CenterPosition
        return
    end
    local beginX = self.GridChapter.localPosition.x
    local diffValue = 0
    if isRight then
        diffValue = self.RightPosition.x - self.CenterPosition.x
    else
        diffValue = self.LeftPosition.x - self.CenterPosition.x
    end
    self:StopMoveTimer()
    self.MoveTimerId1 = XUiHelper.Tween(self:GetMoveDuration(isOpen), function(weight)
        if self.IsDestroy then
            return
        end

        self.GridChapter:UpdateLocalPositionX(beginX - diffValue * weight)
    end, function()
        self.GridChapter.localPosition = self.CenterPosition
    end)
end

function XUiGridFubenChapter:PlayMoveRightAnim(isAnim, isOpen)
    if isAnim == nil then isAnim = true end
    if not isAnim then
        self.GridChapter.localPosition = self.RightPosition
        return
    end
    local beginX = self.GridChapter.localPosition.x
    local diffValue = math.abs(self.RightPosition.x - beginX)
    self:StopMoveTimer()
    self.MoveTimerId2 = XUiHelper.Tween(self:GetMoveDuration(isOpen), function(weight)
        if self.IsDestroy then
            return
        end

        self.GridChapter:UpdateLocalPositionX(beginX + diffValue * weight)
    end, function()
        self.GridChapter.localPosition = self.RightPosition
    end)
end

function XUiGridFubenChapter:PlayMoveLeftAnim(isAnim, isOpen)
    if isAnim == nil then isAnim = true end
    if not isAnim then
        self.GridChapter.localPosition = self.LeftPosition
        return
    end
    local beginX = self.GridChapter.localPosition.x
    local diffValue = math.abs(self.LeftPosition.x - beginX)
    self:StopMoveTimer()
    self.MoveTimerId3 = XUiHelper.Tween(self:GetMoveDuration(isOpen), function(weight)
        if self.IsDestroy then
            return
        end

        self.GridChapter:UpdateLocalPositionX(beginX - diffValue * weight)
    end, function()
        self.GridChapter.localPosition = self.LeftPosition
    end)
end

function XUiGridFubenChapter:GetOpenDuration()
    return self.OpenDuration
end

function XUiGridFubenChapter:StopMoveTimer()
    if self.MoveTimerId1 then
        XScheduleManager.UnSchedule(self.MoveTimerId1)
    end
    self.MoveTimerId1 = nil

    if self.MoveTimerId2 then
        XScheduleManager.UnSchedule(self.MoveTimerId2)
    end
    self.MoveTimerId2 = nil

    if self.MoveTimerId3 then
        XScheduleManager.UnSchedule(self.MoveTimerId3)
    end
    self.MoveTimerId3 = nil
end

function XUiGridFubenChapter:StopAnimeTimer()
    if self.TimerOpen1 then
        XScheduleManager.UnSchedule(self.TimerOpen1)
    end
    self.TimerOpen1 = nil

    if self.TimerOpen2 then
        XScheduleManager.UnSchedule(self.TimerOpen2)
    end
    self.TimerOpen2 = nil

    if self.TimerClose1 then
        XScheduleManager.UnSchedule(self.TimerClose1)
    end
    self.TimerClose1 = nil
    
    if self.TimerClose2 then
        XScheduleManager.UnSchedule(self.TimerClose2)
    end
    self.TimerClose2 = nil
end

function XUiGridFubenChapter:OnDestroy()
    self.IsDestroy = true
    self:StopMoveTimer()
    self:StopAnimeTimer()
end

function XUiGridFubenChapter:GetMoveDuration(isOpen)
    return 0.5
end

return XUiGridFubenChapter
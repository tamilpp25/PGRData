local XUiGridStudyCourse = XClass(nil, "XUiGridStudyCourse")
local IsThisTransformPlayAnim = false

function XUiGridStudyCourse:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self:SetHasPlay(false)
    XTool.InitUiObject(self)
end

function XUiGridStudyCourse:PlayEnableAnime(index)
    if self:GetHasPlay() then
        return
    end

    if XDataCenter.GuideManager.CheckIsInGuide() then
        return
    end
    
    local rect = self.UseGrid:GetComponent("RectTransform")
    local beforePlayPosY = rect.anchoredPosition.y
    local canvasGroup = self.Transform:Find("Grid"):GetComponent("CanvasGroup")
    canvasGroup.alpha = 0
    XScheduleManager.ScheduleOnce(function() 
        if not XTool.UObjIsNil(self.Transform) and self.GameObject.activeInHierarchy then
            self.Transform:Find("Animation/GridEnable"):PlayTimelineAnimation(function ()
                canvasGroup.alpha = 1
                rect.anchoredPosition = Vector2(rect.anchoredPosition.x, beforePlayPosY) -- 播放完的回调也强设一遍目标值
            end)
            self:SetHasPlay(true)
        end 
    end, (index - 1) * 95)
end

function XUiGridStudyCourse:SetHasPlay(flag)
    IsThisTransformPlayAnim = flag
end

function XUiGridStudyCourse:GetHasPlay()
    return IsThisTransformPlayAnim
end

function XUiGridStudyCourse:UpdateGrid(manager, index, currUseMinIndex)
    currUseMinIndex = currUseMinIndex or 1
    self:PlayEnableAnime(index - (currUseMinIndex - 1))
    self.Manager = manager
    self.TxtName.text = manager:ExGetName()
    self.RImgBg:SetRawImage(manager:ExGetIcon())
    self.PanelLock.gameObject:SetActiveEx(manager:ExGetIsLocked())
    self.TxtLock.text = manager:ExGetLockTip()
    
    local isShowTag, textTag = manager:ExGetTagInfo()
    self.PanelTag.gameObject:SetActiveEx(isShowTag)
    self.TextTag.text = textTag

    self:RefreshRedPoint()
end

function XUiGridStudyCourse:RefreshRedPoint()
    self.ImgRedPoint.gameObject:SetActiveEx(self.Manager:ExCheckIsShowRedPoint())
end

return XUiGridStudyCourse
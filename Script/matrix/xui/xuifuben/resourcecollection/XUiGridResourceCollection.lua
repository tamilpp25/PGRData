local XUiGridResourceCollection = XClass(nil, "XUiGridResourceCollection")
local IsThisTransformPlayAnim = false

function XUiGridResourceCollection:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self:SetHasPlay(false)
    XTool.InitUiObject(self)
end

function XUiGridResourceCollection:PlayEnableAnime(index)
    local animationRoot = self.Transform:Find("Animation/GridEnable")
    if not animationRoot then
        return
    end
    --该index是当前使用的grid中的序号，不是总grid里的动态列表组件上的属性的index,etc:共10个gird，若只显示最后5个且该格子是第10个的话，参数Index就是5
    if self:GetHasPlay() then
        return
    end

    if XDataCenter.GuideManager.CheckIsInGuide() then
        return
    end

    local rect = self.UseGrid:GetComponent("RectTransform")
    local beforePlayPosY = rect.anchoredPosition.y
    local canvasGroup = self.UseGrid:GetComponent("CanvasGroup")
    canvasGroup.alpha = 0
    XScheduleManager.ScheduleOnce(function()
        if not XTool.UObjIsNil(self.Transform) and self.GameObject.activeInHierarchy then
            animationRoot:PlayTimelineAnimation(function()
                canvasGroup.alpha = 1
                rect.anchoredPosition = Vector2(rect.anchoredPosition.x, beforePlayPosY) -- 播放完的回调也强设一遍目标值
            end)
            self:SetHasPlay(true)
        end
    end, (index - 1) * 95)
end

function XUiGridResourceCollection:SetAlphaOne()
    local canvasGroup = self.Transform:Find("Grid"):GetComponent("CanvasGroup")
    canvasGroup.alpha = 1
    self.GameObject:SetActiveEx(false)
end

function XUiGridResourceCollection:SetHasPlay(flag)
    IsThisTransformPlayAnim = flag
end

function XUiGridResourceCollection:GetHasPlay()
    return IsThisTransformPlayAnim
end

---@param chapterViewModel XChapterViewModel
function XUiGridResourceCollection:UpdateGrid(chapterViewModel, index, currUseMinIndex)
    self.GameObject:SetActiveEx(true)
    currUseMinIndex = currUseMinIndex or 1
    self:PlayEnableAnime(index - (currUseMinIndex - 1))
    self.RImgBg:SetRawImage(chapterViewModel:GetExtralData().Bg)
    self.RImgIcon:SetRawImage(chapterViewModel:GetIcon())
    self.TxtName.text = chapterViewModel:GetName()
    self.TxtRemainOpen.text = ""
    self.TxtDes.text = chapterViewModel:GetConfig().Desc

    self.PanelLock.gameObject:SetActive(chapterViewModel:GetIsLocked())
    -- self.TxtLock.text = CS.XTextManager.GetText("NotUnlock")
    self.TxtLock.text = chapterViewModel:GetLockTip()

    local tmpText, IsAllDay = chapterViewModel:GetOpenDayString()
    if IsAllDay then
        self.TxtRemainOpen.text = tmpText
    else
        self.TxtRemainOpen.text = CS.XTextManager.GetText("FubenDailyOpenRemark", tmpText)
    end

    local hasTag, tagName = chapterViewModel:CheckHasTimeLimitTag()
    self.PanelNewEffectShop.gameObject:SetActiveEx(hasTag)
    self.TxtShop.text = tagName

    if self.ImgRedPoint then
        self.ImgRedPoint.gameObject:SetActiveEx(chapterViewModel:CheckHasRedPoint())
    end
end

function XUiGridResourceCollection:RefreshRedPoint(chapterViewModel)
    if self.ImgRedPoint and chapterViewModel then
        self.ImgRedPoint.gameObject:SetActiveEx(chapterViewModel:CheckHasRedPoint())
    end
end

return XUiGridResourceCollection
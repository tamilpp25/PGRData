local CSUnityEngineColor = CS.UnityEngine.Color

local XUiGridHeadPortrait = XClass(nil, "XUiGridHeadPortrait")

function XUiGridHeadPortrait:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    self:SetSelect(false)

    self.ImgTagDefault.gameObject:SetActiveEx(false)
    self.ImgTagTime.gameObject:SetActiveEx(false)
end

function XUiGridHeadPortrait:PlayAnimation()
    if XTool.UObjIsNil(self.GridFashionTimeline) then return end

    XScheduleManager.ScheduleOnce(function()
        if self.GridFashionTimeline.gameObject.activeInHierarchy then
            self.GridFashionTimeline:PlayTimelineAnimation()
        end
    end, 40)
end

function XUiGridHeadPortrait:CheckAnimationFinish()
    if not self.ImgSelected then
        return
    end

    local canvasGroup = self.ImgSelected:GetComponent("CanvasGroup")
    if canvasGroup and canvasGroup.alpha ~= 1 then
        self:PlayAnimation()
    end
end

function XUiGridHeadPortrait:SetSelect(isSelect)
    if self.ImgSelected then
        self.ImgSelected.gameObject:SetActiveEx(isSelect)
    end
end

function XUiGridHeadPortrait:SetRedPoint(isSelect)
    if self.ImgRedPoint then
        self.ImgRedPoint.gameObject:SetActiveEx(isSelect)
    end
end

function XUiGridHeadPortrait:Refresh(headInfo, characterId)
    self:CheckAnimationFinish()

    self.RImgIcon:SetRawImage(headInfo.Icon)

    local isUnLock = XDataCenter.FashionManager.IsFashionHeadUnLock(headInfo.HeadFashionId, headInfo.HeadFashionType, characterId)
    local isUsing = XDataCenter.FashionManager.IsFashionHeadUsing(headInfo.HeadFashionId, headInfo.HeadFashionType, characterId)

    if isUsing then --已穿戴
        self.ImgLock.gameObject:SetActiveEx(false)
        self.ImgUse.gameObject:SetActiveEx(true)
        self.RImgIcon.color = CSUnityEngineColor(1, 1, 1, 1)
    elseif isUnLock then --已解锁
        self.ImgLock.gameObject:SetActiveEx(false)
        self.ImgUse.gameObject:SetActiveEx(false)
        self.RImgIcon.color = CSUnityEngineColor(1, 1, 1, 1)
    else -- 未获得
        self.ImgLock.gameObject:SetActiveEx(true)
        self.ImgUse.gameObject:SetActiveEx(false)
        self.RImgIcon.color = CSUnityEngineColor(1, 1, 1, 0.6)
    end

    self:SetRedPoint(XDataCenter.FashionManager.GetAllHeadPortraitIsOwnDic(headInfo.HeadFashionId, headInfo.HeadFashionType).IsNew)
end

return XUiGridHeadPortrait
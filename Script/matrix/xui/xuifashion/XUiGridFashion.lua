local CSUnityEngineColor = CS.UnityEngine.Color

local XUiGridFashion = XClass(nil, "XUiGridFashion")

function XUiGridFashion:Ctor(ui, index, clickCallback)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Index = index
    self.ClickCallback = clickCallback

    XTool.InitUiObject(self)
    self:SetSelect(false)
end


function XUiGridFashion:PlayAnimation()
    if XTool.UObjIsNil(self.GridFashionTimeline) then return end
    XScheduleManager.ScheduleOnce(function()
        if self.GridFashionTimeline.gameObject.activeInHierarchy then
            self.GridFashionTimeline:PlayTimelineAnimation()
        end
    end, 40)
end

function XUiGridFashion:CheckAnimationFinish()
    if not self.ImgSelected then
        return
    end

    local canvasGroup = self.ImgSelected:GetComponent("CanvasGroup")
    if canvasGroup and canvasGroup.alpha ~= 1 then
        self:PlayAnimation()
    end
end

function XUiGridFashion:SetSelect(isSelect)
    if self.ImgSelected then
        self.ImgSelected.gameObject:SetActiveEx(isSelect)
    end
end

function XUiGridFashion:UpdateStatus()
    local status = XDataCenter.FashionManager.GetFashionStatus(self.FashionId)
    
    if self.OpenUiType and self.OpenUiType == XUiConfigs.OpenUiType.NieRCharacterUI then
        local nieRCharacter = XDataCenter.NieRManager.GetSelNieRCharacter()
        if nieRCharacter:GetNieRFashionId() == self.FashionId then
            status = XDataCenter.FashionManager.FashionStatus.Dressed
        else
            status = XDataCenter.FashionManager.FashionStatus.UnLock
        end
    end
    
    if status == XDataCenter.FashionManager.FashionStatus.UnOwned then -- 未获得
        self.ImgLock.gameObject:SetActiveEx(true)
        self.ImgUse.gameObject:SetActiveEx(false)
        self.ImgRedPoint.gameObject:SetActiveEx(false)
        self.RImgIcon.color = CSUnityEngineColor(1, 1, 1, 0.6)
    elseif status == XDataCenter.FashionManager.FashionStatus.Dressed then --已穿戴
        self.ImgLock.gameObject:SetActiveEx(false)
        self.ImgUse.gameObject:SetActiveEx(true)
        self.ImgRedPoint.gameObject:SetActiveEx(false)
        self.RImgIcon.color = CSUnityEngineColor(1, 1, 1, 1)
    elseif status == XDataCenter.FashionManager.FashionStatus.Lock then --已获得，未解锁
        self.ImgLock.gameObject:SetActiveEx(false)
        self.ImgUse.gameObject:SetActiveEx(false)
        self.ImgRedPoint.gameObject:SetActiveEx(true)
        self.RImgIcon.color = CSUnityEngineColor(1, 1, 1, 0.6)
    elseif status == XDataCenter.FashionManager.FashionStatus.UnLock then --已解锁
        self.ImgLock.gameObject:SetActiveEx(false)
        self.ImgUse.gameObject:SetActiveEx(false)
        self.ImgRedPoint.gameObject:SetActiveEx(false)
        self.RImgIcon.color = CSUnityEngineColor(1, 1, 1, 1)
    end
end

function XUiGridFashion:Refresh(fashionId, characterId, rootUi)
    self:CheckAnimationFinish()

    self.FashionId = fashionId
    self.CharacterId = characterId
    self.OpenUiType = rootUi.OpenUiType
    local template = XDataCenter.FashionManager.GetFashionTemplate(fashionId)
    self.RImgIcon:SetRawImage(template.Icon)

    self:UpdateStatus()
end

return XUiGridFashion
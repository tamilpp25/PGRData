---@class XGridPlanetCard
local XGridPlanetCard = XClass(nil, "XGridPlanetCard")

function XGridPlanetCard:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    ---@type XPanelPlanetCard
    self.RootUi = rootUi
    self:InitObj()
    self:AddBtnClickListener()
end

function XGridPlanetCard:InitObj()
    XTool.InitUiObject(self)
    if XTool.UObjIsNil(self.TxtNum) then
        self.TxtNum = XUiHelper.TryGetComponent(self.Transform, "RImgCard/ImgNum/TxtNum", "Text")
    end
    if XTool.UObjIsNil(self.RImgIcon) then
        self.RImgIcon = XUiHelper.TryGetComponent(self.Transform, "RImgCard/TxtIcon/RImgIcon", "RawImage")
    end

    self.Camera = self.RootUi.RootUi.Transform:GetComponent("Canvas").worldCamera
    self.RImgCardShadow.gameObject:SetActiveEx(false)
    if self.Effect then
        self.Effect.gameObject:SetActiveEx(false)
    end
    if self.EffectShadow then
        self.EffectShadow.gameObject:SetActiveEx(false)
    end
    
    self.IsTalent = false
    self.BuildingId = 0
    self.OnSelectCb = false
    ---@type XPlanetIScene
    self.Scene = nil

    self.InitPostion1 = self.RImgCardShadow.transform.localPosition
    self.InitPostion2 = self.RImgCard.transform.localPosition
    self.InitPostion3 = self.Effect.transform.localPosition
    self.InitPostion4 = self.BtnClick.transform.localPosition
    self:SetSelect(false)
end

--region Ui
function XGridPlanetCard:Refresh(buildingId, isTalent)
    if not XTool.IsNumberValid(buildingId) then
        return
    end
    self.BuildingId = buildingId
    self.IsTalent = isTalent
    self.GameObject:SetActiveEx(true)
    self.Effect.gameObject:SetActiveEx(false)
    
    if isTalent then
        self.Scene = XDataCenter.PlanetManager.GetPlanetMainScene()
        self:RefreshTalentCard()
    else
        self.Scene = XDataCenter.PlanetManager.GetPlanetStageScene()
        self:RefreshStageCard()
    end
    self:RefreshRedPoint()
    self:SetSelect(self.BuildingId == self:GetPanelSelectId())
end

function XGridPlanetCard:RefreshTalentCard()
    local viewModel = XDataCenter.PlanetManager.GetViewModel()
    local maxCount = viewModel:GetReformBuildMaxBuyCount(self.BuildingId)
    local curCount = viewModel:GetReformBuildCurCount(self.BuildingId)
    local icon = XPlanetWorldConfigs.GetBuildingIconUrl(self.BuildingId)
    local curHaveCount = viewModel:GetReformCardCurHaveCount(self.BuildingId)
    local isUnLock = viewModel:CheckReformBuildCardIsUnLock(self.BuildingId)
    local isMax = curCount >= maxCount

    self.RImgBuildIcon.gameObject:SetActiveEx(isUnLock)
    
    self.TxtHold.gameObject:SetActiveEx(isUnLock and not isMax and curHaveCount > 0)
    self.ImgNum.gameObject:SetActiveEx(isUnLock and not isMax)
    self.TxtMax.gameObject:SetActiveEx(isUnLock and isMax)
    
    self.RImgCardDark.gameObject:SetActiveEx(isUnLock and isMax or not isUnLock or (not self:IsEnoughCoin() and curHaveCount == 0))
    self.ImgLock.gameObject:SetActiveEx(not isUnLock)
    self.TxtIcon.gameObject:SetActiveEx(not isUnLock)

    self.TxtNum.text = curCount .. "/" .. maxCount
    self.TxtHold.text = XUiHelper.GetText("PlanetRunningTalentBuildHold", curHaveCount)if not string.IsNilOrEmpty(icon) then
        self.RImgBuildIcon:SetRawImage(icon)
    end
    
    if not isUnLock or curHaveCount == 0 then
        self:RefreshTalentShowCast()
    end
end

function XGridPlanetCard:RefreshTalentShowCast()
    local itemId = XDataCenter.ItemManager.ItemId.PlanetRunningTalent
    local itemIcon = XDataCenter.ItemManager.GetItemIcon(itemId)
    self.TxtIcon.text = XPlanetTalentConfigs.GetTalentBuildingBuyPrices(self.BuildingId)
    self.TxtIcon.gameObject:SetActiveEx(true)
    if not string.IsNilOrEmpty(itemIcon) then
        self.RImgIcon:SetRawImage(itemIcon)
    end
end

function XGridPlanetCard:RefreshStageCard()
    local stageData = XDataCenter.PlanetManager.GetStageData()
    local icon = XPlanetWorldConfigs.GetBuildingIconUrl(self.BuildingId)
    local itemId = XDataCenter.ItemManager.ItemId.PlanetRunningStageCoin
    local itemIcon = XDataCenter.ItemManager.GetItemIcon(itemId)

    local stageId = XDataCenter.PlanetManager.GetStageData():GetStageId()
    local maxCount, isShowLimitCount = XPlanetWorldConfigs.GetBuildingLimitCount(self.BuildingId, stageId)
    local curCount = stageData:GetStageBuildingCount(self.BuildingId)
    local isMax = curCount >= maxCount

    -- 建筑图标
    if not string.IsNilOrEmpty(icon) then
        self.RImgBuildIcon:SetRawImage(icon)
    end
    -- 数量限制
    self.ImgNum.gameObject:SetActiveEx(isShowLimitCount)
    self.TxtNum.text = curCount .. "/" .. maxCount
    -- 阴影
    self.RImgCardDark.gameObject:SetActiveEx(isMax or not self:IsEnoughCoin())
    -- 货币消耗
    if not string.IsNilOrEmpty(itemIcon) then
        self.RImgIcon:SetRawImage(itemIcon)
    end
    self.TxtIcon.text = XPlanetWorldConfigs.GetBuildingCast(self.BuildingId)
end

function XGridPlanetCard:PlayUnlockEffect()
    self.Effect.gameObject:SetActiveEx(false)
    self.Effect.gameObject:SetActiveEx(true)
end
--endregion


--region CardSelect
function XGridPlanetCard:SetSelect(active)
    self.RImgCardShadow.gameObject:SetActiveEx(active)
    if active then
        local offect = Vector3(0, 18, 0)
        self.RImgCardShadow.transform.localPosition = self.InitPostion1 + offect
        self.RImgCard.transform.localPosition = self.InitPostion2 + offect
        self.Effect.transform.localPosition = self.InitPostion3 + offect
        self.BtnClick.transform.localPosition = self.InitPostion4 + offect
    else
        self.RImgCardShadow.transform.localPosition = self.InitPostion1
        self.RImgCard.transform.localPosition = self.InitPostion2
        self.Effect.transform.localPosition = self.InitPostion3
        self.BtnClick.transform.localPosition = self.InitPostion4
    end
end

function XGridPlanetCard:SetOnSelectCb(cb)
    self.OnSelectCb = cb
end

function XGridPlanetCard:GetPanelSelectId()
    return self.RootUi:GetSelectBuildId()
end
--endregion


--region StateCheck
function XGridPlanetCard:IsEnoughCoin()
    if self.IsTalent then
        local count = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.PlanetRunningTalent)
        return count >= XPlanetTalentConfigs.GetTalentBuildingBuyPrices(self.BuildingId)
    else
        return XDataCenter.PlanetManager.GetStageData():GetCoin() >= XPlanetWorldConfigs.GetBuildingCast(self.BuildingId)
    end
end

function XGridPlanetCard:IsCardHaveCount()
    if not self.IsTalent then   -- 关卡没有持有数量的概念
        return true
    end
    local viewModel = XDataCenter.PlanetManager.GetViewModel()
    local buyCount = viewModel:GetReformBuildCurBuyCount(self.BuildingId)
    local curCount = viewModel:GetReformBuildCurCount(self.BuildingId)
    if curCount >= buyCount then
        return false
    end
    return true
end

function XGridPlanetCard:IsCardMax()
    if not self.IsTalent then
        local stageId = XDataCenter.PlanetManager.GetStageData():GetStageId()
        local maxCount, _ = XPlanetWorldConfigs.GetBuildingLimitCount(self.BuildingId, stageId)
        if maxCount > 0 and XDataCenter.PlanetManager.GetStageData():GetStageBuildingCount(self.BuildingId) >= maxCount then
            return true
        end
        return false
    end
    local viewModel = XDataCenter.PlanetManager.GetViewModel()
    local maxCount = viewModel:GetReformBuildMaxBuyCount(self.BuildingId)
    local curCount = viewModel:GetReformBuildCurCount(self.BuildingId)
    if curCount >= maxCount then
        return true
    end
    return false
end

function XGridPlanetCard:IsTalentCardUnLock()
    if not self.IsTalent then return true end
    return XDataCenter.PlanetManager.CheckTalentCardIsUnLock(self.BuildingId)
end
--endregion


--region Anim&Drag
function XGridPlanetCard:PlayBackAnim()

end

function XGridPlanetCard:CreateDragCard()
    local copyGameObject = self.RootUi:GetCopyCard()
    ---为了避免安卓平台多指触控
    if not XTool.UObjIsNil(copyGameObject) then
        self.CopyGameObject = nil
        self.CopyCardUiObject = nil
        return
    end

    copyGameObject = CS.UnityEngine.Object.Instantiate(self.GameObject, self.RootUi.Transform)
    copyGameObject.transform.localScale = Vector3(XPlanetConfigs.GetBuildCardScale(), XPlanetConfigs.GetBuildCardScale(), 1)
    copyGameObject.transform.localPosition = XUiHelper.GetScreenClickPosition(self.RootUi.Transform, self.Camera)
    local copyCardUiObject = {}
    XTool.InitUiObjectByUi(copyCardUiObject, copyGameObject) -- 注册引用
    local canvasGroup = copyGameObject:AddComponent(typeof(CS.UnityEngine.CanvasGroup))
    canvasGroup.alpha = XPlanetConfigs.GetBuildCardAlpha()
    canvasGroup.blocksRaycasts = true
    self.RootUi:SetCopyCard(copyGameObject)
    self.RootUi:SetCopyCardUiObject(copyCardUiObject)
    self.CopyGameObject = copyGameObject
    self.CopyCardUiObject = copyCardUiObject
end

function XGridPlanetCard:RefreshDragCard(haveTile, position)
    if XTool.IsTableEmpty(self.CopyCardUiObject) then
        return
    end
    if self.CopyCardUiObject.RImgCardDark then
        self.CopyCardUiObject.RImgCardDark.gameObject:SetActiveEx(not haveTile)
    end
    if self.CopyCardUiObject.ImgLock then
        self.CopyCardUiObject.ImgLock.gameObject:SetActiveEx(false)
    end
    if self.CopyCardUiObject.Effect then
        self.CopyCardUiObject.Effect.gameObject:SetActiveEx(false)
    end
    if self.CopyCardUiObject.EffectShadow then
        self.CopyCardUiObject.EffectShadow.gameObject:SetActiveEx(true)
    end

    if not position then
        position = XUiHelper.GetScreenClickPosition(self.RootUi.Transform, self.Camera)
    end
    local curBuildingList = self.Scene:GetCurBuildingList()
    local occupyGridType = XPlanetWorldConfigs.GetBuildingGridOccupyType(self.BuildingId)
    if occupyGridType == XPlanetWorldConfigs.GridOccupyType.Occupy1 and #curBuildingList == 1 then
        self.CopyGameObject.transform.localPosition = position + XPlanetConfigs.GetBuildCardOffset()
    else
        self.CopyGameObject.transform.localPosition = position
    end 
end

function XGridPlanetCard:CheckCardIsInPanel()
    if XTool.UObjIsNil(self.CopyGameObject) then
        return false
    end
    local localPosition = self.CopyGameObject.transform.localPosition
    local width = self.RootUi.ImgCardBg.transform.rect.width / 2
    local height = self.RootUi.ImgCardBg.transform.rect.height / 2
    local offset = self.RootUi.ImgCardBg.transform.localPosition
    if localPosition.x < offset.x + width and localPosition.y < offset.y+height then
        return true
    else
        return false
    end
end
--endregion


--region RedPoint
function XGridPlanetCard:InitRedPoint(buildId, isTalent)
    if not isTalent then
        return
    end
    self._RedIsUnLock = XDataCenter.PlanetManager.CheckOneTalentBuildUnlockRedPoint(buildId)
    self._RedIsNewLimit = XDataCenter.PlanetManager.CheckOneTalentBuildLimitUnlockRedPoint(buildId)
end

function XGridPlanetCard:ClearRedPoint()
    if not self.IsTalent then
        return
    end
    self._RedIsUnLock = false
    self._RedIsNewLimit = false
    self:RefreshRedPoint()
end

function XGridPlanetCard:RefreshRedPoint()
    if not self.IsTalent then
        return
    end
    if self.Red then
        self.Red.gameObject:SetActiveEx(self._RedIsUnLock or self._RedIsNewLimit)
    end
end
--endregion


--region 按钮绑定
function XGridPlanetCard:AddBtnClickListener()
    XUiHelper.RegisterClickEvent(self, self.BtnDetail, self.OnBtnClick)
 
    self.XUiWidget:AddBeginDragListener(function(eventData)
        self:OnBeginDrag(eventData)
    end)

    self.XUiWidget:AddEndDragListener(function(eventData)
        self:OnEndDrag(eventData)
    end)

    self.XUiWidget:AddDragListener(function (eventData)
        self:OnDrag(eventData)
    end)
end

function XGridPlanetCard:OnBeginDrag(eventData)
    self:ClearRedPoint()
    if XDataCenter.GuideManager.CheckIsInGuide() then
        return
    end
    if self.RootUi:GetIsInDrag() then
        return
    end
    if self.IsTalent and XDataCenter.PlanetManager.GetReformQuickRecycleMode() then
        XUiManager.TipErrorWithKey("PlanetRunningInQuickBuild")
        return
    end

    local talentCanDrag = self.IsTalent and (self:IsCardHaveCount() or self:IsEnoughCoin() and not self:IsCardMax())
    local stageCanDrag = not self.IsTalent and (self:IsEnoughCoin() and not self:IsCardMax())
    local isCanDrag = talentCanDrag or stageCanDrag
    if not self:IsTalentCardUnLock() or not isCanDrag then
        if self:IsCardMax() then
            XUiManager.TipErrorWithKey("PlanetRunningMaxBuild")
        end
        if not self:IsEnoughCoin() then
            XUiManager.TipErrorWithKey("PlanetRunningNoEnoughCoin")
        end
        return
    end

    self:CreateDragCard()
    self.RootUi:SetIsInDrag(true)
    if XTool.UObjIsNil(self.CopyGameObject) then
        return
    end
    self:OnSelect()
    XEventManager.DispatchEvent(XEventId.EVENT_PLANET_PAUSE_RUNNING, XPlanetExploreConfigs.PAUSE_REASON.BUILD)
    
    self:StopTimer()
    self:StartTimer()
end

function XGridPlanetCard:OnDrag(eventData)
    if XDataCenter.GuideManager.CheckIsInGuide() then
        return
    end
    if not self.RootUi:GetIsInDrag() then
        return
    end
    if XTool.UObjIsNil(self.CopyGameObject) then
        return
    end
    if self:CheckCardIsInPanel() then
        self:RefreshDragCard()
        self.Scene:OnDragBuildCard()
    else
        local tile = self.Scene:GetCameraRayTile()
        self:RefreshDragCard(tile)
        self.Scene:OnDragBuildCard(self.BuildingId)
    end
end

function XGridPlanetCard:OnEndDrag(eventData)
    if XDataCenter.GuideManager.CheckIsInGuide() then
        return
    end
    self:StopTimer()
    if XTool.UObjIsNil(self.CopyGameObject) then
        return
    end
    if self:_IsInGuide() and self:_IsGuideNeedDrag() then   -- 引导
        self:OnGuideEndDrag()
        return
    end
    self.RootUi:SetIsInDrag(false)
    local isInPanel = self:CheckCardIsInPanel()
    self.RootUi:DestroyCopyCard()
    self.CopyGameObject = nil
    self.CopyCardUiObject = nil
    
    self:OnCancelSelect()
    if isInPanel then
        self.Scene:OnDragBuildCard()
        XEventManager.DispatchEvent(XEventId.EVENT_PLANET_RESUME_RUNNING, XPlanetExploreConfigs.PAUSE_REASON.BUILD)
        return
    end
    local isQuickBuild
    if self.Scene:CheckIsTalentPlanet() then
        isQuickBuild = XDataCenter.PlanetManager.GetReformQuickBuildMode()
    else
        isQuickBuild = XDataCenter.PlanetManager.GetStageQuickBuildMode()
    end
    self.Scene:OnEndDragBuildCard(self.BuildingId, isQuickBuild)
end

function XGridPlanetCard:OnBtnClick()
    self:ClearRedPoint()
    if self.RootUi:GetIsInDrag() or not self:IsTalentCardUnLock() then
        return
    end
    
    if self:_IsInGuide() and self:_IsGuideNeedDrag() then
        self:OnGuideEndDrag()
    else
        self:_AddGuideClickCount()
        self:OnSelect()
        XLuaUiManager.Open("UiPlanetBuildDetail", self.BuildingId, self.IsTalent, true, nil, nil, nil, handler(self, self.OnCancelSelect))
    end
end

function XGridPlanetCard:OnSelect()
    if self.OnSelectCb then self.OnSelectCb() end
    self:SetSelect(self.BuildingId == self:GetPanelSelectId())
end

function XGridPlanetCard:OnCancelSelect()
    self.RootUi:CancelSelectCard()
    self:SetSelect(self.BuildingId == self:GetPanelSelectId())
end
--endregion

---按住计时,为了避免Unity的OnEndDrag偶发性不响应bug导致卡牌没有销毁
function XGridPlanetCard:StartTimer()
    if self._IsInGuide() then
        return
    end
    local platform = CS.UnityEngine.Application.platform
    local isTouch = true
    self.TimerDrag = XScheduleManager.ScheduleForever(function()
        if XTool.UObjIsNil(self.Transform) then
            self:StopTimer()
            return
        end
        if XTool.UObjIsNil(self.CopyGameObject) then
            self:StopTimer()
            return
        end

        if platform == CS.UnityEngine.RuntimePlatform.WindowsEditor or
                platform == CS.UnityEngine.RuntimePlatform.WindowsPlayer
        then
            isTouch = CS.UnityEngine.Input.GetMouseButton(0)
        else
            isTouch = CS.UnityEngine.Input.touchCount == 1
        end

        if not isTouch then
            self:OnEndDrag()
            return
        end
    end,0, 0)
    --end,XScheduleManager.SECOND * 0.1, 0)
end

function XGridPlanetCard:StopTimer()
    if self.TimerDrag then
        XScheduleManager.UnSchedule(self.TimerDrag)
        self.TimerDrag = nil
    end
end

--region 引导
function XGridPlanetCard:OnGuideBeginDrag()
    
end

function XGridPlanetCard:OnGuideDrag()

end

function XGridPlanetCard:OnGuideEndDrag()
    if XTool.UObjIsNil(self.CopyGameObject) then
        self:CreateDragCard()
        self.RootUi:SetIsInDrag(true)
        if XTool.UObjIsNil(self.CopyGameObject) then
            return
        end
        self:OnSelect()
        XEventManager.DispatchEvent(XEventId.EVENT_PLANET_PAUSE_RUNNING, XPlanetExploreConfigs.PAUSE_REASON.BUILD)
    end
    local canvasTran = self.RootUi.Transform
    local uiCamera = CS.XUiManager.Instance.UiCamera
    local targetTilePosition = self.Scene:GetCamera():WorldToScreenPoint(self.Scene:GetTileHeightPosition(self:_GuideBuildTile()))
    local curCopyObjLocalPosition =  self.CopyGameObject.transform.localPosition
    local hasValue, targetRectPosition = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(canvasTran, Vector2(targetTilePosition.x, targetTilePosition.y), uiCamera)
    local deltaPosition = Vector3(targetRectPosition.x, targetRectPosition.y, 0) - curCopyObjLocalPosition
    
    local haveValue, targetPosition = CS.UnityEngine.RectTransformUtility.ScreenPointToWorldPointInRectangle(canvasTran, Vector2(targetTilePosition.x, targetTilePosition.y), uiCamera)
    local duration = 1
    if haveValue then
        local distance = (self.Transform.position - targetPosition).sqrMagnitude
        local curDistance = (self.Transform.position - targetPosition).sqrMagnitude
        duration = math.min((curDistance / distance), 1)
    end
    if not hasValue then
        self:_EndGuideDrag()
        return
    end
    XLuaUiManager.SetMask(true)
    XUiHelper.Tween(duration, function(t)
        if XTool.UObjIsNil(self.GameObject) or XTool.UObjIsNil(self.CopyGameObject) then
            return
        end
        if self:CheckCardIsInPanel() then
            self:RefreshDragCard(nil, curCopyObjLocalPosition + deltaPosition * t)
            self.Scene:OnDragBuildCard()
        else
            local worldPosition = self.CopyGameObject.transform.position
            local screenPoint = uiCamera:WorldToScreenPoint(worldPosition)
            local tile = self.Scene:GetCameraRayTileByScreenPoint(screenPoint)
            self:RefreshDragCard(tile, curCopyObjLocalPosition + deltaPosition * t)
            self.Scene:OnDragBuildCard(self.BuildingId, nil, tile)
        end
    end, function()
        XLuaUiManager.SetMask(false)
        self:_EndGuideDrag()
    end)
end

function XGridPlanetCard:_EndGuideDrag()
    if XTool.UObjIsNil(self.GameObject) or XTool.UObjIsNil(self.CopyGameObject) then
        return
    end

    local worldPosition = self.CopyGameObject.transform.position
    local screenPoint = CS.XUiManager.Instance.UiCamera:WorldToScreenPoint(worldPosition)
    local tile = self.Scene:GetCameraRayTileByScreenPoint(screenPoint)
    self.RootUi:SetIsInDrag(false)
    self.RootUi:DestroyCopyCard()
    self.CopyGameObject = nil
    self.CopyCardUiObject = nil

    self:OnCancelSelect()
    self.Scene:OnEndDragBuildCard(self.BuildingId, true, nil, tile)
end

function XGridPlanetCard:_IsInGuide()
    return XDataCenter.GuideManager.CheckIsInGuide() and not self.IsTalent and self:_IsGuideCard() and self:_GuideBuildTile()
end

function XGridPlanetCard:_IsGuideNeedDrag()
    local index = 1
    local stageId = XDataCenter.PlanetManager.GetStageData():GetStageId()
    for i, id in ipairs(XPlanetConfigs.GetGuideDragBuildCardList()) do
        if self.BuildingId == id then
            index = i
        end
    end
    if XDataCenter.PlanetManager.GetGuideCardClickCount(self.BuildingId) ==
            XPlanetConfigs.GetGuideCardClickCount(stageId, index) then
        return true
    end
    return false
end

function XGridPlanetCard:_AddGuideClickCount()
    if not self:_IsInGuide() then
        return
    end
    XDataCenter.PlanetManager.AddGuideCardClickCount(self.BuildingId)
end

function XGridPlanetCard:_IsGuideCard()
    for _, id in pairs(XPlanetConfigs.GetGuideDragBuildCardList()) do
        if self.BuildingId == id then
            return true
        end
    end
    return false
end

function XGridPlanetCard:_GuideBuildTile()
    local index = 1
    local stageId = XDataCenter.PlanetManager.GetStageData():GetStageId()
    for i, id in ipairs(XPlanetConfigs.GetGuideDragBuildCardList()) do
        if self.BuildingId == id then
            index = i
        end
    end
    return XPlanetConfigs._GetGuideStageTile(stageId, index)
end
--endregion

return XGridPlanetCard
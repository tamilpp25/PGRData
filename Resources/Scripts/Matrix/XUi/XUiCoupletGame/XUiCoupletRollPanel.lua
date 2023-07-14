local tableInsert = table.insert
local UICamera = CS.XUiManager.Instance.UiCamera

local XUiCoupletRollPanel = XClass(nil, "XUiCoupletRollPanel")

-- local XUiGridWordImage = require("XUi/XUiCoupletGame/XUiGridWordImage")
local XUiGridWordItem = require("XUi/XUiCoupletGame/XUiGridWordItem")

function XUiCoupletRollPanel:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RectTransform = ui
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self:Init()
end

function XUiCoupletRollPanel:Init()
    self.WordMoveLimitX = (self.PanelRightRoll.rect.width - self.DragWordItem.transform.rect.width)/2
    self.WordMoveLimitY = (self.PanelRightRoll.rect.height - self.DragWordItem.transform.rect.height)/2

    self.CoupletWords = {}
    self.TopWordImagePool = {}
    self.DownWordImagePool = {}
    self.TopWordItemPool = {}
    self.DownWordItemPool = {}
    self.DragItem = nil
    self.CurDragWordIndex = 0
end

function XUiCoupletRollPanel:Refresh(coupletId, isSelfChanged)
    self.CurCoupletId = coupletId
    self:RefreshUpWords(coupletId)
    self:RefreshDownWords(coupletId, isSelfChanged)
end

function XUiCoupletRollPanel:RefreshUpWords(coupletId)
    -- local upWords = XCoupletGameConfigs.GetCoupletUpWordsId(coupletId)
    -- local halfCount = #upWords / 2
    -- local _, remainder = math.modf(halfCount)
    -- if remainder > 0 then
    --     halfCount = math.ceil(halfCount)
    -- end

    -- local topDatas = {}
    -- local downDatas = {}
    -- for index, wordId in ipairs(upWords) do
    --     if index <= halfCount then
    --         tableInsert(topDatas, wordId)
    --     else
    --         tableInsert(downDatas, wordId)
    --     end
    -- end
    -- local onCreate = function(item, data)
    --     item:SetActiveEx(true)
    --     item:SetData(data)
    -- end

    -- XUiHelper.CreateTemplates(self, self.TopWordImagePool, topDatas, XUiGridWordImage.New, self.WordImageItem.gameObject, self.PanelLeftRollTop, onCreate)
    -- XUiHelper.CreateTemplates(self, self.DownWordImagePool, downDatas, XUiGridWordImage.New, self.WordImageItem.gameObject, self.PanelLeftRollDown, onCreate)
    self.RImgUp.gameObject:SetActiveEx(true)
    self.RImgUp:SetRawImage(XCoupletGameConfigs.GetCoupletUpImgUrl(coupletId))
end

function XUiCoupletRollPanel:RefreshDownWords(coupletId, isSelfChanged, getWordIndex)
    if XDataCenter.CoupletGameManager.GetCoupletGameStatus(coupletId) == XCoupletGameConfigs.CouPletStatus.Complete then -- 已经完成
        self.PanelRightRollTop.gameObject:SetActiveEx(false)
        self.PanelRightRollDown.gameObject:SetActiveEx(false)
        self.RImgDown.gameObject:SetActiveEx(true)
        self.RImgDown:SetRawImage(XCoupletGameConfigs.GetCoupletDownImgUrl(coupletId))
        if isSelfChanged then
            self.RootUi:PlayAnimation("RImgDownEnable")
        end
    else
        self.PanelRightRollTop.gameObject:SetActiveEx(true)
        self.PanelRightRollDown.gameObject:SetActiveEx(true)
        self.RImgDown.gameObject:SetActiveEx(false)
        local downWords = XDataCenter.CoupletGameManager.GetDownWordsDataById(coupletId)
        local halfCount = #downWords / 2
        local _, remainder = math.modf(halfCount)
        if remainder > 0 then
            halfCount = math.ceil(halfCount)
        end

        local topDatas = {}
        local downDatas = {}
        for index, wordId in ipairs(downWords) do
            if index <= halfCount then
                tableInsert(topDatas, {Id = wordId, Index = index})
            else
                tableInsert(downDatas, {Id = wordId, Index = index})
            end
        end
        local onCreate = function(item, data)
            item:SetActiveEx(true)
            item:OnCreate(data)
            item:SetOnDragCallBack(function() self:OnWordDrag(data) end)
            item:SetOnDragUpCallBack(function () self:OnWordUp() end)
            self.CoupletWords[data.Index] = item
            if getWordIndex and getWordIndex == data.Index then
                item:PlayGetWordAnimation()
            end
        end

        XUiHelper.CreateTemplates(self, self.TopWordItemPool, topDatas, XUiGridWordItem.New, self.WordItem.gameObject, self.PanelRightRollTop, onCreate)
        XUiHelper.CreateTemplates(self, self.DownWordItemPool, downDatas, XUiGridWordItem.New, self.WordItem.gameObject, self.PanelRightRollDown, onCreate)
    end
end

function XUiCoupletRollPanel:ShowWordEffectError()
    for _, item in pairs(self.CoupletWords) do
        if not XDataCenter.CoupletGameManager.CheckWordIsCorrect(self.CurCoupletId, item.Data.Index, item.Data.Id) then
            item:SetEffectErrorActiveEx(false)
            item:SetEffectErrorActiveEx(true)
        end
    end
end

function XUiCoupletRollPanel:OnWordDrag(data)
    if XDataCenter.CoupletGameManager.GetCoupletGameStatus(self.CurCoupletId) == XCoupletGameConfigs.CouPletStatus.Complete
        or not XDataCenter.CoupletGameManager.CheckCoupletIsCheckComplete(self.CurCoupletId) then
            return
    end

    local wordIndex = data.Index
    if self.LastClickIndex and self.LastClickIndex ~= wordIndex then
        self.CoupletWords[self.LastClickIndex].LongClickHandle:Reset()
        self:RefreshDownWords(self.CurCoupletId)
        self.LastClickIndex = nil
    end

    if not data then
        return
    end

    if not self.DragItem then -- 第一次进入拖拽 没有拖拽的文字
        self.CurDragIndex = wordIndex
        self.NearestIndex = nil
        self.CoupletWords[wordIndex]:DontShow(false) -- 隐藏该文字
        self.DragItem = self.DragWordItem
        self.DragItem.gameObject:SetActiveEx(true)
        self.DragItem:SetRawImage(XCoupletGameConfigs.GetCoupletWordImageById(self.CoupletWords[wordIndex].Data.Id))
        self.DragItem.gameObject.transform.localPosition = self:GetPosition()
        self.LastClickIndex = wordIndex
    else -- 持续更新拖拽的碎片位置
        self.DragItem.gameObject.transform.localPosition = self:GetPosition()
        local nearestIndex = 0
        nearestIndex = self:CalculateNearestWordIndex()
        if not self.NearestIndex then
            self.NearestIndex = nearestIndex
            self.CoupletWords[nearestIndex]:SetLight(true)
        else
            if self.NearestIndex ~= nearestIndex then
                self.CoupletWords[self.NearestIndex]:SetLight(false)
                self.NearestIndex = nearestIndex
                self.CoupletWords[nearestIndex]:SetLight(true)
            end
        end
    end
end

function XUiCoupletRollPanel:GetPosition()
    local screenPoint
    if CS.UnityEngine.Application.platform == CS.UnityEngine.RuntimePlatform.WindowsEditor or CS.UnityEngine.Application.platform == CS.UnityEngine.RuntimePlatform.WindowsPlayer then
        screenPoint = CS.UnityEngine.Vector2(CS.UnityEngine.Input.mousePosition.x, CS.UnityEngine.Input.mousePosition.y)
    else
        screenPoint = CS.UnityEngine.Input.GetTouch(0).position
    end

    -- 设置拖拽
    local hasValue, v2 = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(self.PanelRightRoll, screenPoint, UICamera)
    if hasValue then
        local x = v2.x
        local y = v2.y
        if x < -self.WordMoveLimitX then x = -self.WordMoveLimitX elseif x > self.WordMoveLimitX then x = self.WordMoveLimitX end
        if y < -self.WordMoveLimitY then y = -self.WordMoveLimitY elseif y > self.WordMoveLimitY then y = self.WordMoveLimitY end
        return CS.UnityEngine.Vector3(x, y, 0)
    else
        return CS.UnityEngine.Vector3.zero
    end
end

function XUiCoupletRollPanel:OnWordUp()
    if XDataCenter.CoupletGameManager.GetCoupletGameStatus(self.CurCoupletId) == XCoupletGameConfigs.CouPletStatus.Complete
        or not XDataCenter.CoupletGameManager.CheckCoupletIsCheckComplete(self.CurCoupletId) then
            return
    end

    if not self.NearestIndex then -- 点击抬起过快可能导致NearestIndex为空
        self:RefreshDownWords(self.CurCoupletId)
        if self.DragItem then
            self.DragItem.gameObject:SetActiveEx(false)
            self.DragItem = nil
            self.LastClickIndex = nil
        end
        return
    end

    if self.DragItem then
        self.DragItem.gameObject:SetActiveEx(false)
        self.DragItem = nil
        self.LastClickIndex = nil
        self.CoupletWords[self.NearestIndex]:SetLight(false)
        XDataCenter.CoupletGameManager.ChangeWord(self.CurDragIndex, self.NearestIndex)
        self.CurDragIndex = nil
        self.NearestIndex = nil
    end
end

function XUiCoupletRollPanel:CalculateNearestWordIndex()
    local nearestIndex = 0
    local nearestDistance = 0
    for index, wordItem in ipairs(self.CoupletWords) do
        local x1 = self.DragItem.gameObject.transform.position.x
        local y1 = self.DragItem.gameObject.transform.position.y
        local x2 = wordItem.Transform.position.x
        local y2 = wordItem.Transform.position.y
        local distance = (y2-y1)^2 + (x2-x1)^2
        if nearestDistance == 0 then
            nearestIndex = index
            nearestDistance = distance
        else
            if distance < nearestDistance then
                nearestIndex = index
                nearestDistance = distance
            end
        end
    end

    return nearestIndex
end

return XUiCoupletRollPanel
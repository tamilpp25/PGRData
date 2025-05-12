---@class XUiPanelWheelChairManualPassport: XUiNode
---@field _Control XWheelchairManualControl
---@field PanelBanner XUiCenterScroll
---@field PanelBannerScroll UnityEngine.UI.ScrollRect
local XUiPanelWheelChairManualPassport = XClass(XUiNode, 'XUiPanelWheelChairManualPassport')
local XUiPanelWheelChairManualPassportPanel = require('XUi/XUiWheelchairManual/UiPanelWheelChairManualPassport/XUiPanelWheelChairManualPassportPanel')
local XUiGridWheelChairManualPassportScrollDot = require('XUi/XUiWheelchairManual/UiPanelWheelChairManualPassport/XUiGridWheelChairManualPassportScrollDot')

local MISTAKE_DISTANCE = 25

function XUiPanelWheelChairManualPassport:OnStart()
    self._PassportPanel = XUiPanelWheelChairManualPassportPanel.New(self.PanelPassport, self, self.Parent)
    self._PassportPanel:Open()

    self.BtnReceive.CallBack = handler(self, self.OnRecieveAllClick)
    self.BtnBuy.CallBack = handler(self, self.OnBuyClick)
    self.PanelBanner:RegisterEndDragCallBack(handler(self, self.OnScrollDragEndEvent))
    self._ScrollSwitchInterval = self._Control:GetCurActivityScrollCardSwitchInterval()
    self:InitScrollCards()
    self.BtnGet.CallBack = handler(self, self.OnBtnGetClick)

end

function XUiPanelWheelChairManualPassport:OnEnable()
    self:Refresh()
    self:StartScrollUpdateTimer()
    -- 刷新红点
    self:RefreshBtnBuyReddot()
end

function XUiPanelWheelChairManualPassport:OnDisable()
    self:ClearScrollTimer()
    self:ClearScrollUpdateTimer()
end

function XUiPanelWheelChairManualPassport:Refresh()
    self:RefreshLevel()
    self:RefreshBtnRecieveAllState()
end

function XUiPanelWheelChairManualPassport:RefreshLevel()
    self.TxtLevel.text = self._Control:GetBpLevel()

    local percent = 0
    local progressContent = ''
    if self._Control:CheckCurActivityBpLevelIsMax() then
        percent = 1
        progressContent = XMVCA.XWheelchairManual:GetWheelchairManualConfigString('BpLevelMaxProgressLabel')
    else
        local needExp = self._Control:GetCurBPLevelNeedExp()
        local curExp = XDataCenter.ItemManager.GetCount(XMVCA.XWheelchairManual:GetWheelchairManualConfigNum('WheelchairManualBpExp'))
        percent = XTool.IsNumberValid(needExp) and curExp/needExp or 0
        progressContent = XUiHelper.FormatText(XMVCA.XWheelchairManual:GetWheelchairManualConfigString('CommonProcessLabel'), curExp, needExp)
    end
    
   
    self.TxtPointNum.text = progressContent
    self.ImgProgress.fillAmount = percent
end

function XUiPanelWheelChairManualPassport:RefreshBtnRecieveAllState()
    self.BtnReceive.gameObject:SetActiveEx(XMVCA.XWheelchairManual:CheckManualAnyRewardCanGet())
end

function XUiPanelWheelChairManualPassport:RefreshBtnBuyReddot()
    self.BtnBuy:ShowReddot(XMVCA.XWheelchairManual:CheckSubActivityIsNew(XEnumConst.WheelchairManual.ReddotKey.BPRewardNew))
end

function XUiPanelWheelChairManualPassport:OnRecieveAllClick()
    if XMVCA.XWheelchairManual:CheckManualAnyRewardCanGet() then
        XMVCA.XWheelchairManual:RequestWheelchairManualGetManualReward(0, function(success, rewardGoodsList)
            if success then
                self._PassportPanel:Refresh()
                self._Control:ShowRewardList(rewardGoodsList)
            end
        end)
    end
end

function XUiPanelWheelChairManualPassport:OnBuyClick()
    XLuaUiManager.Open('UiWheelChairManualPopupPassportCard')
    self:RefreshBtnBuyReddot()
end

--region 轮播图
function XUiPanelWheelChairManualPassport:InitScrollCards()
    self.CurIndex = 1
    -- 初始化轮播图
    local imgs = self._Control:GetCurActivityScrollCardImages()
    --- 文字图
    local bannerLabels = self._Control:GetCurActivityScrollCardBannerLabels()
    local showImgs
    local showLabels
    local imgCount = XTool.GetTableCount(imgs)
    if imgCount > 0 then
        showImgs = { imgs[imgCount] }
        showLabels = { bannerLabels[imgCount] }

        if imgCount > 1 then
            for i, v in ipairs(imgs) do
                table.insert(showImgs, v)
                table.insert(showLabels, bannerLabels[i])
            end
            table.insert(showImgs, showImgs[2])
            table.insert(showLabels, showLabels[2])
        end
    end

    self._ImgShowCount = XTool.GetTableCount(showImgs)
    self.ChildPosXs = {}
    local cellWidth = self.PanelBannerScroll.content:GetComponent("GridLayoutGroup").cellSize.x
    XUiHelper.RefreshCustomizedList(self.RImgBanner.transform.parent, self.RImgBanner, showImgs and #showImgs or 0, function(index, go)
        local rImg = go:GetComponent(typeof(CS.UnityEngine.UI.RawImage))
        local labelImg = XUiHelper.TryGetComponent(go.transform, "BannerLabelImg", "RawImage")
        if rImg then
            rImg:SetRawImage(showImgs[index])
        end

        if labelImg and not string.IsNilOrEmpty(showLabels[index]) then
            labelImg:SetRawImage(showLabels[index])
        end

        self.ChildPosXs[index] = (index - 1) * cellWidth
    end)
    
    -- 初始化轮播图的进度序列
    self.GridDot.gameObject:SetActiveEx(false)
    self._DotGrids = {}
    XUiHelper.RefreshCustomizedList(self.GridDot.transform.parent, self.GridDot, imgs and #imgs or 0, function(index, go)
        local grid = XUiGridWheelChairManualPassportScrollDot.New(go, self)
        table.insert(self._DotGrids, grid)
    end)
    
    -- 新增拖拽事件
    self.UiPanelAd = self.PanelBanner.gameObject:AddComponent(typeof(CS.XUiWidget))
    self.UiPanelAd:AddPointerClickListener(function()
        self:OnPointerClick()
    end)
    self.UiPanelAd:AddEndDragListener(function()
        self:OnEndDrag()
    end)
    self.UiPanelAd:AddDragListener(function()
        self:OnDrag()
    end)
    
    self._SkipList = self._Control:GetCurActivityScrollCardSkipIds()
    self:RefreshDots()
end

function XUiPanelWheelChairManualPassport:OnDrag()
    self.IsDraging = true
    self:ClearScrollTimer()
end

--停止拖动
function XUiPanelWheelChairManualPassport:OnEndDrag()
    self.IsDraging = false
end

function XUiPanelWheelChairManualPassport:OnPointerClick()
    if self.IsDraging then
        return
    end

    local fixedIndex = self.CurIndex - 1

    if fixedIndex == self._ImgShowCount - 1 then
        fixedIndex = 1
    elseif fixedIndex == 0 then
        fixedIndex = 2    
    end
    
    local skipId = self._SkipList[fixedIndex]

    if XTool.IsNumberValid(skipId) then
        if XFunctionManager.IsCanSkip(skipId) then
            XFunctionManager.SkipInterface(skipId)
        end
    end
end


---@param index @C#传递的索引，从0开始
function XUiPanelWheelChairManualPassport:OnScrollDragEndEvent(index)
    local nowIndex = index + 1
    if self.CurIndex == nowIndex then
        return
    end

    self:ClearScrollTimer()
    self.ScrollTimer = XScheduleManager.ScheduleOnce(function()
        self.PanelBanner:NextPage()
    end, self._ScrollSwitchInterval * XScheduleManager.SECOND)
    
    self.CurIndex = nowIndex
    self:RefreshDots()
end

function XUiPanelWheelChairManualPassport:RefreshDots()
    if not XTool.IsTableEmpty(self._DotGrids) then
        local fixedIndex = self.CurIndex - 1

        if fixedIndex == self._ImgShowCount - 1 then
            fixedIndex = 1    
        elseif fixedIndex == 0 then
            fixedIndex = 2    
        end
        
        for i, v in pairs(self._DotGrids) do
            v.ImgOff.gameObject:SetActiveEx(i ~= fixedIndex)
            v.ImgOn.gameObject:SetActiveEx(i == fixedIndex)
        end
    end
end

function XUiPanelWheelChairManualPassport:ClearScrollTimer()
    if self.ScrollTimer then
        XScheduleManager.UnSchedule(self.ScrollTimer)
        self.ScrollTimer = nil
    end
end

function XUiPanelWheelChairManualPassport:StartScrollUpdateTimer()
    if self._ImgShowCount > 1 then
        self._ScrollCardUpdateTimeId = XScheduleManager.ScheduleForever(function()
            local nowPosX = self.PanelBannerScroll.content.anchoredPosition.x
            local targetPosX = -self.ChildPosXs[self.CurIndex]
            
            -- 当索引是1时，指向循环队列
            if self.CurIndex == 1 and math.abs(nowPosX - targetPosX) <= MISTAKE_DISTANCE then
                self.PanelBanner:SetIndex(self._ImgShowCount - 2)
            elseif self.CurIndex == self._ImgShowCount and math.abs(nowPosX - targetPosX) <= MISTAKE_DISTANCE then
                self.PanelBanner:SetIndex(1)
            end
        end, 100)
    end
end

function XUiPanelWheelChairManualPassport:ClearScrollUpdateTimer()
    if self._ScrollCardUpdateTimeId then
        XScheduleManager.UnSchedule(self._ScrollCardUpdateTimeId)
        self._ScrollCardUpdateTimeId = nil
    end
end

function XUiPanelWheelChairManualPassport:OnBtnGetClick()
    local tabId = XMVCA.XWheelchairManual:GetCurActivityTabIdAndPanelUrlByTabType(XEnumConst.WheelchairManual.TabType.StepTask)
    if XTool.IsNumberValid(tabId) then
        local tabIndex = XMVCA.XWheelchairManual:GetCurActivityTabIndexByTabType(tabId)

        if XTool.IsNumberValid(tabIndex) then
            XEventManager.DispatchEvent(XEventId.EVENT_WHEELCHAIRMANUAL_TAB_GOTO, tabIndex)
        end
    end
end
--endregion


return XUiPanelWheelChairManualPassport
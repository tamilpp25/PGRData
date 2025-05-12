local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
---@class XUiWheelchairManualMain: XLuaUi
---@field _Control XWheelchairManualControl
---@field PanelTitleBtnGroup XUiButtonGroup
local XUiWheelchairManualMain = XLuaUiManager.Register(XLuaUi, 'UiWheelchairManualMain')
local XUiGridWheelchairManualMainTab = require('XUi/XUiWheelchairManual/UiWheelchairManualMain/XUiGridWheelchairManualMainTab')

function XUiWheelchairManualMain:OnAwake()
    self.BtnBack.CallBack = handler(self, self.Close)
    self.BtnMainUi.CallBack = XLuaUiManager.RunMain
end

function XUiWheelchairManualMain:OnStart(selectIndex)
    local itemGroup = self._Control:GetWheelchairManualConfigNumArray('ShowItemGroup')

    if not XTool.IsTableEmpty(itemGroup) then
        self._PanelAsset = XUiPanelAsset.New(self, self.PanelAsset, table.unpack(itemGroup))
    end
    self:InitTabs(selectIndex)
end

function XUiWheelchairManualMain:OnResume()
    self._TabSelectIndexFromResume = self._Control:GetTabIndexCache()
    
    self._Control:SetTabIndexCache(nil)
end

function XUiWheelchairManualMain:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_WHEELCHAIRMANUAL_TAB_GOTO, self.SelectTag, self)
    XEventManager.AddEventListener(XEventId.EVENT_WHEELCHAIRMANUAL_REFRESH_TABS_REDDOT, self.RefreshTabBtnsReddot, self)
    self:StartTimeDownTimer()
    self:RefreshTabBtnsReddot()
end

function XUiWheelchairManualMain:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_WHEELCHAIRMANUAL_TAB_GOTO, self.SelectTag, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_WHEELCHAIRMANUAL_REFRESH_TABS_REDDOT, self.RefreshTabBtnsReddot, self)
    self:StopTimeDownTimer()
end

function XUiWheelchairManualMain:OpenSubUi(url, type)
    if self._SubPanels == nil then
        self._SubPanels = {}
    end

    if not XTool.IsTableEmpty(self._SubPanels) then
        for i, v in pairs(self._SubPanels) do
            v:Close()
        end
    end

    if self._SubPanels[url] then
        self._SubPanels[url]:Open()
    else
        local rootGo = CS.UnityEngine.GameObject('', typeof(CS.UnityEngine.RectTransform))
        rootGo.transform:SetParent(self.PanelRightContent.transform)
        rootGo.transform.localPosition = Vector3.zero
        rootGo.transform.anchorMin = Vector2.zero
        rootGo.transform.anchorMax = Vector2.one
        rootGo.transform.anchoredPosition = Vector2.zero
        rootGo.transform.localScale = Vector3.one
        rootGo.transform.offsetMin = Vector2.zero
        rootGo.transform.offsetMax = Vector2.zero

        local ui = rootGo:LoadPrefab(url)
        ui.gameObject:SetLayerRecursively(self.PanelRightContent.gameObject.layer)
        rootGo.name = ui.name..'Root'
        XUiHelper.SetCanvasesSortingOrder(ui.transform)
        
        self._SubPanels[url] = require(XEnumConst.WheelchairManual.TabTypeModule[type]).New(ui, self)
        self._SubPanels[url]:Open()
    end
end

function XUiWheelchairManualMain:InitTabs(selectIndex)
    local tabs = XMVCA.XWheelchairManual:GetCurActivityTabs()
    self.BtnTab.gameObject:SetActiveEx(false)
    if not XTool.IsTableEmpty(tabs) then
        local buttonList = {}
        self._TabGrids = {}
        XUiHelper.RefreshCustomizedList(self.BtnTab.transform.parent, self.BtnTab, #tabs, function(index, go)
            -- 特殊处理活动引导CheckManualGuideHasAnyActivity
            local tabType = XMVCA.XWheelchairManual:GetManualTabTypeAndPanelUrl(tabs[index])

            if tabType == XEnumConst.WheelchairManual.TabType.Guide and not XMVCA.XWheelchairManual:CheckManualGuideHasAnyActivity() then
                -- 不需要显示活动引导页签
                go.gameObject:SetActiveEx(false)
                return
            end
            
            local grid = XUiGridWheelchairManualMainTab.New(go, self, tabs[index])
            table.insert(buttonList, grid.GridBtn)
            table.insert(self._TabGrids, grid)

            if tabType == XEnumConst.WheelchairManual.TabType.StepTask then
                -- 阶段任务页签副标题需要展示阶段进度
                local contentFormat = XMVCA.XWheelchairManual:GetWheelchairManualConfigString('PlanSecondTitle')
                local planId = self._Control:GetCurActivityCurrentPlanId()
                local passCount, allCount = XMVCA.XWheelchairManual:GetPlanProcess(planId)
                self:SetSecondTitle(XUiHelper.FormatText(contentFormat, self._Control:GetManualPlanName(planId), passCount, allCount), index)
            end
            
        end)
        self.PanelTitleBtnGroup:InitBtns(buttonList, handler(self, self.OnTabSelect), 1)
        self:RefreshTabBtnsState()

        local originSelect = XTool.IsNumberValid(selectIndex) and selectIndex or (self._TabSelectIndexFromResume or 1)
        self._TabSelectIndexFromResume = nil
        
        self.PanelTitleBtnGroup:SelectIndex(originSelect)
        
    end
end

function XUiWheelchairManualMain:OnTabSelect(index, force)
    if index == self._SelectIndex and not force then
        return
    end
    
    local tabGrid = self._TabGrids[index]

    -- 判断是否可选中
    local isOpened, desc = self:CheckTabIsOpened(tabGrid.TabId)

    if not isOpened then
        XUiManager.TipMsg(desc)
        return
    end

    self._SelectIndex = index

    local type, url = XMVCA.XWheelchairManual:GetManualTabTypeAndPanelUrl(tabGrid.TabId)

    if XTool.IsNumberValid(type) and not string.IsNilOrEmpty(url) then
        self:OpenSubUi(url, type)
    end

    tabGrid:OnClickEvent()
    
    self._Control:SetTabIndexCache(index)
    
    -- 设置资源栏颜色（3.0卡池背景和资源栏颜色冲突需要特殊处理下）
    if self._PanelAsset then
        if type == XEnumConst.WheelchairManual.TabType.Lotto then
            self._PanelAsset:SetCountTxtColor(XUiHelper.Hexcolor2Color(XMVCA.XWheelchairManual:GetWheelchairManualConfigString('PanelAssetCountColor', 2)))
        else
            self._PanelAsset:SetCountTxtColor(XUiHelper.Hexcolor2Color(XMVCA.XWheelchairManual:GetWheelchairManualConfigString('PanelAssetCountColor', 1)))
        end
    end
end

function XUiWheelchairManualMain:SelectTag(index)
    self.PanelTitleBtnGroup:SelectIndex(index)
end

function XUiWheelchairManualMain:SetSecondTitle(content, index)
    if self._TabGrids[index] then
        self._TabGrids[index]:SetSecondTitle(content)
    end
end

--- 刷新页签状态
function XUiWheelchairManualMain:RefreshTabBtnsState()
    if not XTool.IsTableEmpty(self._TabGrids) then
        for i, v in pairs(self._TabGrids) do
            local condition = self._Control:GetManualTabCondition(v.TabId)

            if XTool.IsNumberValid(condition) then
                v:SetButtonState(XConditionManager.CheckCondition(condition) and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
            end
        end
    end
end

function XUiWheelchairManualMain:CheckTabIsOpened(tabId)
    local condition = self._Control:GetManualTabCondition(tabId)

    if XTool.IsNumberValid(condition) then
        return XConditionManager.CheckCondition(condition)
    else
        return true
    end
end

--- 刷新页签的红点
function XUiWheelchairManualMain:RefreshTabBtnsReddot()
    if not XTool.IsTableEmpty(self._TabGrids) then
        for i, v in pairs(self._TabGrids) do
            v:RefreshReddot()
        end
    end
end

--region 倒计时
function XUiWheelchairManualMain:StartTimeDownTimer()
    self:StopTimeDownTimer()
    local hasLeftTime = XMVCA.XWheelchairManual:GetLeftTime()

    if hasLeftTime then
        if self.PanelTime then
            self.PanelTime.gameObject:SetActiveEx(true)
        end
        self:UpdateLeftTimeShow()
        self._LeftTimeDownTimeId = XScheduleManager.ScheduleForever(handler(self, self.UpdateLeftTimeShow), XScheduleManager.SECOND)
    else
        if self.TxtTime then
            self.TxtTime.text = ''
        end

        if self.PanelTime then
            self.PanelTime.gameObject:SetActiveEx(false)
        end
    end
end

function XUiWheelchairManualMain:StopTimeDownTimer()
    if self._LeftTimeDownTimeId then
        XScheduleManager.UnSchedule(self._LeftTimeDownTimeId)
        self._LeftTimeDownTimeId = nil
    end
end

function XUiWheelchairManualMain:UpdateLeftTimeShow()
    local hasLeftTime, leftTime = XMVCA.XWheelchairManual:GetLeftTime()
    if self.TxtTime then
        self.TxtTime.text = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
    end
end
--endregion

return XUiWheelchairManualMain
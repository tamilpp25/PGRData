--肉鸽2.0羁绊图鉴
local XUiBiancaTheatreComboTips = XLuaUiManager.Register(XLuaUi, "UiBiancaTheatreComboTips")
local XUiBiancaTheatreComboTipsTab = require("XUi/XUiBiancaTheatre/ComboList/XUiBiancaTheatreComboTipsTab")
local XUiBiancaTheatreComboTipsItemPanel = require("XUi/XUiBiancaTheatre/ComboList/XUiBiancaTheatreComboTipsItemPanel")
local TabType = {
    First = "BtnFirst",
    SecondTop = "BtnSecondTop",
    SecondBottom = "BtnSecondBottom",
    Second = "BtnSecond",
    SecondAll = "BtnSecondAll"
}
local UiButtonState = CS.UiButtonState
function XUiBiancaTheatreComboTips:OnAwake()
    XTool.InitUiObject(self)
    self.ScrollRectInstance = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/GameObject/PanelTab/ScrollTitleTab", "ScrollRect")
    self:RegisterBtnEvent()
    self:SetBtnTemplateDisable()
end

--isShowDisplay：是否展示羁绊图鉴列表（不判断是否有角色）
function XUiBiancaTheatreComboTips:OnStart(eCombo, isShowDisplay)
    self.IsShowDisplay = isShowDisplay
    self:InitComboTab()
    self.ItemPanel = XUiBiancaTheatreComboTipsItemPanel.New(self.PanelPart, self, isShowDisplay)
    --首次选中SubButton，MainButton会错误显示SelectClose，暂时定位不到问题先再选中一次SubButton
    local selectIndex = eCombo and self.ChildTabList[eCombo:GetComboId()] or 1
    self.BtnContent:SelectIndex(selectIndex)
    if selectIndex ~= 1 then
        self.BtnContent:SelectIndex(selectIndex)
        --滑动到选中页签所在位置
        XScheduleManager.ScheduleOnce(function()
            if XTool.UObjIsNil(self.GameObject) then
                return
            end
            local gridLocalPos = self.ScrollRectInstance.transform:InverseTransformPoint(self.TabList[selectIndex].Transform.position)
            if gridLocalPos.y > 0 then
                return
            end
            --选中页签和Viewport间的距离
            local viewportLocalPos = self.ScrollRectInstance.viewport.transform.localPosition
            local difference = Vector3(viewportLocalPos.x, math.abs(viewportLocalPos.y), viewportLocalPos.z) - gridLocalPos
            difference = Vector3(0, difference.y, 0)
            --Content和Viewport间的距离
            local offset = self.BtnContent.transform.position - self.ScrollRectInstance.viewport.transform.position
            offset = Vector3(0, math.abs(offset.y), 0)
            --移动到选中页签所在的坐标
            local contentLocalPos = self.ScrollRectInstance.viewport.transform:InverseTransformPoint(self.BtnContent.transform.position - offset)
            self.BtnContent.transform.localPosition = contentLocalPos + difference
        end, 1)
    end
end

function XUiBiancaTheatreComboTips:SetBtnTemplateDisable()
    self.BtnFirst.gameObject:SetActiveEx(false)
    self.BtnSecondTop.gameObject:SetActiveEx(false)
    self.BtnSecond.gameObject:SetActiveEx(false)
    self.BtnSecondBottom.gameObject:SetActiveEx(false)
    self.BtnSecondAll.gameObject:SetActiveEx(false)
end

function XUiBiancaTheatreComboTips:RegisterBtnEvent()
    self:BindExitBtns()
    self:RegisterClickEvent(self.BtnTanchuangCloseBig, function() self:Close() end)
end

function XUiBiancaTheatreComboTips:InitComboTab()
    self.ComboList = XDataCenter.BiancaTheatreManager.GetComboList()
    self.ComboTabDataList = self:InitComboTabDataList()
    self:CreateComboTab()
end

function XUiBiancaTheatreComboTips:InitComboTabDataList()
    local allCombos = self.ComboList:GetAllCombos()
    local comboList = {} -- {[BaseComboId] = {[1] = ComboListIndex…}}
    local baseComboTypeCfgs = XBiancaTheatreConfigs.GetBaseComboTypeConfig()
    for _, baseComboType in pairs(baseComboTypeCfgs) do
        local baseId = baseComboType.Id
        local orderId = baseComboType.OrderId
        for _, eCombo in pairs(allCombos) do
            if eCombo:GetComboTypeId() == baseId then
                if not comboList[orderId] then comboList[orderId] = {} end
                table.insert(comboList[orderId], eCombo)
            end
        end
    end
    
    --排序
    for _, comboList in pairs(comboList) do
        table.sort(comboList, function(a, b)
            return a:GetComboId() < b:GetComboId()
        end)
    end

    local dataList = {}
    local tabCount = 1
    for orderId, childComboList in pairs(comboList) do
        local comboTypeCfg = XBiancaTheatreConfigs.GetBaseComboTypeCfgByOrderId(orderId)
        local tabData = {
            TabType = TabType.First,
            Name = comboTypeCfg.Name,
            TabId = tabCount,
            BaseComboId = comboTypeCfg.Id
        }
        table.insert(dataList, tabData)
        local fatherTabId = tabCount
        tabCount = tabCount + 1
        local childNum = #childComboList
        local childCount = 0
        local activeChildCount = 0
        for _, childCombo in pairs(childComboList) do
            childCount = childCount + 1
            local childTabData = {
                Name = childCombo:GetName(),
                TabId = tabCount,
                FatherTabId = fatherTabId,
                ComboId = childCombo:GetComboId(),
                Combo = childCombo,
                IsActive = childCombo:GetComboActive()
            }
            if childNum == 1 then
                childTabData.TabType = TabType.SecondAll
            elseif childNum > 1 and childCount == 1 then
                childTabData.TabType = TabType.SecondTop
            elseif childNum > 1 and childCount < childNum then
                childTabData.TabType = TabType.Second
            elseif childNum > 1 and childCount == childNum then
                childTabData.TabType = TabType.SecondBottom
            end
            table.insert(dataList, childTabData)
            tabCount = tabCount + 1
            if childCombo:GetComboActive() then activeChildCount = activeChildCount + 1 end
        end
        tabData.ChildCount = childCount
        tabData.ActiveChildCount = activeChildCount
    end
    return dataList
end

function XUiBiancaTheatreComboTips:CreateComboTab()
    self.TabList = {}
    self.FirstTabList = {}
    self.ChildTabList = {}
    self.BtnList = {}
    for i = 1, #self.ComboTabDataList do
        local data = self.ComboTabDataList[i]
        local btnPrefab = XUiHelper.Instantiate(self[data.TabType].gameObject, self.BtnContent.transform)
        self.TabList[i] = XUiBiancaTheatreComboTipsTab.New(btnPrefab, self, i, data, self.IsShowDisplay,
            function(index, tabType, isSelect) self:OnTabClick(index, tabType, isSelect) end)
        btnPrefab.gameObject:SetActiveEx(data.TabType == TabType.First)
        self.BtnList[i] = btnPrefab:GetComponent("XUiButton")
        if data.TabType == TabType.First then
            self.FirstTabList[data.BaseComboId] = i
        end
        if data.TabType ~= TabType.First then
            self.BtnList[i].SubGroupIndex = data.FatherTabId
            self.ChildTabList[data.ComboId] = i
        end
        self.BtnList[i]:SetButtonState(UiButtonState.Normal)
    end
    self.BtnContent:Init(self.BtnList, function(index) self.TabList[index]:OnClick() end)
end

function XUiBiancaTheatreComboTips:RefreshComboList(childComboData)
    self.ItemPanel:UpdateData(childComboData)
end
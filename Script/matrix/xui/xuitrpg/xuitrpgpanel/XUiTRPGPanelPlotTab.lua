local Object
local CSXTextManagerGetText = CS.XTextManager.GetText
local UiIndex = {
    TRPGTruthRoadMain = 1,  --求真之路
    TRPGYingDi = 2,         --营地
}

--求真之路和探索营地入口
local XUiTRPGPanelPlotTab = XClass(nil, "XUiTRPGPanelPlotTab")

function XUiTRPGPanelPlotTab:Ctor(ui, isShowTRPGTruthRoadMain)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    Object = CS.UnityEngine.Object
    self:InitUiOpenCheckList()
    self:InitTab(isShowTRPGTruthRoadMain)
end

function XUiTRPGPanelPlotTab:InitUiOpenCheckList()
    self.UiOpenCheckList = {
        [UiIndex.TRPGTruthRoadMain] = self.CheckIsOpenTruthRoad,
    }

    self.BtnPrequelPlotTabRedPointConditions = {
        [UiIndex.TRPGTruthRoadMain] = {
            func = self.OnCheckTRPGTruthRoadRedPoint,
            conditionGroup = {XRedPointConditions.Types.CONDITION_TRPG_TRUTH_ROAD_REWARD}
        },
        [UiIndex.TRPGYingDi] = {
            func = self.OnCheckTRPGYingDiRedPoint,
            conditionGroup = {XRedPointConditions.Types.CONDITION_TRPG_COLLECTION_MEMOIR}
        },
    }
end

function XUiTRPGPanelPlotTab:InitTab(isShowTRPGTruthRoadMain)
    self.GroupTabBtns = {}
    self.GroupTabRed = {}
    local config = XTRPGConfigs.GetPanelPlotTabTemplate()
    local name, bg
    for i in ipairs(config) do
        if not self.GroupTabBtns[i] then
            if i == 1 then
                self.GroupTabBtns[i] = self.BtnPrequelPlotTab
            else
                local btn = Object.Instantiate(self.BtnPrequelPlotTab)
                btn.transform:SetParent(self.UiContent.transform, false)
                self.GroupTabBtns[i] = btn
            end
        end
        name = XTRPGConfigs.GetPanelPlotTabName(i)
        bg = XTRPGConfigs.GetPanelPlotTabBg(i)
        if i == UiIndex.TRPGTruthRoadMain then
            self.GroupTabBtns[i].gameObject:SetActiveEx(isShowTRPGTruthRoadMain and true or false)
        else
            self.GroupTabBtns[i].gameObject:SetActiveEx(true)
        end
        self.GroupTabBtns[i]:SetName(name)
        self.GroupTabBtns[i]:SetRawImage(bg)
        self:AddRedPointEvent(i)
    end

    self.UiContent:Init(self.GroupTabBtns, function(groupIndex) self:OnTabsClick(groupIndex) end)
end

function XUiTRPGPanelPlotTab:Refresh()
    local ret
    for i, groupTabBtn in ipairs(self.GroupTabBtns) do
        ret = XTRPGConfigs.CheckPanelPlotTabCondition(i)
        groupTabBtn:SetDisable(not ret)
    end
end

function XUiTRPGPanelPlotTab:OnTabsClick(groupIndex)
    local openUiName = XTRPGConfigs.GetPanelPlotTabOpenUiName(groupIndex)
    local isOpen, desc, param = self:CheckIsOpen(groupIndex)
    if isOpen then
        XLuaUiManager.Open(openUiName, param)
    else
        XUiManager.TipMsg(desc)
    end
end

function XUiTRPGPanelPlotTab:AddRedPointEvent(index)
    local tabBtn = self.GroupTabBtns[index]
    local redPointConditions = self.BtnPrequelPlotTabRedPointConditions[index]
    local func = redPointConditions and redPointConditions.func
    local conditionGroup = redPointConditions and redPointConditions.conditionGroup
    if tabBtn and func and conditionGroup then
        local redId = self:AddRedPointEvent(tabBtn, func, self, conditionGroup)
        self.GroupTabRed[index] = redId
    end
end

function XUiTRPGPanelPlotTab:CheckIsOpen(index)
    if self.UiOpenCheckList[index] then
        return self.UiOpenCheckList[index]()
    end
    return true, ""
end

function XUiTRPGPanelPlotTab:CheckIsOpenTruthRoad()
    local ret, desc = XTRPGConfigs.CheckPanelPlotTabCondition(UiIndex.TRPGTruthRoadMain)
    if ret then
        local mainAreaMaxNum = XTRPGConfigs.GetMainAreaMaxNum()
        local isTruthRoadOpenArea
        for mainAreaId = 1, mainAreaMaxNum do
            isTruthRoadOpenArea = XDataCenter.TRPGManager.IsTruthRoadOpenArea(mainAreaId)
            if isTruthRoadOpenArea then
                return true, "", {mainAreaId}
            end
        end
    end
    return false, desc
end

--更新求真之路红点显示
function XUiTRPGPanelPlotTab:OnCheckTRPGTruthRoadRedPoint(count)
    local tabBtn = self.GroupTabBtns[UiIndex.TRPGTruthRoadMain]
    if tabBtn then
        local ret = XTRPGConfigs.CheckPanelPlotTabCondition(UiIndex.TRPGTruthRoadMain)
        tabBtn:ShowReddot(ret and count >= 0)
    end
end

--更新营地红点显示
function XUiTRPGPanelPlotTab:OnCheckTRPGYingDiRedPoint(count)
    local tabBtn = self.GroupTabBtns[UiIndex.TRPGYingDi]
    if tabBtn then
        tabBtn:ShowReddot(count >= 0)
    end
end

function XUiTRPGPanelPlotTab:OnDestroy()
    self:ReleaseRed()
end

function XUiTRPGPanelPlotTab:ReleaseRed()
    for _, redId in pairs(self.GroupTabRed) do
        self:RemoveRedPointEvent(redId)
    end
end

return XUiTRPGPanelPlotTab
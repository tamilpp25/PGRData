local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiMultiDimDetails = XLuaUiManager.Register(XLuaUi, "UiMultiDimDetails")
local XUiEnvironmentGrid = require("XUi/XUiMultiDim/XUiMultiDimEnvironmentGrid")
local DefaultIndex = 1

function XUiMultiDimDetails:OnAwake()
    self.BtnTanchuangClose.CallBack = function() self:OnBtnTanchuangClose() end
    self.UiEnvironmentPanel = nil
    self:InitDynamicTable()
end

function XUiMultiDimDetails:OnBtnTanchuangClose()
    self:Close()
end

function XUiMultiDimDetails:OnStart(stageId, isSingleStage)
    self.StageId = stageId
    if isSingleStage then
        -- 单人副本
        self.MStage = XMultiDimConfig.GetMultiSingleStageDataById(stageId)
    else
        -- 组队副本
        self.MStage = XMultiDimConfig.GetMultiDimDifficultyStageData(stageId)
    end
    self.BuffIds = self.MStage.BaseBuffId
    if not self.BuffIds or not next(self.BuffIds) then
        return
    end
    
    self:SetData()
end

function XUiMultiDimDetails:InitDynamicTable()
    self.TxtBuffDetail.gameObject:SetActiveEx(false)
    self.RImgBuffDetail.gameObject:SetActiveEx(false)

    self.GridBuff.gameObject:SetActiveEx(false)
    self.DynamicTable = XDynamicTableNormal.New(self.BuffList)
    self.DynamicTable:SetProxy(XUiEnvironmentGrid, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiMultiDimDetails:SetData()
    self:RefreshBuffs()
    self:RefreshBuffDetail()
end

function XUiMultiDimDetails:RefreshBuffDetail(index)
    if index == nil then index = DefaultIndex end
    local buffConfigs = XMultiDimConfig.GetMultiDimBuffDetailsConfig(self.BuffIds[index])
    local childCount = self.BuffDetailContent.childCount
    for i = childCount, 1, -1 do
        CS.UnityEngine.Object.Destroy(self.BuffDetailContent:GetChild(i - 1).gameObject)
    end
    local content, contentType, value, typeIndex, go
    for i = 1, #buffConfigs.TeachingContents do
        content = buffConfigs.TeachingContents[i]
        -- 解释content
        content = string.gsub(content, "\"", "") -- hack:配置读取出来会有双分号
        typeIndex = string.find(content, ":")
        if typeIndex == nil then
            contentType = "img"
            value = content
        else
            contentType = string.sub(content, 1, typeIndex - 1)
            value = string.sub(content, typeIndex + 1)
        end
        if contentType == "text" then
            go = CS.UnityEngine.Object.Instantiate(self.TxtBuffDetail, self.BuffDetailContent)
            go:GetComponent("Text").text = value
        elseif contentType == "img" then
            go = CS.UnityEngine.Object.Instantiate(self.RImgBuffDetail, self.BuffDetailContent)
            go:GetComponent("RawImage"):SetRawImage(value)
        end
        go.gameObject:SetActiveEx(true)
    end
end

function XUiMultiDimDetails:RefreshBuffs()
    self.DynamicTable:SetDataSource(self.BuffIds)
    self.DynamicTable:ReloadDataSync(1)
end

function XUiMultiDimDetails:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetData(self.BuffIds[index], index)
    end
end

function XUiMultiDimDetails:OnBuffGridClicked(index)
    for _, grid in pairs(self.DynamicTable:GetGrids()) do
        grid:SetSelectStatus(false)
    end
    self:RefreshBuffDetail(index)
end
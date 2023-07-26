local XUiColorTableBuffDetail = XLuaUiManager.Register(XLuaUi, "UiColorTableBuffDetail")
local XUiGridColorTableBuffDetail = require("XUi/XUiColorTable/Grid/XUiGridColorTableBuffDetail")
local DefaultIndex = 1

function XUiColorTableBuffDetail:OnAwake()
    self.BuffCfgList = {} -- buff配置表
    self.SelectIndex = 1

    self:SetButtonCallBack()
    self:InitDynamicTable()
end

function XUiColorTableBuffDetail:OnStart(buffCfgList)
    self.BuffCfgList = buffCfgList
end

function XUiColorTableBuffDetail:OnEnable()
    self:RefreshDynamicTable()
    self:RefreshBuffDetail(1)
end

function XUiColorTableBuffDetail:SetButtonCallBack()
    self.BtnTanchuangClose.CallBack = function() self:Close() end
end

function XUiColorTableBuffDetail:InitDynamicTable()
    self.TxtBuffDetail.gameObject:SetActiveEx(false)
    self.RImgBuffDetail.gameObject:SetActiveEx(false)

    self.GridBuff.gameObject:SetActiveEx(false)
    self.DynamicTable = XDynamicTableNormal.New(self.BuffList)
    self.DynamicTable:SetProxy(XUiGridColorTableBuffDetail, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiColorTableBuffDetail:RefreshDynamicTable()
    self.DynamicTable:SetDataSource(self.BuffCfgList)
    self.DynamicTable:ReloadDataSync(1)
end

function XUiColorTableBuffDetail:RefreshBuffDetail(index)
    local buffConfig = self.BuffCfgList[index]
    if buffConfig == nil then return end

    local childCount = self.BuffDetailContent.childCount
    for i = childCount, 1, -1 do
        CS.UnityEngine.Object.Destroy(self.BuffDetailContent:GetChild(i - 1).gameObject)
    end
    local content, contentType, value, typeIndex, go
    for i = 1, #buffConfig.TeachingContents do
        content = buffConfig.TeachingContents[i]
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

function XUiColorTableBuffDetail:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local isSelect = index == self.SelectIndex
        grid:SetData(self.BuffCfgList[index], index)
        grid:SetSelectStatus(isSelect)
    end
end

function XUiColorTableBuffDetail:OnBuffGridClicked(index)
    for i, grid in pairs(self.DynamicTable:GetGrids()) do
        local isSelect = i == index
        grid:SetSelectStatus(isSelect)
    end
    self:RefreshBuffDetail(index)
end
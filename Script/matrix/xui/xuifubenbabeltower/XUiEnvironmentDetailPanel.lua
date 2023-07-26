local DefaultIndex = 1

--######################## XUiEnvironmentGrid ########################
local XUiEnvironmentGrid = XClass(nil, "XUiEnvironmentGrid")

function XUiEnvironmentGrid:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.RootUi = rootUi
    self.Index = nil
    self.BtnSelf.CallBack = function() self:OnBtnSelfClicked() end
end

function XUiEnvironmentGrid:SetData(buffId, index)
    self.Index = index
    local buffConfigs = XFubenBabelTowerConfigs.GetBabelBuffConfigs(buffId)
    -- 描述
    self.TxtAmbien.text = buffConfigs.Desc
    -- 序号
    self.TxtNumber.text = (index > 9) and index or string.format("0%d", index)
    self.TxtName.text = buffConfigs.Name
    self:SetSelectStatus(index == DefaultIndex)
end

function XUiEnvironmentGrid:SetSelectStatus(value)
    self.ImgSelected.gameObject:SetActiveEx(value)
end

function XUiEnvironmentGrid:OnBtnSelfClicked()
    self.RootUi:OnBuffGridClicked(self.Index)
    self:SetSelectStatus(true)
end

--######################## XUiEnvironmentDetailPanel ########################
local XUiEnvironmentDetailPanel = XClass(nil, "XUiEnvironmentDetailPanel")

function XUiEnvironmentDetailPanel:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.GridBuff.gameObject:SetActiveEx(false)
    self.DynamicTable = XDynamicTableNormal.New(self.BuffList)
    self.DynamicTable:SetProxy(XUiEnvironmentGrid, self)
    self.DynamicTable:SetDelegate(self)
    self.BuffIds = nil
end

function XUiEnvironmentDetailPanel:SetData(buffIds)
    self.BuffIds = buffIds
    self:RefreshBuffs()
    self:RefreshBuffDetail()
end

function XUiEnvironmentDetailPanel:RefreshBuffDetail(index)
    if index == nil then index = DefaultIndex end
    local buffConfigs = XFubenBabelTowerConfigs.GetBabelBuffConfigs(self.BuffIds[index])
    self.TxtBuffDetail.gameObject:SetActiveEx(false)
    self.RImgBuffDetail.gameObject:SetActiveEx(false)
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

function XUiEnvironmentDetailPanel:RefreshBuffs()
    self.DynamicTable:SetDataSource(self.BuffIds)
    self.DynamicTable:ReloadDataSync(1)
end

function XUiEnvironmentDetailPanel:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetData(self.BuffIds[index], index)
    end
end

function XUiEnvironmentDetailPanel:OnBuffGridClicked(index)
    for _, grid in pairs(self.DynamicTable:GetGrids()) do
        grid:SetSelectStatus(false)
    end
    self:RefreshBuffDetail(index)
end

return XUiEnvironmentDetailPanel

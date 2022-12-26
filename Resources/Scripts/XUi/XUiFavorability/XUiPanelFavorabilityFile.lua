XUiPanelFavorabilityFile = XClass(nil, "XUiPanelFavorabilityFile")

function XUiPanelFavorabilityFile:Ctor(ui, uiRoot, parent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot
    self.Parent = parent
    self.GridPool = {}
    XTool.InitUiObject(self)
    self.GridItem.gameObject:SetActiveEx(false)
end

function XUiPanelFavorabilityFile:OnRefresh()
    self:RefreshDatas()
end

function XUiPanelFavorabilityFile:RefreshDatas()
    local characterId = self.UiRoot:GetCurrFavorabilityCharacter()
    if not characterId then
        return
    end
    local fileData = XFavorabilityConfigs.GetCharacterBaseDataById(characterId)

    if fileData == nil then
        return
    end

    self.TxtRoleName.text = XDataCenter.FavorabilityManager.GetNameWithTitleById(characterId)
    self.TxtTradeName.text = XCharacterConfigs.GetCharacterTradeName(characterId)

    self:GenerateDataGrid(fileData)
end

function XUiPanelFavorabilityFile:GenerateDataGrid(fileData)
    -- 回收格子
    for i = self.DataContent.transform.childCount - 1, 0, -1 do
        local grid = self.DataContent:GetChild(i)
        local gridGO = grid.gameObject

        if gridGO.activeSelf then
            gridGO:SetActiveEx(false)
            table.insert(self.GridPool, gridGO)
        end
    end

    -- 拿出格子
    for i, dataTitle in ipairs(fileData.BaseDataTitle) do
        local grid

        if next(self.GridPool) then
            grid = table.remove(self.GridPool)
        else
            grid = CS.UnityEngine.Object.Instantiate(self.GridItem)
        end

        -- 数据赋值
        grid.transform:SetParent(self.DataContent, false)
        local txtTitle = XUiHelper.TryGetComponent(grid.transform, "TxtBaseDataTitle", "Text")
        local txtData = XUiHelper.TryGetComponent(grid.transform, "TxtBaseData", "Text")
        txtTitle.text = dataTitle
        txtData.text = fileData.BaseData[i] or ""

        grid.gameObject:SetActiveEx(true)
    end
end

function XUiPanelFavorabilityFile:SetViewActive(isActive)
    self.GameObject:SetActive(isActive)
    if isActive then
        self:RefreshDatas()
    end
end

function XUiPanelFavorabilityFile:OnSelected(isSelected)
    self.GameObject:SetActive(isSelected)
    if isSelected then
        self:RefreshDatas()
    end
end

return XUiPanelFavorabilityFile
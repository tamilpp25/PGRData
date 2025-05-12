local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")

local XUiBagOrgnizeEditor = XLuaUiManager.Register(XLuaUi, 'UiBagOrgnizeEditor')

local CSInput = CS.UnityEngine.Input

function XUiBagOrgnizeEditor:OnAwake()
    self.BtnBack.CallBack = handler(self, self.Close)
    self.BtnMainUi.CallBack = XLuaUiManager.RunMain
    self._EditorControl = self._Control:GetEditorControl()

    XUiHelper.RegisterClickEvent(self, self.SaveBtn, self.OnSaveBtnClick)
    XUiHelper.RegisterClickEvent(self, self.ResetBtn, self.OnResetBtnClick)
    
    self.MonoProxy = self.GameObject:AddComponent(typeof(CS.XLuaBehaviour))
    self.MonoProxy.LuaLateUpdate = handler(self, self.OnLateUpdate)
end

function XUiBagOrgnizeEditor:OnStart()
    self:InitTiles()
    self:InitFiles()
    self:InitMap()
end

function XUiBagOrgnizeEditor:OnDestroy()
    self._EditorControl = nil
    self.MonoProxy.LuaLateUpdate = nil
    self.MonoProxy = nil
end

function XUiBagOrgnizeEditor:Close()
    if XTool.IsNumberValid(self._SelectedFileIndex) then
        if self._EditorControl:CheckFileIsChanged(self._SelectedFileIndex) then
            XUiManager.DialogTip('配置未保存', '当前配置有编辑更改且未保存，是否放弃更改并退出？', nil, nil, function()
                self.Super.Close(self)
            end)
            return
        end
    end
    
    self.Super.Close(self)
end

function XUiBagOrgnizeEditor:InitTiles()
    self._EditorControl:ReloadTiles()
    local tileList = self._EditorControl:GetTiles()

    if not XTool.IsTableEmpty(tileList) then
        self._TileList = XDynamicTableNormal.New(self.TileList)
        self._TileList:SetDelegate(self)
        self._TileList:SetProxy(require('XUi/XUiBagOrganizeActivity/Editor/XUiGridBagOrgnizeTileEditor'), self)
        
        self._TileList:SetDataSource(tileList)
        self._TileList:ReloadDataASync()
    end
end

function XUiBagOrgnizeEditor:InitFiles()
    self._EditorControl:ReloadFiles()
    local files = self._EditorControl:GetFiles()

    if not XTool.IsTableEmpty(files) then
        self._FileList = XDynamicTableNormal.New(self.FileList)
        self._FileList:SetDelegate(self)
        self._FileList:SetDynamicEventDelegate(handler(self, self.OnFileDynamicTableEvent))
        self._FileList:SetProxy(require('XUi/XUiBagOrganizeActivity/Editor/XUiGridBagOrganizeFileEditor'), self)

        self._FileList:SetDataSource(files)
        self._FileList:ReloadDataASync()
    end
end

function XUiBagOrgnizeEditor:InitMap()
    self.Tile.gameObject:SetActiveEx(false)
    self.TileMap.enabled = false
    self._EditorControl:ReloadMap()
    local map = self._EditorControl:GetMap()

    if map then
        -- 设置尺寸
        local singleWidth = self.Content.cellSize.x + self.Content.spacing.x
        local singleHeight = self.Content.cellSize.y +self.Content.spacing.y
        
        local finalWidth = singleWidth * self._EditorControl:GetMapWidth() + self.Content.padding.left + self.Content.padding.right
        local finalHeight = singleHeight * self._EditorControl:GetMapHeight() + self.Content.padding.top + self.Content.padding.bottom

        self.Content.transform.sizeDelta = Vector2(finalWidth, finalHeight)
        
        -- 生成格子
        self._Block = {}
        
        local proxy = require('XUi/XUiBagOrganizeActivity/Editor/XUiGridBagOrignizeBlockEditor')
        
        for i, v in ipairs(map._Map) do
            local obj = CS.UnityEngine.GameObject.Instantiate(self.Tile, self.Tile.transform.parent)
            local blockCtrl = proxy.New(obj, self, v)
            blockCtrl:Open()
            table.insert(self._Block, blockCtrl)
        end
        
        -- 刷新尺寸显示
        self.MapSizeText.text = tostring(self._EditorControl:GetMapWidth())..' X '..tostring(self._EditorControl:GetMapHeight())
    end
end

function XUiBagOrgnizeEditor:OnDynamicTableEvent(event, index, proxy)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        proxy:Refresh(self._TileList.DataSource[index])
        -- 默认选中第一个
        if index == 1 then
            proxy:OnClickEvent()
        end
    end
end

function XUiBagOrgnizeEditor:OnFileDynamicTableEvent(event, index, proxy)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        self._InitTable = true
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        proxy:Refresh(self._FileList.DataSource[index], index)
        -- 默认选中第一个
        if index == 1 and self._InitTable then
            self._InitTable = false
            proxy:OnClickEvent()
        end
    end
end

function XUiBagOrgnizeEditor:OnSaveBtnClick()
    self._EditorControl:SaveMap()

    if XTool.IsNumberValid(self._SelectedFileIndex) then
        -- 判断更改状态
        self.changedTips.gameObject:SetActiveEx(self._EditorControl:CheckFileIsChanged(self._SelectedFileIndex))
    end
end

function XUiBagOrgnizeEditor:OnResetBtnClick()
    -- 清空网格数据
    self._EditorControl:ClearMap()
    -- 刷新前端网格显示
    local map = self._EditorControl:GetMap()
    for i, v in ipairs(map._Map) do
        self._Block[i]:Refresh(v)
    end
    self._EditorControl:MarkDataState(false)
    self:OnFileChanged()
end

function XUiBagOrgnizeEditor:OnFileChanged()
    if XTool.IsNumberValid(self._SelectedFileIndex) then
        -- 刷新网格
        self._EditorControl:ReloadFileById(self._SelectedFileIndex)
        self:RefreshMapShow()
        -- 判断更改状态
        self.changedTips.gameObject:SetActiveEx(self._EditorControl:CheckFileIsChanged(self._SelectedFileIndex))
    end
end

function XUiBagOrgnizeEditor:OnMapChanged()
    if XTool.IsNumberValid(self._SelectedFileIndex) then
        -- 判断更改状态
        self.changedTips.gameObject:SetActiveEx(self._EditorControl:CheckFileIsChanged(self._SelectedFileIndex))
    end
end

function XUiBagOrgnizeEditor:RefreshMapShow()
    if not XTool.IsTableEmpty(self._Block) then
        for i, v in pairs(self._Block) do
            v:Refresh()
        end
    end
end

function XUiBagOrgnizeEditor:OnSelectFileEvent(uiFileSelected)
    if XTool.IsNumberValid(self._SelectedFileIndex) then

        if self._EditorControl:CheckFileIsChanged(self._SelectedFileIndex) then
            local sureFunc = function()
                self._EditorControl:MarkDataState(false)
                self:_UnSelectOldFileGrid()
                uiFileSelected:Select()
                self._SelectedFileIndex = uiFileSelected and uiFileSelected.Index or 0
                self:OnFileChanged()
            end

            local closeFunc = function()
                uiFileSelected.Btn:SetButtonState(CS.UiButtonState.Normal)
            end

            XUiManager.DialogTip('配置未保存', '当前配置有编辑更改且未保存，是否放弃更改并切换配置？', nil, closeFunc, sureFunc)
            return
        end

        self:_UnSelectOldFileGrid()
    end

    uiFileSelected:Select()
    self._SelectedFileIndex = uiFileSelected and uiFileSelected.Index or 0
    self:OnFileChanged()
end

function XUiBagOrgnizeEditor:_UnSelectOldFileGrid()
    if XTool.IsNumberValid(self._SelectedFileIndex) then
        local grids = self._FileList:GetGrids()

        if grids then
            for i, grid in pairs(grids) do
                if grid.Index == self._SelectedFileIndex then
                    grid:UnSelect()
                end
            end
        end
    end
end

function XUiBagOrgnizeEditor:OnSelectTileEvent(uiTileSelected)
    if self._SelectedBtn then
        self._SelectedBtn:UnSelect()
    end

    uiTileSelected:Select()

    self._SelectedBtn = uiTileSelected
end

function XUiBagOrgnizeEditor:OnLateUpdate()
    if CSInput.GetKey('q') then
        self._IsDragMode = true
        self.TileMap.enabled = true
    else
        self._IsDragMode = false
        self.TileMap.enabled = false
    end
end

function XUiBagOrgnizeEditor:IsPaintMode()
    return not self._IsDragMode
end

return XUiBagOrgnizeEditor
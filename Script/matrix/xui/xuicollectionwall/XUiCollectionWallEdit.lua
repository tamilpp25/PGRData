local XUiCollectionWallEdit = XLuaUiManager.Register(XLuaUi, "UiCollectionWallEdit")

local XUiGridSelectItem = require("XUi/XUiCollectionWall/XUiCollectionWallGrid/XUiGridSelectItem")
local XUiGridPlacedCollection = require("XUi/XUiCollectionWall/XUiCollectionWallGrid/XUiGridPlacedCollection")

function XUiCollectionWallEdit:OnStart(wallData)
    self.IsEditMode = false
    self.WallData = wallData
    self.CurSelectCollection = nil          -- 摆放模式中选择的收藏品
    self.IsPanelSelectItemDraging = false   -- 底部的Item选择界面是否在拖动中
    self.IsSaving = false                   -- 是否正在保存中

    self.RedHorPool = {}    -- 水平红格子条
    self.RedVerPool = {}    -- 垂直红格子条

    self.BlueHorPool = {}   -- 水平蓝格子条
    self.BlueVerPool = {}   -- 垂直蓝格子条

    self.GridOccupy = {}    -- 记录被占用中的格子，索引：xy坐标，如01,22，x为十位数，y为个位数,值：占用这个格子的收藏品Id
    self.CollectionDic = {} -- 墙面上的收藏品字典，id做索引

    self:InitComponent()
    self:AddListener()

    -- 默认中心位置
    self.DefaultLocalPos = {}
    self.DefaultLocalPos.x = self.PanelWall.rect.width / 2
    self.DefaultLocalPos.y = self.PanelWall.rect.height / 2

    self:Refresh()
end

function XUiCollectionWallEdit:OnEnable()
    if self.IsEditMode then
        -- 处于编辑模式,释放编辑模式开启动画
        self:PlayAnimation("PanelCenterEnable")
    end
end

function XUiCollectionWallEdit:OnDisable()
    if self.CurSelectCollection then
        -- 处于摆放模式,返回到编辑模式
        self:OnBtnCancelClick()
    end
end

---
--- 根据Manager中存放的WallData来生成墙面
function XUiCollectionWallEdit:Refresh()
    self.PedestalId = self.WallData:GetPedestalId()
    self.BackgroundId = self.WallData:GetBackgroundId()
    self:RefreshBackground()
    self:GenerateCollection(self.WallData:GetCollectionSetInfos())
    self:UpdateGridOccupy()

    if self.IsEditMode then
        self:RefreshSelectItemList()
    end
end

function XUiCollectionWallEdit:InitComponent()
    self.RImgFrame.gameObject:SetActiveEx(false)
    self.PanelTag.gameObject:SetActiveEx(false)
    self.PanelConfirmMenu.gameObject:SetActiveEx(false)
    self.PanelSelectItem.gameObject:SetActiveEx(false)
    self.GridDecorationItem.gameObject:SetActiveEx(false)
    self.ImgEmpty.gameObject:SetActiveEx(false)

    self.BlueHorItem.gameObject:SetActiveEx(false)
    self.BlueVerItem.gameObject:SetActiveEx(false)
    self.RedHorItem.gameObject:SetActiveEx(false)
    self.RedVerItem.gameObject:SetActiveEx(false)

    self.BtnEdit.gameObject:SetActiveEx(true)

    self:InitTagGroup()
    self:InitDynamicTable()
end

function XUiCollectionWallEdit:InitTagGroup()
    self.Tag = {
        self.TagBackground,
        self.TagPedestal,
        self.TagLittle,
        self.TagMiddle,
        self.TagBig,
    }
    self.TagGroup:Init(self.Tag, function(tagIndex)
        self:OnClickTagCallBack(tagIndex)
    end)
end

function XUiCollectionWallEdit:OnPanelItemListDrag(eventData)
    if self.PanelItemListScorllRect then
        self.PanelItemListScorllRect:OnDrag(eventData);
    end
end

function XUiCollectionWallEdit:OnPanelItemListBeginDrag(eventData)
    if self.PanelItemListScorllRect then
        self.PanelItemListScorllRect:OnBeginDrag(eventData);
    end
end

function XUiCollectionWallEdit:OnPanelItemListEndDrag(eventData)
    if self.PanelItemListScorllRect then
        self.PanelItemListScorllRect:OnEndDrag(eventData);
    end
end

---
--- 设置摆放模式时，操作菜单的位置
function XUiCollectionWallEdit:SetPanelConfirmMenuPos()
    -- 如果操作菜单显示在界面上，则更新位置
    if  self.PanelConfirmMenu.gameObject.activeSelf or  self.PanelConfirmMenu.gameObject.activeInHierarchy then
        if not self.CurSelectCollection then
            XLog.Error("XUiCollectionWallEdit:SetPanelConfirmMenuPos函数错误,CurSelectCollection为 nil")
        else
            self.PanelConfirmMenu.localPosition = self.CurSelectCollection:GetPos()
        end
    end
end

---
--- 'index'与XCollectionWallConfigs.EnumSelectType一致
function XUiCollectionWallEdit:OnClickTagCallBack(index)
    self.SelectType = index
    self:SetupDynamicTable(index)
    self:PlayAnimation("ViewportQieHuan")
    self.PanelSelectItem.gameObject:SetActiveEx(true)
end

function XUiCollectionWallEdit:RefreshSelectItemList()
    if self.IsEditMode then
        self:SetupDynamicTable(self.SelectType)
    end
end

function XUiCollectionWallEdit:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList)
    self.DynamicTable:SetProxy(XUiGridSelectItem, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiCollectionWallEdit:SetupDynamicTable(type)
    local curWallData = self:GenerateCurWallData()
    self.PageDatas = XDataCenter.CollectionWallManager.GetItemList(curWallData, type)
    self.DynamicTable:SetDataSource(self.PageDatas)
    self.DynamicTable:ReloadDataASync()
    self.ImgEmpty.gameObject:SetActiveEx(#self.PageDatas <= 0)
end

function XUiCollectionWallEdit:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self.PageDatas[index], self.SelectType)
    end
end

---
--- 根据'collectionId'收藏品Id在'localPos'上创建收藏品
--- 'localPos'为空，则使用中心位置
---@param collectionId number
---@param isNew boolean
---@param localPos table
---@param sizeId number
---@return table
function XUiCollectionWallEdit:CreatePlacedCollection(collectionId, isNew, localPos, sizeId)
    if not collectionId then
        XLog.Error("XUiCollectionWallEdit.CreatePlacedCollection函数错误，参数collectionId为 nil")
        return
    end

    local baseItemPath = XCollectionWallConfigs.GetColDecPath(self.PedestalId)
    local baseItem = self.WallContent:LoadPrefab(baseItemPath)
    if baseItem == nil or not baseItem:Exist() then
        return
    end
    baseItem.gameObject:SetActiveEx(false)

    local obj = CS.UnityEngine.Object.Instantiate(baseItem)
    local scale = XCollectionWallConfigs.GetCollectionScale(sizeId)

    obj.transform:SetParent(self.WallContent, false)
    obj.transform.localScale = CS.UnityEngine.Vector3(scale, scale, scale)
    obj.gameObject:SetActiveEx(true)

    local data = {}
    data.Id = collectionId
    data.LocalPos = localPos or self.DefaultLocalPos
    data.SizeId = sizeId
    data.IsNew = isNew

    local placedCollection = XUiGridPlacedCollection.New(obj, self, self.WallContent, data)
    self.CollectionDic[collectionId] = placedCollection

    return placedCollection
end

---
--- 收纳收藏品时，清理对应的脚本引用
function XUiCollectionWallEdit:StorageCollection(collectionId)
    CS.UnityEngine.GameObject.Destroy(self.CollectionDic[collectionId].GameObject)
    self.CollectionDic[collectionId] = nil
end

---
--- 根据CollectionDic中存放的收藏品脚本来生成当前收藏品墙的数据
function XUiCollectionWallEdit:GenerateCurWallData()
    local data = {}
    data.Id = self.WallData:GetId()
    data.BackgroundId = self.BackgroundId
    data.PedestalId = self.PedestalId
    data.CollectionSetInfos = {}
    for id, placedCollection in pairs(self.CollectionDic) do
        local temp = {}
        local gridPos = placedCollection:GetGridPos()

        temp.Id = id
        temp.X = gridPos.x
        temp.Y = gridPos.y
        temp.SizeId = placedCollection:GetSizeId()
        table.insert(data.CollectionSetInfos, temp)
    end
    return data
end

---
--- 是否进入摆放模式
--- 进入摆放模式需要参数'placedCollection'（XUiGridPlacedCollection）
--- 如果'placedCollection'为空，则视为退出摆放模式
--- 'isFollowMouse':摆放的物体是否跟随鼠标
--- 'isNew':是新摆放的物体，还是点击旧的物体
---@param placedCollection table
function XUiCollectionWallEdit:EnterPutModel(placedCollection)
    if self:GetIsSaving() then
        return
    end
    
    self.CurSelectCollection = placedCollection
    local isEnter = placedCollection and true or false
    if isEnter then
        self:PlayAnimation("PanelCenterDisable",function()
            self.PanelTag.gameObject:SetActiveEx(not isEnter)
            self.PanelSelectItem.gameObject:SetActiveEx(not isEnter)
        end)
    else
        self:PlayAnimation("PanelCenterEnable")
        self.PanelTag.gameObject:SetActiveEx(not isEnter)
        self.PanelSelectItem.gameObject:SetActiveEx(not isEnter)
    end
    self.PanelTop.gameObject:SetActiveEx(not isEnter)
    self.PanelConfirmMenu.gameObject:SetActiveEx(isEnter)
    self.RImgFrame.gameObject:SetActiveEx(isEnter)

    if placedCollection then
        local count = self.WallContent.childCount
        placedCollection.Transform:SetSiblingIndex(count - 1)

        self.IsPanelSelectItemDraging = false
        placedCollection:SetSelect(true)
        self:SetPanelConfirmMenuPos()
        self:CheckConflict(placedCollection:GetId(), placedCollection:GetOccupyGridsList(), false)
        self:SetAcross()
    end
end

---
--- 设置摆放模式时的蓝色与红色格子条
function XUiCollectionWallEdit:SetAcross()
    if self.CurSelectCollection then
        local gridNum = XCollectionWallConfigs.GetCollectionGridNum(self.CurSelectCollection:GetSizeId())
        self:RecoverAcross(gridNum)

        if self.HasConflict then
            self:GenerateAcross(self.RedHorPool, self.RedHorItem, gridNum)
            self:GenerateAcross(self.RedVerPool, self.RedVerItem, gridNum)
        else
            self:GenerateAcross(self.BlueHorPool, self.BlueHorItem, gridNum)
            self:GenerateAcross(self.BlueVerPool, self.BlueVerItem, gridNum)
        end
        self:UpdateAcrossPos(gridNum)
    end
end

function XUiCollectionWallEdit:GenerateAcross(pool, baseItem, gridNum)
    for i = 1, gridNum do
        local grid = pool[i]
        if not grid then
            grid = CS.UnityEngine.Object.Instantiate(baseItem)
            grid.transform:SetParent(self.PanelAcross, false)
            table.insert(pool, grid)
        end
        grid.gameObject:SetActiveEx(true)
    end
end

function XUiCollectionWallEdit:RecoverAcross(gridNum)
    for i = 1, gridNum do
        -- 蓝条
        if self.RedHorPool[i] then
            self.RedHorPool[i].gameObject:SetActiveEx(false)
        end
        if self.RedVerPool[i] then
            self.RedVerPool[i].gameObject:SetActiveEx(false)
        end

        -- 红条
        if self.BlueHorPool[i] then
            self.BlueHorPool[i].gameObject:SetActiveEx(false)
        end
        if self.BlueVerPool[i] then
            self.BlueVerPool[i].gameObject:SetActiveEx(false)
        end
    end
end

---
--- 设置格子条的位置
function XUiCollectionWallEdit:UpdateAcrossPos(gridNum)
    if not self.CurSelectCollection then
        return
    end

    local gridPos = self.CurSelectCollection:GetGridPos()
    if self.HasConflict then
        for i = 1, gridNum do
            -- 水平
            self.RedHorPool[i].transform.localPosition = CS.UnityEngine.Vector3(
                    self.RedHorPool[i].transform.localPosition.x,
                    (gridPos.y + i - 1) * XCollectionWallConfigs.CellSize,
                    0)
            -- 垂直
            self.RedVerPool[i].transform.localPosition = CS.UnityEngine.Vector3(
                    (gridPos.x + i - 1) * XCollectionWallConfigs.CellSize,
                    self.RedVerPool[i].transform.localPosition.y,
                    0)
        end
    else
        for i = 1, gridNum do
            -- 水平
            self.BlueHorPool[i].transform.localPosition = CS.UnityEngine.Vector3(
                    self.BlueHorPool[i].transform.localPosition.x,
                    (gridPos.y + i - 1) * XCollectionWallConfigs.CellSize,
                    0)
            -- 垂直
            self.BlueVerPool[i].transform.localPosition = CS.UnityEngine.Vector3(
                    (gridPos.x + i - 1) * XCollectionWallConfigs.CellSize,
                    self.BlueVerPool[i].transform.localPosition.y,
                    0)
        end
    end
end

---
--- 更新格子占用情况
function XUiCollectionWallEdit:UpdateGridOccupy()
    self.GridOccupy = {}
    for _, placedCollection in pairs(self.CollectionDic) do
        local occupyGridList = placedCollection:GetOccupyGridsList()
        for _,gridPos in pairs(occupyGridList) do
            local gridId = gridPos.x * 10 + gridPos.y
            self.GridOccupy[gridId] = placedCollection:GetId()
        end
    end
end

---
--- 检查冲突，设置标志位
--- 'isSetAcross'是否需要设置格子条
--- @param collectionId number
--- @param occupyGridList table
--- @param isSetAcross boolean
function XUiCollectionWallEdit:CheckConflict(collectionId, occupyGridList, isSetAcross)
    if self.CurSelectCollection then
        for _, gridPos in pairs(occupyGridList) do
            local gridId = gridPos.x * 10 + gridPos.y
            if self.GridOccupy[gridId] and self.GridOccupy[gridId] ~= collectionId then
                local oriConflict = self.HasConflict
                self.HasConflict = true

                if oriConflict == false and isSetAcross then
                    self:SetAcross()
                end
                return
            else
                local oriConflict = self.HasConflict
                self.HasConflict = false

                if oriConflict == true and isSetAcross then
                    self:SetAcross()
                end
            end
        end
    end
end

---
--- 设置冲突标志
function XUiCollectionWallEdit:SetConflict(isConflict)
    self.HasConflict = isConflict
end

---
--- 是否冲突
function XUiCollectionWallEdit:IsConflict()
    return self.HasConflict
end

---
--- 更改墙面
---@param data table
function XUiCollectionWallEdit:ChangeBackgroundId(backgroundId)
    if self.BackgroundId == backgroundId then
        return
    end
    self.BackgroundId = backgroundId
    self:RefreshBackground()
    self.DynamicTable:ReloadDataASync()
end

function XUiCollectionWallEdit:RefreshBackground()
    self:PlayAnimation("RImgWallBgQieHuan")
    local bgPath = XCollectionWallConfigs.GetColDecPath(self.BackgroundId)
    self.RImgWallBg:SetRawImage(bgPath)
end

---
--- 更改底座
---@param pedestalId table
function XUiCollectionWallEdit:ChangePedestalId(pedestalId)
    if self.PedestalId == pedestalId then
        return
    end
    self.PedestalId = pedestalId

    local data = self:GenerateCurWallData()
    self:ClearAllCollection()
    self:GenerateCollection(data.CollectionSetInfos)
    self.DynamicTable:ReloadDataASync()
end

function XUiCollectionWallEdit:GenerateCollection(collectionSetInfos)
    for _, info in pairs(collectionSetInfos) do
        local gridPos = {}
        gridPos.x = info.X
        gridPos.y = info.Y

        local size = XCollectionWallConfigs.GetCollectionSize(info.SizeId)
        local localPos = XDataCenter.CollectionWallManager.GetLocalPosByGridPos(gridPos, size)

        self:CreatePlacedCollection(info.Id, false, localPos, info.SizeId)
    end
end

function XUiCollectionWallEdit:ClearAllCollection()
    for _, placedCollection in pairs(self.CollectionDic) do
        CS.UnityEngine.GameObject.Destroy(placedCollection.GameObject)
    end
    self.CollectionDic = {}
end

function XUiCollectionWallEdit:QuitEditMode()
    self:PlayAnimation("PanelCenterDisable", function()
        self.RImgFrame.gameObject:SetActiveEx(false)
        self.PanelTag.gameObject:SetActiveEx(false)
        self.PanelConfirmMenu.gameObject:SetActiveEx(false)
        self.BtnEdit.gameObject:SetActiveEx(true)
        self.PanelSelectItem.gameObject:SetActiveEx(false)
    end)
    self.IsEditMode = false
    self.CurSelectCollection = nil
end

function XUiCollectionWallEdit:AddListener()
    self.BtnBack.CallBack = function()
        self:Close()
    end
    self:BindHelpBtn(self.BtnExplain, "CollectionWall")

    self.BtnEdit.CallBack = function()
        self:OnBtnEditClick()
    end
    self.BtnUndo.CallBack = function()
        self:OnBtnUndoClick()
    end
    self.BtnSave.CallBack = function()
        self:OnBtnSaveClick()
    end

    self.BtnOk.CallBack = function()
        self:OnBtnOkClick()
    end
    self.BtnCancel.CallBack = function()
        self:OnBtnCancelClick()
    end
    self.BtnStorage.CallBack = function()
        self:OnBtnStorageClick()
    end
end

function XUiCollectionWallEdit:OnBtnUndoClick()
    XUiManager.DialogTip(CS.XTextManager.GetText("TipTitle"), CS.XTextManager.GetText("CollectionWallUndo"),
            XUiManager.DialogType.Normal, nil, function()
                self:ClearAllCollection()
                self:Refresh()
            end)
end

function XUiCollectionWallEdit:OnBtnSaveClick()
    --摆放模式中选择了收藏品不保存
    if self.CurSelectCollection then
        return
    end

    self.IsSaving = true
    local errorCb = function()
        self.IsSaving = false
    end
    
    -- 构造发送请求需要的数据
    local wallId = self.WallData:GetId()
    local setInfo = self:GenerateCurWallData()
    local pedestalId = setInfo.PedestalId
    local backgroundId = setInfo.BackgroundId

    XDataCenter.CollectionWallManager.RequestEditCollectionWall(wallId, pedestalId, backgroundId, setInfo.CollectionSetInfos, function()
        -- 截图保存
        self.PanelTop.gameObject:SetActiveEx(false)
        self.ImgWire.gameObject:SetActiveEx(false)

        self.BtnEdit.gameObject:SetActiveEx(false)
        self.PanelSelectItem.gameObject:SetActiveEx(false)
        self.PanelTag.gameObject:SetActiveEx(false)
        local imgName = XDataCenter.CollectionWallManager.GetCaptureImgName(wallId)

        XDataCenter.CollectionWallManager.CaptureCamera(imgName, function()
            -- 截图完成后重新设置Ui
            self.PanelTop.gameObject:SetActiveEx(true)
            self.ImgWire.gameObject:SetActiveEx(true)

            self.BtnEdit.gameObject:SetActiveEx(not self.IsEditMode)
            self.PanelSelectItem.gameObject:SetActiveEx(self.IsEditMode)
            self.PanelTag.gameObject:SetActiveEx(self.IsEditMode)
            self.IsSaving = false
            XUiManager.TipSuccess(CS.XTextManager.GetText("SetAppearanceSuccess"))
        end)
    end, errorCb)
end

function XUiCollectionWallEdit:OnBtnOkClick()
    if self.HasConflict then
        XUiManager.TipError(CS.XTextManager.GetText("CollectionWallPlaceNotCorrect"))
        return
    else
        local gridNum = XCollectionWallConfigs.GetCollectionGridNum(self.CurSelectCollection:GetSizeId())
        self:RecoverAcross(gridNum)
        self.CurSelectCollection:Confirm()
        self:EnterPutModel(nil)
    end
end

function XUiCollectionWallEdit:OnBtnCancelClick()
    local gridNum = XCollectionWallConfigs.GetCollectionGridNum(self.CurSelectCollection:GetSizeId())
    self:RecoverAcross(gridNum)
    self.CurSelectCollection:Cancel()
    self:EnterPutModel(nil)
end

function XUiCollectionWallEdit:OnBtnStorageClick()
    local gridNum = XCollectionWallConfigs.GetCollectionGridNum(self.CurSelectCollection:GetSizeId())
    self:RecoverAcross(gridNum)
    self.CurSelectCollection:Storage()
    self:EnterPutModel(nil)
end

function XUiCollectionWallEdit:OnBtnEditClick()
    self.BtnEdit.gameObject:SetActiveEx(false)
    self.PanelTag.gameObject:SetActiveEx(true)
    self.DynamicTable:Clear()
    self.TagGroup:SelectIndex(1)
    self:PlayAnimation("PanelCenterEnable")
    self.IsEditMode = true
end

function XUiCollectionWallEdit:Close()
    if self.IsEditMode then
        local curWallData = self:GenerateCurWallData()
        if XDataCenter.CollectionWallManager.IsNeedSave(self.WallData:GetId(), curWallData) then
            XUiManager.DialogTip(CS.XTextManager.GetText("FurnitureTips"), CS.XTextManager.GetText("FurnitureIsSave"),
                    XUiManager.DialogType.Normal, function()
                        self:ClearAllCollection()
                        self:Refresh()
                        self:QuitEditMode()
                    end, function()
                        self:QuitEditMode()
                        self:OnBtnSaveClick()
                    end)
        else
            self:QuitEditMode()
        end
    else
        self.Super.Close(self)
    end
end

function XUiCollectionWallEdit:GetIsSaving()
    return self.IsSaving
end 
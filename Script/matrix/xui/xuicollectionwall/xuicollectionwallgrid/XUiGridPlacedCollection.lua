local XUiGridPlacedCollection = XClass(nil, "XUiGridPlacedCollection")

local XUiCollectionStyle = require("XUi/XUiMedal/XUiCollectionStyle")
local Vector3 = CS.UnityEngine.Vector3


---
--- 'collectionData'的结构为{ Id, LocalPos, PedestalId }
function XUiGridPlacedCollection:Ctor(ui, rootUi, parentUi, collectionData)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.ParentRectTransform = parentUi

    self.IsNew = collectionData.IsNew
    self.Id = collectionData.Id
    self.SizeId = collectionData.SizeId         -- 尺寸Id
    self.CollectionStyleDic = {}                -- Key:收藏品Id  Value:XUiCollectionStyle脚本

    -- 可移动的范围边界
    self.Size = XCollectionWallConfigs.GetCollectionSize(collectionData.SizeId)
    self.OriGridPos = XDataCenter.CollectionWallManager.GetGridPosByLocalPos(collectionData.LocalPos, self.Size)

    self.MinXY = self.Size / 2
    self.MaxX = self.ParentRectTransform.rect.width - (self.Size / 2)
    self.MaxY = self.ParentRectTransform.rect.height - (self.Size / 2)

    self.Camera = CS.XUiManager.Instance.UiCamera
    XTool.InitUiObject(self)

    -- 监听点击
    self.GoInputHandler = self.Transform:GetComponent(typeof(CS.XGoInputHandler))
    if XTool.UObjIsNil(self.GoInputHandler) then
        self.GoInputHandler = self.GameObject:AddComponent(typeof(CS.XGoInputHandler))
    end
    if not XTool.UObjIsNil(self.GoInputHandler) then
        self.GoInputHandler:AddPointerClickListener(function(eventData)
            self:OnClick(eventData)
        end)
        self.GoInputHandler:AddDragListener(function(eventData)
            self:OnDrag(eventData)
        end)
    end
    self:InitComponent()
    self:SetPos(self.OriGridPos, true)
end

function XUiGridPlacedCollection:InitComponent()
    self.TxtName.text = XMedalConfigs.GetCollectionNameById(self.Id)

    local prefabPath = XMedalConfigs.GetCollectionPrefabPath(self.Id)
    local styleObj = self.CollectionStyleNode.gameObject:LoadPrefab(prefabPath)
    local collectionData = XDataCenter.MedalManager.GetScoreTitleById(self.Id)
    self.CollectionStyleDic[self.Id] = XUiCollectionStyle.New(styleObj, collectionData)

    self:SetSelect(false)
end

function XUiGridPlacedCollection:SetSelect(isSelect)
    self.IsSelected = isSelect
    self.RImBlack.gameObject:SetActiveEx(isSelect)
end

---
--- 取消
function XUiGridPlacedCollection:Cancel()
    if self.IsNew then
        -- 删除物体和字典中的脚本引用
        self.RootUi:StorageCollection(self.Id)
        self.RootUi:SetConflict(false)
    else
        -- 恢复位置
        self:SetPos(self.OriGridPos, false)
    end
    self:SetSelect(false)
    self.RootUi:UpdateGridOccupy()
end

---
--- 确认
function XUiGridPlacedCollection:Confirm()
    if self.IsNew then
        -- 刷新选择列表
        self.RootUi:RefreshSelectItemList()
        self.IsNew = false
    end
    self:SetSelect(false)
    self.OriGridPos = self.GridPos
    self.RootUi:UpdateGridOccupy()
end

---
--- 收纳
function XUiGridPlacedCollection:Storage()
    -- 删除物体和字典中的脚本引用
    self.RootUi:StorageCollection(self.Id)
    -- 更新格子占用情况
    self.RootUi:UpdateGridOccupy()
    -- 设置冲突
    self.RootUi:SetConflict(false)
    if not self.IsNew then
        -- 刷新选择列表
        self.RootUi:RefreshSelectItemList()
    end
end

---
--- 调整位置，把Screen坐标换算成Canvas坐标
--- 然后再转成对应的格子行列坐标
function XUiGridPlacedCollection:AdjustPosition(screenPos)
    -- 设置拖拽
    local hasValue, pos = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(self.ParentRectTransform, screenPos, self.Camera)
    if hasValue then
        local localPos = {}
        localPos.x = pos.x
        localPos.y = pos.y

        if localPos.x < self.MinXY then
            localPos.x = self.MinXY
        elseif localPos.x > self.MaxX then
            localPos.x = self.MaxX
        end

        if localPos.y < self.MinXY then
            localPos.y = self.MinXY
        elseif localPos.y > self.MaxY then
            localPos.y = self.MaxY
        end
        local gridPos = XDataCenter.CollectionWallManager.GetGridPosByLocalPos(localPos, self.Size)
        self:SetPos(gridPos, true)
    end
end

---
--- 设置本地
function XUiGridPlacedCollection:SetPos(gridPos, isSetAcross)
    if XTool.UObjIsNil(self.Transform) then
        return
    end
    self.GridPos = {}
    self.GridPos.x = gridPos.x
    self.GridPos.y = gridPos.y

    local posVector2 = XDataCenter.CollectionWallManager.GetLocalPosByGridPos(gridPos, self.Size)

    self.Transform.localPosition = Vector3(posVector2.x, posVector2.y, 0)
    self.RootUi:SetPanelConfirmMenuPos()
    self.RootUi:CheckConflict(self.Id, self:GetOccupyGridsList(), isSetAcross)
    self.RootUi:UpdateAcrossPos(XCollectionWallConfigs.GetCollectionGridNum(self.SizeId))
end

---
--- 获取本地坐标
function XUiGridPlacedCollection:GetPos()
    if XTool.UObjIsNil(self.Transform) then
        return
    end
    return self.Transform.localPosition
end

---
--- 设获取格子坐标
function XUiGridPlacedCollection:GetGridPos()
    return self.GridPos
end

function XUiGridPlacedCollection:GetOccupyGridsList()
    local result = {}
    local gridNum = XCollectionWallConfigs.GetCollectionGridNum(self.SizeId)
    for i = 1,gridNum do
        for j =1,gridNum do
            local temp = {}
            temp.x = self.GridPos.x + (i - 1)
            temp.y = self.GridPos.y + (j - 1)
            table.insert(result,temp)
        end
    end

    return result
end

---
--- 获取尺寸Id
function XUiGridPlacedCollection:GetSizeId()
    return self.SizeId
end

function XUiGridPlacedCollection:GetId()
    return self.Id
end

---
--- 点击
function XUiGridPlacedCollection:OnClick()
    if self.RootUi.IsEditMode then
        if self.RootUi.CurSelectCollection then
            return
        end

        -- 进入摆放模式
        self.RootUi:EnterPutModel(self)
    end
end

---
--- 拖动
function XUiGridPlacedCollection:OnDrag(eventData)
    if not self.IsSelected then
        return
    end

    local pos = eventData.position
    return self:AdjustPosition(pos)
end

function XUiGridPlacedCollection:Destroy()
    self.GoInputHandler:RemoveAllListeners()
end

return XUiGridPlacedCollection
local XUiGridSelectItem = XClass(nil, "XUiGridSelectItem")

local XUiCollectionStyle = require("XUi/XUiMedal/XUiCollectionStyle")

function XUiGridSelectItem:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.PointerDownPosition = nil
    self.CollectionStyleDic = {}    -- Key:收藏品Id  Value:XUiCollectionStyle脚本

    XTool.InitUiObject(self)
    self.PanelTip.gameObject:SetActiveEx(false)

    self.BtnItemWidget:AddPointerDownListener(function(data) self:OnBtnItemPointerDown(data) end)
    self.BtnItemWidget:AddDragListener(function(data) self:OnBtnItemOnDrag(data) end)
    self.BtnItemWidget:AddPointerClickListener(function(data) self:OnBtnItemClick(data) end)

    self.BtnItemWidget:AddBeginDragListener(function(data) self:OnBtnItemOnBeginDrag(data) end)
    self.BtnItemWidget:AddEndDragListener(function(data) self:OnBtnItemOnEndDrag(data) end)
end

---
--- 'data'的结构根据种类有不同的结构（XCollectionWallManager.GetItemList函数构建）
---  装饰品：{ Id, IsUnlock }
---  收藏品：Id
---
--- 'selectType'选择的种类，类型为XCollectionWallConfigs.EnumSelectType
---@param data table
---@param selectType number
function XUiGridSelectItem:UpdateGrid(data, selectType)
    self.Data = data
    self.SelectType = selectType

    -- 根据选择种类分成收藏品(大中小)和装饰品(底座、墙面)
    if selectType == XCollectionWallConfigs.EnumSelectType.BACKGROUND
            or selectType == XCollectionWallConfigs.EnumSelectType.PEDESTAL then
        self.IsDecoration = true
    elseif selectType == XCollectionWallConfigs.EnumSelectType.LITTL
            or selectType == XCollectionWallConfigs.EnumSelectType.MIDDLE
            or selectType == XCollectionWallConfigs.EnumSelectType.BIG then
        self.IsDecoration = false
    else
        XLog.Error("XUiGridSelectItem:UpdateGrid函数错误，selectType不是XCollectionWallConfigs.EnumSelectType类型的值")
        return
    end

    if self.IsDecoration then
        if data.Id == XEnumConst.SpecialHandling.DEADCollectiblesId then
            self.TxtName.text = XUiHelper.ReplaceUnicodeSpace(XCollectionWallConfigs.GetColDecName(data.Id))
            self.TxtName.resizeTextForBestFit = true
        else
            self.TxtName.text = XCollectionWallConfigs.GetColDecName(data.Id)
        end
        self.ImgDecorationIcon:SetRawImage(XCollectionWallConfigs.GetColDecIcon(data.Id))

        self.CollectionStyleNode.gameObject:SetActiveEx(false)
        self.ImgDecorationIcon.gameObject:SetActiveEx(true)
        self.PanelTip.gameObject:SetActiveEx(not data.IsUnlock)
        self.ImgIconController.enabled = not data.IsUnlock

        if selectType == XCollectionWallConfigs.EnumSelectType.BACKGROUND then
            self.PanelChoice.gameObject:SetActiveEx(data.Id  == self.RootUi.BackgroundId)
        else
            self.PanelChoice.gameObject:SetActiveEx(data.Id  == self.RootUi.PedestalId)
        end
    else
        if data == XEnumConst.SpecialHandling.DEADCollectiblesId then
            self.TxtName.text = XUiHelper.ReplaceUnicodeSpace(XMedalConfigs.GetCollectionNameById(data))
            self.TxtName.resizeTextForBestFit = true
        else
            self.TxtName.text = XMedalConfigs.GetCollectionNameById(data)
        end

        local prefabPath = XMedalConfigs.GetCollectionPrefabPath(data)
        local styleObj = self.CollectionStyleNode.gameObject:LoadPrefab(prefabPath)
        local collectionData = XDataCenter.MedalManager.GetScoreTitleById(data)
        self.CollectionStyleDic[data] = XUiCollectionStyle.New(styleObj, collectionData)

        self.CollectionStyleNode.gameObject:SetActiveEx(true)
        self.ImgDecorationIcon.gameObject:SetActiveEx(false)
        self.PanelTip.gameObject:SetActiveEx(false)
        self.ImgIconController.enabled = false
        self.PanelChoice.gameObject:SetActiveEx(false)
    end
end

---
--- 按下事件
function XUiGridSelectItem:OnBtnItemPointerDown(data)
    self.PointerDownPosition = data.position.y
end

---
--- 点击
function XUiGridSelectItem:OnBtnItemClick(data)
    if self.RootUi.IsPanelSelectItemDraging then
        return
    end

    if not data then
        return
    end

    if self.SelectType == nil then
        XLog.Error("XUiGridSelectItem:OnBtnItemClick函数错误，self.SelectType为 nil")
        return
    end

    if self.IsDecoration then
        -- 装饰品
        if self.Data.IsUnlock then
            -- 已解锁
            if self.SelectType == XCollectionWallConfigs.EnumSelectType.BACKGROUND then
                self.RootUi:ChangeBackgroundId(self.Data.Id)
            elseif self.SelectType == XCollectionWallConfigs.EnumSelectType.PEDESTAL then
                self.RootUi:ChangePedestalId(self.Data.Id)
            else
                XLog.Error("XUiGridSelectItem:OnBtnItemClick函数错误，SelectType的值不是装饰品")
                return
            end
        else
            -- 未解锁
            local unlockType = XCollectionWallConfigs.GetColDecUnlockType(self.Data.Id)
            local txtTip
            if unlockType == XCollectionWallConfigs.EnumDecorationUnlockType.Condition then
                local conditionId = XCollectionWallConfigs.GetColDecCondition(self.Data.Id)
                txtTip = XConditionManager.GetConditionDescById(conditionId)
            else
                txtTip = XCollectionWallConfigs.GetColDecLockDesc(self.Data.Id)
            end
            XUiManager.TipError(txtTip)
        end
    else
        -- 收藏品
        if self.RootUi.CurSelectCollection or self.RootUi:GetIsSaving() then
            -- 已经处于摆放模式(防止多次点击)
            -- 保存中不进入摆放模式
            return
        end

        -- 进入摆放模式
        local sizeId = XDataCenter.MedalManager.GetQuality(self.Data)
        local placedCollection = self.RootUi:CreatePlacedCollection(self.Data, true, nil, sizeId)
        self.RootUi:EnterPutModel(placedCollection)
    end
end

---
--- 拖拽
function XUiGridSelectItem:OnBtnItemOnDrag(data)
    if not self.PointerDownPosition then
        return
    end
    self.RootUi:OnPanelItemListDrag(data)
end

function XUiGridSelectItem:OnBtnItemOnBeginDrag(data)
    self.RootUi.IsPanelSelectItemDraging = true
    self.RootUi:OnPanelItemListBeginDrag(data)
end

function XUiGridSelectItem:OnBtnItemOnEndDrag(data)
    self.RootUi.IsPanelSelectItemDraging = false
    self.RootUi:OnPanelItemListEndDrag(data)
end

function XUiGridSelectItem:Destroy()
    self.BtnItemWidget:RemoveAllListeners()
end

return XUiGridSelectItem
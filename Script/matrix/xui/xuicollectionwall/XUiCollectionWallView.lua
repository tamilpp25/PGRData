local XUiCollectionWallView = XLuaUiManager.Register(XLuaUi, "UiCollectionWallView")
local XUiGridViewCollection = require("XUi/XUiCollectionWall/XUiCollectionWallGrid/XUiGridViewCollection")

local DEFAULT_INDEX = 1

function XUiCollectionWallView:OnStart(wallDataList, inType, otherPlayerCollectionList)
    if wallDataList == nil or next(wallDataList) == nil then
        XLog.Error("XUiCollectionWallView:OnStart函数错误，wallDataList参数没有数据")
        return
    end

    self.InType = inType
    self.WallDataList = wallDataList
    self.OtherPlayerCollectionList = otherPlayerCollectionList

    XDataCenter.CollectionWallManager.SortWallEntityByRank(self.WallDataList)

    self.CollectionPool = {}    -- 收藏品GameObject
    self.CurrentCollection = {} -- 当前墙面的收藏品格子脚本

    self.Min = 1
    self.Max = #wallDataList
    self.Index = DEFAULT_INDEX

    self.BaseItem = {}  -- 底座Id做索引，保存对应的ui物体模板
    self.ItemResource = {} --缓存resource

    self:AddListener()
end

function XUiCollectionWallView:OnEnable()
    self:Refresh()
end

function XUiCollectionWallView:OnDestroy()
    for _, res in pairs(self.ItemResource) do
        CS.XResourceManager.Unload(res)
    end
    self.ItemResource = {}
    self.Resource = nil
end

function XUiCollectionWallView:Refresh()
    self:RecoverCollection()

    self.BtnLeft.gameObject:SetActiveEx(self.Index ~= self.Min)
    self.BtnRight.gameObject:SetActiveEx(self.Index ~= self.Max)

    local wallData = self.WallDataList[self.Index]
    if wallData then
        local pedestalId = wallData:GetPedestalId()

        for i, collectionInfo in pairs(wallData:GetCollectionSetInfos()) do
            self.CollectionPool[pedestalId] = self.CollectionPool[pedestalId] or {}

            local grid = self.CollectionPool[pedestalId][i]
            if not grid then
                grid = self:GenerateCollection(collectionInfo,pedestalId)
                table.insert(self.CollectionPool[pedestalId], grid)
            else
                local scale = XCollectionWallConfigs.GetCollectionScale(collectionInfo.SizeId)
                grid.transform.localScale = CS.UnityEngine.Vector3(scale, scale, scale)
            end

            grid.gameObject:SetActiveEx(true)
            if self.InType == XDataCenter.MedalManager.InType.Normal then
                self.CurrentCollection[collectionInfo.Id] = XUiGridViewCollection.New(grid, collectionInfo, self.InType)
            else
                if not self.OtherPlayerCollectionList then
                    XLog.Error("XUiCollectionWallView:Refresh函数错误，查看他人信息时，没有OtherPlayerCollectionList数据")
                    return
                end

                -- 找到对应收藏品的数据
                local hasCollection = false

                for _, otherCollection in pairs(self.OtherPlayerCollectionList) do
                    if otherCollection.Id == collectionInfo.Id then
                        hasCollection = true
                        self.CurrentCollection[collectionInfo.Id] = XUiGridViewCollection.New(grid, collectionInfo, self.InType, otherCollection)
                    end
                end

                if not hasCollection then
                    XLog.Error(string.format("XUiCollectionWallView:Refresh函数错误，未其他玩家信息中没有Id:%s的收藏品数据", collectionInfo.Id))
                    grid.gameObject:SetActiveEx(false)
                end
            end
        end

        local bgPath = XCollectionWallConfigs.GetColDecPath(wallData:GetBackgroundId())
        self.RImgWallBg:SetRawImage(bgPath)
    else
        XLog.Error("XUiCollectionWallView:Refresh函数错误，wallData为 nil")
    end
end

function XUiCollectionWallView:GenerateCollection(collectionInfo, pedestalId)
    if not collectionInfo then
        XLog.Error("XUiCollectionWallView:GenerateCollection函数错误，参数collectionInfo为 nil")
        return
    end

    if not self.BaseItem[pedestalId] then
        local baseItemPath = XCollectionWallConfigs.GetColDecPath(pedestalId)

        self.Resource = CS.XResourceManager.Load(baseItemPath)
        self.ItemResource[baseItemPath] = self.Resource

        local baseItem = CS.UnityEngine.Object.Instantiate(self.Resource.Asset)
        if baseItem == nil or not baseItem:Exist() then
            return
        end
        baseItem.transform:SetParent(self.PanelWall, false)
        baseItem.gameObject:SetLayerRecursively(self.PanelWall.gameObject.layer)
        baseItem.gameObject:SetActiveEx(false)

        self.BaseItem[pedestalId] = baseItem
    end

    local obj = CS.UnityEngine.Object.Instantiate(self.BaseItem[pedestalId])
    local scale = XCollectionWallConfigs.GetCollectionScale(collectionInfo.SizeId)

    obj.transform:SetParent(self.PanelWall, false)
    obj.transform.localScale = CS.UnityEngine.Vector3(scale, scale, scale)
    obj.gameObject:SetActiveEx(true)

    return obj
end

function XUiCollectionWallView:RecoverCollection()
    for _, collection in pairs(self.CurrentCollection) do
        collection.GameObject:SetActiveEx(false)
        collection:Destroy()
    end
    self.CurrentCollection = {}
end

function XUiCollectionWallView:AddListener()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnRight.CallBack = function()
        self:OnBtnRightClick()
    end
    self.BtnLeft.CallBack = function()
        self:OnBtnLeftClick()
    end
end

function XUiCollectionWallView:OnBtnRightClick()
    self.Index = self.Index + 1
    if self.Index > self.Max then
        XLog.Error("XUiCollectionWallView:OnRightClick函数错误，Index大于最大值")
        self.Index = self.Max
    end
    self:PlayAnimation("QieHuan")
    self:Refresh()
end

function XUiCollectionWallView:OnBtnLeftClick()
    self.Index = self.Index - 1
    if self.Index < self.Min then
        XLog.Error("XUiCollectionWallView:OnBtnLeftClick，Index小于最小值")
        self.Index = self.Min
    end
    self:PlayAnimation("QieHuan")
    self:Refresh()
end

function XUiCollectionWallView:OnBtnBackClick()
    self:Close()
end
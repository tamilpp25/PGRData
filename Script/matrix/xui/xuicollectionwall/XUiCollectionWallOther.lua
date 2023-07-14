local XUiCollectionWallOther = XClass(nil, "XUiCollectionWallOther")
local XUiGridPlacedCollectionOther = require("XUi/XUiCollectionWall/XUiCollectionWallGrid/XUiGridPlacedCollectionOther")

function XUiCollectionWallOther:Ctor(ui, pedestalId, backgroundId, collectionInfo, scoreTitleDic)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.PedestalId = pedestalId
    self.BackgroundId = backgroundId
    self.CollectionInfo = collectionInfo
    self.ScoreTitleDic = scoreTitleDic
    self.CollectionDic = {}

    self:Refresh()
end

function XUiCollectionWallOther:Refresh()
    self:RefreshBackground()
    self:GenerateCollection(self.CollectionInfo)
end

function XUiCollectionWallOther:RefreshBackground()
    local bgPath = XCollectionWallConfigs.GetColDecPath(self.BackgroundId)
    self.RImgWallBg:SetRawImage(bgPath)
end

function XUiCollectionWallOther:GenerateCollection(collectionSetInfos)
    for _, info in pairs(collectionSetInfos) do
        local gridPos = {}
        gridPos.x = info.X
        gridPos.y = info.Y

        local size = XCollectionWallConfigs.GetCollectionSize(info.SizeId)
        local localPos = XDataCenter.CollectionWallManager.GetLocalPosByGridPos(gridPos, size)

        self:CreatePlacedCollection(info.Id, false, localPos, info.SizeId)
    end
end

function XUiCollectionWallOther:CreatePlacedCollection(collectionId, isNew, localPos, sizeId)
    if not collectionId then
        XLog.Error("XUiCollectionWallEdit.CreatePlacedCollection函数错误，参数collectionId为 nil")
        return
    end

    local scoreTitle = self.ScoreTitleDic[collectionId]
    if not scoreTitle then
        XLog.Error(string.format("XUiCollectionWallEdit.CreatePlacedCollection函数错误，没有收藏品Id：%s的数据信息", collectionId))
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

    local placedCollection = XUiGridPlacedCollectionOther.New(obj, self, self.WallContent, data, scoreTitle)
    self.CollectionDic[collectionId] = placedCollection

    return placedCollection
end

return XUiCollectionWallOther
local XUiGridPlacedCollectionOther = XClass(nil, "XUiGridPlacedCollectionOther")

local XUiCollectionStyle = require("XUi/XUiMedal/XUiCollectionStyle")
local Vector3 = CS.UnityEngine.Vector3

---
--- 'collectionData'的结构为{ Id, LocalPos, PedestalId }
--- 'scoreTitle'为其他玩家的收藏品数据，如分数、等级
function XUiGridPlacedCollectionOther:Ctor(ui, rootUi, parentUi, collectionData, scoreTitle)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.ParentRectTransform = parentUi
    self.ScoreTitle = scoreTitle

    self.IsNew = collectionData.IsNew
    self.Id = collectionData.Id
    self.SizeId = collectionData.SizeId         -- 尺寸Id

    self.CollectionStyleDic = {}    -- Key:收藏品Id  Value:XUiCollectionStyle脚本

    self.Size = XCollectionWallConfigs.GetCollectionSize(collectionData.SizeId)
    self.OriGridPos = XDataCenter.CollectionWallManager.GetGridPosByLocalPos(collectionData.LocalPos, self.Size)

    XTool.InitUiObject(self)

    self:InitComponent()
    self:SetPos(self.OriGridPos, true)
end

function XUiGridPlacedCollectionOther:InitComponent()
    self.TxtName.text = self.ScoreTitle.Name

    local styleObj = self.CollectionStyleNode.gameObject:LoadPrefab(self.ScoreTitle.PrefabPath)
    self.CollectionStyleDic[self.Id] = XUiCollectionStyle.New(styleObj, self.ScoreTitle)

    self:SetSelect(false)
end

function XUiGridPlacedCollectionOther:SetSelect(isSelect)
    self.IsSelected = isSelect
    self.RImBlack.gameObject:SetActiveEx(isSelect)
end

---
--- 设置本地
function XUiGridPlacedCollectionOther:SetPos(gridPos)
    if XTool.UObjIsNil(self.Transform) then
        return
    end
    self.GridPos = {}
    self.GridPos.x = gridPos.x
    self.GridPos.y = gridPos.y

    local posVector2 = XDataCenter.CollectionWallManager.GetLocalPosByGridPos(gridPos, self.Size)

    self.Transform.localPosition = Vector3(posVector2.x, posVector2.y, 0)
end

---
--- 获取本地坐标
function XUiGridPlacedCollectionOther:GetPos()
    if XTool.UObjIsNil(self.Transform) then
        return
    end
    return self.Transform.localPosition
end

---
--- 设获取格子坐标
function XUiGridPlacedCollectionOther:GetGridPos()
    return self.GridPos
end

---
--- 获取尺寸Id
function XUiGridPlacedCollectionOther:GetSizeId()
    return self.SizeId
end

function XUiGridPlacedCollectionOther:GetId()
    return self.Id
end

return XUiGridPlacedCollectionOther
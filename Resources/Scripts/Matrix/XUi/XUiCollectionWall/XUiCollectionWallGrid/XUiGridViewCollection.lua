local XUiGridViewCollection = XClass(nil, "XUiGridViewCollection")

local XUiCollectionStyle = require("XUi/XUiMedal/XUiCollectionStyle")
local Vector3 = CS.UnityEngine.Vector3

function XUiGridViewCollection:Ctor(ui, collectionData, inType, otherPlayerCollection)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.OtherPlayerCollection = otherPlayerCollection
    self.Id = collectionData.Id
    self.InType = inType
    self.CollectionStyleDic = {}    -- Key:收藏品Id  Value:XUiCollectionStyle脚本

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
    end

    self:InitComponent()
    self:Refresh(collectionData)
end

function XUiGridViewCollection:InitComponent()
    local data
    if self.InType == XDataCenter.MedalManager.InType.OtherPlayer then
        data = self.OtherPlayerCollection
    elseif self.InType == XDataCenter.MedalManager.InType.Normal then
        -- 查看自己
        data = XDataCenter.MedalManager.GetScoreTitleById(self.Id)
    end
    local styleObj = self.CollectionStyleNode.gameObject:LoadPrefab(data.PrefabPath)
    self.CollectionStyleDic[data] = XUiCollectionStyle.New(styleObj, data)
    self.RImBlack.gameObject:SetActiveEx(false)
end

function XUiGridViewCollection:Refresh(collectionData)
    local gridSize = XCollectionWallConfigs.GetCollectionSize(collectionData.SizeId)
    local gridPos = {}
    gridPos.x  = collectionData.X
    gridPos.y  = collectionData.Y

    self:SetPos(gridPos, gridSize)
    self.TxtName.text = XMedalConfigs.GetCollectionNameById(collectionData.Id)
end

function XUiGridViewCollection:SetPos(gridPos, gridSize)
    if XTool.UObjIsNil(self.Transform) then
        return
    end

    local posVector2 = XDataCenter.CollectionWallManager.GetLocalPosByGridPos(gridPos, gridSize)
    self.Transform.localPosition = Vector3(posVector2.x, posVector2.y, 0)
end

---
--- 点击
function XUiGridViewCollection:OnClick()
    local data
    if self.InType == XDataCenter.MedalManager.InType.OtherPlayer then
        data = self.OtherPlayerCollection
    elseif self.InType == XDataCenter.MedalManager.InType.Normal then
        -- 查看自己
        data = XDataCenter.MedalManager.GetScoreTitleById(self.Id)
    end

    if not data then
        XLog.Error("XUiGridViewCollection:OnClick函数错误，找不到对应的收藏品数据")
        return
    end

    XLuaUiManager.Open("UiCollectionTip", data, XDataCenter.MedalManager.InType.Normal)
end

function XUiGridViewCollection:Destroy()
    self.GoInputHandler:RemoveAllListeners()
end

return XUiGridViewCollection
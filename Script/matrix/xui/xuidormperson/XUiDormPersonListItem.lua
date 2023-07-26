local Object = CS.UnityEngine.Object
local V3O = CS.UnityEngine.Vector3.one
local XUiDormPersonSingleItem = require("XUi/XUiDormPerson/XUiDormPersonSingleItem")
local XUiDormPersonListItem = XClass(nil, "XUiDormPersonListItem")
local DormPersonMaxCount = 3

function XUiDormPersonListItem:Ctor(ui)
    self.PoolObjs = {}
    self.CurObjs = {}
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.PersonSingleItem.gameObject:SetActiveEx(false)
end

-- 更新数据
function XUiDormPersonListItem:OnRefresh(itemData, curDormId)
    if not itemData then
        return
    end

    self.ItemData = itemData
    self.PanelName.gameObject:SetActive(true)
    self.TxtName.text = itemData.DormitoryName
    self.PanelNameAtPresent.gameObject:SetActive(curDormId == itemData.DormitoryId)

    self.CharacterIds = XTool.Clone(itemData.CharacterIdList or {})

    local len = #self.CharacterIds
    for _ = 1, DormPersonMaxCount - len do
        table.insert(self.CharacterIds, -1)
    end

    local index = 0
    for k, v in ipairs(self.CharacterIds) do
        if not self.CurObjs[k] then
            local item = self:GetItem(index)
            self.CurObjs[k] = item
        end
        index = index + 1
        self.CurObjs[k]:SetState(true)
        self.CurObjs[k]:OnRefresh(v, itemData.DormitoryId)
    end

    if self.PreLen and self.PreLen > index then
        for _ = index + 1, self.PreLen do
            self:RecycleItem(table.remove(self.CurObjs))
        end
    end
    self.PreLen = index
end

function XUiDormPersonListItem:GetItem(index)
    if #self.PoolObjs > 0 then
        return table.remove(self.PoolObjs)
    end

    local obj = Object.Instantiate(self.PersonSingleItem)
    obj.transform:SetParent(self.PersonList, false)
    obj.transform.localScale = V3O
    obj.gameObject.name = index
    local item = XUiDormPersonSingleItem.New(obj)
    item:SetState(true)
    return item
end

function XUiDormPersonListItem:RecycleItem(item)
    if not item then
        return
    end

    item:SetState(false)
    table.insert(self.PoolObjs, item)
end

return XUiDormPersonListItem
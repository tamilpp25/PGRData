-- 肉鸽模拟经营场景地图节点
---@class XRogueSimArea
---@field _Control XRogueSimControl
---@field _Scene XRogueSimScene
local XRogueSimArea = XClass(nil, "XRogueSimArea")

---@param scene XRogueSimScene
function XRogueSimArea:Ctor(scene, areaId, isUnlock, canUnlock)
    self._Control = scene._MainControl
    self._Scene = scene
    self._IsLoaded = false
    self.Id = areaId
    self.IsUnlock = isUnlock
    self.CanUnlock = canUnlock
    local areaCfg = self._Control.MapSubControl:GetRogueSimAreaConfig(self.Id)
    self.FocusGridId = areaCfg.FocusGridId
    self.UnlockUiGridId = areaCfg.UnlockUiGridId
    self.UnlockCost = areaCfg.UnlockCost
    self.UnlockExpReward = areaCfg.UnlockExpReward
    self.Texts = areaCfg.Texts
    self.TextGridIds = areaCfg.TextGridIds
end

-- 加载
function XRogueSimArea:Load()
    if self._IsLoaded then return end

    local go = CS.UnityEngine.Object.Instantiate(self._Scene.UiArea, self._Scene.UiAreaList)
    self.Transform = go.transform
    self.GameObject = go.gameObject
    self.Transform.name = tostring(self.Id)
    self.GameObject:SetActiveEx(true)
    XTool.InitUiObject(self)
    self._IsLoaded = true
    self:OnLoaded()
end

-- 加载完成回调
function XRogueSimArea:OnLoaded()
    self:Refresh()
end

-- 释放
function XRogueSimArea:Release()
    self._Scene = nil
    self._Control = nil
    self.Transform = nil
    self.GameObject = nil
end

-- 设置区域已解锁
function XRogueSimArea:SetAreaUnlock()
    self.IsUnlock = true
    self:RefreshName()
end

-- 设置区域可购买解锁
function XRogueSimArea:SetAreaCanUnlock()
    self.CanUnlock = true
end

-- 获取区域名称
function XRogueSimArea:GetName()
    if self.Name then
        return self.Name
    end
    self.Name = ""
    for _, text in ipairs(self.Texts) do
        self.Name = self.Name .. text
    end
end

-- 刷新区域
function XRogueSimArea:Refresh()
    self:RefreshName()
    self:RefreshPanelUnlock()
end

-- 刷新区域名称
function XRogueSimArea:RefreshName()
    if self.NameTexts then return end
    
    self.TxtName.gameObject:SetActiveEx(false)
    if not self.IsUnlock then return end
    if XTool.IsTableEmpty(self.TextGridIds) then return end
    
    self.NameTexts = {}
    local CSInstantiate = CS.UnityEngine.Object.Instantiate
    for i, gridId in ipairs(self.TextGridIds) do
        local go = CSInstantiate(self.TxtName, self.TxtName.transform.parent)
        go.gameObject:SetActiveEx(true)
        local worldPos = self._Scene:GetWorldPosByGridId(gridId)
        go.transform.localPosition = CS.UnityEngine.Vector3(worldPos.x, worldPos.z, 0)
        local textComp = go:GetComponent("Text")
        textComp.text = self.Texts[i]
        table.insert(self.NameTexts, textComp)
    end
end

-- 刷新区域解锁面板
function XRogueSimArea:RefreshPanelUnlock()
    -- TODO 解锁面板的UI从格子改到区域里
    if self.UnlockUiGridId == 0 then return end
    local grid = self._Scene:GetGrid(self.UnlockUiGridId)
    grid:RefreshCityBuyPanel()
end

return XRogueSimArea

local XUiPanel3DMapChapter = XClass(nil, "XUiPanel3DMapChapter")
local XUiGrid3DMapStage = require("XUi/XUiSuperTower/Map/XUiGrid3DMapStage")
local XUiGrid3DMapTheme = require("XUi/XUiSuperTower/Map/XUiGrid3DMapTheme")
local CSTextManagerGetText = CS.XTextManager.GetText
local CSObjectInstantiate = CS.UnityEngine.Object.Instantiate
local CSUnityEngineGameObject = CS.UnityEngine.GameObject
local Vector3 = CS.UnityEngine.Vector3
function XUiPanel3DMapChapter:Ctor(ui, effectParent, gridTheme, gridStage)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.EffectParent = effectParent
    XTool.InitUiObject(self)
    self.MapStageList = {}
    self.MapTheme = {}
    self.GridTheme = gridTheme
    self.GridStage = gridStage
    self.GridTheme.gameObject:SetActiveEx(false)
    self.GridStage.gameObject:SetActiveEx(false)
    
    self.TerrainEffect = CSUnityEngineGameObject("TerrainEffect")
    self.TerrainEffect.transform:SetParent(effectParent.transform, false)
    self.MapEffect = CSUnityEngineGameObject("MapEffect")
    self.MapEffect.transform:SetParent(effectParent.transform, false)
end

function XUiPanel3DMapChapter:UpdatePanel(data, index, IsNewTheme)
    self.STTheme = data
    self.IsNewTheme = IsNewTheme
    self.ThemeIndex = index
    self:UpdateStage(index)
    self:UpdateTheme(index, IsNewTheme)
end

function XUiPanel3DMapChapter:UpdateStage(themeIndex)
    local stageDataList = self.STTheme:GetTargetStageList()
    local curIndex = self:GetCurStageIndex()
    for index,data in pairs(stageDataList) do
        if not self.MapStageList[index] then
            self:CreateStage(index)
        end
        self.MapStageList[index]:UpdateGrid(self.STTheme, data, themeIndex, index, index == curIndex, index == curIndex + 1)
    end
end

function XUiPanel3DMapChapter:GetCurStageIndex()
    local stageDataList = self.STTheme:GetTargetStageList()
    for index,data in pairs(stageDataList) do
        if data:CheckStageIsOpen() and not data:CheckIsClear() then
            return index
        end
    end
    return 0
end

function XUiPanel3DMapChapter:CreateStage(index)
    local str = index < 10 and "Stage0%d" or "Stage%d"
    local panelName = string.format(str,index)
    local parentObj = self.PanelStageParent:GetObject(panelName)
    if not parentObj then
        XLog.Error("Is Not Exist Stage:".. panelName .." In 3DUI")
    else
        local obj = CSObjectInstantiate(self.GridStage, parentObj)
        obj.transform.localPosition = Vector3(0, 0, 0)
        obj.gameObject:SetActiveEx(true)
        self.MapStageList[index] = XUiGrid3DMapStage.New(obj)
    end
end

function XUiPanel3DMapChapter:UpdateTheme(index, isNewTheme)
    if not self.MapTheme or not next(self.MapTheme) then
        self:CreateTheme()
    end
    self.MapTheme:UpdateGrid(self.STTheme, index, isNewTheme)
    
    local terrainEffect = self.STTheme:GetMapTerrainEffect()
    
    local mapEffect
    if not self.STTheme:CheckIsOpen() then
        mapEffect = self.STTheme:GetMapLockEffect()
    else
        mapEffect = self.IsNewTheme and self.STTheme:GetMapCurrentEffect() or self.STTheme:GetMapNormalEffect()
    end
    
    self:LoadEffect(terrainEffect, self.TerrainEffect)
    self:LoadEffect(mapEffect, self.MapEffect)
end

function XUiPanel3DMapChapter:CreateTheme()
    local obj = CSObjectInstantiate(self.GridTheme, self.PanelInfoParent)
    obj.transform.localPosition = Vector3(0, 0, 0)
    obj.gameObject:SetActiveEx(true)
    self.MapTheme = XUiGrid3DMapTheme.New(obj)
end

function XUiPanel3DMapChapter:ShowThemeInfo(IsShow)
    self.PanelInfoParent.gameObject:SetActiveEx(IsShow)
    self:ShowEffect(self.MapEffect, IsShow)
end

function XUiPanel3DMapChapter:ShowStageInfo(IsShow)
    self.PanelStageParent.gameObject:SetActiveEx(IsShow)
    self:ShowEffect(self.TerrainEffect, IsShow)
    self:ShowStageEffect(IsShow)
end

function XUiPanel3DMapChapter:LoadEffect(effectPath, effectParent)
    if effectPath then
        self.Effect = self.Effect or {}
        local effect = self.Effect[effectParent]

        if effect == nil or XTool.UObjIsNil(effect) then
            effect = effectParent.gameObject:LoadPrefab(effectPath)
            self.Effect[effectParent] = effect
        end

        effect.gameObject:SetActiveEx(false)
        effect.gameObject:SetActiveEx(true)
    end
end

function XUiPanel3DMapChapter:ShowEffect(effectParent, IsShow)
    if effectParent then
        effectParent.gameObject:SetActiveEx(IsShow)
    end
end

function XUiPanel3DMapChapter:ShowStageEffect(IsShow)
    for _,mapStage in pairs(self.MapStageList) do
        mapStage:ShowEffect(IsShow)
    end
end

function XUiPanel3DMapChapter:GetIndex()
    return self.ThemeIndex
end

function XUiPanel3DMapChapter:StopStageTimer()
    for _,mapStage in pairs(self.MapStageList) do
        mapStage:StopTimer()
    end
end

function XUiPanel3DMapChapter:GetStageByIndex(index)
    return self.MapStageList and self.MapStageList[index]
end

function XUiPanel3DMapChapter:GetTheme()
    return self.MapTheme
end

return XUiPanel3DMapChapter
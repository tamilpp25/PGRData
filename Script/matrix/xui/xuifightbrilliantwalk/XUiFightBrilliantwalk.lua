local CSXFightIntStringMapManagerTryGetString = CS.XFightIntStringMapManager.TryGetString

local XUiFightBrilliantwalk = XLuaUiManager.Register(XLuaUi, "UiFightBrilliantwalk")
local XUiBaseTips = require("XUi/XUiFightBrilliantwalk/XUiBaseTips")
local XUiBrokenLineTips = require("XUi/XUiFightBrilliantwalk/XUiBrokenLineTips")

--锁定的表现样式类型
local StyleType = {
    NoLine = 1,
    BrokenLine = 2
}

local MOD_MAX_COUNT = 5 --图标最大数量

function XUiFightBrilliantwalk:OnAwake()
    self.TipsEntity = {}
    self.LoadPrefab = {}
    self:InitObj()
end

function XUiFightBrilliantwalk:OnEnable()
    self.Timer = XScheduleManager.ScheduleForever(handler(self, self.Update), 0, 0)
end

function XUiFightBrilliantwalk:OnDisable()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiFightBrilliantwalk:InitObj()
    self:InitModImgList()
end

function XUiFightBrilliantwalk:InitModImgList()
    self.ModImgList = {}
    for i = 1, MOD_MAX_COUNT do
        local dictionary = {}
        dictionary.Green = XUiHelper.TryGetComponent(self["Mod" .. i], "Green")
        dictionary.GreenIcon = XUiHelper.TryGetComponent(self["Mod" .. i], "Green/Mod1Icon", "Image")
        dictionary.Red = XUiHelper.TryGetComponent(self["Mod" .. i], "Red", "Image")
        dictionary.RedIcon = XUiHelper.TryGetComponent(self["Mod" .. i], "Red/Mod1Icon", "Image")
        dictionary.Lock = XUiHelper.TryGetComponent(self["Mod" .. i], "Lock")

        dictionary.Green.gameObject:SetActiveEx(false)
        dictionary.Red.gameObject:SetActiveEx(false)
        dictionary.Lock.gameObject:SetActiveEx(false)

        self.ModImgList[i] = dictionary
    end
end

function XUiFightBrilliantwalk:Update()
    for _, entity in pairs(self.TipsEntity) do
        if entity.Update then
            entity:Update()
        end
    end
end

----------跟随tips相关 begin-----------
function XUiFightBrilliantwalk:InitTips(id, npc, styleType, xOffset, yOffset, endX, endY, jointName, effectName)
    local tips = self:GetTips(id)
    if tips and tips:GetStyleType() ~= styleType then
        self:DestroyTips(id)
        tips = nil
    end

    if not tips then
        tips = self:GetClassObj(styleType)
        self.TipsEntity[id] = tips
    end

    tips:Init(npc, jointName, xOffset, yOffset, styleType, endX, endY, effectName)
end

function XUiFightBrilliantwalk:InitTipsEx(id, npc, styleType, xOffset, yOffset, endX, endY, jointName, configId)
    local tips = self:GetTips(id)
    if (tips) and (tips:GetStyleType() ~= styleType or tips:GetConfigId() ~= configId) then
        self:DestroyTips(id)
        tips = nil
    end

    if not tips then
        tips = self:GetClassObj(styleType, configId)
        self.TipsEntity[id] = tips
        tips:SetConfigId(configId)
    end

    local effectName = XFightBrilliantwalkConfigs.GetEffectName(configId)
    tips:Init(npc, jointName, xOffset, yOffset, styleType, endX, endY, effectName)
end

--获得锁定的表现样式类型对应的类对象
function XUiFightBrilliantwalk:GetClassObj(styleType, configId)
    local prefabName = XFightBrilliantwalkConfigs.GetPrefabPath(configId, styleType)
    local prefab = prefabName and self.LoadPrefab[prefabName] 
    if not prefab then
        prefab = self.Transform:GetLoader():Load(prefabName)
        self.LoadPrefab[prefabName] = prefab
    end
    
    if styleType == StyleType.NoLine then
        return XUiBaseTips.New(XUiHelper.Instantiate(prefab, self.Transform))
    elseif styleType == StyleType.BrokenLine then
        return XUiBrokenLineTips.New(XUiHelper.Instantiate(prefab, self.Transform))
    end
    XLog.Error("不存在的锁定样式类型：", styleType)
end

function XUiFightBrilliantwalk:GetTips(id)
    if not self.TipsEntity then
        self.TipsEntity = {}
    end
    return self.TipsEntity[id]
end

function XUiFightBrilliantwalk:SetTipsDesc(id, textIndex, tipTextId, varIndex, value)
    local tips = self:GetTips(id)
    if not tips then
        return
    end
    tips:SetDesc(textIndex, tipTextId, varIndex, value)
end

function XUiFightBrilliantwalk:DestroyTips(id)
    if not self.TipsEntity[id] then
        return
    end
    self.TipsEntity[id]:OnDestroy()
    self.TipsEntity[id] = nil
end
----------跟随tips相关 end-------------

----------图标相关 begin-----------
function XUiFightBrilliantwalk:GetModImgDict(index)
    if not self.ModImgList then
        self:InitModImgList()
    end
    return self.ModImgList[index]
end

function XUiFightBrilliantwalk:SetModPercent(index, percent)
    local modImgDict = self:GetModImgDict(index)
    if not modImgDict then
        return
    end

    --1全绿，0全红
    percent = 1 - percent
    modImgDict.Red.fillAmount = percent
    modImgDict.RedIcon.fillAmount = percent
    modImgDict.Red.gameObject:SetActiveEx(true)
end

function XUiFightBrilliantwalk:SetModIsUnlock(index, isUnlock)
    local modImgDict = self:GetModImgDict(index)
    if not modImgDict then
        return
    end

    modImgDict.Green.gameObject:SetActiveEx(isUnlock)
    modImgDict.Lock.gameObject:SetActiveEx(not isUnlock)
end

function XUiFightBrilliantwalk:SetIcon(index, assetPathId)
    local modImgDict = self:GetModImgDict(index)
    if not modImgDict then
        return
    end

    if not XTool.IsNumberValid(assetPathId) then
        modImgDict.Red.gameObject:SetActiveEx(false)
        modImgDict.Green.gameObject:SetActiveEx(false)
        modImgDict.Lock.gameObject:SetActiveEx(false)
        return
    end

    local succeed, iconPath = CSXFightIntStringMapManagerTryGetString(assetPathId)
    if not succeed then
        return
    end

    modImgDict.GreenIcon:SetSprite(iconPath)
    modImgDict.RedIcon:SetSprite(iconPath)
end
----------图标相关 end-----------
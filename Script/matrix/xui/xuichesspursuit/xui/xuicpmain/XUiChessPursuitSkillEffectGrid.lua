local XChessPursuitCtrl = require("XUi/XUiChessPursuit/XChessPursuitCtrl")
local XUiChessPursuitSkillEffectGrid = XClass(nil, "XUiChessPursuitSkillEffectGrid")
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate
local CSXResourceManagerLoad
local CSXResourceManagerUnLoad = CS.XResourceManager.Unload
local CSUnityEngineGameObjectDestroy = CS.UnityEngine.GameObject.Destroy
local ChessPursuitBuffStartEffectTime = CS.XGame.ClientConfig:GetFloat("ChessPursuitBuffStartEffectTime")
local ChessPursuitBuffStartEffect = CS.XGame.ClientConfig:GetString("ChessPursuitBuffStartEffect")
local ChessPursuitArrowEffect = CS.XGame.ClientConfig:GetString("ChessPursuitArrowEffect")
local ChessPursuitUseCardEffect = CS.XGame.ClientConfig:GetString("ChessPursuitUseCardEffect")
local CSUnityEngineVector3 = CS.UnityEngine.Vector3

local CARD_EFFECT_Y = {
    [XChessPursuitCtrl.SCENE_SELECT_TARGET.CUBE] = 0.503,
    [XChessPursuitCtrl.SCENE_SELECT_TARGET.TEAM] = 0,
    [XChessPursuitCtrl.SCENE_SELECT_TARGET.BOSS] = 0,
}

local USE_CARD_EFFECT_Y = {
    [XChessPursuitCtrl.SCENE_SELECT_TARGET.CUBE] = 0.92,
    [XChessPursuitCtrl.SCENE_SELECT_TARGET.TEAM] = 0.92,
    [XChessPursuitCtrl.SCENE_SELECT_TARGET.BOSS] = 0.436,
}

local EffectMaxCount = 3

function XUiChessPursuitSkillEffectGrid:Ctor(uiRoot, cubeIndex, targetType, mapId)
    self.UiRoot = uiRoot
    self.CubeIndex = cubeIndex
    self.TargetType = targetType
    self.TmEffectGo = {}
    self.IsDispose = false
    self.MapId = mapId
end

function XUiChessPursuitSkillEffectGrid:Disable()
    self.IsCheckRePlayEffect = true
end

function XUiChessPursuitSkillEffectGrid:Dispose()
    for cardId, go in pairs(self.TmEffectGo) do
        CSUnityEngineGameObjectDestroy(go)
    end

    if self.UseCardEffectRes then
        CSXResourceManagerUnLoad(self.UseCardEffectRes)
    end

    if self.BuffStartEffectRes then
        CSXResourceManagerUnLoad(self.BuffStartEffectRes)
    end

    if self.ArrowEffectRes then
        CSXResourceManagerUnLoad(self.ArrowEffectRes)
    end

    for _, res in pairs(self.UseCardEffectResDic) do
        CSXResourceManagerUnLoad(res)
    end

    self.TmEffectGo = nil
    self.IsDispose = true
end

function XUiChessPursuitSkillEffectGrid:Refresh()
    if self.IsCheckRePlayEffect then
        self:CheckRePlayEffect()
    end

    local chessPursuitMapDb = XDataCenter.ChessPursuitManager.GetChessPursuitMapDb(self.MapId)
    local xChessPursuitCardDbList
    if self.TargetType == XChessPursuitCtrl.SCENE_SELECT_TARGET.BOSS then
        xChessPursuitCardDbList = chessPursuitMapDb:GetBossCardDb() or {}
        self:RefreshEffect(xChessPursuitCardDbList)
    else
        local xChessPursuitMapGridCardDb = chessPursuitMapDb:GetGridCardDb()
        xChessPursuitCardDbList = {}
        for _,v in ipairs(xChessPursuitMapGridCardDb) do
            if v.Id == self.CubeIndex-1 then
                xChessPursuitCardDbList = v.Cards or {}
                break
            end
        end

        self:RefreshEffect(xChessPursuitCardDbList)
    end
end

function XUiChessPursuitSkillEffectGrid:RefreshEffect(xChessPursuitCardDbList)
    local isPlayEffectAnima = false

    --去除已经过期的
    for cardId, go in pairs(self.TmEffectGo) do
        local isExist = false
        for i,card in ipairs(xChessPursuitCardDbList) do
            if card.Id == cardId then
                isExist = true
                break
            end
        end

        if not isExist then
            CSUnityEngineGameObjectDestroy(go)
            self.TmEffectGo[cardId] = nil
            isPlayEffectAnima = true
        end
    end

    for k, card in ipairs(xChessPursuitCardDbList) do
        if not self.TmEffectGo[card.Id] then
            local parent = self:GetTargetGo()
            local effect = XChessPursuitConfig.GetCardEffect(card.CardCfgId)
            if parent and effect then
                local resource = self.UseCardEffectResDic[effect]
                if not resource then
                    resource = CSXResourceManagerLoad(effect)
                    XLog.Error("[XResourceManager优化] 已经无法运行, 从XResourceManager改为loadPrefab")
                    self.UseCardEffectResDic[effect] = resource
                end
                self.TmEffectGo[card.Id] = CSUnityEngineObjectInstantiate(resource.Asset, parent)
                self.TmEffectGo[card.Id].gameObject:SetActiveEx(false)
                self.TmEffectGo[card.Id].gameObject.transform.localPosition = CSUnityEngineVector3(0, CARD_EFFECT_Y[self.TargetType], 0)
                isPlayEffectAnima = true
            end
        end
    end

    if isPlayEffectAnima then
        self:RePlayEffectAnima()
    end
end

function XUiChessPursuitSkillEffectGrid:CheckRePlayEffect()
    self.IsCheckRePlayEffect = false
    if not XTool.IsTableEmpty(self.TmEffectGo) then
        local effectTotalNum = 0
        for _ in pairs(self.TmEffectGo) do
            effectTotalNum = effectTotalNum + 1
        end
        if effectTotalNum > 1 then
            self:RePlayEffectAnima()
        end
    end
end

function XUiChessPursuitSkillEffectGrid:RePlayEffectAnima()
    local parent = self:GetTargetGo()
    if not parent then
        return
    end
    
    local effectTotalNum = 0
    for _, go in pairs(self.TmEffectGo) do
        go.gameObject:SetActiveEx(false)
        effectTotalNum = effectTotalNum + 1
    end

    local effectNum = 1
    local delayTime = effectTotalNum > 1 and EffectMaxCount / effectTotalNum * 1000 or 1000
    for k, go in pairs(self.TmEffectGo) do
        self.BuffStartEffectRes = self.BuffStartEffectRes or CSXResourceManagerLoad(ChessPursuitBuffStartEffect)
        XLog.Error("[XResourceManager优化] 已经无法运行, 从XResourceManager改为loadPrefab")
        local onStartEffect = CSUnityEngineObjectInstantiate(self.BuffStartEffectRes.Asset, parent)
        CS.XScheduleManager.ScheduleOnce(function()
            if not XTool.UObjIsNil(onStartEffect) then
                CSUnityEngineGameObjectDestroy(onStartEffect)
            end
            if self.IsDispose then
                return
            end
            if not XTool.UObjIsNil(go) then
                go.gameObject:SetActiveEx(true)
            end
        end, math.floor(ChessPursuitBuffStartEffectTime + effectNum * delayTime))
        effectNum = effectNum + 1
    end
end

function XUiChessPursuitSkillEffectGrid:GetTargetGo()
    if self.TargetType == XChessPursuitCtrl.SCENE_SELECT_TARGET.BOSS then
        return self.UiRoot.ChessPursuitBoss.Transform
    else
        local chessPursuitCubes = XChessPursuitCtrl.GetChessPursuitCubes()
        return chessPursuitCubes[self.CubeIndex].Transform
    end
end

function XUiChessPursuitSkillEffectGrid:GetTargetType()
    return self.TargetType
end

--@region 布阵阶段的箭头特效
function XUiChessPursuitSkillEffectGrid:LoadJianTou()
    if self.TargetType == XChessPursuitCtrl.SCENE_SELECT_TARGET.CUBE then
        local parent = self:GetTargetGo()
        self.ArrowEffectRes = self.ArrowEffectRes or CSXResourceManagerLoad(ChessPursuitArrowEffect)
        XLog.Error("[XResourceManager优化] 已经无法运行, 从XResourceManager改为loadPrefab")
        local cubes = XChessPursuitCtrl.GetCSXChessPursuitCtrlCom().Cubes
        local localPos = parent.transform.position
        local nextPos = self:GetNextIndexPos()
        local q = CS.UnityEngine.Quaternion.LookRotation(CS.UnityEngine.Vector3(nextPos.x - localPos.x, 0, nextPos.z - localPos.z))

        self.jianTouGo = CSUnityEngineObjectInstantiate(self.ArrowEffectRes.Asset, parent)
        self.jianTouGo.transform.localPosition = CSUnityEngineVector3(0, CARD_EFFECT_Y[XChessPursuitCtrl.SCENE_SELECT_TARGET.CUBE], 0)
        self.jianTouGo.transform.localScale = CS.UnityEngine.Vector3(0.6, 0.6, 0.6)
        self.jianTouGo.transform.rotation = q
    end
end

function XUiChessPursuitSkillEffectGrid:GetNextIndexPos()
    local cubes = XChessPursuitCtrl.GetCSXChessPursuitCtrlCom().Cubes
    if self.CubeIndex >= cubes.Count then
        return cubes[0].transform.position
    else
        return cubes[self.CubeIndex].transform.position
    end
end

function XUiChessPursuitSkillEffectGrid:DestroyArrow()
    if not XTool.UObjIsNil(self.jianTouGo) then
        CSUnityEngineGameObjectDestroy(self.jianTouGo, 1)
    end
end
--@endregion

--使用卡时候播放的特效
function XUiChessPursuitSkillEffectGrid:LoadUseCardEffect()
    local parent = self:GetTargetGo()
    self.UseCardEffectRes = self.UseCardEffectRes or CSXResourceManagerLoad(ChessPursuitUseCardEffect)
    XLog.Error("[XResourceManager优化] 已经无法运行, 从XResourceManager改为loadPrefab")
    local effectGo = CSUnityEngineObjectInstantiate(self.UseCardEffectRes.Asset, parent)
    effectGo.transform.localPosition = CSUnityEngineVector3(0, USE_CARD_EFFECT_Y[self.TargetType], 0)
    effectGo.transform.localScale = CS.UnityEngine.Vector3(0.4, 0.4, 0.4)

    CSUnityEngineGameObjectDestroy(effectGo, 1)
end

return XUiChessPursuitSkillEffectGrid
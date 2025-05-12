local Fuben = {}
local Character = {}
local DlcCharacter = {}
local DlcFuben = {}
local Player = {}
local SetConfigs = {}
local LoginManager = {}
local Equip = {}
local Set = {}
local PhotographManager = {}
local X3CProxy = {}
local Theatre4 = {}
local UIInterface = {}
local ConditionManager = {}

function Fuben.CheckSettleFight()
    return XDataCenter.FubenManager.CheckSettleFight()
end

function Fuben.GetStageRebootId(stageId)
    return XDataCenter.FubenManager.GetStageRebootId(stageId)
end

function Fuben.GetStageBgmId(stageId)
    return XDataCenter.FubenManager.GetStageBgmId(stageId)
end

function Fuben.GetStageAmbientSound(stageId)
    return XDataCenter.FubenManager.GetStageAmbientSound(stageId)
end

function Fuben.GetStageOnlineMsgId(stageId)
    return XDataCenter.FubenManager.GetStageOnlineMsgId(stageId)
end

function Fuben.GetStageForceAllyEffect(stageId)
    return XDataCenter.FubenManager.GetStageForceAllyEffect(stageId)
end

function Fuben.GetStageResetHpCounts(stageId)
    return XDataCenter.FubenManager.GetStageResetHpCounts(stageId)
end

function Fuben.GetAssistTemplateInfo()
    return XDataCenter.FubenManager.GetAssistTemplateInfo()
end

function Fuben.GetStageCfg(stageId)
    return XDataCenter.FubenManager.GetStageCfg(stageId)
end

function Fuben.GetStageType(stageId)
    return XDataCenter.FubenManager.GetStageType(stageId)
end

--点击黑屏，模拟关闭教学操作
function Fuben.CloseGuideUI()
    local uiGuide = CsXUiManager.Instance:FindTopUi("UiGuide")
    if uiGuide then
        local proxy = uiGuide.UiProxy.UiLuaTable
        proxy:OnBtnPassClick() 
    end
end

function Character.GetFightCharHeadIcon(character, characterId)
    return XMVCA.XCharacter:GetFightCharHeadIcon(character, characterId)
end

function Character.GetCharSmallHeadIconByCharacter(character)
    return XMVCA.XCharacter:GetCharSmallHeadIconByCharacter(character)
end

function Character.GetCharacter(id)
    return XMVCA.XCharacter:GetCharacter(id)
end

function Character.GetCharacterNpcDic(id)
    return XMVCA.XCharacter:GetCharacterNpcDic(id)
end

function Character.GetCharacterIdByNpcId(id)
    return XMVCA.XCharacter:GetCharacterIdByNpcId(id)
end

function DlcCharacter.GetFightCharHeadIcon(worldNpcData)
    return XMVCA.XBigWorldCharacter:GetFightCharHeadIcon(worldNpcData)
end

function DlcCharacter.GetCommandantNpcData()
    return XMVCA.XBigWorldCharacter:GetCommandantNpcData()
end

function DlcFuben.GetWorldType(worldId)
    return XMVCA.XDlcWorld:GetWorldTypeById(worldId)
end

function DlcFuben.GetModelIdByWorldNpcData(worldType, npcData)
    if worldType ~= XEnumConst.DlcWorld.WorldType.BigWorld then
        return nil
    end

    if not npcData then
        XLog.Error("CsCallLua.DlcFuben.GetModelIdByCharacterData 参数错误: npcData == null")

        return nil
    end

    local characterData = npcData.Character

    if not characterData then
        XLog.Error("CsCallLua.DlcFuben.GetModelIdByCharacterData 参数错误: npcData.Character == null")

        return nil
    end

    local fashionId = characterData.FashionId

    if fashionId <= 0 then
        local characterId = characterData.Id

        fashionId = XMVCA.XBigWorldCharacter:GetFashionId(characterId)
    end

    local modelId = XMVCA.XBigWorldCharacter:GetModelIdByFashionId(fashionId)

    if string.IsNilOrEmpty(modelId) then
        return nil
    end

    return modelId
end

function DlcFuben.GetNpcPartModelDataByPartData(npcPartData)
    if not npcPartData or not npcPartData.PartList then
        return nil
    end

    local partList = XTool.CsList2LuaTable(npcPartData.PartList)

    return XMVCA.XBigWorldCommanderDIY:GetNpcPartModelData(partList)
end

function DlcFuben.GetNpcPartDataByGender(gender)
    return XMVCA.XBigWorldCommanderDIY:GetNpcPartDataByGender(gender)
end

function DlcFuben.GetBigWorldText(key)
    return XMVCA.XBigWorldService:GetText(key)
end

--- 兼容黑幕进战斗设置战斗代理
function DlcFuben.InitFightDelegate(worldId)
    XMVCA.XDlcWorld:InitFightDelegate(worldId)
end

function Player.GetLevel()
    return XPlayer.GetLevel()
end

function SetConfigs.GetDefaultKeyMapIds(id)
    local cfg = XSetConfigs.GetControllerMapCfg()
    return cfg[id] and cfg[id].DefaultKeyMapIds
end

function LoginManager.SetHeartbeatTimeout(heartbeatTimeout)
    XLoginManager.SetHeartbeatTimeout(heartbeatTimeout)
end

-- 重置心跳超时时间
function LoginManager.ResetHeartbeatTimeout()
    XLoginManager.ResetHeartbeatTimeout()
end

--- TODO 实现逻辑挪到XEquipAgency
--- @desc 获取武器模型名字列表(战斗用)
function Equip.GetWeaponModelNameList(templateId)
    local nameList = {}
    local usage = XEnumConst.EQUIP.WEAPON_USAGE.BATTLE
    local template = XMVCA.XEquip:GetEquipResConfig(templateId)
    for _, modelId in pairs(template.ModelTransId) do
        local modelName = XMVCA.XEquip:GetEquipModelName(modelId, usage)
        table.insert(nameList, modelName)
    end
    return nameList
end

function Equip.GetWeaponModelNameListByModelId(id)
    local usage = XEnumConst.EQUIP.WEAPON_USAGE.BATTLE
    local modelName = XMVCA.XEquip:GetEquipModelName(id, usage)
    return modelName
end


--- @desc 获取武器Low模型名字列表(战斗用)
function Equip.GetWeaponLowModelNameList(templateId)
    local nameList = {}
    local usage = XEnumConst.EQUIP.WEAPON_USAGE.BATTLE
    local template = XMVCA.XEquip:GetEquipResConfig(templateId)
    if template == null then return nameList end
    
    for _, modelId in pairs(template.ModelTransId) do
        local modelName = XMVCA.XEquip:GetEquipLowModelName(modelId, usage)
        table.insert(nameList, modelName)
    end
    return nameList
end

--- TODO 实现逻辑挪到XEquipAgency
--- @desc 获取武器模型名字列表(战斗用)
function Equip.GetWeaponModelNameListByFight(fightNpcData)
    local nameList = {}
    local characterId = fightNpcData.Character.Id
    local weaponFashionId = fightNpcData.WeaponFashionId or XDataCenter.WeaponFashionManager.GetCharacterWearingWeaponFashionId(characterId)
    local usage = XEnumConst.EQUIP.WEAPON_USAGE.BATTLE
    for _, equipData in pairs(fightNpcData.Equips) do -- equipData为C#的XEquipData
        local templateId = equipData.TemplateId
        local breakthrough = equipData.Breakthrough
        local resonanceCount = equipData.ResonanceInfo.Count
        if  XMVCA.XEquip:IsEquipWeapon(templateId) then
            local idList = XMVCA.XEquip:GetWeaponEquipModelIdListByTemplateId(templateId, weaponFashionId, resonanceCount, breakthrough)
            for _, modelId in ipairs(idList) do
                table.insert(nameList, XMVCA.XEquip:GetEquipModelName(modelId, usage))
            end
            break
        end
    end
    return nameList or {}
end

-- TODO 实现逻辑挪到XEquipAgency
--- @desc 获取武器模型名字列表(战斗用)
function Equip.GetWeaponLowModelNameListByFight(fightNpcData)
    local nameList = {}
    local characterId = fightNpcData.Character.Id
    local weaponFashionId = fightNpcData.WeaponFashionId or XDataCenter.WeaponFashionManager.GetCharacterWearingWeaponFashionId(characterId)
    local usage = XEnumConst.EQUIP.WEAPON_USAGE.BATTLE
    for _, equipData in pairs(fightNpcData.Equips) do -- equipData为C#的XEquipData
        local templateId = equipData.TemplateId
        local breakthrough = equipData.Breakthrough
        local resonanceCount = equipData.ResonanceInfo.Count
        if  XMVCA.XEquip:IsEquipWeapon(templateId) then
            local idList = XMVCA.XEquip:GetWeaponEquipModelIdListByTemplateId(templateId, weaponFashionId, resonanceCount, breakthrough)
            for _, modelId in ipairs(idList) do
                table.insert(nameList, XMVCA.XEquip:GetEquipLowModelName(modelId, usage))
            end
            break
        end
    end
    return nameList or {}
end


--- @desc 获取武器模型Hash,同组使用一个Name.hash，获取一次就行
function Equip.GetWeaponModelHashListByFight(fightNpcData)
    local name = ""
    local characterId = fightNpcData.Character.Id
    local weaponFashionId = fightNpcData.WeaponFashionId or XDataCenter.WeaponFashionManager.GetCharacterWearingWeaponFashionId(characterId)
    local usage = XEnumConst.EQUIP.WEAPON_USAGE.BATTLE
    for _, equipData in pairs(fightNpcData.Equips) do -- equipData为C#的XEquipData
        local templateId = equipData.TemplateId
        local breakthrough = equipData.Breakthrough
        local resonanceCount = equipData.ResonanceInfo.Count
        if  XMVCA.XEquip:IsEquipWeapon(templateId) then
            local idList = XMVCA.XEquip:GetWeaponEquipModelIdListByTemplateId(templateId, weaponFashionId, resonanceCount, breakthrough)
            for _, modelId in ipairs(idList) do
                name =  XMVCA.XEquip:GetEquipModelHash(modelId, usage)
                break
            end
        end
    end
    return name
end


--- TODO 实现逻辑挪到XEquipAgency
--- @desc 获取武器动画controller(战斗用)
function Equip.GetWeaponControllerList(templateId)
    local controllerList = {}
    local usage = XEnumConst.EQUIP.WEAPON_USAGE.BATTLE
    local template = XMVCA.XEquip:GetEquipResConfig(templateId)
    for _, modelId in pairs(template.ModelTransId) do
        local controller = XMVCA.XEquip:GetEquipAnimController(modelId, usage)
        table.insert(controllerList, controller or "")
    end
    return controllerList
end

--- TODO 实现逻辑挪到XEquipAgency
--- @desc 获取武器模动画controller(战斗用)
function Equip.GetWeaponControllerListByFight(fightNpcData)
    local controllerList = {}
    local characterId = fightNpcData.Character.Id
    local weaponFashionId =
        fightNpcData.WeaponFashionId or
        XDataCenter.WeaponFashionManager.GetCharacterWearingWeaponFashionId(characterId)
    local usage = XEnumConst.EQUIP.WEAPON_USAGE.BATTLE
    for _, equipData in pairs(fightNpcData.Equips) do -- equipData为C#的XEquipData
        local templateId = equipData.TemplateId
        local breakthrough = equipData.Breakthrough
        local resonanceCount = equipData.ResonanceInfo.Count
        if XMVCA.XEquip:IsEquipWeapon(templateId) then
            local idList = XMVCA.XEquip:GetWeaponEquipModelIdListByTemplateId(templateId, weaponFashionId, resonanceCount, breakthrough)
            for _, modelId in ipairs(idList) do
                table.insert(controllerList, XMVCA.XEquip:GetEquipAnimController(modelId, usage))
            end
            break
        end
    end
    return controllerList
end

--[[ MVCA改造时，XEquipManager未找到该函数，翻以前日志也未找到
function Equip.GetWeaponAnimStateNameByFight(fightNpcData)
    
end
]]

--- TODO 实现逻辑挪到XEquipAgency
--- @desc 获取角色武器共鸣特效(战斗用) v2.17功能已废弃
function Equip.GetWeaponResonanceEffectPathByFight(fightNpcData)
    return nil
end

--- @desc 获取灵敏度值(战斗用)
function Set.GetSensitivityValue(id)
    return XDataCenter.SetManager.GetSensitivityValue(id)
end

--- @desc 设置灵敏度(战斗用)
function Set.SetSensitivityValue(id, value)
    XDataCenter.SetManager.SetSensitivityValue(id, value)
end

--- @desc 打开灵敏度设置界面(战斗用)
function Set.OpenSensitivityUi()
    XDataCenter.SetManager.OpenSensitivityUi()
end

function PhotographManager.SharePhotoBefore(texture)
    local photoName = "[" .. tostring(XPlayer.Id) .. "]" .. XTime.GetServerNowTimestamp()
    XDataCenter.PhotographManager.SharePhotoBefore(photoName, texture, XPlatformShareConfigs.PlatformType.Local)
end

function X3CProxy.Receive(cmd, data)
    return XMVCA.X3CProxy:Receive(cmd, data)
end

function X3CProxy.CheckPrintEnable()
    return XMVCA.X3CProxy:CheckPrintEnable()
end

function X3CProxy.SetPrintEnable(value)
    return XMVCA.X3CProxy:SetPrintEnable(value)
end

function Theatre4.GetGoldCount()
    return XMVCA:GetAgency(ModuleId.XTheatre4):GetGoldCount()
end

function Theatre4.GetGoldName()
    return XMVCA:GetAgency(ModuleId.XTheatre4):GetGoldName()
end

function Theatre4.GetCostItemText()
    return CS.XTextManager.GetText("RebootCostText", Theatre4.GetGoldName())
end

function UIInterface.CallUIFunction(uiName, uiFunc)
    local ui = XFightUiManager.GetChildUiFight(uiName)
    if ui then
        local proxy = ui.UiProxy.UiLuaTable
        proxy[uiFunc](proxy)
    end
end

function UIInterface.CallUIFunctionP1(uiName, uiFunc, p1)
    local ui = XFightUiManager.GetChildUiFight(uiName)
    if ui then
        local proxy = ui.UiProxy.UiLuaTable
        proxy[uiFunc](proxy, p1)
    end
end

function UIInterface.CallUIFunctionP2(uiName, uiFunc, p1, p2)
    local ui = CsXUiManager.Instance:FindTopUi(uiName)
    if ui then
        local proxy = ui.UiProxy.UiLuaTable
        proxy[uiFunc](proxy, p1, p2)
    end
end

function UIInterface.CallUIFunctionP3(uiName, uiFunc, p1, p2, p3)
    local ui = CsXUiManager.Instance:FindTopUi(uiName)
    if ui then
        local proxy = ui.UiProxy.UiLuaTable
        proxy[uiFunc](proxy, p1, p2, p3)
    end
end

function UIInterface.CallUIFunctionP4(uiName, uiFunc, p1, p2, p3, p4)
    local ui = CsXUiManager.Instance:FindTopUi(uiName)
    if ui then
        local proxy = ui.UiProxy.UiLuaTable
        proxy[uiFunc](proxy, p1, p2, p3, p4)
    end
end

function ConditionManager.CheckCondition(conditionId)
    return XConditionManager.CheckCondition(conditionId)
end

CsCallLua = {}
CsCallLua.Fuben = Fuben
CsCallLua.Character = Character
CsCallLua.DlcFuben = DlcFuben
CsCallLua.Player = Player
CsCallLua.SetConfigs = SetConfigs
CsCallLua.LoginManager = LoginManager
CsCallLua.Equip = Equip
CsCallLua.Set = Set
CsCallLua.PhotographManager = PhotographManager
CsCallLua.X3CProxy = X3CProxy
CsCallLua.Theatre4 = Theatre4
CsCallLua.DlcCharacter = DlcCharacter
CsCallLua.UIInterface = UIInterface
CsCallLua.ConditionManager = ConditionManager

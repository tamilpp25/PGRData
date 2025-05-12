---@class XSameColorControl : XControl
---@field private _Model XSameColorModel
local XSameColorControl = XClass(XControl, "XSameColorControl")
function XSameColorControl:OnInit()
    --初始化内部变量
end

function XSameColorControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XSameColorControl:RemoveAgencyEvent()

end

function XSameColorControl:OnRelease()
    
end

--region Ui
function XSameColorControl:OpenShop()
    if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon)
            or XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopActive) then
        local shopId = tonumber(self._Model:GetClientCfgStringValue("ShopId"))
        XShopManager.GetShopInfo(shopId, function()
            XLuaUiManager.Open("UiSameColorGameShop", shopId)
        end)
    end
end
--endregion

--region Scene
function XSameColorControl:HandleModelHideNode(ModelInfo, BattleShowModelId)
    local model = ModelInfo.Model
    if XTool.UObjIsNil(model) then
        return
    end

    local hideNodeNameData = self:GetCfgBattleShowRoleHideNodeNameList(BattleShowModelId)
    for _, nodeName in ipairs(hideNodeNameData) do
        local parts = model.gameObject:FindTransform(nodeName)
        if not XTool.UObjIsNil(parts) then
            parts.gameObject:SetActiveEx(false)
        end
    end
end

function XSameColorControl:HandleModelReadyHideNode(ModelInfo, BattleShowModelId)
    local model = ModelInfo.Model
    if XTool.UObjIsNil(model) then
        return
    end

    local hideNodeNameData = self:GetCfgBattleShowRoleReadyHideNodeNameList(BattleShowModelId)
    for _, nodeName in ipairs(hideNodeNameData) do
        local parts = model.gameObject:FindTransform(nodeName)
        if not XTool.UObjIsNil(parts) then
            parts.gameObject:SetActiveEx(false)
        end
    end
end
--endregion

--region Game
function XSameColorControl:CheckPosIsAdjoin(posA, posB)
    local adjoinX = false
    local adjoinY = false
    local sameX = false
    local sameY = false
    if posA.PositionX == posB.PositionX + 1 or posA.PositionX == posB.PositionX - 1 then
        adjoinX = true
    end
    if posA.PositionY == posB.PositionY + 1 or posA.PositionY == posB.PositionY - 1 then
        adjoinY = true
    end
    if posA.PositionX == posB.PositionX then
        sameX = true
    end
    if posA.PositionY == posB.PositionY then
        sameY = true
    end
    return (adjoinX and sameY) or (adjoinY and sameX)
end
--endregion

--region Data - Task
---@param taskType number XEnumConst.SAME_COLOR_GAME.TASK_TYPE
function XSameColorControl:GetTaskData(taskType, isSort)
    return self._Model:GetTaskData(taskType, isSort)
end
--endregion

--region Cfg - PassiveSkillConfig
function XSameColorControl:GetCfgPassiveSkillName(id)
    local cfg = self._Model:GetPassiveSkillCfg(id)
    return cfg and cfg.Name
end

function XSameColorControl:GetCfgPassiveSkillDesc(id)
    local cfg = self._Model:GetPassiveSkillCfg(id)
    return cfg and cfg.Desc
end
--endregion

--region Cfg - ClientConfig
function XSameColorControl:GetClientCfgStringValue(key, index)
    return self._Model:GetClientCfgStringValue(key, index)
end

function XSameColorControl:GetClientCfgValue(key)
    return self._Model:GetClientCfgValue(key)
end

function XSameColorControl:GetCfgHelpId()
    local helpId = tonumber(self:GetClientCfgStringValue("HelpId"))
    return XHelpCourseConfig.GetHelpCourseTemplateById(helpId).Function
end

function XSameColorControl:GetCfgAssetItemIds()
    local result = {}
    for _, v in ipairs(self:GetClientCfgValue("AssetItemIds")) do
        table.insert(result, tonumber(v))
    end
    return result
end

function XSameColorControl:GetCfgBossBattleBgmCueId()
    local value = self:GetClientCfgStringValue("BossBattleBgmCueId")
    return value and tonumber(value)
end
--endregion

--region Cfg - BattleShowRole
---@return number[]
function XSameColorControl:GetCfgBattleShowRoleWeaponIdList(ModelId)
    local cfg = self._Model:GetBattleShowRoleCfg(ModelId)
    return cfg and cfg.WeaponId or {}
end

---@return string[]
function XSameColorControl:GetCfgBattleShowRoleHideNodeNameList(ModelId)
    local cfg = self._Model:GetBattleShowRoleCfg(ModelId)
    return cfg and cfg.HideNodeName or {}
end

---@return string[]
function XSameColorControl:GetCfgBattleShowRoleReadyHideNodeNameList(ModelId)
    local cfg = self._Model:GetBattleShowRoleCfg(ModelId)
    return cfg and cfg.ReadyHideNodeName or {}
end
--endregion

--region Cfg - BallBuffEffectShow
---@return string
function XSameColorControl:GetCfgBallBuffEffect(buffType)
    local cfg = self._Model:GetBallBuffEffectShowCfg(buffType)
    return cfg and cfg.EffectUrl
end
--endregion

--region Cfg - SkillEffectShow

---@return XTableSameColorSkillEffectShow
function XSameColorControl:GetSkillEffectShowCfg(skillId)
    return self._Model:GetSkillEffectShowCfg(skillId)
end

---@return number XEnumConst.SAME_COLOR_GAME.SKILL_EFFECT_TIME_TYPE
function XSameColorControl:GetCfgSkillBeforeRemoveEffectType(skillId)
    local cfg = self._Model:GetSkillEffectShowCfg(skillId)
    return cfg and cfg.BeforeRemoveEffectType
end

---@return string[]
function XSameColorControl:GetCfgSkillBeforeRemoveEffectUrlList(skillId)
    local cfg = self._Model:GetSkillEffectShowCfg(skillId)
    return cfg and cfg.BeforeRemoveEffect
end

---@return number XEnumConst.SAME_COLOR_GAME.SKILL_EFFECT_TIME_TYPE
function XSameColorControl:GetCfgSkillOnRemoveEffectType(skillId)
    local cfg = self._Model:GetSkillEffectShowCfg(skillId)
    return cfg and cfg.RemoveEffectType
end

---@return string[]
function XSameColorControl:GetCfgSkillOnRemoveEffectUrlList(skillId)
    local cfg = self._Model:GetSkillEffectShowCfg(skillId)
    return cfg and cfg.RemoveEffect
end

---@return number XEnumConst.SAME_COLOR_GAME.SKILL_EFFECT_TIME_TYPE
function XSameColorControl:GetCfgSkillChangeBallEffectType(skillId)
    local cfg = self._Model:GetSkillEffectShowCfg(skillId)
    return cfg and cfg.ChangeBallEffectType
end

---@return string[]
function XSameColorControl:GetCfgSkillChangeBallEffectUrlList(skillId)
    local cfg = self._Model:GetSkillEffectShowCfg(skillId)
    return cfg and cfg.ChangeBallEffect
end

---@return string[]
function XSameColorControl:GetCfgSkillBallRemoveEffect(skillId)
    local cfg = self._Model:GetSkillEffectShowCfg(skillId)
    return cfg and cfg.BallRemoveEffect
end
--endregion

--region Cfg - AttributeFactor
function XSameColorControl:GetCfgAttributeFactorElementType(id)
    local cfg = self._Model:GetAttributeFactorCfg(id)
    return cfg and cfg.Type
end

function XSameColorControl:GetCfgAttributeFactorElementDesc(id)
    local cfg = self._Model:GetAttributeFactorCfg(id)
    return cfg and cfg.Desc
end
--endregion

--region Cfg - AttributeType
function XSameColorControl:GetCfgAttributeTypeIcon(type)
    local cfg = self._Model:GetAttributeTypeCfg(type)
    return cfg and cfg.Icon
end

function XSameColorControl:GetCfgAttributeTypeBossDesc(type)
    local cfg = self._Model:GetAttributeTypeCfg(type)
    return cfg and cfg.BossDesc
end
--endregion

return XSameColorControl
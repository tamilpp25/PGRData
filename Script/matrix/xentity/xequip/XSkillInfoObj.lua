local XSkillInfoObj = {}

local function Setmetatable(M, config)
    local mt = {
        __metatable = "readonly table",
        __index = function(_, k)
            if M[k] then
                return M[k]
            else
                return config[k]
            end
        end,
        __newindex = function()
            XLog.Error("attempt to update a readonly table")
        end,
    }

    return setmetatable({}, mt)
end

local function GetResonanceSkillInfoByType(equipResonanceType, templateId)
    if equipResonanceType == XEnumConst.EQUIP.RESONANCE_TYPE.ATTRIB then
        return XAttribManager.TryGetAttribGroupTemplate(templateId)
    elseif equipResonanceType == XEnumConst.EQUIP.RESONANCE_TYPE.CHARACTER_SKILL then
        return XMVCA.XCharacter:GetCharacterSkillPoolSkillInfo(templateId)
    elseif equipResonanceType == XEnumConst.EQUIP.RESONANCE_TYPE.WEAPON_SKILL then
        return XMVCA.XEquip:GetConfigWeaponSkill(templateId)
    end
end

local function GetDescription(equipResonanceType, config)
    if equipResonanceType == XEnumConst.EQUIP.RESONANCE_TYPE.WEAPON_SKILL then
        local linkCharacterSkillId = config.DesLinkCharacterSkillId
        if linkCharacterSkillId and linkCharacterSkillId ~= 0 then
            return XMVCA.XCharacter:GetSpecialWeaponSkillDes(linkCharacterSkillId)
        else
            return config.Description
        end
    else
        return config.Description
    end
end

--[[
    @desc: 意识、武器、属性的工厂类
	--@equipResonanceType: 枚举XEnumConst.EQUIP.RESONANCE_TYPE
    --@id: 对应config内的id字段
]]
function XSkillInfoObj.New(equipResonanceType, id)
    local config = GetResonanceSkillInfoByType(equipResonanceType, id)

    if not config then
        XLog.Error(string.format("没有找到对应的配置 equipResonanceType:%s id:%s", equipResonanceType, id))
        return 
    end

    local M = {}
    M.EquipResonanceType = equipResonanceType
    M.Description = GetDescription(equipResonanceType, config)

    function M:IsSame(skillInfoObj)
        if skillInfoObj then
            if self.EquipResonanceType == skillInfoObj.EquipResonanceType and self.Id == skillInfoObj.Id then
                return true
            else
                return false
            end
        else
            return false
        end
    end

    --用于服务端的Id
    function M:GetSkillIdToServer()
        if XEnumConst.EQUIP.RESONANCE_TYPE.CHARACTER_SKILL == self.EquipResonanceType then
            return self.SkillId
        else
            return self.Id
        end
    end

    return Setmetatable(M, config)
end


return XSkillInfoObj

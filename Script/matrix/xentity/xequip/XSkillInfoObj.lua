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
    if equipResonanceType == XEquipConfig.EquipResonanceType.Attrib then
        return XAttribManager.TryGetAttribGroupTemplate(templateId)
    elseif equipResonanceType == XEquipConfig.EquipResonanceType.CharacterSkill then
        return XCharacterConfigs.GetCharacterSkillPoolSkillInfo(templateId)
    elseif equipResonanceType == XEquipConfig.EquipResonanceType.WeaponSkill then
        return XEquipConfig.GetWeaponSkillInfo(templateId)
    end
end

local function GetDescription(equipResonanceType, config)
    if equipResonanceType == XEquipConfig.EquipResonanceType.WeaponSkill then
        local linkCharacterSkillId = config.DesLinkCharacterSkillId
        if linkCharacterSkillId and linkCharacterSkillId ~= 0 then
            return XDataCenter.CharacterManager.GetSpecialWeaponSkillDes(linkCharacterSkillId)
        else
            return config.Description
        end
    else
        return config.Description
    end
end

--[[
    @desc: 意识、武器、属性的工厂类
	--@equipResonanceType: 枚举XEquipConfig.EquipResonanceType
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
        if XEquipConfig.EquipResonanceType.CharacterSkill == self.EquipResonanceType then
            return self.SkillId
        else
            return self.Id
        end
    end

    return Setmetatable(M, config)
end


return XSkillInfoObj

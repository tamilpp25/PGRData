local XEquip = require("XEntity/XEquip/XEquip")

-- tableKey{ tableName = {ReadFunc , DirPath, Identifier, TableDefindName, CacheType} }
local TableKey = 
{
    Equip = { CacheType = XConfigUtil.CacheType.Normal },
    EquipBreakThrough = { TableDefindName = "XTableEquipBreakthrough" }, -- XTable定义的大小写不一致
    EquipSuit = { CacheType = XConfigUtil.CacheType.Normal },
    EquipSuitEffect = {},
    EquipDecompose = {},
    EatEquipCost = {},
    EquipResonance = {},
    EquipResonanceUseItem = {},
    WeaponSkill = {},
    WeaponSkillPool = {},
    EquipAwake = {},
    WeaponOverrun = {},
    CharacterSuitPriority = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "CharacterId"},
    EquipRes = { DirPath = XConfigUtil.DirectoryType.Client },
    EquipModel = { DirPath = XConfigUtil.DirectoryType.Client },
    EquipModelTransform = { DirPath = XConfigUtil.DirectoryType.Client },
    EquipSkipId = { DirPath = XConfigUtil.DirectoryType.Client },
    EquipAnim = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "ModelId", ReadFunc = XConfigUtil.ReadType.String },
    EquipModelShow = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.String },
    EquipResByFool = { DirPath = XConfigUtil.DirectoryType.Client },
    EquipSignboard = { DirPath = XConfigUtil.DirectoryType.Client },
    WeaponDeregulateUI = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Lv" },
}

---@class XEquipModel : XModel
local XEquipModel = XClass(XModel, "XEquipModel")
function XEquipModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析

    --服务器数据
    self.EquipDic = {} --Equip实例对象列表

    --config相关
    self:InitConfig()
end

function XEquipModel:ClearPrivate()
    self.WeaponOverrunDic = nil

    --这里执行内部数据清理
    --XLog.Error("请对内部数据进行清理")
end

function XEquipModel:ResetAll()
    --这里执行重登数据清理
    --XLog.Error("重登数据清理")

    self.EquipDic = {}
end

----------public start----------
-- 登陆初始化装备数据
function XEquipModel:InitEquipData(dataList)
    for _, protoData in pairs(dataList) do
        self.EquipDic[protoData.Id] = XEquip.New(protoData)
    end
end

-- 刷新装备列表
function XEquipModel:UpdateEquipData(dataList)
    for _, protoData in pairs(dataList) do
        local equip = self.EquipDic[protoData.Id]
        if not equip then
            equip = XEquip.New(protoData)
            self.EquipDic[protoData.Id] = equip
        else
            equip:SyncData(protoData)
        end
    end
end

-- 获取装备的XEquip对象实例
function XEquipModel:GetEquip(equipId)
    local equip = self.EquipDic[equipId]
    if equip then 
        return equip
    else
        XLog.Error("XEquipModel.GetEquip error: 装备不存在, equipId: " .. tostring(equipId))
        return
    end
end

-- 获取所有装备的XEquip对象实例
function XEquipModel:GetEquipDic()
    return self.EquipDic
end

-- 删除装备
function XEquipModel:DeleteEquip(equipId)
    self.EquipDic[equipId] = nil
end

----------public end----------

----------配置表 start----------
function XEquipModel:InitConfig()
    self._ConfigUtil:InitConfigByTableKey("Equip", TableKey)

    -- 初始化升级文件夹内的配置表
    self.LevelUpTableKey = {}
    local paths = CS.XTableManager.GetPaths("Share/Equip/LevelUpTemplate/")
    XTool.LoopCollection(paths, function(path)
        local key = tonumber(XTool.GetFileNameWithoutExtension(path))
        self.LevelUpTableKey[key] = { Identifier = "Level", TableDefindName = "XTableEquipLevelUp"}
    end)
    self._ConfigUtil:InitConfigByTableKey("Equip/LevelUpTemplate", self.LevelUpTableKey)
end

-- 初始化突破表
function XEquipModel:InitEquipBreakthroughConfig()
    self.EquipBreakthroughTemplate = {}
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.EquipBreakThrough)
    for _, config in pairs(cfgs) do
        if not self.EquipBreakthroughTemplate[config.EquipId] then
            self.EquipBreakthroughTemplate[config.EquipId] = {}
        end

        if config.AttribPromotedId == 0 then
            XLog.ErrorTableDataNotFound("XEquipModel.InitEquipBreakthroughConfig", "self.EquipBreakthroughTemplate", "Share/Equip/EquipBreakThrough.tab = ", 
                "config.EquipId", tostring(config.EquipId))
        end

        self.EquipBreakthroughTemplate[config.EquipId][config.Times] = config
    end
end

-- 初始化武器超限表
function XEquipModel:InitWeaponOverrunCfgs()
    self.WeaponOverrunDic = {}
    local overrunTemplates = self._ConfigUtil:GetByTableKey(TableKey.WeaponOverrun)
    for _, cfg in ipairs(overrunTemplates) do
        local weaponId = cfg.WeaponId
        local cfgs = self.WeaponOverrunDic[weaponId]
        if not cfgs then 
            cfgs = {}
            self.WeaponOverrunDic[weaponId] = cfgs
        end
        table.insert(cfgs, cfg)
    end
end

function XEquipModel:GetConfigEquip(id)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.Equip)
    if id then
        if cfgs[id] then
            return cfgs[id]
        else
            XLog.Error("请检查配置表Share/Equip/Equip.tab，未配置行Id = " .. tostring(id))
        end
    else
        return cfgs
    end
end

-- 获取装备的突破配置表列表
function XEquipModel:GetEquipBreakthroughCfgs(templateId)
    if not self.EquipBreakthroughTemplate then 
        self:InitEquipBreakthroughConfig()
    end

    local cfgs = self.EquipBreakthroughTemplate[templateId]
    if not cfgs then
        XLog.ErrorTableDataNotFound("XEquipModel.GetEquipBreakthroughCfg", "cfgs", "Share/Equip/EquipBreakThrough.tab", "templateId", tostring(templateId))
    end
    return cfgs
end

-- 获取装备突破次数对应的配置表
function XEquipModel:GetEquipBreakthroughCfg(templateId, times)
    local cfgs = self:GetEquipBreakthroughCfgs(templateId)
    local config = cfgs[times]
    if not config then
        XLog.ErrorTableDataNotFound("XEquipModel.GetEquipBreakthroughCfg", "config", "Share/Equip/EquipBreakThrough.tab", "templateId : times", 
            tostring(templateId) .. " : " .. tostring(times))
        return
    end

    return config
end

function XEquipModel:GetConfigEquipSuit(id)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.EquipSuit)
    if id then
        if cfgs[id] then
            return cfgs[id]
        else
            XLog.Error("请检查配置表Share/Equip/EquipSuit.tab，未配置行Id = " .. tostring(id))
        end
    else
        return cfgs
    end
end

function XEquipModel:GetConfigEquipSuitEffect(id)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.EquipSuitEffect)
    if id then
        if cfgs[id] then
            return cfgs[id]
        else
            XLog.Error("请检查配置表Share/Equip/EquipSuitEffect.tab，未配置行Id = " .. tostring(id))
        end
    else
        return cfgs
    end
end

function XEquipModel:GetConfigEquipDecompose(id)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.EquipDecompose)
    if id then
        if cfgs[id] then
            return cfgs[id]
        else
            XLog.Error("请检查配置表Share/Equip/EquipDecompose.tab，未配置行Id = " .. tostring(id))
        end
    else
        return cfgs
    end
end

function XEquipModel:GetConfigEatEquipCost(id)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.EatEquipCost)
    if id then
        if cfgs[id] then
            return cfgs[id]
        else
            XLog.Error("请检查配置表Share/Equip/EatEquipCost.tab，未配置行Id = " .. tostring(id))
        end
    else
        return cfgs
    end
end

function XEquipModel:GetConfigEquipResonance(id)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.EquipResonance)
    if id then
        if cfgs[id] then
            return cfgs[id]
        else
            XLog.Error("请检查配置表Share/Equip/EquipResonance.tab，未配置行Id = " .. tostring(id))
        end
    else
        return cfgs
    end
end

function XEquipModel:GetConfigEquipResonanceUseItem(id)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.EquipResonanceUseItem)
    if id then
        if cfgs[id] then
            return cfgs[id]
        else
            XLog.Error("请检查配置表Share/Equip/EquipResonanceUseItem.tab，未配置行Id = " .. tostring(id))
        end
    else
        return cfgs
    end
end

function XEquipModel:GetConfigWeaponSkill(id)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.WeaponSkill)
    if id then
        if cfgs[id] then
            return cfgs[id]
        else
            XLog.Error("请检查配置表Share/Equip/WeaponSkill.tab，未配置行Id = " .. tostring(id))
        end
    else
        return cfgs
    end
end

function XEquipModel:GetConfigWeaponSkillPool(id)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.WeaponSkillPool)
    if id then
        if cfgs[id] then
            return cfgs[id]
        else
            XLog.Error("请检查配置表Share/Equip/WeaponSkillPool.tab，未配置行Id = " .. tostring(id))
        end
    else
        return cfgs
    end
end

function XEquipModel:GetConfigEquipAwake(id)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.EquipAwake)
    if id then
        if cfgs[id] then
            return cfgs[id]
        else
            XLog.Error("请检查配置表Share/Equip/EquipAwake.tab，未配置行Id = " .. tostring(id))
        end
    else
        return cfgs
    end
end

function XEquipModel:GetConfigCharacterSuitPriority(id)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.CharacterSuitPriority)
    if id then
        return cfgs[id]
    else
        return cfgs
    end
end

function XEquipModel:GetConfigEquipRes(id)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.EquipRes)
    if id then
        if cfgs[id] then
            return cfgs[id]
        else
            XLog.Error("请检查配置表Client/Equip/EquipRes.tab，未配置行Id = " .. tostring(id))
        end
    else
        return cfgs
    end
end

function XEquipModel:GetConfigEquipModel(id)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.EquipModel)
    if id then
        if cfgs[id] then
            return cfgs[id]
        else
            XLog.Error("请检查配置表Client/Equip/EquipModel.tab，未配置行Id = " .. tostring(id))
        end
    else
        return cfgs
    end
end

function XEquipModel:GetConfigEquipModelTransform(id)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.EquipModelTransform)
    if id then
        if cfgs[id] then
            return cfgs[id]
        else
            XLog.Error("请检查配置表Client/Equip/EquipModelTransform.tab，未配置行Id = " .. tostring(id))
        end
    else
        return cfgs
    end
end

function XEquipModel:GetConfigEquipSkipId(id)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.EquipSkipId)
    if id then
        if cfgs[id] then
            return cfgs[id]
        else
            XLog.Error("请检查配置表Client/Equip/EquipSkipId.tab，未配置行Id = " .. tostring(id))
        end
    else
        return cfgs
    end
end

function XEquipModel:GetConfigEquipAnim(id)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.EquipAnim)
    if id then
        if cfgs[id] then
            return cfgs[id]
        else
            XLog.Error("请检查配置表Client/Equip/EquipAnim.tab，未配置行Id = " .. tostring(id))
        end
    else
        return cfgs
    end
end

function XEquipModel:GetConfigEquipModelShow(id)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.EquipModelShow)
    if id then
        if cfgs[id] then
            return cfgs[id]
        else
            XLog.Error("请检查配置表Client/Equip/EquipModelShow.tab，未配置行Id = " .. tostring(id))
        end
    else
        return cfgs
    end
end

function XEquipModel:GetConfigEquipResByFool(id)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.EquipResByFool)
    if id then
        if cfgs[id] then
            return cfgs[id]
        else
            XLog.Error("请检查配置表Client/Equip/EquipResByFool.tab，未配置行Id = " .. tostring(id))
        end
    else
        return cfgs
    end
end

function XEquipModel:GetConfigWeaponDeregulateUI(id)
    local cfgs = self._ConfigUtil:GetByTableKey(TableKey.WeaponDeregulateUI)
    if id then
        if cfgs[id] then
            return cfgs[id]
        else
            XLog.Error("请检查配置表Client/Equip/WeaponDeregulateUI.tab，未配置行Lv = " .. tostring(id))
        end
    else
        return cfgs
    end
end

-- 获取武器对应所有超限配置
function XEquipModel:GetWeaponOverrunCfgsByTemplateId(templateId)
    if not self.WeaponOverrunDic then
        self:InitWeaponOverrunCfgs()
    end

    local cfgs = self.WeaponOverrunDic[templateId]
    return cfgs
end

-- 获取等级配置表
function XEquipModel:GetLevelUpCfg(templateId, times, level)
    local breakthroughCfg = self:GetEquipBreakthroughCfg(templateId, times)
    if not breakthroughCfg then
        return
    end

    local key = self.LevelUpTableKey[breakthroughCfg.LevelUpTemplateId]
    local cfgs = self._ConfigUtil:GetByTableKey(key)
    if not cfgs then
        XLog.ErrorTableDataNotFound("XEquipModel.GetLevelUpCfg", "template", "Share/Equip/LevelUpTemplate/", "levelUpTemplateId", tostring(breakthroughCfg.LevelUpTemplateId))
        return
    end

    local config = cfgs[level]
    if not config then
        XLog.ErrorTableDataNotFound("XEquipModel.GetLevelUpCfg", "level", "Share/Equip/LevelUpTemplate/"..tostring(breakthroughCfg.LevelUpTemplateId)..".tab", 
            "level", tostring(level))
        return
    end

    return config
end
----------配置表 end----------

return XEquipModel

local XBWOtherSetting = require("XModule/XBigWorldSet/XSetting/XBWOtherSetting")
local XBWAudioSetting = require("XModule/XBigWorldSet/XSetting/XBWAudioSetting")
local XBWGraphicsSetting = require("XModule/XBigWorldSet/XSetting/XBWGraphicsSetting")
local XBWSetTypeData = require("XModule/XBigWorldSet/XData/XBWSetTypeData")

---@class XBigWorldSetModel : XModel
local XBigWorldSetModel = XClass(XModel, "XBigWorldSetModel")

local TableKey = {
    BigWorldSetType = {
        DirPath = XConfigUtil.DirectoryType.Client,
        Identifier = "Type",
    },
}

function XBigWorldSetModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    ---@type table<number, XBWSetTypeData>
    self._TypeDataCache = {}

    ---@type table<number, XBWSettingBase>
    self._SettingCache = {}
    
    self._MaxScreenOff = false
    self._ScreenOffValue = 0

    self._ConfigUtil:InitConfigByTableKey("BigWorld/Common/Set", TableKey)
end

function XBigWorldSetModel:ClearPrivate()
    --这里执行内部数据清理
    -- XLog.Error("请对内部数据进行清理")
end

function XBigWorldSetModel:ResetAll()
    --这里执行重登数据清理
    -- XLog.Error("重登数据清理")
end

-- region Config

---@return XTableBigWorldSetType[]
function XBigWorldSetModel:GetBigWorldSetTypeConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.BigWorldSetType) or {}
end

---@return XTableBigWorldSetType
function XBigWorldSetModel:GetBigWorldSetTypeConfigByType(type)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.BigWorldSetType, type, false) or {}
end

function XBigWorldSetModel:GetBigWorldSetTypeTypeNameByType(type)
    local config = self:GetBigWorldSetTypeConfigByType(type)

    return config.TypeName
end

function XBigWorldSetModel:GetBigWorldSetTypePriorityByType(type)
    local config = self:GetBigWorldSetTypeConfigByType(type)

    return config.Priority
end

function XBigWorldSetModel:GetBigWorldSetTypeIconByType(type)
    local config = self:GetBigWorldSetTypeConfigByType(type)

    return config.Icon
end

function XBigWorldSetModel:GetBigWorldSetTypeUiNameByType(type)
    local config = self:GetBigWorldSetTypeConfigByType(type)

    return config.UiName
end

function XBigWorldSetModel:GetBigWorldSetTypePcUiNameByType(type)
    local config = self:GetBigWorldSetTypeConfigByType(type)

    return config.PcUiName
end

-- endregion

function XBigWorldSetModel:GetMaxScreenOff()
    if not self._MaxScreenOff then
        self._MaxScreenOff = CS.XGame.ClientConfig:GetFloat("SpecialScreenOff")
    end

    return self._MaxScreenOff
end

function XBigWorldSetModel:SetSpecialScreenOff(value)
    local maxScreenOff = self:GetMaxScreenOff()

    self._ScreenOffValue = value * maxScreenOff
    CS.XUiSafeAreaAdapter.SetSpecialScreenOff(self._ScreenOffValue)
    XDataCenter.SetManager.SetAdaptorScreenChange()
end

function XBigWorldSetModel:GetSpecialScreenOff()
    return self._ScreenOffValue or 0
end

---@return XBWSetTypeData
function XBigWorldSetModel:GetSetTypeData(setType)
    local typeData = self._TypeDataCache[setType]

    if not typeData then
        local config = self:GetBigWorldSetTypeConfigByType(setType)
        
        typeData = XBWSetTypeData.New(config)
        self._TypeDataCache[setType] = typeData
    end

    return typeData
end

---@return XBWSettingBase
function XBigWorldSetModel:GetSettingBySetType(setType)
    local setting = self._SettingCache[setType]

    if not setting then
        setting = self:CreateSettingBySetType(setType)
        self._SettingCache[setType] = setting
    else
        setting:InitValue()
    end

    return setting
end

---@return XBWSettingBase
function XBigWorldSetModel:CreateSettingBySetType(setType)
    if setType == XEnumConst.BWSetting.SetType.Other then
        return XBWOtherSetting.New()
    elseif setType == XEnumConst.BWSetting.SetType.Voice then
        return XBWAudioSetting.New()
    elseif setType == XEnumConst.BWSetting.SetType.Graphics then
        return XBWGraphicsSetting.New()
    end
end

return XBigWorldSetModel
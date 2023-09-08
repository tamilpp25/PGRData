---@class XSubPackageModel : XModel
---@field _SubpackageDict table<number, XSubpackage>
local XSubPackageModel = XClass(XModel, "XSubPackageModel")

local XSubpackage

local TableKey = {
    --分包分组
    SubPackageGroup = { CacheType = XConfigUtil.CacheType.Normal, DirPath = XConfigUtil.DirectoryType.Client },
    --分包
    SubPackage = { CacheType = XConfigUtil.CacheType.Normal, DirPath = XConfigUtil.DirectoryType.Client },
    --分包拦截检测
    SubPackageIntercept = { CacheType = XConfigUtil.CacheType.Temp ,DirPath = XConfigUtil.DirectoryType.Client, Identifier = "EntryType" },
    --语言拦截
    SubPackageVoiceIntercept = {CacheType = XConfigUtil.CacheType.Normal, DirPath = XConfigUtil.DirectoryType.Client },
}

function XSubPackageModel:OnInit()
    self._ConfigUtil:InitConfigByTableKey("DlcRes", TableKey)

    self._SubpackageDict = {}
    
    self._SubId2GroupId = {}
    
    self._SubIntercept = nil

    self._IsDlcBuild = CS.XInfo.IsDlcBuild

    self._LaunchType = CS.XRemoteConfig.LaunchSelectType
end

function XSubPackageModel:IsOpen()
    --PC暂时不开分包下载
    if XDataCenter.UiPcManager.IsPc() then
        return false
    end

    if not self:CheckChannelEnable() then
        return false
    end
    
    return self._IsDlcBuild and (self._LaunchType and self._LaunchType ~= 0) and not XUiManager.IsHideFunc
end

function XSubPackageModel:CheckChannelEnable()
    local channelId = CS.XHeroSdkAgent.GetAppChannelId()
    if string.IsNilOrEmpty(channelId) then
        return true
    end
    
    local channels = CS.XRemoteConfig.SubPackAppChannel --字符串，直接判断是否包含对应Id
    if string.IsNilOrEmpty(channels) then
        return true
    end
    
    return string.find(channels, channelId)
end

function XSubPackageModel:ClearPrivate()
    self:ClearTemp()
end

function XSubPackageModel:ResetAll()
    self:ClearTemp()
end

function XSubPackageModel:ClearTemp()
    self._GroupIdList = nil
end

function XSubPackageModel:GetGroupIdList()
    if self._GroupIdList then
        return self._GroupIdList
    end

    local list = {}

    ---@type table<number, XTableSubPackageGroup>
    local templates = self._ConfigUtil:GetByTableKey(TableKey.SubPackageGroup)
    for id, _ in pairs(templates) do
        table.insert(list, id)
    end

    table.sort(list, function(a, b)
        return a < b
    end)

    self._GroupIdList = list

    return list
end

function XSubPackageModel:InitSubIntercept()
    self._SubIntercept = {}
    ---@type table<number, XTableSubPackageIntercept>
    local templates = self._ConfigUtil:GetByTableKey(TableKey.SubPackageIntercept)
    for _, template in pairs(templates) do
        if not self._SubIntercept[template.EntryType] then
            self._SubIntercept[template.EntryType] = {}
        end
        for _, param in pairs(template.Params) do
            self._SubIntercept[template.EntryType][param] = param
        end
    end
end

--- 获取分包组配置
---@param groupId number 组Id
---@return XTableSubPackageGroup
--------------------------
function XSubPackageModel:GetGroupTemplate(groupId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SubPackageGroup, groupId)
end

--- 获取分包配置
---@param subpackageId number
---@return XTableSubPackage
--------------------------
function XSubPackageModel:GetSubpackageTemplate(subpackageId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SubPackage, subpackageId)
end

function XSubPackageModel:GetSubPackageName(subpackageId)
    local template = self:GetSubpackageTemplate(subpackageId)
    return template and template.Name or "???"
end

---@return XSubpackage
function XSubPackageModel:GetSubpackageItem(subpackageId)
    local item = self._SubpackageDict[subpackageId]
    if not item then
        if not XSubpackage then
            XSubpackage = require("XModule/XSubPackage/XEntity/XSubpackage")
        end
        item = XSubpackage.New(subpackageId)
        self._SubpackageDict[subpackageId] = item
    end

    return item
end

function XSubPackageModel:CheckIntercept(entryType, param)
    --不填，默认需要拦截检测
    if not entryType then
        return true
    end
    if not self._SubIntercept then
        self:InitSubIntercept()
    end
    --不存在类型，不拦截
    if not self._SubIntercept[entryType] then
        return false
    end
    if not self._SubIntercept[entryType][param] then
        return true
    end
    return false
end

function XSubPackageModel:GetSubpackageGroupId(subpackageId)
    if not XTool.IsTableEmpty(self._SubId2GroupId) then
        return self._SubId2GroupId[subpackageId]
    end
    self._SubId2GroupId = {}

    ---@type table<number, XTableSubPackageGroup>
    local templates = self._ConfigUtil:GetByTableKey(TableKey.SubPackageGroup)
    for _, template in pairs(templates) do
        for _, subId in pairs(template.SubPackageId) do
            self._SubId2GroupId[subId] = template.Id
        end
    end
    
    return self._SubId2GroupId[subpackageId]
end

---@return XTableSubPackageVoiceIntercept
function XSubPackageModel:GetVoiceIntercept(cvType)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SubPackageVoiceIntercept, cvType)
end

function XSubPackageModel:GetCookieKey(key)
    --资源只与包体有关，跟账号无关联
    return string.format("SUBPACKAGE_LOCAL_RECORD_%s", key)
end

function XSubPackageModel:GetWifiAutoSelect(groupId)
    local key = self:GetCookieKey("WIFI_SELECT" .. groupId)
    local data = XSaveTool.GetData(key)
    if not data then
        return false
    end
    return data
end

function XSubPackageModel:SaveWifiAutoSelect(groupId, value)
    local key = self:GetCookieKey("WIFI_SELECT" .. groupId)
    XSaveTool.SaveData(key, value)
end

return XSubPackageModel
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
    SubPackageIntercept = { CacheType = XConfigUtil.CacheType.Temp ,DirPath = XConfigUtil.DirectoryType.Client },
}

function XSubPackageModel:OnInit()
    self._ConfigUtil:InitConfigByTableKey("DlcRes", TableKey)

    self._SubpackageDict = {}

    self._NecessarySubIds = nil --必要资源

    self._SubId2GroupId = {}

    self._SubIntercept = nil

    self._IsDlcBuild = CS.XInfo.IsDlcBuild

    self._LaunchType = CS.XRemoteConfig.LaunchSelectType
end

function XSubPackageModel:ClearPrivate()
    self:ClearTemp()
end

function XSubPackageModel:ResetAll()
    self:ClearTemp()
end

function XSubPackageModel:ClearTemp()
    self._GroupIdList = nil
    self._NecessarySubIds = nil
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
        if XTool.IsTableEmpty(template.Params) then
            self._SubIntercept[template.EntryType][0] = template.SubPackageId
        else
            for _, param in pairs(template.Params) do
                self._SubIntercept[template.EntryType][param] = template.SubPackageId
            end
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

function XSubPackageModel:GetSubpackageIndex(subpackageId)
    local template = self:GetSubpackageTemplate(subpackageId)
    return template and template.Index or "???"
end

---@return XSubpackage
function XSubPackageModel:GetSubpackageItem(subpackageId)
    local groupId = self:GetSubpackageGroupId(subpackageId)
    if not groupId then
        XLog.Warning("Could not found subpackageId = " .. tostring(subpackageId))
        return
    end
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

function XSubPackageModel:GetNecessarySubIds()
    if self._NecessarySubIds then
        return self._NecessarySubIds
    end
    ---@type table<number, XTableSubPackage>
    local templates = self._ConfigUtil:GetByTableKey(TableKey.SubPackage)
    local nType = XEnumConst.SUBPACKAGE.SUBPACKAGE_TYPE.NECESSARY
    local list = {}
    for _, template in pairs(templates) do
        if template.Type == nType then
            table.insert(list, template.Id)
        end
    end
    
    table.sort(list, function(a, b)
        local templateA = self:GetSubpackageTemplate(a)
        local templateB = self:GetSubpackageTemplate(b)
        return templateA.Index < templateB.Index
    end)
    
    self._NecessarySubIds = list

    return self._NecessarySubIds
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

function XSubPackageModel:GetEntrySubpackageId(entryType, param)
    --不填，检测必要资源
    if not entryType then
        return XEnumConst.SUBPACKAGE.CUSTOM_SUBPACKAGE_ID.NECESSARY
    end
    param = param or 0
    if not self._SubIntercept then
        self:InitSubIntercept()
    end
    if not self._SubIntercept[entryType] then
        return XEnumConst.SUBPACKAGE.CUSTOM_SUBPACKAGE_ID.INVALID
    end
    local subId = self._SubIntercept[entryType][param]
    --未找到，检测必要资源
    if not subId then
        return XEnumConst.SUBPACKAGE.CUSTOM_SUBPACKAGE_ID.NECESSARY
    end

    return subId
end

--玩法入口依赖的所有Subpackage
function XSubPackageModel:GetAllSubpackageIds(entryType, param)
    local subId = self:GetEntrySubpackageId(entryType, param)
    --不依赖分包
    if subId == XEnumConst.SUBPACKAGE.CUSTOM_SUBPACKAGE_ID.INVALID then
        return nil
    elseif subId == XEnumConst.SUBPACKAGE.CUSTOM_SUBPACKAGE_ID.NECESSARY then
        return self:GetNecessarySubIds()
    else
        local template = self:GetSubpackageTemplate(subId)
        local list = { subId }
        for _, id in ipairs(template.BindSubIds or {}) do
            table.insert(list, id)
        end
        return list
    end
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
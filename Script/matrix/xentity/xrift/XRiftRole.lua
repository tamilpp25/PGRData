local XBaseRole = require("XEntity/XRole/XBaseRole")

---@class XRiftRole 大秘境【角色】实例（含机器人和自用角色）
local XRiftRole = XClass(XBaseRole, "XRiftRole")

function XRiftRole:Ctor(rawData)
    self.RawData = rawData
    self.Id = self:GetCharacterId() --方便筛选
    -- 服务器下发确认的数据
    self.s_AllEntityPlugInList = {} --插件实例
    self.s_AllPluginIds = {}
end

-- 最终显示的战力
function XRiftRole:GetFinalShowAbility()
    local orgAbility = self:GetAbility() --角色初始战力
    local pluginAbility = 0 -- 插件加成战力
    for k, xPlugin in pairs(self:GetPlugIns()) do
        pluginAbility = pluginAbility + xPlugin:GetAbility() --插件基础战力
    end
    local xAttrTemplate = XDataCenter.RiftManager.GetAttrTemplate(XRiftConfig.DefaultAttrTemplateId)

    return orgAbility + pluginAbility + xAttrTemplate:GetAbility()
end

-- 加点倾向(仅客户端显示，不会影响任何数据)
function XRiftRole:GetAttrTypeName()
    local charId = self:GetCharacterId()
    local allConfigs = XRiftConfig.GetAllConfigs(XRiftConfig.TableKey.RiftCharacterAndRobot)
    local config = allConfigs[charId]
    if not config then
        return nil
    end

    local allAttr = XRiftConfig.GetAllConfigs(XRiftConfig.TableKey.RiftTeamAttribute)
    local attrTypeName = allAttr[config.AttrType].Name
    return attrTypeName, config.AttrType
end

-- 当前装备的总插件负载
function XRiftRole:GetCurrentLoad()
    local load = 0
    for i, xPlugin in pairs(self:GetPlugIns()) do
        load = load + xPlugin.Config.Load
    end
    return load
end

-- 是否达到插件负载上限
function XRiftRole:CheckLoadLimit()
    return self:GetCurrentLoad() >= XDataCenter.RiftManager.GetMaxLoad()
end

-- 加上是否达到插件负载上限
function XRiftRole:CheckLoadLimitAddPlugin(pluginId)
    local addXPlugin = XDataCenter.RiftManager.GetPlugin(pluginId)
    return self:GetCurrentLoad() + addXPlugin.Config.Load > XDataCenter.RiftManager.GetMaxLoad()
end

function XRiftRole:SyncPlugInIds(data)
    -- 插入新的插件
    self.s_AllPluginIds = data
    local pluginCount = #data
    if pluginCount < #self.s_AllEntityPlugInList then --删除多余的插件
        for i = pluginCount + 1, #self.s_AllEntityPlugInList do
            self.s_AllEntityPlugInList[i] = nil
        end
    end

    for i, pluginId in pairs(data) do
        local xPlugin = self.s_AllEntityPlugInList[i]
        if xPlugin and xPlugin:GetId() == pluginId then
            -- nothing
        else
            self.s_AllEntityPlugInList[i] = XDataCenter.RiftManager.GetPlugin(pluginId)
        end
    end
end

function XRiftRole:GetPlugIns()
    return self.s_AllEntityPlugInList
end

function XRiftRole:GetPlugInIdList()
    return self.s_AllPluginIds
end

-- 检查是否有更高级的插件获得(在成员界面里对应角色的Add按钮红点)
function XRiftRole:CheckHasUpgradePluginRedpoint()
    for k, xPlugin in pairs(XDataCenter.RiftManager.GetAllPlugin()) do
        if xPlugin:GetHave() and xPlugin.Config.CharacterId == self:GetCharacterId() and xPlugin:GetCharacterUpgradeRedpoint() then
            return true
        end
    end
end

-- 清除红点提示
function XRiftRole:ClearUpgradePluginRedpoint()
    for k, xPlugin in pairs(XDataCenter.RiftManager.GetAllPlugin()) do
        if xPlugin:GetHave() and xPlugin.Config.CharacterId == self:GetCharacterId() then
            xPlugin:SetCharacterUpgradeRedpoint(false)
        end
    end
end

function XRiftRole:CheckHasPlugin(pluginId)
    return table.contains(self.s_AllPluginIds, pluginId)
end

return XRiftRole
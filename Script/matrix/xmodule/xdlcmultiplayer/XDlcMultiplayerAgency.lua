local XDlcMultiplayerConfigAgency = require("XModule/XDlcMultiplayer/XDlcMultiplayerConfigAgency")

---@class XDlcMultiplayerAgency : XDlcMultiplayerConfigAgency
---@field private _Model XDlcMultiplayerModel
local XDlcMultiplayerAgency = XClass(XDlcMultiplayerConfigAgency, "XDlcMultiplayerAgency")

function XDlcMultiplayerAgency:OnInit()
    --初始化一些变量

    --设置C#委托
    CS.StatusSyncFight.XFightDelegate.GetDlcMultiplayerSkill = Handler(self, self.CSGetDlcMultiplayerSkillConfigById)
end

function XDlcMultiplayerAgency:OnRelease()
    --移除C#委托
    CS.StatusSyncFight.XFightDelegate.GetDlcMultiplayerSkill = nil
end

function XDlcMultiplayerAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
end

function XDlcMultiplayerAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

---@return XTableDlcMultiplayerActivity
function XDlcMultiplayerAgency:GetDlcMultiplayerActivityConfigById(id)
    return self._Model:GetDlcMultiplayerActivityConfigById(id)
end

function XDlcMultiplayerAgency:GetDlcMultiplayerSkillConfigById(id)
    return self._Model:GetDlcMultiplayerSkillConfigById(id)
end

function XDlcMultiplayerAgency:CSGetDlcMultiplayerSkillConfigById(id)
    local config = self:GetDlcMultiplayerSkillConfigById(id)
    local obj = CS.StatusSyncFight.XDlcMultiplayerSkill()
    obj.Id = config.Id
    obj.InitMagicId = config.InitMagicId
    obj.MagicId = config.MagicId
    obj.Icon  = config.Icon
    return obj
end

---@return XTableDlcMultiplayerChapter
function XDlcMultiplayerAgency:GetDlcMultiplayerChapterConfigById(id)
    return self._Model:GetDlcMultiplayerChapterConfigById(id)
end

---@return XTableDlcMultiplayerChapterGroup
function XDlcMultiplayerAgency:GetDlcMultiplayerChapterGroupConfigById(id)
    return self._Model:GetDlcMultiplayerChapterGroupConfigById(id)
end

---@return XTableDlcMultiPlayerCharacter
function XDlcMultiplayerAgency:GetDlcMultiplayerCharacterConfigById(id)
    return self._Model:GetDlcMultiplayerCharacterConfigById(id)
end

---@return XTableDlcMultiplayerCharacterPool
function XDlcMultiplayerAgency:GetDlcMultiplayerCharacterPoolConfigById(id)
    return self._Model:GetDlcMultiplayerCharacterPoolConfigById(id)
end

---@return XTableDlcMultiplayerWorld
function XDlcMultiplayerAgency:GetDlcMultiplayerWorldConfigById(worldId)
    return self._Model:GetDlcMultiplayerWorldConfigById(worldId)
end

---@return XTableDlcMultiplayerTitle
function XDlcMultiplayerAgency:GetDlcMultiplayerTitleConfigById(id)
    return self._Model:GetDlcMultiplayerTitleConfigById(id)
end

---@return XTableDlcMultiplayerTitleGroup
function XDlcMultiplayerAgency:GetDlcMultiplayerTitleGroupConfigById(id)
    return self._Model:GetDlcMultiplayerTitleGroupConfigById(id)
end

---@return XTableDlcMultiplayerConfig
function XDlcMultiplayerAgency:GetDlcMultiplayerConfigConfigByKey(key)
    return self._Model:GetDlcMultiplayerConfigConfigByKey(key)
end

function XDlcMultiplayerAgency:RegisterPrivateConfig(moduleId, tableName)
    self._Model:RegisterActivityPrivateConfig(moduleId, tableName)
end

function XDlcMultiplayerAgency:LoadPrivateConfig(moduleId)
    self._Model:LoadActivityPrivateConfig(moduleId)
end

function XDlcMultiplayerAgency:ClearPrivateConfig(moduleId)
    self._Model:ClearActivityPrivateConfig(moduleId)
end

return XDlcMultiplayerAgency
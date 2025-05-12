---@class XFightCaptureV217Model : XModel
local XFightCaptureV217Model = XClass(XModel, "XFightCaptureV217Model")

local TableKey = {
    --- 角色动作
    CaptureV217NpcAction = { DirPath = XConfigUtil.DirectoryType.Client, },
    --- 屏幕特效
    CaptureV217ScreenEffect = { DirPath = XConfigUtil.DirectoryType.Client, },
    --- 镜头参数
    CaptureV217Camera = { DirPath = XConfigUtil.DirectoryType.Client, },
    --- 贴纸
    CaptureV217Sticker = { DirPath = XConfigUtil.DirectoryType.Client, },
}

function XFightCaptureV217Model:OnInit()
    self._ConfigUtil:InitConfigByTableKey("Fight/CaptureV217", TableKey)
    -- 动作配置id字典，key：GroupId，value：Id列表
    self.ActionDic = {}
    -- 贴纸配置id字典，key：GroupId，value：Id列表
    self.StickerDic = {}
end

function XFightCaptureV217Model:ClearPrivate()
end

function XFightCaptureV217Model:ResetAll()
end

--region Cfg - CaptureV217Camera
function XFightCaptureV217Model:GetCameraParams(id)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.CaptureV217Camera, id)
    return config and config.Params
end
--endregion

--region Cfg - CaptureV217NpcAction
function XFightCaptureV217Model:GetActionIdList(groupId)
    if XTool.IsTableEmpty(self.ActionDic) then
        for id, cfg in pairs(self._ConfigUtil:GetByTableKey(TableKey.CaptureV217NpcAction)) do
            if not self.ActionDic[cfg.GroupId] then
                self.ActionDic[cfg.GroupId] = {}
            end
            table.insert(self.ActionDic[cfg.GroupId], id)
        end
    end
    
    return self.ActionDic[groupId]
end

---@return XTableCaptureV217NpcAction
function XFightCaptureV217Model:GetActionCfg(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.CaptureV217NpcAction, id)
end

function XFightCaptureV217Model:GetActionName(id)
    local cfg = self:GetActionCfg(id)
    return cfg and cfg.ActionName
end

function XFightCaptureV217Model:GetActionUnlockDesc(id)
    local cfg = self:GetActionCfg(id)
    return cfg and cfg.UnlockDesc
end

function XFightCaptureV217Model:GetPlayParams(id)
    local cfg = self:GetActionCfg(id)
    return cfg and cfg.PlayParams
end
--endregion

--region Cfg - CaptureV217Sticker
function XFightCaptureV217Model:GetStickerIdList(groupId)
    if XTool.IsTableEmpty(self.StickerDic) then
        for id, cfg in pairs(self._ConfigUtil:GetByTableKey(TableKey.CaptureV217Sticker)) do
            if not self.StickerDic[cfg.GroupId] then
                self.StickerDic[cfg.GroupId] = {}
            end
            table.insert(self.StickerDic[cfg.GroupId], id)
        end
    end

    return self.StickerDic[groupId]
end

---@return XTableCaptureV217Sticker
function XFightCaptureV217Model:GetStickerCfg(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.CaptureV217Sticker, id)
end

function XFightCaptureV217Model:GetStickerCfgSmallIconPath(id)
    local cfg = self:GetStickerCfg(id)
    return cfg and cfg.SmallIconPath
end

function XFightCaptureV217Model:GetStickerCfgIconPath(id)
    local cfg = self:GetStickerCfg(id)
    return cfg and cfg.IconPath
end

function XFightCaptureV217Model:GetStickerCfgUnlockDesc(id)
    local cfg = self:GetStickerCfg(id)
    return cfg and cfg.UnlockDesc
end

function XFightCaptureV217Model:GetStickerCfgWidth(id)
    local cfg = self:GetStickerCfg(id)
    return cfg and cfg.Width
end

function XFightCaptureV217Model:GetStickerCfgHeight(id)
    local cfg = self:GetStickerCfg(id)
    return cfg and cfg.Height
end

function XFightCaptureV217Model:GetStickerCfgDefaultScale(id)
    local cfg = self:GetStickerCfg(id)
    return cfg and cfg.DefaultScale
end

function XFightCaptureV217Model:GetStickerCfgMaxScale(id)
    local cfg = self:GetStickerCfg(id)
    return cfg and cfg.MaxScale
end

function XFightCaptureV217Model:GetStickerCfgMinScale(id)
    local cfg = self:GetStickerCfg(id)
    return cfg and cfg.MinScale
end
--endregion

--region Cfg - CaptureV217ScreenEffect
function XFightCaptureV217Model:GetScreenEffectIdList()
    if not XTool.IsTableEmpty(self.ScreenEffectIdList) then
        return self.ScreenEffectIdList
    end

    self.ScreenEffectIdList = {}
    for id in pairs(self._ConfigUtil:GetByTableKey(TableKey.CaptureV217ScreenEffect)) do
        table.insert(self.ScreenEffectIdList, id)
    end
    return self.ScreenEffectIdList
end

function XFightCaptureV217Model:GetScreenEffectName(id)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.CaptureV217ScreenEffect, id)
    return config and config.Name
end

function XFightCaptureV217Model:GetScreenEffectPath(id)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.CaptureV217ScreenEffect, id)
    return config and config.Path
end
--endregion

return XFightCaptureV217Model
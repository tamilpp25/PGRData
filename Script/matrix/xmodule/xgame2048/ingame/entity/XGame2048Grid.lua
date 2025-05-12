---@class XGame2048Grid
---@field Uid
---@field protected _GridType
---@field protected _IsMoveable boolean
---@field protected _TypeCfg XTableGame2048BlockType
local XGame2048Grid = XClass(nil, 'XGame2048Grid')

--- 初始化数据，游戏初始化时调用
---@param blockCfg XTableGame2048Block
function XGame2048Grid:InitData(data, blockCfg, typeCfg)
    self.Id = data.BlockId
    self._Cfg = blockCfg
    self._TypeCfg = typeCfg
    self._X = data.X
    self._Y = data.Y
    
    if blockCfg.Type == XMVCA.XGame2048.EnumConst.GridType.Rock then
        self._Value = data.Value
    else
        self._Value = blockCfg.Level
    end
    
    self._ExtValue = data.ExtValue
    self._ServerData = data
end

function XGame2048Grid:GetConfig()
    return self._Cfg
end

function XGame2048Grid:GetTypeCfg()
    return self._TypeCfg
end

function XGame2048Grid:GetGridType()
    return self._Cfg.Type
end

function XGame2048Grid:IsMoveableGrid()
    return self._TypeCfg.CanMove
end

function XGame2048Grid:IsMergeable()
    return self._TypeCfg.CanMerge
end

function XGame2048Grid:GetX()
    return self._X
end

function XGame2048Grid:GetY()
    return self._Y
end

function XGame2048Grid:GetValue()
    return self._Value or 0
end

function XGame2048Grid:GetExValue()
    return self._ExtValue or 0
end

function XGame2048Grid:GetScore()
    return self._Cfg.AddScore
end

function XGame2048Grid:GetLevelUpId()
    return self._Cfg.LevelUpId
end

function XGame2048Grid:GetDoublingLevelUpId()
    return self._Cfg.DoublingLevelUpId
end

-- 合成移动期间使用，判断是否禁止移动，目前主要用于冰块合成
function XGame2048Grid:GetIsMoveLock()
    return self._IsMoveLock
end

function XGame2048Grid:SetNewPosition(x, y)
    self._X = x
    self._Y = y
end

function XGame2048Grid:GetServerData()
    return self._ServerData
end

---@param blockCfg XTableGame2048Block
function XGame2048Grid:SetNewConfig(blockCfg, typeCfg)
    self.Id = blockCfg.Id
    self._Cfg = blockCfg
    self._TypeCfg = typeCfg
    if blockCfg.Type == XMVCA.XGame2048.EnumConst.GridType.Rock then
        self._Value = blockCfg.HitTimes
    else
        self._Value = blockCfg.Level
    end
end

function XGame2048Grid:SetServerData(data)
    self._ServerData = data
end

function XGame2048Grid:SetValue(newValue)
    self._Value = newValue
end

function XGame2048Grid:SetExValue(newExValue)
    self._ExtValue = newExValue
end

-- 合成移动期间使用，设置是否禁止移动，目前主要用于冰块合成
function XGame2048Grid:SetMoveLock(isLock)
    self._IsMoveLock = isLock
end

function XGame2048Grid:SyncToServerData()
    self._ServerData.BlockId = self.Id
    self._ServerData.X = self._X
    self._ServerData.Y = self._Y
    self._ServerData.Value = self._Value
    self._ServerData.ExtValue = self._ExtValue
end

function XGame2048Grid:OnRecycle()
    self.Id = nil
    self._Cfg = nil
    self._TypeCfg = nil
    self._X = nil
    self._Y = nil
    self._Value = nil
    self._ExtValue = nil
    self._IsMoveLock = nil
    self._ServerData = nil
end

return XGame2048Grid
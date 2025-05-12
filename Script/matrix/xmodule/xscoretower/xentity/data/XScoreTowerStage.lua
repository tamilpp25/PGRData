---@class XScoreTowerStage
local XScoreTowerStage = XClass(nil, "XScoreTowerStage")

function XScoreTowerStage:Ctor()
    -- ScoreTowerStage表Id
    self.CfgId = 0
    self.FloorId = 0
    -- 当前插件点数
    self.PlugInPoint = 0
    -- 当前关卡分数
    self.CurPoint = 0
    -- 当前关卡星级
    self.CurStar = 0
    -- 是否已通关
    self.IsPass = false
    -- 选择的插件索引
    ---@type number[]
    self.SelectedPlugIndex = {}
end

function XScoreTowerStage:NotifyScoreTowerStage(data)
    self.CfgId = data.CfgId or 0
    self.FloorId = data.FloorId or 0
    self.PlugInPoint = data.PlugInPoint or 0
    self.CurPoint = data.CurPoint or 0
    self.CurStar = data.CurStar or 0
    self.IsPass = data.IsPass or false
    self.SelectedPlugIndex = data.SelectedPlugIndex or {}
end

--region 数据更新

-- 更新插件索引
function XScoreTowerStage:UpdateSelectedPlugIndex(plugIndex)
    self.SelectedPlugIndex = plugIndex or {}
end

--endregion

--region 数据获取

-- 获取配置Id
function XScoreTowerStage:GetCfgId()
    return self.CfgId
end

-- 获取层Id
function XScoreTowerStage:GetFloorId()
    return self.FloorId
end

-- 获取插件点数
function XScoreTowerStage:GetPlugInPoint()
    return self.PlugInPoint
end

-- 获取当前关卡分数
function XScoreTowerStage:GetCurPoint()
    return self.CurPoint
end

-- 获取当前关卡星级
function XScoreTowerStage:GetCurStar()
    return self.CurStar
end

-- 是否已通关
function XScoreTowerStage:GetIsPass()
    return self.IsPass
end

-- 获取选择的插件索引
function XScoreTowerStage:GetSelectedPlugIndex()
    return self.SelectedPlugIndex
end

--endregion

return XScoreTowerStage

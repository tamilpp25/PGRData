---@class XRogueSimMap
local XRogueSimMap = XClass(nil, "XRogueSimMap")

function XRogueSimMap:Ctor()
    ---@type XRogueSimMapArea[]
    self.AreaDatas = {}
    ---@type table<number, XRogueSimMapArea>
    self.AreaDataDic = {}
    ---@type XRogueSimMapGrid[]
    self.GridDatas = {}
end

function XRogueSimMap:UpdateMapData(data)
    self.AreaDatas = {}
    self.AreaDataDic = {}
    local XRogueSimMapArea = require("XModule/XRogueSim/XEntity/XRogueSimMapArea")
    for _, v in ipairs(data.AreaDatas) do -- AreaDatas是有顺序的
        local area = XRogueSimMapArea.New(v)
        table.insert(self.AreaDatas, area)
        self.AreaDataDic[area.Id] = area
    end

    self.GridDatas = {}
    self:AddMapGridDatas(data.GridDatas)
end

-- 更新区域数据
function XRogueSimMap:UpdateMapAreaData(data)
    local area = self.AreaDataDic[data.Id]
    area:UpdateData(data)
end

-- 设置区域已解锁
function XRogueSimMap:SetAreaIsUnlock(areaId)
    local area = self.AreaDataDic[areaId]
    if area then
        area:SetUnlock()
    else
        XLog.Error(string.format("服务器下发的解锁区域Id:%s，进关卡初始化的时候没下发", areaId))
    end
end

-- 设置区域已获得
function XRogueSimMap:SetAreaIsObtain(areaId)
    local area = self.AreaDataDic[areaId]
    if area then
        area:SetObtain()
    end
end

-- 添加多个格子数据
function XRogueSimMap:AddMapGridDatas(gridDatas)
    for _, v in pairs(gridDatas) do
        self:AddMapGridData(v)
    end
end

-- 添加单个格子数据
function XRogueSimMap:AddMapGridData(data)
    if not data then
        return
    end
    local grid = self.GridDatas[data.Id]
    if not grid then
        grid = require("XModule/XRogueSim/XEntity/XRogueSimMapGrid").New(data)
        self.GridDatas[data.Id] = grid
    else
        grid:UpdateMapGridData(data)
    end
end

---@type XRogueSimMapArea[]
function XRogueSimMap:GetAreaDatas()
    return self.AreaDatas
end

function XRogueSimMap:GetAreaData(areaId)
    return self.AreaDataDic[areaId]
end

function XRogueSimMap:GetGridData(gridId)
    return self.GridDatas[gridId]
end

-- 获得可解锁的区域Id哈希表
function XRogueSimMap:GetAreaIdCanUnlockDic()
    local areaDic = {}
    for _, areaData in ipairs(self.AreaDatas) do
        if areaData.State == XEnumConst.RogueSim.AreaStateType.Locked or areaData.State == XEnumConst.RogueSim.AreaStateType.Unlocked then
            areaDic[areaData.Id] = true
        end
    end
    return areaDic
end

-- 获取已解锁的区域Id哈希表
function XRogueSimMap:GetAreaIdUnlockDic()
    local areaDic = {}
    for _, areaData in ipairs(self.AreaDatas) do
        if areaData.State == XEnumConst.RogueSim.AreaStateType.Unlocked then
            areaDic[areaData.Id] = true
        end
    end
    return areaDic
end

-- 获取已获得区域的数量
function XRogueSimMap:GetObtainAreaCount()
    local count = 0
    for _, areaData in pairs(self.AreaDatas) do
        if areaData:GetIsObtain() then
            count = count + 1
        end
    end
    return count
end

-- 获取已解锁未获得的区域Ids
function XRogueSimMap:GetUnlockNotObtainAreaIds()
    local areaIds = {}
    for _, areaData in pairs(self.AreaDatas) do
        if areaData.State == XEnumConst.RogueSim.AreaStateType.Locked and not areaData:GetIsObtain() then
            table.insert(areaIds, areaData.Id)
        end
    end
    return areaIds
end

-- 获取已获得的区域Ids
function XRogueSimMap:GetObtainAreaIds()
    local areaIds = {}
    for _, areaData in pairs(self.AreaDatas) do
        if areaData:GetIsObtain() then
            table.insert(areaIds, areaData.Id)
        end
    end
    return areaIds
end

return XRogueSimMap

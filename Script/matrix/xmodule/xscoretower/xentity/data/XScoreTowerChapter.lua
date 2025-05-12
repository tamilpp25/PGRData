---@class XScoreTowerChapter
local XScoreTowerChapter = XClass(nil, "XScoreTowerChapter")

function XScoreTowerChapter:Ctor()
    -- 章节Id
    self.ChapterId = 0
    -- 当前正在进行的塔Id
    self.CurTowerId = 0
    -- 当前章节分数
    self.CurPoint = 0
    -- 当前章节星级
    self.CurStar = 0
    -- 塔数据
    ---@type XScoreTowerTower[]
    self.TowerDatas = {}
end

function XScoreTowerChapter:NotifyScoreTowerChapterData(data)
    self.ChapterId = data.ChapterId or 0
    self.CurTowerId = data.CurTowerId or 0
    self.CurPoint = data.CurPoint or 0
    self.CurStar = data.CurStar or 0
    self:UpdateTowerDatas(data.TowerDatas)
end

--region 数据更新

function XScoreTowerChapter:UpdateTowerDatas(data)
    self.TowerDatas = {}
    if not data then
        return
    end
    for _, v in pairs(data) do
        self:AddTowerData(v)
    end
end

function XScoreTowerChapter:AddTowerData(data)
    if not data then
        return
    end
    local towerData = self.TowerDatas[data.TowerId]
    if not towerData then
        towerData = require("XModule/XScoreTower/XEntity/Data/XScoreTowerTower").New()
        self.TowerDatas[data.TowerId] = towerData
    end
    towerData:NotifyScoreTowerTowerData(data)
end

--endregion

--region 数据获取

-- 获取章节Id
function XScoreTowerChapter:GetChapterId()
    return self.ChapterId
end

-- 获取正在进行的塔Id
function XScoreTowerChapter:GetCurTowerId()
    return self.CurTowerId
end

-- 获取当前章节分数
function XScoreTowerChapter:GetCurPoint()
    return self.CurPoint
end

-- 获取当前章节星级
function XScoreTowerChapter:GetCurStar()
    return self.CurStar
end

-- 获取所有的塔数据
---@return XScoreTowerTower[]
function XScoreTowerChapter:GetTowerDatas()
    return self.TowerDatas
end

-- 获取塔数据
---@param towerId number 塔Id
---@return XScoreTowerTower
function XScoreTowerChapter:GetTowerData(towerId)
    return self.TowerDatas[towerId]
end

--endregion

return XScoreTowerChapter

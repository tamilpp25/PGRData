local XCollectionWall = XClass(nil, "XCollectionWall")

--[[
XCollectionWall =
{
    1、Id,                     -- CollectionWall表的Id标识
    2、IsShow,                 -- 是否展示，boolean值
    3、State,                  -- 墙的状态，类型为XCollectionWallConfigs.EnumWallState(服务器不派发，需要客户端自己计算并更新)
    4、BackgroundId,           -- 背景Id，关联表CollectionWallDecoration
    5、PedestalId,             -- 底座Id，关联表CollectionWallDecoration

    6、CollectionSetInfos =    -- 墙上摆放的收藏品
    {
        index = {
            Id,     -- 收藏品Id
            X,      -- 坐标X
            Y,      -- 坐标Y
            SizeId  -- 尺寸Id
        }
    },

    -- 存储在config中的数据
    7、Rank,                   -- 排序值
    8、Name,                   -- 墙的名称
    9、Condition,              -- 解锁条件
}
--]]

function XCollectionWall:Ctor(id)
    self.Id = id
    self.IsShow = true
    self.State = XCollectionWallConfigs.EnumWallState.Lock
    self.BackgroundId = 0
    self.PedestalId = 0

    self.CollectionSetInfos = {}
end

---
--- 根据'data'的内容来更新相应的属性
--- 需要注意的是key的名称和类型要与属性一致
---@param date table
function XCollectionWall:UpdateDate(date)
    for key, value in pairs(date) do
        self[key] = value
    end
end

---
--- 1、获取Id
---@return number
function XCollectionWall:GetId()
    return self.Id
end

---
--- 2、获取是否展示属性
---@return boolean
function XCollectionWall:GetIsShow()
    return self.IsShow
end

---
--- 3、获取状态
---@return boolean
function XCollectionWall:GetState()
    return self.State
end

---
--- 4、获取背景Id
---@return number
function XCollectionWall:GetBackgroundId()
    if self.BackgroundId <= 0 then
        XLog.Error("XCollectionWall:GeBackground函数错误，BackgroundId数据未更新")
        return self:GetCfg().InitBackgroundId
    else
        return self.BackgroundId
    end
end

---
--- 5、获取底座Id
---@return number
function XCollectionWall:GetPedestalId()
    if self.PedestalId <= 0 then
        XLog.Error("XCollectionWall:GePedestal函数错误，PedestalId数据未更新")
        return self:GetCfg().InitPedestalId
    else
        return self.PedestalId
    end
end

---
--- 6、获取摆放的收藏品数组,数据结构在开头的注释说明中有写明
---@return number
function XCollectionWall:GetCollectionSetInfos()
    return self.CollectionSetInfos
end

function XCollectionWall:GetWallPicture(cb)
    if not cb then
        XLog.Error("The ScreenShot API Must Need CallBack")
        return
    end

    local fileName = XDataCenter.CollectionWallManager.GetCaptureImgName(self.Id)
    local textureCache = XDataCenter.CollectionWallManager.GetLocalCaptureCache(fileName)

    if textureCache then
        cb(textureCache)
        return
    end

    CS.XTool.LoadLocalCaptureImgWithoutSuffix(fileName, function(texture)
        XDataCenter.CollectionWallManager.SetLocalCaptureCache(fileName, texture)
        cb(texture)
    end)
end

-----------------------------------------------存储在config中的数据--------------------------------------------------------

function XCollectionWall:GetCfg()
    return XCollectionWallConfigs.GetCollectionWallCfg(self.Id)
end

---
--- 7、从配表中获取排序值
---@return number
function XCollectionWall:GetRank()
    return self:GetCfg().Rank
end

---
--- 8、从配表中获取名称
---@return string
function XCollectionWall:GetName()
    return self:GetCfg().Name
end

---
--- 9、从配表中获取解锁条件
---@return number
function XCollectionWall:GetCondition()
    return self:GetCfg().Condition
end

return XCollectionWall
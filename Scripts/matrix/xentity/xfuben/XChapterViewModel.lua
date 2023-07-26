-- 章节视图数据
---@class XChapterViewModel
local XChapterViewModel = XClass(nil, "XChapterViewModel")

--[[
    config : {
        Id,
        ExtralData : 额外数据
        ExtralName : 额外名字
        Name : 名称
        Icon : 图标
    }
]]
function XChapterViewModel:Ctor(config)
    self.Config = config
    -- 用于新手引导定位
    self.Id = config.Id or 0
end

function XChapterViewModel:GetId()
    return self.Config.Id or 0
end

function XChapterViewModel:GetExtralData()
    return self.Config.ExtralData
end

function XChapterViewModel:GetConfig()
    return self.Config
end

function XChapterViewModel:GetExtralName()
    return self.Config.ExtralName or ""
end

function XChapterViewModel:GetName()
    return self.Config.Name or ""
end

function XChapterViewModel:GetIcon()
    return self.Config.Icon or ""
end

-- 获取进度
function XChapterViewModel:GetProgress()
    return 0
end

-- 获取当前和最大进度值
function XChapterViewModel:GetCurrentAndMaxProgress()
    return 0, 0
end

-- 获取进度提示
function XChapterViewModel:GetProgressTips()
    return ""
end

-- 检查是否有红点提示
function XChapterViewModel:CheckHasRedPoint()
    return false
end

-- 检查是否有新标志，一般规则为已解锁+未通关
function XChapterViewModel:CheckHasNewTag()
    return false
end

-- 检查是否有限时标志，一般规则为有TimeId
function XChapterViewModel:CheckHasTimeLimitTag()
    return false
end

-- 获取周目次数
function XChapterViewModel:GetWeeklyChallengeCount()
    return 0
end

-- 获取是否已锁
function XChapterViewModel:GetIsLocked()
    return false 
end

-- 获取锁提示
function XChapterViewModel:GetLockTip()
    return XUiHelper.GetText("CommonLockedTip")
end

-- 获取运行时间提示
function XChapterViewModel:GetTimeTips()
    return ""
end

-- 检查是否已开启
function XChapterViewModel:CheckIsOpened()
    return true
end

-- 检查是否已通关
function XChapterViewModel:CheckIsPassed()
    return false
end

-- 检测是否在活动时间内
function XChapterViewModel:CheckInTime()
    return true
end

-- 检测该章节是不是隐藏章节
function XChapterViewModel:GetDifficulty()
end

return XChapterViewModel
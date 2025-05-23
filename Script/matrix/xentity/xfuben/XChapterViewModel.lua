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

function XChapterViewModel:GetPriority()
    return self.Config.Priority or 0
end

--- 获取成就图标
function XChapterViewModel:GetAchievementIcon()
    return nil
end

--- 获取成就未解锁图标
function XChapterViewModel:GetAchievementIconLock()
    return nil
end

--- 成就是否解锁
function XChapterViewModel:IsAchievementUnlock()
    return false
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

-- 检查是否有特殊标志
function XChapterViewModel:CheckHasSpecialTag()
    return false
end

-- 获取特殊标志的名称
function XChapterViewModel:GetSpecialTagName()
    return ""
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
    return nil
end

-- 是否显示特效
function XChapterViewModel:IsShowEffect()
    return false
end

-- 获取普通章节下一关卡入口下标（主界面显示进度）
function XChapterViewModel:GetNormalChapterNextStageOrderId()
    return nil
end

-- 获取主界面的进度展示
--- @return string progress 关卡进度
--- @return string difficult 难度
function XChapterViewModel:GetUiMainProgress()
    return nil, nil
end

-- 打开章节UI界面
-- 有此函数时，通过此函数打开界面。没有此函数时，走通用打开界面逻辑
--[[
function XChapterViewModel:OnOpenChapterUi()

end
]]

return XChapterViewModel
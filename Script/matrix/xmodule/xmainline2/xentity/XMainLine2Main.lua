local XChapterViewModel = require("XEntity/XFuben/XChapterViewModel")

---@class XMainLine2Main
local XMainLine2Main = XClass(XChapterViewModel, "XMainLine2Main")

function XMainLine2Main:Ctor(config)
    self.Id = config.Id
    self.Config = config
end

function XMainLine2Main:Release()
    self.Id = nil
    self.Config = nil
end

function XMainLine2Main:GetId()
    return self.Id
end

function XMainLine2Main:GetConfig()
    return self.Config
end

function XMainLine2Main:GetIcon()
    return self.Config.Icon
end

--- 获取成就图标
function XMainLine2Main:GetAchievementIcon()
    return XMVCA.XMainLine2:GetMainAchievementIcon(self.Id)
end

--- 获取成就未解锁图标
function XMainLine2Main:GetAchievementIconLock()
    return XMVCA.XMainLine2:GetAchievementChapterIconLock(self.Id)
end

--- 成就是否解锁
function XMainLine2Main:IsAchievementUnlock()
    local curCnt, maxCnt = XMVCA.XMainLine2:GetMainAchievementProgress(self.Id)
    return curCnt >= maxCnt
end

function XMainLine2Main:GetExtralData()
    return {
        MainId = self.Config.Id,
        GroupId = self.Config.GroupId,
        OrderId = self.Config.OrderId,
    }
end

function XMainLine2Main:GetExtralName()
    return self.Config.Title
end

function XMainLine2Main:GetName()
    return self.Config.Name
end

function XMainLine2Main:GetNameFontSize()
    return self.Config.NameFontSize
end

-- 获取当前和最大进度值
function XMainLine2Main:GetCurrentAndMaxProgress()
    return XMVCA.XMainLine2:GetMainProgress(self.Id)
end

-- 检查是否有新关卡标志：已解锁 + 未通关
function XMainLine2Main:CheckHasNewTag()
    return XMVCA.XMainLine2:IsMainHasNewTag(self.Id)
end

-- 检查是否有限时标志
function XMainLine2Main:CheckHasTimeLimitTag()
    return XMVCA.XMainLine2:IsMainShowTimeLimitTag(self.Id)
end

-- 检查是否有特殊标志
function XMainLine2Main:CheckHasSpecialTag()
    return XMVCA.XMainLine2:IsMainShowSpecialTag(self.Id)
end

-- 获取特殊标志的名称
function XMainLine2Main:GetSpecialTagName()
    return XMVCA.XMainLine2:GetMainSpecialTagName(self.Id)
end

-- 获取特殊特效
function XMainLine2Main:GetSpecialEffect()
    return XMVCA.XMainLine2:GetSpecialEffect(self.Id)
end

-- 是否上锁
function XMainLine2Main:GetIsLocked()
    local isUnlock, tips = XMVCA.XMainLine2:IsMainUnlock(self.Id)
    return not isUnlock
end

-- 获取锁提示
function XMainLine2Main:GetLockTip()
    local isUnlock, tips = XMVCA.XMainLine2:IsMainUnlock(self.Id)
    return tips
end

-- 检查是否已通关
function XMainLine2Main:CheckIsPassed()
    return XMVCA.XMainLine2:IsMainPassed(self.Id)
end

-- 检查是否有红点提示
function XMainLine2Main:CheckHasRedPoint()
    return XMVCA.XMainLine2:IsMainRed(self.Id)
end

-- 是否显示特效
function XMainLine2Main:IsShowEffect()
    local curCnt, maxCnt = XMVCA.XMainLine2:GetMainAchievementProgress(self.Id)
    return curCnt >= maxCnt
end

-- 获取普通章节下一关卡入口下标（主界面显示进度）
function XMainLine2Main:GetNormalChapterNextStageOrderId()
    local chapterId = XMVCA.XMainLine2:GetChapterId(self.Id, XEnumConst.MAINLINE2.DIFFICULTY_TYPE.NORMAL)
    local uiIndex, orderId = XMVCA.XMainLine2:GetChapterNextEntrance(chapterId)
    return orderId
end

-- 获取主界面的进度展示
--- @return string progress 关卡进度
--- @return string difficult 难度
function XMainLine2Main:GetUiMainProgress()
    return XMVCA.XMainLine2:GetUiMainProgress(self.Id)
end

-- 打开章节UI界面
function XMainLine2Main:OnOpenChapterUi()
    XMVCA.XMainLine2:OpenChapterUi(self.Id)
end

return XMainLine2Main
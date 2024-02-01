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

function XMainLine2Main:GetAchievementIcon()
    return XMVCA:GetAgency(ModuleId.XMainLine2):GetMainAchievementIcon(self.Id)
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

-- 获取当前和最大进度值
function XMainLine2Main:GetCurrentAndMaxProgress()
    return XMVCA:GetAgency(ModuleId.XMainLine2):GetMainProgress(self.Id)
end

-- 检查是否有新关卡标志：已解锁 + 未通关
function XMainLine2Main:CheckHasNewTag()
    return XMVCA:GetAgency(ModuleId.XMainLine2):IsMainHasNewTag(self.Id)
end

-- 检查是否有限时标志
function XMainLine2Main:CheckHasTimeLimitTag()
    return XMVCA:GetAgency(ModuleId.XMainLine2):IsMainShowTimeLimitTag(self.Id)
end

-- 是否上锁
function XMainLine2Main:GetIsLocked()
    local agency = XMVCA:GetAgency(ModuleId.XMainLine2)
    local isUnlock, tips = agency:IsMainUnlock(self.Id)
    return not isUnlock
end

-- 获取锁提示
function XMainLine2Main:GetLockTip()
    local agency = XMVCA:GetAgency(ModuleId.XMainLine2)
    local isUnlock, tips = agency:IsMainUnlock(self.Id)
    return tips
end

-- 检查是否已通关
function XMainLine2Main:CheckIsPassed()
    return XMVCA:GetAgency(ModuleId.XMainLine2):IsMainPassed(self.Id)
end

-- 检查是否有红点提示
function XMainLine2Main:CheckHasRedPoint()
    return XMVCA:GetAgency(ModuleId.XMainLine2):IsMainRed(self.Id)
end

-- 是否显示特效
function XMainLine2Main:IsShowEffect()
    local curCnt, maxCnt = XMVCA:GetAgency(ModuleId.XMainLine2):GetMainAchievementProgress(self.Id)
    return curCnt >= maxCnt
end

-- 获取普通章节下一关卡入口下标（主界面显示进度）
function XMainLine2Main:GetNormalChapterNextStageOrderId()
    local agency = XMVCA:GetAgency(ModuleId.XMainLine2)
    local chapterId = agency:GetChapterId(self.Id, XEnumConst.MAINLINE2.DIFFICULTY_TYPE.NORMAL)
    local uiIndex, orderId = agency:GetChapterNextEntrance(chapterId)
    return orderId
end

-- 打开章节UI界面
function XMainLine2Main:OnOpenChapterUi()
    XMVCA:GetAgency(ModuleId.XMainLine2):OpenChapterUi(self.Id)
end

return XMainLine2Main
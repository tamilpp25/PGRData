local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")

---@class XSimulateTrainAgency : XFubenActivityAgency
---@field _Model XSimulateTrainModel
local XSimulateTrainAgency = XClass(XFubenActivityAgency, "XSimulateTrainAgency")

function XSimulateTrainAgency:OnInit()
    -- 初始化一些变量
    self:RegisterActivityAgency()
end

function XSimulateTrainAgency:InitRpc()
    -- 注册服务器事件
    XRpc.NotifySimulateTrainData = handler(self, self.NotifySimulateTrainData)
end

function XSimulateTrainAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

--- 获取当前开启活动Id
function XSimulateTrainAgency:GetActivityId()
    return self._Model:GetActivityId()
end

-- 活动是否开启中
function XSimulateTrainAgency:IsActivityOpen()
    return self._Model:IsActivityOpen()
end

-- 怪物是否在活动中
function XSimulateTrainAgency:IsMonsterInActivity(monsterId)
    return self._Model:IsMonsterInActivity(monsterId)
end

--- 处理活动结束
function XSimulateTrainAgency:HandleActivityEnd()
    self._Model:HandleActivityEnd()
end


---------------------------------------- #region 配置表 ----------------------------------------
function XSimulateTrainAgency:GetActivityEndTime(id)
    return self._Model:GetActivityEndTime(id)
end

function XSimulateTrainAgency:GetBossRobotIds(id)
    return self._Model:GetBossRobotIds(id)
end

function XSimulateTrainAgency:GetBossSkillIds(id)
    return self._Model:GetBossSkillIds(id)
end

function XSimulateTrainAgency:GetBossIdByMonsterId(monsterId)
    return self._Model:GetBossIdByMonsterId(monsterId)
end

function XSimulateTrainAgency:GetConfigSkill(id)
    return self._Model:GetConfigSkill(id)
end
---------------------------------------- #endregion 配置表 ----------------------------------------


---------------------------------------- #region Rpc ----------------------------------------
--- 通知数据演习数据
function XSimulateTrainAgency:NotifySimulateTrainData(data)
    self._Model:NotifySimulateTrainData(data)
end
---------------------------------------- #endregion Rpc ----------------------------------------


---------------------------------------- #region 副本入口扩展 ----------------------------------------
function XSimulateTrainAgency:ExGetConfig()
    if XTool.IsTableEmpty(self.ExConfig) then
        ---@type XTableFubenActivity
        self.ExConfig = XMVCA.XFuben:GetFubenActivityConfigByManagerName(self.__cname)
    end
    return self.ExConfig
end

--- 打开玩法界面
function XSimulateTrainAgency:ExOpenMainUi()
    local isOpen, tips = self._Model:IsActivityOpen()
    if not isOpen then
        XUiManager.TipError(tips)
        return
    end
    
    XLuaUiManager.Open("UiSimulateTrainMain")
end

---------------------------------------- #endregion 副本入口扩展 ----------------------------------------

---------------------------------------- #region 跳转和红点 ----------------------------------------
--- 跳转玩法接口
function XSimulateTrainAgency:SkipToSimulateTrain()
    self:ExOpenMainUi()
end

--- 是否显示活动红点
function XSimulateTrainAgency:IsShowActivityRedPoint()
    return self._Model:IsShowActivityRedPoint()
end

--- 是否显示boss红点
function XSimulateTrainAgency:IsShowBossRedPoint(bossId)
    return self._Model:IsShowBossRedPoint(bossId)
end

--- 打开boss详情
--- @param monsterId number 怪物Id
function XSimulateTrainAgency:OpenBossDetailUi(monsterId)
    local isOpen, tips = self._Model:IsActivityOpen()
    if not isOpen then
        XUiManager.TipError(tips)
        return
    end
    
    local bossId = self._Model:GetBossIdByMonsterId(monsterId)
    if bossId then
        XLuaUiManager.Open("UiSimulateTrainBossDetail", bossId)
    end
end
---------------------------------------- #endregion 跳转和红点 ----------------------------------------

return XSimulateTrainAgency
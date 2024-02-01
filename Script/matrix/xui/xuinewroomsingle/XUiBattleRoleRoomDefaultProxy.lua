---@class XUiBattleRoleRoomDefaultProxy
local XUiBattleRoleRoomDefaultProxy = XClass(nil, "XUiBattleRoleRoomDefaultProxy")

-- PS : 加上这个主要为了兼容旧编队界面逻辑带来的写法
-- 这里负责处自身玩法的事件，一般不建议使用，可通过切OnEnable注册和Disable关闭事件监听即可
function XUiBattleRoleRoomDefaultProxy:OnNotify(evt, ...)

end

-- 根据实体id获取角色视图数据
-- return : XCharacterViewModel
function XUiBattleRoleRoomDefaultProxy:GetCharacterViewModelByEntityId(id)
    if id > 0 then
        local entity = nil
        if XEntityHelper.GetIsRobot(id) then
            entity = XRobotManager.GetRobotById(id)
        else
            entity = XMVCA.XCharacter:GetCharacter(id)
        end
        if entity == nil then
            XLog.Warning(string.format("找不到id%s的角色", id))
            return
        end
        return entity:GetCharacterViewModel()
    end
    return nil
end

-- 通过实体Id获取角色Id，基本上只要实现好GetCharacterViewModelByEntityId接口可不必处理该接口
-- return : number 角色id
function XUiBattleRoleRoomDefaultProxy:GetCharacterIdByEntityId(id)
    local viewModel = self:GetCharacterViewModelByEntityId(id)
    if viewModel == nil then return end
    return viewModel:GetId()
end

-- 获取实体战力，如有特殊战力计算公式，可重写
-- return : number 战力
function XUiBattleRoleRoomDefaultProxy:GetRoleAbility(entityId)
    -- local viewModel = self:GetCharacterViewModelByEntityId(entityId)
    -- if viewModel then
    --     return viewModel:GetAbility()
    -- end
    -- return 0
    ---@type XCharacterAgency
    local ag = XMVCA:GetAgency(ModuleId.XCharacter)
    return ag:GetCharacterHaveRobotAbilityById(entityId)
end

-- 根据实体Id获取伙伴实体
-- return : XPartner
function XUiBattleRoleRoomDefaultProxy:GetPartnerByEntityId(id)
    if id <= 0 then return nil end
    local result = nil
    if XEntityHelper.GetIsRobot(id) then
        result = XRobotManager.GetRobotPartner(id)
    else
        result = XDataCenter.PartnerManager.GetCarryPartnerEntityByCarrierId(id)
    end
    return result
end

function XUiBattleRoleRoomDefaultProxy:GetIsShowRoleBGEffect()
    return true
end

-- 获取子面板数据，主要用来增加编队界面自身玩法信息，就不用污染通用的预制体
--[[
    return : {
        assetPath : 资源路径
        proxy : 子面板代理
        proxyArgs : 子面板SetData传入的参数列表
    }
]]
function XUiBattleRoleRoomDefaultProxy:GetChildPanelData()
    return nil
end

-- 获取XUiBattleRoomRoleDetail代理，默认XUiBattleRoomRoleDetailDefaultProxy
-- return : 继承自XUiBattleRoomRoleDetailDefaultProxy类或匿名类
function XUiBattleRoleRoomDefaultProxy:GetRoleDetailProxy()
    return nil
end

-- 获取是否能够进入战斗，主要检查队伍设置是否正确，是否满足关卡配置的强制性条件
-- team : XTeam
-- return : bool
function XUiBattleRoleRoomDefaultProxy:GetIsCanEnterFight(team, stageId)
    -- 检查队长是否为空
    if team:GetCaptainPosEntityId() == 0 then
        return false, CS.XTextManager.GetText("TeamManagerCheckCaptainNil")
    end
    -- 检查首发位置是否为空
    if team:GetFirstFightPosEntityId() == 0 then
        return false, CS.XTextManager.GetText("TeamManagerCheckFirstFightNil")
    end
    -- 检查关卡开启条件
    return self:CheckStageForceConditionWithTeamEntityId(team, stageId)
end

-- 检查是否满足关卡配置的强制性条件
-- return : bool
function XUiBattleRoleRoomDefaultProxy:CheckStageForceConditionWithTeamEntityId(team, stageId, showTip)
    local fubenManager = XDataCenter.FubenManager
    local _, forceConditionIds = fubenManager.GetConditonByMapId(stageId)
    return fubenManager.CheckFightConditionByTeamData(forceConditionIds, team:GetEntityIds(), showTip)
end

-- 进入战斗
-- team : XTeam
-- stageId : number
function XUiBattleRoleRoomDefaultProxy:EnterFight(team, stageId, challengeCount, isAssist)
    local stageConfig = XDataCenter.FubenManager.GetStageCfg(stageId)
    local teamId = team:GetId()
    local isAssist = isAssist
    local challengeCount = challengeCount
    XDataCenter.FubenManager.EnterFight(stageConfig, teamId, isAssist, challengeCount)
end

-- 检查是否能够编辑队伍，关卡若是配置了固定机器人为不可编辑
function XUiBattleRoleRoomDefaultProxy:CheckIsCanEditorTeam(stageId, showTip)
    if showTip == nil then showTip = true end
    if #XDataCenter.FubenManager.GetStageCfg(stageId).RobotId > 0 then
        if showTip then
            XUiManager.TipError(XUiHelper.GetText("NewRoomSingleCannotSetRobot"))
        end
        return false
    end
    return true
end

-- 获取编队界面左下角提示信息，可追加自身玩法的信息
-- return : { "提示1", ... }
function XUiBattleRoleRoomDefaultProxy:GetTipDescs()
    return {}
end

-- 获取编队能获取到所有实体，只有在关卡配置AISuggestType为XFubenConfigs.AISuggestType并拥有机器人时要实现
-- 目前只用来对比队伍内角色和已拥有相同试玩角色战力高低提示，可参考XUiBattleRoomRoleDetailDefaultProxy.GetEntities
-- return : { ... }
function XUiBattleRoleRoomDefaultProxy:GetEntities()
    return {}
end

-- return : bool 是否开启自动关闭检查, number 自动关闭的时间戳(秒), function 每秒更新的回调 function(isClose) isClose标志是否到达结束时间
function XUiBattleRoleRoomDefaultProxy:GetAutoCloseInfo()
    return false
end

-- 检查关卡机器人是否使用自定义代理，默认不使用传入的代理，使用回默认代理，可以走回统一界面，避免多系统代理冲突
-- return : bool
function XUiBattleRoleRoomDefaultProxy:CheckStageRobotIsUseCustomProxy(robotIds)
    return #robotIds <= 0
end

-- 创建编队自定义提示的gameObject，默认放在所有提示的最下面
function XUiBattleRoleRoomDefaultProxy:CreateCustomTipGo(panel)
end

-- 过滤预设队伍实体Id
-- teamData : 旧系统的队伍数据
function XUiBattleRoleRoomDefaultProxy:FilterPresetTeamEntitiyIds(teamData)
    return teamData
end

--######################## AOP ########################

function XUiBattleRoleRoomDefaultProxy:AOPOnStartBefore(rootUi)
    
end

function XUiBattleRoleRoomDefaultProxy:AOPOnStartAfter(rootUi)
    
end

function XUiBattleRoleRoomDefaultProxy:AOPOnEnableAfter(rootUi)
    
end

function XUiBattleRoleRoomDefaultProxy:AOPRefreshRoleInfosAfter(rootUi)
    
end

function XUiBattleRoleRoomDefaultProxy:AOPRefreshFightControlStateBefore(rootUi)
    
end

function XUiBattleRoleRoomDefaultProxy:AOPOnCharacterClickBefore(rootUi, index)
    
end

function XUiBattleRoleRoomDefaultProxy:AOPOnRefreshPartnersBefore(self)
    
end

function XUiBattleRoleRoomDefaultProxy:CheckIsCanDrag()
    return true
end

function XUiBattleRoleRoomDefaultProxy:AOPHideCharacterLimits()
    return false
end

function XUiBattleRoleRoomDefaultProxy:ClearErrorTeamEntityId(...)
    XEntityHelper.ClearErrorTeamEntityId(...)
end

function XUiBattleRoleRoomDefaultProxy:AOPGoPartnerCarry()
    return false
end

---点击切换首个进场角色时触发
function XUiBattleRoleRoomDefaultProxy:AOPOnFirstFightBtnClick(buttonGroup, index, team)
    return false
end

---切换队长位置前触发
function XUiBattleRoleRoomDefaultProxy:AOPOnCaptainPosChangeBefore(newCaptainPos, team)
    return false
end

---检查index位置是否可以拖起角色
function XUiBattleRoleRoomDefaultProxy:CheckIsCanMoveUpCharacter(index, time)
    return true
end

---检查index位置是否可以拖放角色
function XUiBattleRoleRoomDefaultProxy:CheckIsCanMoveDownCharacter(index)
    return true
end

-- 该界面是否启用q版模型 默认用愚人节检测
function XUiBattleRoleRoomDefaultProxy:CheckUseCuteModel()
    return XDataCenter.AprilFoolDayManager.IsInCuteModelTime()
end

function XUiBattleRoleRoomDefaultProxy:AOPOnClickFight()
    return false
end

return XUiBattleRoleRoomDefaultProxy
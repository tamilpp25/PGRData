require("XBehavior/XLuaBehaviorManager")
require("XBehavior/XLuaBehaviorAgent")
---@class XGuildDormCharAgent : XLuaBehaviorAgent
local XGuildDormCharAgent = XLuaBehaviorManager.RegisterAgent(XLuaBehaviorAgent, "XGuildDormCharAgent")

function XGuildDormCharAgent:Ctor()
    self.Role = nil
    self.BubbleTimeId = nil
end

function XGuildDormCharAgent:GetId()
    return self.Role:GetId()
end

function XGuildDormCharAgent:GetPlayerId()
    return self.Role:GetEntityId()
end

function XGuildDormCharAgent:GetEntityId()
    return self.Role:GetEntityId()
end

---@param role XGuildDormBaseRole
function XGuildDormCharAgent:SetRole(role)
    self.Role = role
end

-- 设置角色交互触发
function XGuildDormCharAgent:SetCharInteractTrigger(isOn)
    XLog.Warning("================= SetCharInteractTrigger 用不上 ", isOn)
end

-- 关联家具
function XGuildDormCharAgent:InteractFurniture()
    XLog.Warning("================= InteractFurniture 用不上")
    return true
end

function XGuildDormCharAgent:CheckCanGetReward()
    -- 隐藏奖励信息
    local currentInteractInfo = self.Role:GetCurrentInteractInfo()
    local room = XDataCenter.GuildDormManager.GetCurrentRoom()
    local furnitrue = room:GetFurnitureById(currentInteractInfo.Id)
    return furnitrue:CheckIsAllocatedReward()
end

-- eventType : DormCharacterEvent表的CompletedType
function XGuildDormCharAgent:CheckEventCompleted(eventType, callback)
    local currentInteractInfo = self.Role:GetCurrentInteractInfo()
    if eventType == XGuildDormConfig.FurnitureRewardEventType.Normal then
        -- 如果不是自己玩家，直接标记失败
        if not self.Role:CheckIsSelfPlayer() then
            return false
        end
        if not self:CheckCanGetReward() then
            return false
        end
        XDataCenter.GuildDormManager.RequestGetDailyInteractReward(function(res, rewardGoodsList)
            if callback then callback(not res) end
            if res then
                -- 隐藏奖励信息
                XUiManager.OpenUiObtain(rewardGoodsList, XUiHelper.GetText("Award"))
                local room = XDataCenter.GuildDormManager.GetCurrentRoom()
                if room == nil then return end
                local furnitrue = room:GetFurnitureById(currentInteractInfo.Id)
                if furnitrue == nil then return end
                furnitrue:SetIsAllocatedReward(false)
                XEventManager.DispatchEvent(XEventId.EVENT_GUILD_DORM_DESTROY_SPECIAL_UI, furnitrue:GetEntityId(), "PanelSummerGift")
            end
        end)
        return true    
    end
    return false
end

function XGuildDormCharAgent:ShowEventReward(cb)
    if cb then cb() end
    -- if not self.Role:CheckIsSelfPlayer() then
    --     return false
    -- end
    -- if not self:CheckCanGetReward() then
    --     return false
    -- end
    -- -- 隐藏奖励信息
    -- local currentInteractInfo = self.Role:GetCurrentInteractInfo()
    -- local room = XDataCenter.GuildDormManager.GetCurrentRoom()
    -- local furnitrue = room:GetFurnitureById(currentInteractInfo.Id)
    -- furnitrue:SetIsAllocatedReward(false)
    -- if currentInteractInfo.RewardGoodsList then
    --     XUiManager.OpenUiObtain(currentInteractInfo.RewardGoodsList, XUiHelper.GetText("Award"), function()
    --          if cb then cb() end
    --     end)
    -- else
    --     if cb then cb() end
    -- end
    -- XEventManager.DispatchEvent(XEventId.EVENT_GUILD_DORM_DESTROY_SPECIAL_UI, furnitrue:GetEntityId(), "PanelSummerGift")
end

-- 做动画
function XGuildDormCharAgent:DoAction(actionId, needFadeCross, crossDuration)
    self.Role:GetRLRole():PlayAnimation(actionId, needFadeCross, crossDuration)
end

function XGuildDormCharAgent:ShowBubble(dialogId, callback)
    local config = XGuildDormConfig.GetCfgByIdKey(XGuildDormConfig.TableKey.GuildDormDialog, dialogId)
    if config == nil then 
        if callback then callback() end
        return
    end
    -- 避免打断当前对话
    if self.BubbleTimeId then
        if callback then callback() end
        return
    end
    self:RefreshBubble(dialogId, 1, callback)
end

function XGuildDormCharAgent:RefreshBubble(dialogId, index, callback)
    local config = XGuildDormConfig.GetCfgByIdKey(XGuildDormConfig.TableKey.GuildDormDialog, dialogId)
    local content = nil
    if config.Content then
        content = config.Content[index] or ""
    end
    local hideTime = 0
    if config.Time then
        hideTime = config.Time[index] or 0
    end
    if not string.IsNilOrEmpty(content) then
        XEventManager.DispatchEvent(XEventId.EVENT_GUILD_DORM_ENTITY_TALK, self.Role, content, false, hideTime)
    end
    if hideTime > 0 then
        self.BubbleTimeId = XScheduleManager.ScheduleOnce(function()
            self:RefreshBubble(dialogId, index + 1, callback)
        end, hideTime)
    else
        self:StopBubbleTime()
        if callback then callback() end
    end
end

-- 隐藏汽包
function XGuildDormCharAgent:HideBubble()
    if self.Role.GetIsRemove and self.Role:GetIsRemove() then
        XLog.Debug("正在销毁Npc时不隐藏对话、避免打断销毁流程")
        return
    end
    self:StopBubbleTime()
end

function XGuildDormCharAgent:StopBubbleTime()
    if self.BubbleTimeId then
        XScheduleManager.UnSchedule(self.BubbleTimeId)
        self.BubbleTimeId = nil
    end
end

-- 播放特效
function XGuildDormCharAgent:PlayEffect(effectId, worldPos)
    local rlRole = self.Role:GetRLRole()
    XEventManager.DispatchEvent(XEventId.EVENT_GUILD_DORM_ENTITY_SHOW_EFFECT, self.Role:GetEntityId(), self:GetId()
    , effectId, rlRole:GetTransform(), worldPos)
end

-- 隐藏特效
function XGuildDormCharAgent:HideEffect()
    XEventManager.DispatchEvent(XEventId.EVENT_GUILD_DORM_ENTITY_HIDE_EFFECT, self.Role:GetEntityId())
end

-- 家具播放特效
function XGuildDormCharAgent:FurniturePlayEffect(effectId, localPosition, specialNode, specialNodeName)
    local furniture = self:GetFurniture()
    if furniture then
        furniture:FurniturePlayEffect(effectId, localPosition, specialNode, specialNodeName)
    end
end

-- 家具隐藏特效
function XGuildDormCharAgent:FurnitureHideEffect(effectIds)
    local furniture = self:GetFurniture()
    if furniture then
        furniture:FurnitureHideEffect(effectIds)
    end
end

function XGuildDormCharAgent:GetFurniture()
    local currentInteractInfo = self.Role:GetCurrentInteractInfo()
    if currentInteractInfo == nil then
        XLog.Error("公会宿舍家具特效相关交互信息为空")
        return
    end
    local room = XDataCenter.GuildDormManager.GetCurrentRoom()
    local furnitureId = currentInteractInfo.Id
    return room:GetFurnitureById(furnitureId)
end

-- 检测是否结束家具交互
function XGuildDormCharAgent:CheckDisInteractFurniture()
    XLog.Warning("================= CheckDisInteractFurniture 用不上 ")
    return true
end

-- 设置是否有阻挡
function XGuildDormCharAgent:SetObstackeEnable(value)
    XLog.Warning("================= SetObstackeEnable 用不上 ")
end

function XGuildDormCharAgent:CheckCharInteractPosByIndex(index)
    XLog.Warning("================= CheckCharInteractPosByIndex 用不上 ")
    return true
end

-- 改变状态
function XGuildDormCharAgent:ChangeStatus(state,ignoreBehaviorChange)
    if state == XGuildDormConfig.RoleFSMType.IDLE or state== XGuildDormConfig.RoleFSMType.PATROL_IDLE then
        self.Role:UpdateInteractStatus(XGuildDormConfig.InteractStatus.End,ignoreBehaviorChange)
        self.Role:EnableCharacterController(true)
    end
end

function XGuildDormCharAgent:SetForwardToFurniture(forward)
    local currentInteractInfo = self.Role:GetCurrentInteractInfo()
    if currentInteractInfo == nil then
        XLog.Error("公会宿舍行为树SetForwardToFurniture时交互信息为空")
        return
    end
    local eulerAngle = currentInteractInfo.InteractPos.transform.eulerAngles
    if forward < 0 then
        eulerAngle = eulerAngle + CS.UnityEngine.Vector3(0, 180, 0)
    end
    self.Role:GetAgent():SetVarDicByKey("TurnTo", eulerAngle)
    return true
end

-- 设置与角色的交互方向
function XGuildDormCharAgent:SetForwardToPlayer(forward)
    local room = XDataCenter.GuildDormManager.GetCurrentRoom()
    local role = room:GetRoleByPlayerId(XPlayer.Id)
    ---@type UnityEngine.Quaternion
    local targetRotation = CS.XGuildDormHelper.GetEulerAngles(role:GetRLRole():GetTransform(), self.Role:GetRLRole():GetTransform())
    local eulerAngle = targetRotation.eulerAngles
    if forward < 0 then
        eulerAngle = eulerAngle + CS.UnityEngine.Vector3(0, 180, 0)
    end
    self.Role:GetAgent():SetVarDicByKey("TurnTo", eulerAngle)
    return true
end

function XGuildDormCharAgent:TurnToFurnitureStayPos(cb, isSlerp, isSetPosition)
    local currentInteractInfo = self.Role:GetCurrentInteractInfo()
    -- 设置停留位置
    local stayPos = currentInteractInfo.StayPos
    local transform = self.Role:GetRLRole():GetTransform()
    if isSetPosition then
        transform.position = stayPos.transform.position
    end
    if isSlerp then
        self.Role:GetAgent():SetVarDicByKey("TurnToData", {
            rotation = stayPos.transform.rotation,
            finishedCb = cb
        })
    else
        transform.rotation = stayPos.transform.rotation
        if cb then cb() end
    end
end

-- 设置Npc为出生点的位置和方向
function XGuildDormCharAgent:TurnToInitPos(isSetPosition, isSlerp)
    local rlRole = self.Role:GetRLRole()
    local interactInfo = rlRole:GetInteractInfoList()
    local initPos = interactInfo.InitPos
    local transform = rlRole:GetTransform()
    if initPos then
        if isSetPosition then
            transform.position = initPos.position
        end
        if not isSlerp then
            transform.rotation = initPos.rotation
        else
            local eulerAngle = initPos.eulerAngles
            self.Role:GetAgent():SetVarDicByKey("TurnTo", eulerAngle)
        end
    end
    
    return true
end

function XGuildDormCharAgent:CheckIsDirectInteract()
    return self.Agent:GetVarDicByKey("IsDirectInteract")
end

function XGuildDormCharAgent:SwitchCamera(cb)
    if cb then cb() end
    XLog.Debug("================= SwitchCamera 已废弃 ")
    --local room = XDataCenter.GuildDormManager.GetCurrentRoom()
    --local rlRole = self.Role:GetRLRole()
    --local interactInfo = rlRole:GetInteractInfoList()
    --room:PlayCameraSwitchAnim(interactInfo.CameraPos, cb)
end

function XGuildDormCharAgent:ResetCamera(cb)
    if cb then cb() end
    XLog.Debug("================= ResetCamera 已废弃 ")
    --local room = XDataCenter.GuildDormManager.GetCurrentRoom()
    --room:ResetCameraController(cb)
end

-- 设置相机看向坐标和距离
function XGuildDormCharAgent:SetCameraParam(distance)
    local room = XDataCenter.GuildDormManager.GetCurrentRoom()
    local role = room:GetRoleByPlayerId(XPlayer.Id)
    local centralPoint = (role:GetRLRole():GetTransform().position + self.Role:GetRLRole():GetTransform().position) / 2
    local cameraController = XDataCenter.GuildDormManager.SceneManager.GetCurrentScene():GetCameraController()
    cameraController:SetNpcInteract(true, distance)
    cameraController:SetLookAtPos(centralPoint)
end

-- 恢复相机设置
function XGuildDormCharAgent:ResetCameraParam()
    local room = XDataCenter.GuildDormManager.GetCurrentRoom()
    local role = room:GetRoleByPlayerId(XPlayer.Id)
    role:GetRLRole():UpdateCameraFollow()
    local cameraController = XDataCenter.GuildDormManager.SceneManager.GetCurrentScene():GetCameraController()
    cameraController:SetNpcInteract(false)
end

function XGuildDormCharAgent:PlayTalkSystem(id)
    if XGuildDormConfig.CheckHasTalkId(id) then
        XLuaUiManager.Open("UiGuildMovie", id, self.Role)
    else
        XLog.Error("公会宿舍播放对话id在配置表中不存在" .. id)
        XScheduleManager.ScheduleOnce(function()
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_DORM_TALK_END)    
        end, 1)
    end
end

function XGuildDormCharAgent:PlayAlphaAnim(alpha, time, cb)
    self.Role:GetRLRole():PlayTargetAlphaAnim(alpha, time, cb)
end

function XGuildDormCharAgent:Destroy()
    local room = XDataCenter.GuildDormManager.GetCurrentRoom()
    room:DestroyNpc(self.Role)
end

return XGuildDormCharAgent
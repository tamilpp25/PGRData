-- 本脚本主要起到对部分【常用多逻辑接口组合】与【常见的复数参数判断】进行二次封装以便调用, 功能作用类似于组合行为树
-- 策划写逻辑时可以先在各自脚本集合成一个方法，然后再可以联系TD/程序看有没有迁移到这里的实际必要 

-- 基础逻辑块分类
-- 以Check为前缀：   做条件判断 return boolean
-- 以Do为前缀：      做逻辑执行 以doData响应具体执行逻辑, 视情况return数据 
-- 以Process为前缀： 对象的一个具体行为, 包含了Check、SelectTodo、Do逻辑, 视情况return数据, 参考Char_3005.lua的ProcessChangeMoveState

XScriptTool = {}

--region Checker
---检查是否是Npc交互对象
---@param proxy StatusSyncFight.XFightScriptProxy
---@param eventArgs
function XScriptTool.CheckNpcInteractStart(proxy, eventArgs, targetNpcId)
    if proxy:IsPlayerNpc(eventArgs.LauncherId) and eventArgs.TargetId == targetNpcId and eventArgs.Type == 1 then
        return true
    end
    return false
end
--endregion


--region Do
---Npc传送(不带转向)
---@param proxy StatusSyncFight.XFightScriptProxy
---@param npcId number
---@param position Mathematics.float3 参考{x=0, y=0, z=0}
---@param isNotEffect boolean 是否不带传送特效
function XScriptTool.DoTeleportNpcPos(proxy, npcId, position, isNotEffect)
    proxy:SetNpcPosition(npcId, position, true) --不转向传送
    if isNotEffect then
        return
    end
    proxy:ApplyMagic(npcId, npcId, 200037, 1) --传送特效
end

---Npc传送(不带转向、带特效、带黑幕)
---@param proxy StatusSyncFight.XFightScriptProxy
---@param npcId number
---@param position Mathematics.float3 参考{x=0, y=0, z=0}
---@param blackEnterDuration number 黑幕渐入时间
---@param blackExitDuration number 黑幕渐出时间
function XScriptTool.DoTeleportNpcPosWithBlackScreen(proxy, npcId, position, blackEnterDuration, blackExitDuration)
    if not blackEnterDuration then
        blackEnterDuration = 0.5
    end
    if not blackExitDuration then
        blackExitDuration = 0.5
    end
    local teleportFunc = function()
        proxy:SetNpcPosition(npcId, position, true)
        proxy:ApplyMagic(npcId, npcId, 200037, 1)
    end
    proxy:PlayBlackScreenEffect(blackEnterDuration, blackExitDuration)
    proxy:AddTimerTask(blackEnterDuration, teleportFunc)
end

---Npc传送(带转向、带特效、带黑幕)
---@param proxy StatusSyncFight.XFightScriptProxy
---@param npcId number
---@param position Mathematics.float3 参考{x=0, y=0, z=0}
---@param rotation Mathematics.float3 参考{x=0, y=0, z=0}
---@param blackEnterDuration number 黑幕渐入时间
---@param blackExitDuration number 黑幕渐出时间
function XScriptTool.DoTeleportNpcPosAndRotWithBlackScreen(proxy, npcId, position, rotation, blackEnterDuration, blackExitDuration)
    if not blackEnterDuration then
        blackEnterDuration = 0.5
    end
    if not blackExitDuration then
        blackExitDuration = 0.5
    end
    local teleportFunc = function()
        proxy:SetNpcPosAndRot(npcId, position, rotation, true)
        proxy:ApplyMagic(npcId, npcId, 200037, 1)
    end
    proxy:PlayBlackScreenEffect(blackEnterDuration, blackExitDuration)
    proxy:AddTimerTask(blackEnterDuration, teleportFunc)
end
--endregion


--region Process

--endregion
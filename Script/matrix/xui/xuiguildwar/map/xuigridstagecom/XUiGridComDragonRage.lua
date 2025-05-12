--- 公会战关卡节点UI，负责分担处理龙怒系统相关表现的组件
---@class XUiGridComDragonRage --目前关卡节点都没有继承XUiNode，因此暂不按照XUiNode的方式处理
---@field Owner XUiGridStage
local XUiGridComDragonRage = XClass(nil, 'XUiGridComDragonRage')

function XUiGridComDragonRage:Ctor(owner)
    self.Owner = owner
end

--- 根据当前龙怒状态、节点类型选择播放常驻特效、动画
function XUiGridComDragonRage:PlayDragonRageStateShow(isDragonRageOpen)
    if isDragonRageOpen and self.Owner.GameObject.activeSelf then
        local nodeType = self.Owner.StageNode:GetNodeType()

        -- 龙怒玩法，有父节点的非废墟节点都是龙怒节点
        if nodeType ~= XGuildWarConfig.NodeType.NodeRelic and XTool.IsNumberValid(self.Owner.StageNode:GetRootId()) then
            --todo 播放龙怒节点常驻特效
            
            return
        end
        
        --todo 废墟节点播放废墟特效
        if nodeType == XGuildWarConfig.NodeType.NodeRelic then
            
            return
        end
    end
    
end

--- 关卡切换时，龙怒状态节点显示动画
function XUiGridComDragonRage:PlayDragonRageChangeShow(cb)
    -- 判断自己是什么节点，普通节点隐藏，龙怒节点显示
    if XTool.IsNumberValid(self.Owner.StageNode:GetRootId()) then
        --todo 龙怒节点显示动画
        if cb then
            cb()
        end
    else
        -- todo 原节点隐藏动画
        if cb then
            cb()
        end
    end
    
end

--- 关卡切换时，废墟节点显示动画 
function XUiGridComDragonRage:PlayRelicChangeShow(cb)
    if self.Owner.StageNode:GetNodeType() == XGuildWarConfig.NodeType.NodeRelic then
        --todo 废墟节点显示动画
        if cb then
            cb()
        end
    else
        -- todo 原节点隐藏动画
        if cb then
            cb()
        end
    end
end

--- 暂停所有正在播放的动画
function XUiGridComDragonRage:StopTween()
    
end


return XUiGridComDragonRage
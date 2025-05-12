--- 公会战7.0新增龙怒系统的子控制器，用于封装龙怒系统玩法在XGuildWarControl上的接口
---@class XDragonRageControl: XControl
---@field private _Model XGuildWarModel
local XDragonRageControl = XClass(XControl, 'XDragonRageControl')

function XDragonRageControl:OnInit()

end


function XDragonRageControl:OnRelease()

end

--- 是否开启龙怒系统玩法
function XDragonRageControl:GetIsOpenDragonRage()
    return self._Model:GetDragonRageData():GetIsOpenDragonRage()
end

--- 是否解锁龙怒系统
function XDragonRageControl:GetIsUnlockDragonRage()
    return self._Model:GetDragonRageData():GetIsUnlockDragonRage()
end

--- 当前龙怒等级
function XDragonRageControl:GetDragonRageLevel()
    return self._Model:GetDragonRageData():GetDragonRageLevel()
end

--- 当前龙怒值
function XDragonRageControl:GetDragonRageValue()
    return self._Model:GetDragonRageData():GetDragonRageValue()
end

--- 当前等级龙怒值最大值
function XDragonRageControl:GetDragonRageValueMAX()
    local cfgId = self._Model:GetDragonRageData():GetDragonRageCfgId()

    if XTool.IsNumberValid(cfgId) then
        ---@type XTableGuildWarDragonRage
        local cfg = self._Model:GetDragonRageCfgById(cfgId)

        if cfg then
            return cfg.UpLimit
        end
    end
    
    return 0
end

--- 当前龙怒阶段节点配置Id
function XDragonRageControl:GetDragonRageNodeCfgId()
    return self._Model:GetDragonRageData():GetFullDragonRageCfgId()
end

--- 当前龙怒值是否处于下降阶段
function XDragonRageControl:GetIsDragonRageValueDown()
    return self._Model:GetDragonRageData():GetIsDragonRageValueDown()
end

--- 当前龙怒周目配置Id
function XDragonRageControl:GetGameThroughCfgId()
    return self._Model:GetDragonRageData():GetGameThroughCfgId()
end

--- 获取当前周目的周目BuffId
function XDragonRageControl:GetGameThroughBuffId()
    local throughId = self:GetGameThroughCfgId()

    if XTool.IsNumberValid(throughId) then
        ---@type XTableGuildWarPlayThrough
        local cfg = self._Model:GetDragonRagePlayThroughCfgById(throughId)

        if cfg then
            return cfg.ShowBuffId
        end
    end
end

--- 获取当前周目的周目buff描述
function XDragonRageControl:GetGameThroughBuffDescFormat()
    local throughId = self:GetGameThroughCfgId()

    if XTool.IsNumberValid(throughId) then
        ---@type XTableGuildWarPlayThrough
        local cfg = self._Model:GetDragonRagePlayThroughCfgById(throughId)

        if cfg then
            return cfg.ShowBuffDescFormat
        end
    end
end

--- 根据当前龙怒状态，针对存在两种状态的节点，获取它们组成的列表
function XDragonRageControl:GetMainMapNodesWithDragonRage()
    --- 龙怒系统存在重复节点
    if self:GetIsOpenDragonRage() then
        ---@type XGWBattleManager
        local battleManager = XDataCenter.GuildWarManager.GetBattleManager()

        ---@type XGWNode[]
        local nodeList = battleManager:GetMainMapNodes()
        
        if self:GetIsDragonRageValueDown() then
            -- 龙怒状态排除原节点
            local dragonRageNodeCfgId = self:GetDragonRageNodeCfgId()
            local cfg = self._Model:GetDragonRageNodeChangeCfgById(dragonRageNodeCfgId)

            if cfg then
                for i = #nodeList, 1, -1 do
                    if table.contains(cfg.ChangeNodeIds, nodeList[i]:GetId()) and not nodeList[i]:GetIsDead() then
                        -- 如果该节点处于原节点列表，且未击破，需要移除
                        table.remove(nodeList, i)
                    elseif nodeList[i]:GetNodeType() ~= XGuildWarConfig.NodeType.NodeRelic and XTool.IsNumberValid(nodeList[i]:GetRootId()) then
                        if not table.contains(cfg.ChangeNodeIds, nodeList[i]:GetRootId()) or nodeList[i]:GetIsDead() then
                            -- 如果该节点是龙怒节点，它所属的原节点不在列表中，或者已击破，那么它自己需要移除
                            table.remove(nodeList, i)
                        end
                    end
                end
            end
            
        else
            -- 非龙怒状态排除龙怒节点
            for i = #nodeList, 1, -1 do
                if nodeList[i]:GetNodeType() ~= XGuildWarConfig.NodeType.NodeRelic and XTool.IsNumberValid(nodeList[i]:GetRootId()) then
                    table.remove(nodeList, i)
                end
            end
        end
        
        -- 根据周目选择废墟节点或原节点
        local gameThroughId = self:GetGameThroughCfgId()
        ---@type XTableGuildWarPlayThrough
        local gameThroughCfg = self._Model:GetDragonRagePlayThroughCfgById(gameThroughId)

        if gameThroughCfg then
            for i = #nodeList, 1, -1 do
                if table.contains(gameThroughCfg.ChangeNodeIds, nodeList[i]:GetId()) then
                    -- 如果该节点处于原节点列表，需要移除
                    table.remove(nodeList, i)
                elseif nodeList[i]:GetNodeType() == XGuildWarConfig.NodeType.NodeRelic and XTool.IsNumberValid(nodeList[i]:GetRootId()) and not table.contains(gameThroughCfg.ChangeNodeIds, nodeList[i]:GetRootId()) then
                    -- 如果该节点是废墟节点，它所属的原节点不在列表中，那么它自己需要移除
                    table.remove(nodeList, i)
                end
            end
        end
        
        return nodeList
    end
end

--- 根据周目配置Id，获取变成废墟的原节点Id列表
function XDragonRageControl:GetChangeToRelicNodeIdsByGameThroughId(id)
    if XTool.IsNumberValid(id) then
        ---@type XTableGuildWarPlayThrough
        local cfg = self._Model:GetDragonRagePlayThroughCfgById(id)

        if cfg then
            return cfg.ChangeNodeIds
        end
    end
end


--region ---------- 行为序列处理 ---------->>>

--- 播放龙怒系统结束的动画(龙怒积累结束）
function XDragonRageControl:ShowDragonRageFull(actionGroup, showOverCallback)
    -- todo 满龙怒，触发节点切换动画
    
    if XLuaUiManager.IsMaskShow(XGuildWarConfig.MASK_KEY) then
        XLuaUiManager.SetMask(false, XGuildWarConfig.MASK_KEY)
    end

    local callBackFinish = function()
        XLuaUiManager.SetMask(true, XGuildWarConfig.MASK_KEY)
        showOverCallback()
    end

    callBackFinish()
end

--- 播放龙怒系统开始的动画（龙怒积累开始）
function XDragonRageControl:ShowDragonRageEmpty(actionGroup, showOverCallback)
    --- 龙怒积累，播放弹窗节点重建
    if XLuaUiManager.IsMaskShow(XGuildWarConfig.MASK_KEY) then
        XLuaUiManager.SetMask(false, XGuildWarConfig.MASK_KEY)
    end

    local callBackFinish = function()
        XLuaUiManager.SetMask(true, XGuildWarConfig.MASK_KEY)
        showOverCallback()
    end

    XLuaUiManager.OpenWithCloseCallback("UiGuildWarBossReaultsRebuild", callBackFinish)
end

--- 播放龙怒系统节点切换为废墟的动画
function XDragonRageControl:ShowNodeToRelic(nodeIdList, showOverCallback)
    if XLuaUiManager.IsMaskShow(XGuildWarConfig.MASK_KEY) then
        XLuaUiManager.SetMask(false, XGuildWarConfig.MASK_KEY)
    end

    local callBackFinish = function()
        XLuaUiManager.SetMask(true, XGuildWarConfig.MASK_KEY)
        showOverCallback()
    end

    if not XTool.IsTableEmpty(nodeIdList) then
        XLuaUiManager.Open("UiGuildWarNodeToRelicReaults", nodeIdList, callBackFinish)
    else
        callBackFinish()
    end
end

--endregion <<<-------------------------

return XDragonRageControl
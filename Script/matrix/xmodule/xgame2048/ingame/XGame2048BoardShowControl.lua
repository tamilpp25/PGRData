--- 2048玩法分管背景角色动作响应的子控制器
---@class XGame2048BoardShowControl: XControl
---@field private _MainControl XGame2048GameControl
---@field private _Model XGame2048Model
local XGame2048BoardShowControl = XClass(XControl, 'XGame2048BoardShowControl')

function XGame2048BoardShowControl:OnInit()

end

function XGame2048BoardShowControl:OnRelease()
    self:StopNoOperationCheckTimer()
end

function XGame2048BoardShowControl:SetCurStageShowConfigId(id)
    self._ConfigId = id
    self._BoardShowMap = {}
    
    -- 对动画按照类型进行归类
    if XTool.IsNumberValid(self._ConfigId) then
        ---@type XTableGame2048BoardShowGroup
        local showCfg = self._Model:GetGame2048BoardShowGroupCfgById(self._ConfigId)

        if showCfg then
            for i, showId in pairs(showCfg.BoardShowIds) do
                ---@type XTableGame2048BoardShow
                local boardShowCfg = self._Model:GetGame2048BoardShowCfgById(showId)

                if boardShowCfg then
                    ---@type XTableGame2048ShowCondition
                    local showConditionCfg = self._Model:GetGame2048ShowConditionCfgById(boardShowCfg.ShowConditionId)

                    if showConditionCfg then
                        if self._BoardShowMap[showConditionCfg.Type] == nil then
                            self._BoardShowMap[showConditionCfg.Type] = boardShowCfg.Id
                        elseif type(self._BoardShowMap[showConditionCfg.Type]) ~= 'table' then
                            local boardShowCfgList = { self._BoardShowMap[showConditionCfg.Type] }
                            table.insert(boardShowCfgList, boardShowCfg.Id)
                            self._BoardShowMap[showConditionCfg.Type] = boardShowCfgList
                        else
                            table.insert(self._BoardShowMap[showConditionCfg.Type], boardShowCfg.Id)
                        end
                    end
                end
            end
        end
    end
    
    self:ResetNoOperationTimer()
    self:StartNoOperationCheckTimer()
end

--- 当前关卡结束（无论放弃还是完成）
function XGame2048BoardShowControl:OnStageEnd()
    self:StopNoOperationCheckTimer()
end

function XGame2048BoardShowControl:ResetNoOperationTimer()
    self._LatestOperationTime = CS.UnityEngine.Time.time
end

--region 响应事件检查
function XGame2048BoardShowControl:OnFerverLevelUpEvent()
    if not XTool.IsTableEmpty(self._BoardShowMap) then
        local feverLevelUpShow = self._BoardShowMap[XMVCA.XGame2048.EnumConst.BoardShowConditionType.FeverLevelUp]
        
        if type(feverLevelUpShow) == 'number' then
            ---@type XTableGame2048BoardShow
            local boardShowCfg = self._Model:GetGame2048BoardShowCfgById(feverLevelUpShow)

            if boardShowCfg then
                ---@type XTableGame2048ShowCondition
                local showConditionCfg = self._Model:GetGame2048ShowConditionCfgById(boardShowCfg.ShowConditionId)

                if showConditionCfg and showConditionCfg.Params[1] == self._MainControl.TurnControl:GetBoardLv()then
                    self._MainControl:DispatchEvent(XMVCA.XGame2048.EventIds.EVENT_GAME2048_SHOW_ACTION, boardShowCfg)
                end
            end
        elseif not XTool.IsTableEmpty(feverLevelUpShow) then
            -- 找到优先级高的播放
            local resultShowCfg = nil
            local resultShowPriority = math.maxinteger
            
            for i, showId in pairs(feverLevelUpShow) do
                ---@type XTableGame2048BoardShow
                local boardShowCfg = self._Model:GetGame2048BoardShowCfgById(showId)

                if boardShowCfg then
                    ---@type XTableGame2048ShowCondition
                    local showConditionCfg = self._Model:GetGame2048ShowConditionCfgById(boardShowCfg.ShowConditionId)

                    if showConditionCfg and showConditionCfg.Params[1] == self._MainControl.TurnControl:GetBoardLv() then
                        if resultShowCfg == nil or showConditionCfg.Params[2] < resultShowPriority then
                            resultShowCfg = boardShowCfg
                            resultShowPriority = showConditionCfg.Params[2]
                        end
                    end
                end
            end

            if resultShowCfg then
                self._MainControl:DispatchEvent(XMVCA.XGame2048.EventIds.EVENT_GAME2048_SHOW_ACTION, resultShowCfg)
            end
        end
    end
end

function XGame2048BoardShowControl:OnGridMergeEvent(targetBlockId)
    if not XTool.IsTableEmpty(self._BoardShowMap) then
        local targetGridMergeShow = self._BoardShowMap[XMVCA.XGame2048.EnumConst.BoardShowConditionType.TargetGridMerge]

        if type(targetGridMergeShow) == 'number' then
            ---@type XTableGame2048BoardShow
            local boardShowCfg = self._Model:GetGame2048BoardShowCfgById(targetGridMergeShow)

            if boardShowCfg then
                ---@type XTableGame2048ShowCondition
                local showConditionCfg = self._Model:GetGame2048ShowConditionCfgById(boardShowCfg.ShowConditionId)

                if showConditionCfg and showConditionCfg.Params[1] == targetBlockId then
                    self._MainControl:DispatchEvent(XMVCA.XGame2048.EventIds.EVENT_GAME2048_SHOW_ACTION, boardShowCfg)
                end
            end
        elseif not XTool.IsTableEmpty(targetGridMergeShow) then
            -- 找到优先级高的播放
            local resultShowCfg = nil
            local resultShowPriority = math.maxinteger
            
            for i, showId in pairs(targetGridMergeShow) do
                ---@type XTableGame2048BoardShow
                local boardShowCfg = self._Model:GetGame2048BoardShowCfgById(showId)

                if boardShowCfg then
                    ---@type XTableGame2048ShowCondition
                    local showConditionCfg = self._Model:GetGame2048ShowConditionCfgById(boardShowCfg.ShowConditionId)

                    if showConditionCfg and showConditionCfg.Params[1] == targetBlockId then
                        if resultShowCfg == nil or showConditionCfg.Params[2] < resultShowPriority then
                            resultShowCfg = boardShowCfg
                            resultShowPriority = showConditionCfg.Params[2]
                        end
                    end
                end
            end

            if resultShowCfg then
                self._MainControl:DispatchEvent(XMVCA.XGame2048.EventIds.EVENT_GAME2048_SHOW_ACTION, resultShowCfg)
            end
        end
    end
end

function XGame2048BoardShowControl:OnNoOperationStayEvent(passTime)
    if not XTool.IsTableEmpty(self._BoardShowMap) then
        local noOperationStayShow = self._BoardShowMap[XMVCA.XGame2048.EnumConst.BoardShowConditionType.NoOperationStayTime]

        if type(noOperationStayShow) == 'number' then
            ---@type XTableGame2048BoardShow
            local boardShowCfg = self._Model:GetGame2048BoardShowCfgById(noOperationStayShow)

            if boardShowCfg then
                ---@type XTableGame2048ShowCondition
                local showConditionCfg = self._Model:GetGame2048ShowConditionCfgById(boardShowCfg.ShowConditionId)

                if showConditionCfg and showConditionCfg.Params[1] <= passTime then
                    self._MainControl:DispatchEvent(XMVCA.XGame2048.EventIds.EVENT_GAME2048_SHOW_ACTION, boardShowCfg)
                    self:ResetNoOperationTimer()
                end
            end
        elseif not XTool.IsTableEmpty(noOperationStayShow) then
            local maxConditionShowCfg = nil
            local maxBoardShowCfg = nil
            
            for i, showId in pairs(noOperationStayShow) do
                ---@type XTableGame2048BoardShow
                local boardShowCfg = self._Model:GetGame2048BoardShowCfgById(showId)

                if boardShowCfg then
                    ---@type XTableGame2048ShowCondition
                    local showConditionCfg = self._Model:GetGame2048ShowConditionCfgById(boardShowCfg.ShowConditionId)

                    if showConditionCfg and showConditionCfg.Params[1] <= passTime then
                        if maxConditionShowCfg == nil or showConditionCfg.Params[1] > maxConditionShowCfg then
                            maxConditionShowCfg = showConditionCfg
                            maxBoardShowCfg = boardShowCfg
                        end
                    end
                end
            end

            if maxBoardShowCfg then
                self._MainControl:DispatchEvent(XMVCA.XGame2048.EventIds.EVENT_GAME2048_SHOW_ACTION, maxBoardShowCfg)
                self:ResetNoOperationTimer()
            end
        end
    end
end
--endregion

--region 无操作检查定时器
function XGame2048BoardShowControl:StopNoOperationCheckTimer()
    if self._NoOperationCheckTimeId then
        XScheduleManager.UnSchedule(self._NoOperationCheckTimeId)
        self._NoOperationCheckTimeId = nil
    end
end

function XGame2048BoardShowControl:StartNoOperationCheckTimer()
    self:StopNoOperationCheckTimer()

    self._NoOperationCheckTimeId = XScheduleManager.ScheduleForever(function() 
        local passTime = CS.UnityEngine.Time.time - self._LatestOperationTime
        self:OnNoOperationStayEvent(passTime)
    end, XScheduleManager.SECOND * 0.1)
end
--endregion

return XGame2048BoardShowControl
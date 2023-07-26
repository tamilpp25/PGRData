--大逃杀策略节点
---@class XEscapeTacticsNodeData
local XEscapeTacticsNodeData = XClass(nil, "XEscapeTacticsNodeData")

local Default = {
    _LayerId = 0,           --层数
    _NodeId = 0,            --节点Id
    _TacticsId = 0,         --选择的策略Id, -1表示选择跳过
    _TacticsIdList = {},    --可选择策略
}

function XEscapeTacticsNodeData:Ctor()
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end
end

function XEscapeTacticsNodeData:UpdateData(data)
    self._LayerId = data.LayerId
    self._NodeId = data.NodeId
    self._TacticsId = data.TacticsId
    self._TacticsIdList = data.TacticsIdList
end

function XEscapeTacticsNodeData:SetSelectTacticsId(tacticsId)
    self._TacticsId = tacticsId
end

function XEscapeTacticsNodeData:GetSelectTacticsId()
    if self._TacticsId <= 0 then
        return false
    end
    return self._TacticsId
end

function XEscapeTacticsNodeData:GetLayerId()
    return self._LayerId
end

function XEscapeTacticsNodeData:GetNodeId()
    return self._NodeId
end

function XEscapeTacticsNodeData:GetTacticsList()
    local result = { }
    if XTool.IsTableEmpty(self._TacticsIdList) then
        return result
    end
    for _, id in ipairs(self._TacticsIdList) do
        result[#result+1] = XDataCenter.EscapeManager.GetTactics(id)
    end
    return result
end

function XEscapeTacticsNodeData:GetSelectTactics()
    if self._TacticsId <= 0 then
        return false
    end
    return XDataCenter.EscapeManager.GetTactics(self._TacticsId)
end

function XEscapeTacticsNodeData:IsSelect()
    return self._TacticsId ~= 0
end

return XEscapeTacticsNodeData
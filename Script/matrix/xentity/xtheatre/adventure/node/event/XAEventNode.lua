local XANode = require("XEntity/XTheatre/Adventure/Node/XANode")
local XAEventNode = XClass(XANode, "XAEventNode")

function XAEventNode:Ctor()
    self.EventConfig = nil
    self.EventClientConfig = nil
end

function XAEventNode:InitWithServerData(data)
    XAEventNode.Super.InitWithServerData(self, data)
    -- 获取事件配置信息
    self.EventConfig = XTheatreConfigs.GetEventNodeConfig(data.ConfigId, data.CurStepId)
    self.EventClientConfig = XTheatreConfigs.GetTheatreEventClientConfig(self.EventConfig.EventId)
end

function XAEventNode:GetTitle()
    return self.EventConfig.Title
end

function XAEventNode:GetTitleContent()
    return self.EventConfig.TitleContent
end

function XAEventNode:GetRoleIcon()
    return self.EventConfig.RoleIcon
end

function XAEventNode:GetRoleName()
    return self.EventConfig.RoleName
end

function XAEventNode:GetRoleContent()
    return self.EventConfig.RoleContent
end

function XAEventNode:GetBgAsset()
    return self.EventConfig.BgAsset
end

-- 获取事件的描述
function XAEventNode:GetDesc()
    return self.EventConfig.EventDesc
end

function XAEventNode:GetEventType()  
    return self.EventConfig.Type
end

function XAEventNode:GetEventId()
    return self.EventConfig.EventId
end

function XAEventNode:GetNextStepId()
    return self.EventConfig.NextStepId
end

-- 获取右下角确定按钮文案
function XAEventNode:GetBtnConfirmText()
    return self.EventConfig.ConfirmContent
end

function XAEventNode:GetNodeTypeIcon()
    if self.EventClientConfig and self.EventClientConfig.NodeTypeIcon then
        return self.EventClientConfig.NodeTypeIcon
    end
    return XAEventNode.Super.GetNodeTypeIcon(self)
end

function XAEventNode:GetNodeTypeDesc()
    if self.EventClientConfig and self.EventClientConfig.NodeTypeDesc then
        return self.EventClientConfig.NodeTypeDesc
    end
    return XAEventNode.Super.GetNodeTypeDesc(self)
end

function XAEventNode:GetNodeTypeName()
    if self.EventClientConfig and self.EventClientConfig.NodeTypeName then
        return self.EventClientConfig.NodeTypeName
    end
    return XAEventNode.Super.GetNodeTypeName(self)
end

-- function XAEventNode:GetShowDatas()
--     return { XTheatreConfigs.GetClientConfig("EventNodeIcon", self.EventConfig.Type) }
-- end

function XAEventNode:Trigger(callback)
    XAEventNode.Super.Trigger(self, function()
        -- 打开页面
        XLuaUiManager.Open("UiTheatreOutpost")
    end)
end

function XAEventNode:RequestTriggerNode(callback, optionIndex)
    local requestBody = {
        CurStepId = self.EventConfig.StepId,
        OptionId = optionIndex,
    }
    XNetwork.CallWithAutoHandleErrorCode("TheatreEventNodeNextStepRequest", requestBody, function(res)
        local newEventNode = self:UpdateNextStepEventNode(res.NextStepId)
        -- 发放奖励
        if table.nums(res.RewardGoodsList) > 0 then
            XUiManager.OpenUiObtain(res.RewardGoodsList)
        end
        if callback then callback(newEventNode) end
    end)
end

function XAEventNode:UpdateNextStepEventNode(nextStepId)
    local newData = self.RawData
    newData.CurStepId = nextStepId
    return XDataCenter.TheatreManager.GetCurrentAdventureManager():
        GetCurrentChapter():UpdateNextEventNode(self, newData)
end

return XAEventNode
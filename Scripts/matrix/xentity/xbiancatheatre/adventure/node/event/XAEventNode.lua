local XANode = require("XEntity/XBiancaTheatre/Adventure/Node/XANode")
local XAEventNode = XClass(XANode, "XAEventNode")

function XAEventNode:Ctor()
    self.EventConfig = nil
    self.EventClientConfig = nil
end

function XAEventNode:InitWithServerData(data)
    XAEventNode.Super.InitWithServerData(self, data)
    -- 获取事件配置信息
    self:UpdateConfig(data.EventId, data.CurStepId)
    self.EventClientConfig = XBiancaTheatreConfigs.GetTheatreEventClientConfig(data.EventId)
end

function XAEventNode:UpdateConfig(eventId, curStepId)
    self.EventConfig = XBiancaTheatreConfigs.GetEventNodeConfig(eventId, curStepId)
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

function XAEventNode:Trigger(callback)
    XAEventNode.Super.Trigger(self, function()
        -- 打开页面
        XLuaUiManager.Open("UiBiancaTheatreOutpost")
    end)
end

--事件，下一步，选择选项
function XAEventNode:RequestTriggerNode(callback, optionIndex)
    local requestBody = {
        CurEventStepId = self:GetCurStepId(),
        OptionId = optionIndex, --选项ID，1开始
    }
    local curAdventureManager = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager()
    local curStep = curAdventureManager:GetCurrentChapter():GetCurStep()
    XNetwork.CallWithAutoHandleErrorCode("BiancaTheatreEventNodeNextStepRequest", requestBody, function(res)
        local newEventStep = self:UpdateNextStepEvent(res.NextEventStepId, res.FightTemplateId, curStep)
        -- 发放奖励、获得局内道具
        if not (XTool.IsTableEmpty(res.RewardGoodsList) and XTool.IsTableEmpty(res.InnerItemIds)) then
            XDataCenter.BiancaTheatreManager.AddTipOpenData("UiBiancaTheatreTipReward", nil, res.RewardGoodsList, nil, nil, nil, res.InnerItemIds)
            XDataCenter.BiancaTheatreManager.CheckTipOpenList()
        end
        -- 检查移除局内道具
        local optionType = self.EventConfig.OptionType[optionIndex]
        if optionType == XBiancaTheatreConfigs.SelectableEventItemType.ConsumeItem and self.EventConfig.OptionItemType[optionIndex] == XBiancaTheatreConfigs.XEventStepItemType.InnerItem then
            curAdventureManager:RemoveItemData(self.EventConfig.OptionItemId[optionIndex])
        end
        -- 检查灵视是否开启
        local isEvent = self.NodeType and self.NodeType == XBiancaTheatreConfigs.NodeType.Event
        local isVisionSelect = self.EventConfig.StepRewardItemType and self.EventConfig.StepRewardItemType == XBiancaTheatreConfigs.XEventStepItemType.OpenVision
        if isEvent and isVisionSelect then
            XDataCenter.BiancaTheatreManager.UpdateIsOpenVision(true)
            XDataCenter.BiancaTheatreManager.OpenVision()
        end
        -- 记录通过的步骤节点
        XDataCenter.BiancaTheatreManager.AddPassedEventRecord(self.EventConfig.EventId, self.EventConfig.StepId)
        if callback then callback(newEventStep) end
    end)
end

-- 更新下一个事件节点
function XAEventNode:UpdateNextStepEvent(nextStepId, fightTemplateId, curStep)
    self:SetCurStepId(nextStepId)
    self:SetFightTemplateId(fightTemplateId)
    local newData = self.RawData
    return curStep:UpdateNextEventNode(self, newData)
end

function XAEventNode:GetNodeTypeSmallIcon()
    return self.EventClientConfig and self.EventClientConfig.SmallIcon or XAEventNode.Super.GetNodeTypeSmallIcon(self)
end

return XAEventNode
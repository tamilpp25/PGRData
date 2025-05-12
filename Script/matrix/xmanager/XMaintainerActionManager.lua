local XBoxNodeEntity = require("XEntity/XMaintainerAction/XBoxNodeEntity")
local XCardChangeNodeEntity = require("XEntity/XMaintainerAction/XCardChangeNodeEntity")
local XDirectionChangeNodeEntity = require("XEntity/XMaintainerAction/XDirectionChangeNodeEntity")
local XExtraActionPointNodeEntity = require("XEntity/XMaintainerAction/XExtraActionPointNodeEntity")
local XFallBackNodeEntity = require("XEntity/XMaintainerAction/XFallBackNodeEntity")
local XFightNodeEntity = require("XEntity/XMaintainerAction/XFightNodeEntity")
local XForwardNodeEntity = require("XEntity/XMaintainerAction/XForwardNodeEntity")
local XMaintainerActionGameDataEntity = require("XEntity/XMaintainerAction/XMaintainerActionGameDataEntity")
local XMaintainerActionPlayerEntity = require("XEntity/XMaintainerAction/XMaintainerActionPlayerEntity")
local XNoneNodeEntity = require("XEntity/XMaintainerAction/XNoneNodeEntity")
local XStartNodeEntity = require("XEntity/XMaintainerAction/XStartNodeEntity")
local XUnKnowNodeEntity = require("XEntity/XMaintainerAction/XUnKnowNodeEntity")
local XSimulationFightNodeEntity = require("XEntity/XMaintainerAction/XSimulationFightNodeEntity")
local XWarehouseNodeEntity = require("XEntity/XMaintainerAction/XWarehouseNodeEntity")
local XExploreNodeEntity = require("XEntity/XMaintainerAction/XExploreNodeEntity")
local XMentorNodeEntity = require("XEntity/XMaintainerAction/XMentorNodeEntity")

XMaintainerActionManagerCreator = function()
    local XMaintainerActionManager = {}
    local CSTextManagerGetText = CS.XTextManager.GetText
    local CSXGameClientConfig = CS.XGame.ClientConfig

    local MapNodeList = {}
    local PlayerDic = {}
    local GameData = {}
    local RecordData = nil
    
    local IsFightWin = false
    local MessageTypeList = {}
    
    local RESET_COUNT_DOWN_NAME = "MaintainerActionReset"
    
    local METHOD_NAME = {
        MaintainerActionNodeEventRequest = "MaintainerActionNodeEventRequest",
        MaintainerActionPlayCardRequest = "MaintainerActionPlayCardRequest",
        MaintainerActionRecordRequest = "MaintainerActionRecordRequest",
    }

    function XMaintainerActionManager.Init()
        XMaintainerActionManager.ClearRecordData()
    end

    function XMaintainerActionManager.CreatePlayer(data)
        PlayerDic = {}
        for index,player in pairs(data.Players) do
            PlayerDic[player.PlayerId] = XMaintainerActionPlayerEntity.New(player.PlayerId)
            PlayerDic[player.PlayerId]:UpdateData(player)
        end
    end
    
    function XMaintainerActionManager.CreateGameData(data)
        GameData = XMaintainerActionGameDataEntity.New()
        GameData:UpdateData(data)
        local nowTime = XTime.GetServerNowTimestamp()
        XCountDown.RemoveTimer(RESET_COUNT_DOWN_NAME)
        XCountDown.CreateTimer(RESET_COUNT_DOWN_NAME, data.ResetTime - nowTime)
    end

    function XMaintainerActionManager.CreateMap(data)
        MapNodeList = {}
        for _,node in pairs(data.Nodes) do
            MapNodeList = MapNodeList or {}
            XMaintainerActionManager.CreateNode(node)
        end
    end
    
    function XMaintainerActionManager.CreateNode(node)
        local nodeEntity = {}
        if node.NodeType == XMaintainerActionConfigs.NodeType.UnKnow then
            nodeEntity = XUnKnowNodeEntity.New(node.NodeId, node.NodeType)
        elseif node.NodeType == XMaintainerActionConfigs.NodeType.Start then
            nodeEntity = XStartNodeEntity.New(node.NodeId, node.NodeType)
        elseif node.NodeType == XMaintainerActionConfigs.NodeType.Fight then
            nodeEntity = XFightNodeEntity.New(node.NodeId, node.NodeType)
        elseif node.NodeType == XMaintainerActionConfigs.NodeType.Box then
            nodeEntity = XBoxNodeEntity.New(node.NodeId, node.NodeType)
        elseif node.NodeType == XMaintainerActionConfigs.NodeType.None then
            nodeEntity = XNoneNodeEntity.New(node.NodeId, node.NodeType)
        elseif node.NodeType == XMaintainerActionConfigs.NodeType.Forward then
            nodeEntity = XForwardNodeEntity.New(node.NodeId, node.NodeType)
        elseif node.NodeType == XMaintainerActionConfigs.NodeType.FallBack then
            nodeEntity = XFallBackNodeEntity.New(node.NodeId, node.NodeType)
        elseif node.NodeType == XMaintainerActionConfigs.NodeType.CardChange then
            nodeEntity = XCardChangeNodeEntity.New(node.NodeId, node.NodeType)
        elseif node.NodeType == XMaintainerActionConfigs.NodeType.DirectionChange then
            nodeEntity = XDirectionChangeNodeEntity.New(node.NodeId, node.NodeType)
        elseif node.NodeType == XMaintainerActionConfigs.NodeType.ActionPoint then
            nodeEntity = XExtraActionPointNodeEntity.New(node.NodeId, node.NodeType)
        elseif node.NodeType == XMaintainerActionConfigs.NodeType.SimulationFight then
            nodeEntity = XSimulationFightNodeEntity.New(node.NodeId, node.NodeType)
        elseif node.NodeType == XMaintainerActionConfigs.NodeType.Warehouse then
            nodeEntity = XWarehouseNodeEntity.New(node.NodeId, node.NodeType)
        elseif node.NodeType == XMaintainerActionConfigs.NodeType.Explore then
            nodeEntity = XExploreNodeEntity.New(node.NodeId, node.NodeType)
        elseif node.NodeType == XMaintainerActionConfigs.NodeType.Mentor then
            nodeEntity = XMentorNodeEntity.New(node.NodeId, node.NodeType)
        end
        local tmpData = {}
        tmpData.Value = node.Value
        tmpData.EventId = node.EventId
        nodeEntity:UpdateData(tmpData)
        MapNodeList[node.NodeId] = nodeEntity
        return nodeEntity
    end
    
    function XMaintainerActionManager.CreateRecordData(data)
        RecordData = data
    end

    function XMaintainerActionManager.UpdateGameData(data)
        if GameData and next(GameData) then
            GameData:UpdateData(data)
        end
    end
    
    function XMaintainerActionManager.GetRecordData()
        return RecordData
    end
    
    function XMaintainerActionManager.ClearRecordData()
        RecordData = nil
    end
    
    function XMaintainerActionManager.GetGameData()
        return GameData
    end
    
    function XMaintainerActionManager.GetPlayerDic()
        return PlayerDic
    end
    
    function XMaintainerActionManager.GetPlayerById(id)
        return PlayerDic[id]
    end
    
    function XMaintainerActionManager.GetPlayerMySelf()
        return PlayerDic[XPlayer.Id]
    end
    
    function XMaintainerActionManager.GetMapNodeList()
        return MapNodeList
    end
    
    function XMaintainerActionManager.GetMapNodeById(id)
        return MapNodeList[id]
    end
    
    function XMaintainerActionManager.GetResetCountDownName()
        return RESET_COUNT_DOWN_NAME
    end
    
    function XMaintainerActionManager.AddMessageType(type)
        MessageTypeList = MessageTypeList or {}
        MessageTypeList[type] = true
    end
    
    function XMaintainerActionManager.GetMessageTypeList()
        return MessageTypeList
    end
    
    function XMaintainerActionManager.GetMaintainerActionName()
        local maintainerActionCfg = XMaintainerActionConfigs.GetMaintainerActionTemplates()
        return maintainerActionCfg.Name
    end
    
    function XMaintainerActionManager.GetMaintainerActionStartTime()
        local maintainerActionCfg = XMaintainerActionConfigs.GetMaintainerActionTemplates()
        local startTime = XFunctionManager.GetStartTimeByTimeId(maintainerActionCfg.TimeId) or 0
        return startTime
    end
    
    function XMaintainerActionManager.CheckIsFightComplete()
        return GameData:IsFightOver()
    end
    
    function XMaintainerActionManager.CheckIsBoxComplete()
        return GameData:IsBoxOver()
    end
    
    function XMaintainerActionManager.CheckIsWarehouseComplete()
        return GameData:IsWarehouseOver() or not GameData:GetHasWarehouseNode()
    end
    
    function XMaintainerActionManager.CheckIsActionPointOver()
        local maxCount = GameData:GetMaxDailyActionCount() + GameData:GetExtraActionCount()
        local IsOver = GameData:GetUsedActionCount() >= maxCount
        return IsOver
    end
    
    function XMaintainerActionManager.CheckIsAllComplete()
        return XMaintainerActionManager.CheckIsBoxComplete() and 
        XMaintainerActionManager.CheckIsFightComplete() and 
        XMaintainerActionManager.CheckIsWarehouseComplete()
    end
    
    function XMaintainerActionManager.CheckDayUpdateMessage()
        if MessageTypeList then
            if MessageTypeList[XMaintainerActionConfigs.MessageType.DayUpdate] then
                XUiManager.TipText("MaintainerActionEventDayUpdate")
                XMaintainerActionManager.RemoveMessageType(XMaintainerActionConfigs.MessageType.DayUpdate)
            end
        end
    end

    function XMaintainerActionManager.CheckWeekUpdateMessage()
        if MessageTypeList then
            if MessageTypeList[XMaintainerActionConfigs.MessageType.WeekUpdate] then
                XUiManager.TipText("MaintainerActionEventWeekUpdate")
                XScheduleManager.ScheduleOnce(function()
                        XLuaUiManager.RunMain()
                    end, 1)
                return true
            end
        end
        return false
    end

    function XMaintainerActionManager.CheckEventCompleteMessage(cb)
        local IsShowMessage = false
        if MessageTypeList then
            if MessageTypeList[XMaintainerActionConfigs.MessageType.EventComplete] then
                local strFight = CSTextManagerGetText("MaintainerActionWinFightText", GameData:GetMaxFightWinCount(), GameData:GetMaxFightWinCount())
                local strBox = CSTextManagerGetText("MaintainerActionWinBoxText", GameData:GetMaxBoxCount(), GameData:GetMaxBoxCount())
                local strWarehouse = GameData:GetHasWarehouseNode() and CSTextManagerGetText("MaintainerActionWinWarehouseText", GameData:GetMaxWarehouseFinishCount(), GameData:GetMaxWarehouseFinishCount()) or nil
                local msgList = {strFight, strBox, strWarehouse}
                local hintText = CSTextManagerGetText("MaintainerActionFinishHint", CSTextManagerGetText("MaintainerActionTaskCount"))
                XScheduleManager.ScheduleOnce(function()
                        XLuaUiManager.Open("UiFubenMaintaineractionTipLayer", hintText, msgList, XMaintainerActionConfigs.TipType.EventComplete, cb)
                    end, 1)
                XMaintainerActionManager.RemoveMessageType(XMaintainerActionConfigs.MessageType.EventComplete)
                XMaintainerActionManager.RemoveMessageType(XMaintainerActionConfigs.MessageType.FightComplete)
                IsShowMessage = true
            end
        end
        if not IsShowMessage then
            if cb then cb() end
        end
    end
    
    function XMaintainerActionManager.CheckFightCompleteMessage(cb)
        local IsShowMessage = false
        if MessageTypeList then
            if MessageTypeList[XMaintainerActionConfigs.MessageType.FightComplete] then
                local hintText = CSTextManagerGetText("MaintainerActionFinishHint", CSTextManagerGetText("MaintainerActionWinCount"))
                XScheduleManager.ScheduleOnce(function()
                        XLuaUiManager.Open("UiFubenMaintaineractionTipLayer", hintText, nil, XMaintainerActionConfigs.TipType.FightComplete, cb)
                    end, 1)
                XMaintainerActionManager.RemoveMessageType(XMaintainerActionConfigs.MessageType.FightComplete)
                IsShowMessage = true
            end
        end
        if not IsShowMessage then
            if cb then cb() end
        end
    end
    
    function XMaintainerActionManager.CheckMentorCompleteMessage(cb)
        local IsShowMessage = false
        local IsMentorFinish = GameData:GetMentorStatus() == XMaintainerActionConfigs.MonterNodeStatus.Finish
        if XMaintainerActionManager.CheckIsNewFinish(XMaintainerActionConfigs.MessageType.MentorComplete) and IsMentorFinish then
            local hintText = CSTextManagerGetText("MaintainerActionFinishHint", CSTextManagerGetText("MaintainerActionMentorCount"))
            XScheduleManager.ScheduleOnce(function()
                    XLuaUiManager.Open("UiFubenMaintaineractionTipLayer", hintText, nil, XMaintainerActionConfigs.TipType.MentorComplete, cb)
                end, 1)
            XDataCenter.MaintainerActionManager.AddFinish(XMaintainerActionConfigs.MessageType.MentorComplete, GameData:GetMentorStatus())
            IsShowMessage = true
        end
        if not IsShowMessage then
            if cb then cb() end
        end
    end
    
    function XMaintainerActionManager.ClearMessageTypeList()
        MessageTypeList = {}
    end
    
    function XMaintainerActionManager.RemoveMessageType(type)
        if MessageTypeList and MessageTypeList[type] then
            MessageTypeList[type] = nil
        end
    end
    
    function XMaintainerActionManager.IsStart()
        return GameData and next(GameData)
    end

    function XMaintainerActionManager.CheckIsOpen()
        local functionId = XFunctionManager.FunctionName.MaintainerAction
        local isOpen = XFunctionManager.JudgeCanOpen(functionId)
        if isOpen then
            if not XDataCenter.MaintainerActionManager.IsStart() then
                local startTime = XDataCenter.MaintainerActionManager.GetMaintainerActionStartTime()
                local nowTime = XTime.GetServerNowTimestamp()
                local desc = ""
                if startTime >= nowTime then
                    local timeStr = XTime.TimestampToGameDateTimeString(startTime, "yyyy/MM/dd")
                    desc = CS.XTextManager.GetText("MaintainerActionNotStart",timeStr)
                else
                    desc = CS.XTextManager.GetText("MaintainerActionNotOpen")
                end 
                return false, desc
            else
                return true
            end
        else
            return false, XFunctionManager.GetFunctionOpenCondition(functionId)
        end
    end

    ---------------------------------------stage相关-------------------------------------->>>
    --function XMaintainerActionManager.InitStageInfo()
    --    local maintainerActionCfg = XMaintainerActionConfigs.GetMaintainerActionTemplates()
    --    local maintainerActionLevelCfg = XMaintainerActionConfigs.GetMaintainerActionLevelTemplates()
    --    for _, level in pairs(maintainerActionLevelCfg) do
    --        local stageIdList = level.StageIds
    --        for _, stageId in pairs(stageIdList) do
    --            local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    --            stageInfo.Type = XDataCenter.FubenManager.StageType.MaintainerAction
    --            stageInfo.ChapterName = maintainerActionCfg.Name
    --        end
    --    end
    --end
    
    function XMaintainerActionManager.OpenMaintainerActionWind()
        XDataCenter.MaintainerActionManager.ClearMessageTypeList()
        if not XMVCA.XSubPackage:CheckSubpackage(XEnumConst.FuBen.ChapterType.MaintainerAction) then
            return
        end
        XLuaUiManager.Open("UiFubenMaintaineraction")
    end

    ---------------------------------------stage相关---------------------------------------<<<

    function XMaintainerActionManager.CheckIsNewStoryID(Id)
        if XSaveTool.GetData(string.format("%d%s%s", XPlayer.Id, "MaintainerActionStory", Id)) then
            return false
        end
        return true
    end

    function XMaintainerActionManager.MarkStoryID(Id)
        if not XSaveTool.GetData(string.format("%d%s%s", XPlayer.Id, "MaintainerActionStory", Id)) then
            XSaveTool.SaveData(string.format("%d%s%s", XPlayer.Id, "MaintainerActionStory", Id), Id)
        end
    end
    
    function XMaintainerActionManager.CheckIsNewFinish(type)
        if XSaveTool.GetData(string.format("%d%s%d", XPlayer.Id, "MaintainerActionMentorFinish", type)) then
            return false
        end
        return true
    end

    function XMaintainerActionManager.AddFinish(type, curStatus)
        if not XSaveTool.GetData(string.format("%d%s%d", XPlayer.Id, "MaintainerActionMentorFinish", type)) then
            XSaveTool.SaveData(string.format("%d%s%d", XPlayer.Id, "MaintainerActionMentorFinish", type), curStatus)
        end
    end
    
    function XMaintainerActionManager.DeletFinish(type, curStatus)
        local status = XSaveTool.GetData(string.format("%d%s%d", XPlayer.Id, "MaintainerActionMentorFinish", type))
        if status and curStatus < status then
            XSaveTool.RemoveData(string.format("%d%s%d", XPlayer.Id, "MaintainerActionMentorFinish", type))
        end
    end
    
    function XMaintainerActionManager.NodeEventRequest(cb, errorCb)
        XNetwork.Call(METHOD_NAME.MaintainerActionNodeEventRequest, {}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    if errorCb then errorCb(res.Node) end
                    return
                end
                if cb then cb(res.Node) end
            end)
    end

    function XMaintainerActionManager.PlayerMoveRequest(cardNum, posId, cb)
        XNetwork.Call(METHOD_NAME.MaintainerActionPlayCardRequest, {Card = cardNum}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                if cb then cb(res) end
            end)
    end
    
    function XMaintainerActionManager.PlayerRecordRequest(cb)
        if RecordData then
            if cb then cb() end
            return
        end
        XNetwork.Call(METHOD_NAME.MaintainerActionRecordRequest, {}, function(res)
                if res.Code ~= XCode.Success then
                    XUiManager.TipCode(res.Code)
                    return
                end
                XMaintainerActionManager.CreateRecordData(res.Records)
                if cb then cb() end
            end)
    end

    XMaintainerActionManager.Init()
    return XMaintainerActionManager
end

XRpc.NotifyMaintainerActionData = function(data)
    XDataCenter.MaintainerActionManager.ClearRecordData()
    XDataCenter.MaintainerActionManager.CreatePlayer(data)
    XDataCenter.MaintainerActionManager.CreateGameData(data)
    XDataCenter.MaintainerActionManager.CreateMap(data)
    XDataCenter.MaintainerActionManager.AddMessageType(XMaintainerActionConfigs.MessageType.WeekUpdate)
    XDataCenter.MaintainerActionManager.DeletFinish(XMaintainerActionConfigs.MessageType.MentorComplete, data.MentorStatus)
    XEventManager.DispatchEvent(XEventId.EVENT_MAINTAINERACTION_WEEK_UPDATA)
end

XRpc.NotifyMaintainerActionDailyReset = function(data)
    XDataCenter.MaintainerActionManager.UpdateGameData(data)
    XDataCenter.MaintainerActionManager.AddMessageType(XMaintainerActionConfigs.MessageType.DayUpdate)
    XEventManager.DispatchEvent(XEventId.EVENT_MAINTAINERACTION_DAY_UPDATA)
end

XRpc.NotifyMaintainerActionFightWin = function(data)
    local mySelf = XDataCenter.MaintainerActionManager.GetPlayerMySelf()
    mySelf:MarkNodeEvent()
    XDataCenter.MaintainerActionManager.UpdateGameData(data)
    
    local IsFightComplete = XDataCenter.MaintainerActionManager.CheckIsFightComplete()
    local IsAllComplete = XDataCenter.MaintainerActionManager.CheckIsAllComplete()
    if IsAllComplete then
        XDataCenter.MaintainerActionManager.AddMessageType(XMaintainerActionConfigs.MessageType.EventComplete) 
    elseif IsFightComplete then
        XDataCenter.MaintainerActionManager.AddMessageType(XMaintainerActionConfigs.MessageType.FightComplete)
    end
end

XRpc.NotifyMaintainerActionNodeChange = function(data)
    local node = XDataCenter.MaintainerActionManager.CreateNode(data.Node)
    if node:GetIsMentor() then
        local gameData = XDataCenter.MaintainerActionManager.GetGameData()
        gameData:SetMentorStatus(node:GetMentorStatus())
    end
    XEventManager.DispatchEvent(XEventId.EVENT_MAINTAINERACTION_NODE_CHANGE)
end
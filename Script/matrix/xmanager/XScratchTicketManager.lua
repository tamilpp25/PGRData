-- 刮刮乐活动管理器
XScratchTicketManagerCreator = function()
    local XScratchTicketManager = {}
    local AllActivities = {}
    XScratchTicketManager.PlayStatus = {
        NotStart = 1, --未开始游戏
        Playing = 2, --正在游玩
    }
    local REQUEST_NAMES = {
        StartScratch = "ScratchTicketActivityStartRequest", --开始刮刮卡游戏
        OpenGrid = "ScratchTicketActivityOpenGridRequest", --预览格子
        ExChange = "ScratchTicketActivityEndRequest", --开奖
        Reset = "ScratchTicketActivityResetRequest", --重置刮刮卡(完成一局游戏)
    }
    function XScratchTicketManager.Init()

    end

    function XScratchTicketManager.UpdateActivity(id, activityDb)

    end
    --================
    --刷新活动数据
    --[[
    public class ScratchTicketActivityDb
    {
    public int Id; --对应Activity表Id

    //已经开放的Grid
    public List<ScratchTicketActivityOpenGridDb>    OpenGrid = new List<ScratchTicketActivityOpenGridDb>();

    //缓存配置表
    public int LuckNumber { get; set; }

    //选择哪一个开奖列
    public int SelectOpen { get; set; }

    public int GridCfgIndex { get; set; }  --ScratchTicket表GridIds的序号，对应Grid表

    public int CfgIndex { get; set; } --Activity表ScratchTicket数组的序号，对应ScratchTicket的Id
    }

    public class ScratchTicketActivityOpenGridDb
    {
    public int Index;
    public int Num;
    }
    ]]
    --================
    function XScratchTicketManager.UpdateActivities(activityDbs)
        for id, activity in pairs(activityDbs) do
            if not AllActivities[activity.Id] then
                local controllerScript = require("XEntity/XScratchTicket/XScratchTicketActivityController")
                AllActivities[activity.Id] = controllerScript.New(activity.Id)
            end
            AllActivities[activity.Id]:UpdateData(activity)
        end
    end

    function XScratchTicketManager.GetActivityController(id)
        if not AllActivities[id] then
            local controllerScript = require("XEntity/XScratchTicket/XScratchTicketActivityController")
            AllActivities[id] = controllerScript.New(id)
        end
        return AllActivities[id]
    end

    function XScratchTicketManager.StartGame(activityId)
        if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ScratchTicket, true) then
            XNetwork.Call(REQUEST_NAMES.StartScratch, { Id = activityId }, function(reply)
                    if reply.Code ~= XCode.Success then
                        XUiManager.TipCode(reply.Code)
                        return
                    end
                    AllActivities[activityId]:UpdateData(reply.ActivityDb)
                    XEventManager.DispatchEvent(XEventId.EVENT_SCRATCH_TICKET_ACTIVITY_START, activityId)
                end)
        end
    end

    function XScratchTicketManager.OpenGrid(activityId, gridIndex)
        XNetwork.Call(REQUEST_NAMES.OpenGrid, { Id = activityId, GridIndex = gridIndex - 1 }, function(reply)
                if reply.Code ~= XCode.Success then
                    XUiManager.TipCode(reply.Code)
                    return
                end
                AllActivities[reply.Id]:OpenGrid(reply.GridIndex + 1, reply.Num)
                XEventManager.DispatchEvent(XEventId.EVENT_SCRATCH_TICKET_OPEN_GRID, activityId)
            end)
    end

    function XScratchTicketManager.ExChange(activityId, openIndex)
        XNetwork.Call(REQUEST_NAMES.ExChange, { Id = activityId, OpenIndex = openIndex }, function(reply)
                if reply.Code ~= XCode.Success then
                    XUiManager.TipCode(reply.Code)
                    return
                end
                AllActivities[reply.ActivityDb.Id]:UpdateData(reply.ActivityDb)
                local ticket = AllActivities[reply.ActivityDb.Id]:GetTicket()
                local rewardId
                local rewardList
                if reply.ActivityDb.IsWin then
                    rewardId = ticket:GetWinRewardId()
                else
                    rewardId = ticket:GetLoseRewardId()
                end
                if rewardId and rewardId > 0 then
                    rewardList = XRewardManager.GetRewardList(rewardId)
                end
                XEventManager.DispatchEvent(XEventId.EVENT_SCRATCH_TICKET_SHOW_RESULT, activityId, rewardList)
            end)
    end

    function XScratchTicketManager.ResetGame(activityId)
        XNetwork.Call(REQUEST_NAMES.Reset, { Id = activityId }, function(reply)
                if reply.Code ~= XCode.Success then
                    XUiManager.TipCode(reply.Code)
                    return
                end
                AllActivities[activityId]:UpdateData(reply.ActivityDb)
                XEventManager.DispatchEvent(XEventId.EVENT_SCRATCH_TICKET_RESET, activityId)
            end)
    end
    XScratchTicketManager.Init()
    return XScratchTicketManager
end

--===============
--刮刮乐活动数据推送
--@param db : {List<ScratchTicketActivityDb>}
--===============
XRpc.NotifyScratchTicketActivity = function(db)
    XDataCenter.ScratchTicketManager.UpdateActivities(db.ActivityDbs)
end
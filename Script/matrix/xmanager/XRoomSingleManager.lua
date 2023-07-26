XRoomSingleManager = XRoomSingleManager or {}

XRoomSingleManager.PlayerType = {
    None = 0,
    Firend = 1,
    Guild = 2,
    Stranger = 3,
}

XRoomSingleManager.BtnType = {
    None = 0,--隐藏按钮
    SelectStage = 1,--返回选关界面
    Again = 2,--再次挑战
    Next = 3,--下一关
    Main = 4,--返回主界面
    ArenaOnlineBack = 5,--返回（联机）
    ArenaOnlineAgain = 6,--再次挑战（联机）
}

XRoomSingleManager.AgainBtnType = {
    [XRoomSingleManager.BtnType.Again] = true,
    [XRoomSingleManager.BtnType.ArenaOnlineAgain] = true,
}

local FIGHT_EVENT = "Share/Fight/FightEvent.tab"
local FightEventCfg    = {}

function XRoomSingleManager.Init()
    FightEventCfg = XTableManager.ReadByIntKey(FIGHT_EVENT, XTable.XTableFightEvent, "Id")
end

function XRoomSingleManager.GetEventDescByMapId(stageId)
    local eventId = XDataCenter.FubenManager.GetStageCfg(stageId).EventId
    if eventId <= 0 then
        return nil
    end
    local eventCfg = FightEventCfg[eventId]
    if not eventCfg then
        return nil
    end
    return eventCfg.Description
end

function XRoomSingleManager.GetEvenDesc(eventId)
    local eventCfg = FightEventCfg[eventId]
    return eventCfg.Description
end

function XRoomSingleManager.GetBtnText(btnType)
    if    btnType == XRoomSingleManager.BtnType.SelectStage then return CS.XTextManager.GetText("BattleWinSelectStage")
    elseif btnType == XRoomSingleManager.BtnType.Again then return CS.XTextManager.GetText("BattleWinAgain")
    elseif btnType == XRoomSingleManager.BtnType.Next then return CS.XTextManager.GetText("BattleWinNext")
    elseif btnType == XRoomSingleManager.BtnType.Main then return CS.XTextManager.GetText("BattleWinMain")
    elseif btnType == XRoomSingleManager.BtnType.ArenaOnlineBack then return CS.XTextManager.GetText("BattleWinArenaOnlineBack")
    elseif btnType == XRoomSingleManager.BtnType.ArenaOnlineAgain then return CS.XTextManager.GetText("BattleWinArenaOnlineAgain")
    else return "" end
end
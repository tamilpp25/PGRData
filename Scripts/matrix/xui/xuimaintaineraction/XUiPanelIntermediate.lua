local XUiPanelIntermediate = XClass(nil, "XUiPanelIntermediate")
local XUiGridMapNote = require("XUi/XUiMaintainerAction/XUiGridMapNote")
local XUiGridPlayer = require("XUi/XUiMaintainerAction/XUiGridPlayer")
local MapNodeMaxCount = 16
local RouteType = {
    MoveRoute = 1,
    CradRoute = 2,
}
function XUiPanelIntermediate:Ctor(ui,base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    XTool.InitUiObject(self)
    self.GridMap.gameObject:SetActiveEx(false)
    self.Avatar.gameObject:SetActiveEx(false)
    self:CreatStageMap()
end

function XUiPanelIntermediate:CreatStageMap()
    local mapNodeList = XDataCenter.MaintainerActionManager.GetMapNodeList()
    local playerDic = XDataCenter.MaintainerActionManager.GetPlayerDic()
    self.LineList = {}
    self.IatticeList = {}
    self.NodeList = {}
    self.PlayerList = {}
    for i = 1, MapNodeMaxCount do
        local line = self.PanelLine:GetObject(string.format("Line%d",i))
        local Iattice = self.PanelIattice:GetObject(string.format("Iattice%d",i))
        if not line or not Iattice then
            break
        else
            table.insert(self.LineList, line)
            table.insert(self.IatticeList, Iattice)
            line.gameObject:SetActiveEx(false)
        end
    end

    for _,mapNode in pairs(mapNodeList)do
        local ui = CS.UnityEngine.Object.Instantiate(self.GridMap,self.IatticeList[mapNode:GetId() + 1])
        ui.gameObject:SetActiveEx(true)
        local grid = XUiGridMapNote.New(ui,self)
        grid:UpdateNote(mapNode)
        --if mapNode:GetIsNeedPlayAnime() then
        --    grid:PlayEventAnime()
        --end
        self.NodeList[mapNode:GetId()] = grid
    end

    for key,player in pairs(playerDic)do
        local ui = CS.UnityEngine.Object.Instantiate(self.Avatar,self.Transform)
        ui.gameObject:SetActiveEx(true)
        local grid = XUiGridPlayer.New(ui,self)
        grid:SetPlayerData(player)
        self.PlayerList[key] = grid
    end
end

function XUiPanelIntermediate:UpdatePanel()
    local mapNodeList = XDataCenter.MaintainerActionManager.GetMapNodeList()
    for _,mapNode in pairs(mapNodeList)do
        self.NodeList[mapNode:GetId()]:UpdateNote(mapNode)
    end
end

function XUiPanelIntermediate:SetCurNodeNameTag(id)
    local player = self.PlayerList[id]
    if player then
        player:SetCurNodeNameTag()
    end
end

function XUiPanelIntermediate:MovePlayerById(id,targetNodeId,cb)
    local player = self.PlayerList[id]
    if player then
        local route = self:CreateRoute(id,nil,targetNodeId,RouteType.MoveRoute)
        player:Move(route,cb)
    end
end

function XUiPanelIntermediate:ReverseMovePlayerById(id,targetNodeId,cb)
    local player = self.PlayerList[id]
    if player then
        player:DoChangeDirection()
        local route = self:CreateRoute(id,nil,targetNodeId,RouteType.MoveRoute)
        player:DoChangeDirection()
        player:Move(route,cb)
    end
end

function XUiPanelIntermediate:CreateRoute(id,cardNum,targetNodeId,type)
    local playerDic = XDataCenter.MaintainerActionManager.GetPlayerDic()
    local player = playerDic[id]
    if not player then return nil end

    local route = {}
    local curNodeId = player:GetPosNodeId()
    local IsInStartNode = (curNodeId == 0)
    if type == RouteType.MoveRoute then
        local IsFirst = true
        for index = 1 , MapNodeMaxCount do
            if not IsFirst then
                table.insert(route,curNodeId)
            end
            if curNodeId == targetNodeId then
                break
            end
            if not player:GetIsReverse() then
                curNodeId = curNodeId < MapNodeMaxCount - 1 and curNodeId + 1 or 0
            else
                curNodeId = curNodeId > 0 and curNodeId - 1 or MapNodeMaxCount - 1
            end
            IsFirst = false
        end
    elseif type == RouteType.CradRoute then
        local IsFirst = true
        for index = 1 , cardNum + 1 do
            table.insert(route,curNodeId)
            if not IsFirst then
                if curNodeId == 0 then
                    break
                end
            end
            if not player:GetIsReverse() then
                curNodeId = curNodeId < MapNodeMaxCount - 1 and curNodeId + 1 or 0
            else
                curNodeId = curNodeId > 0 and curNodeId - 1 or (not IsInStartNode and 0 or MapNodeMaxCount - 1)
            end
            IsFirst = false
        end
    end
    return route
end

function XUiPanelIntermediate:ShowCardSelectRoute(cardNum)
    local route = self.Base.CardRouteList[cardNum]
    if not route then
       return 
    end

    for _,node in pairs(self.NodeList)do
        node:SetNodeState(XMaintainerActionConfigs.NodeState.Normal)
    end

    for _,routeId in pairs(route) do
        self.NodeList[routeId]:SetNodeState(XMaintainerActionConfigs.NodeState.OnRoute)
    end
    self.NodeList[route[#route]]:SetNodeState(XMaintainerActionConfigs.NodeState.Target)
end

function XUiPanelIntermediate:CreateCardRouteList()
    local gameData = XDataCenter.MaintainerActionManager.GetGameData()
    self.Base.CardRouteList = {}
    for _,card in pairs(gameData:GetCards()) do
        local route = self:CreateRoute(XPlayer.Id,card,nil,RouteType.CradRoute)
        self.Base.CardRouteList[card] = route
    end
end

function XUiPanelIntermediate:StopPlayerTween()
    for _,player in pairs(self.PlayerList) do
        player:StopTween()
    end
end


return XUiPanelIntermediate
local XUiPanelBelow = XClass(nil, "XUiPanelBelow")
local XUiGridCard = require("XUi/XUiMaintainerAction/XUiGridCard")
local CSTextManagerGetText = CS.XTextManager.GetText
local MaxCardCount = 3
local MaxMentorCount = 1
function XUiPanelBelow:Ctor(ui,base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    XTool.InitUiObject(self)
    self:CreatePanel()
    self:SetButtonCallBack()
    self:UnSelectAllCard()
end

function XUiPanelBelow:SetButtonCallBack()
    self.BtnRecording.CallBack = function()
        self:OnBtnRecordingClick()
    end
end

function XUiPanelBelow:OnBtnRecordingClick()
    XDataCenter.MaintainerActionManager.PlayerRecordRequest(function ()
            XLuaUiManager.Open("UiFubenMaintaineractionRecording")
        end)
end

function XUiPanelBelow:CreatePanel()
    self.BattleCount:GetObject("Title").text = CSTextManagerGetText("MaintainerActionWinCount")
    self.BattleFinish:GetObject("Title").text = CSTextManagerGetText("MaintainerActionWinCount")
    
    self.BoxCount:GetObject("Title").text = CSTextManagerGetText("MaintainerActionBoxCount")
    self.BoxFinish:GetObject("Title").text = CSTextManagerGetText("MaintainerActionBoxCount")
    
    self.MentorCount:GetObject("Title").text = CSTextManagerGetText("MaintainerActionMentorCount")
    self.MentorFinish:GetObject("Title").text = CSTextManagerGetText("MaintainerActionMentorCount")
    
    self.WarehouseCount:GetObject("Title").text = CSTextManagerGetText("MaintainerActionWarehouseCount")
    self.WarehouseFinish:GetObject("Title").text = CSTextManagerGetText("MaintainerActionWarehouseCount")
    
    self.ActionCount:GetObject("Title").text = CSTextManagerGetText("MaintainerActionDayPower")

    self.CardPos = {[1] = self.PanelOperating:GetObject("Pos1").transform.localPosition,
        [2] = self.PanelOperating:GetObject("Pos2").transform.localPosition,
        [3] = self.PanelOperating:GetObject("Pos3").transform.localPosition,
        [4] = self.PanelOperating:GetObject("PosNew").transform.localPosition}

    local btnCard = self.PanelOperating:GetObject("BtnCard")
    btnCard.gameObject:SetActiveEx(false)

    local gameData = XDataCenter.MaintainerActionManager.GetGameData()
    self.CardList = {}
    for index=1, MaxCardCount do
        local obj = CS.UnityEngine.Object.Instantiate(btnCard)
        obj.gameObject:SetActiveEx(true)
        obj.transform:SetParent(self.PanelOperating.transform, false)
        obj.transform.localPosition = self.CardPos[index]
        local grid = XUiGridCard.New(obj,self)
        local cardNums = gameData:GetCards()
        grid:SetCardNum(cardNums[index] or 0)
        grid:SetCardPosId(index)
        table.insert(self.CardList, grid)
    end
end

function XUiPanelBelow:UnSelectAllCard()
    for _,card in pairs(self.CardList) do
        card:SetCardState(XMaintainerActionConfigs.CardState.Normal)
    end
end

function XUiPanelBelow:UpdatePanel()
    local gameData = XDataCenter.MaintainerActionManager.GetGameData()
    local mapNodeList = XDataCenter.MaintainerActionManager.GetMapNodeList()
    
    self.BattleCount:GetObject("Count").text = gameData:GetFightWinCount()
    self.BattleCount:GetObject("CountMax").text = string.format("/%d", gameData:GetMaxFightWinCount())
    self.BattleCount.gameObject:SetActiveEx(not gameData:IsFightOver())
    self.BattleFinish.gameObject:SetActiveEx(gameData:IsFightOver())
    
    self.BoxCount:GetObject("Count").text = gameData:GetBoxCount()
    self.BoxCount:GetObject("CountMax").text = string.format("/%d", gameData:GetMaxBoxCount())
    self.BoxCount.gameObject:SetActiveEx(not gameData:IsBoxOver())
    self.BoxFinish.gameObject:SetActiveEx(gameData:IsBoxOver())
    
    self.ActionCount:GetObject("Count").text = gameData:GetUsedActionCount()
    self.ActionCount:GetObject("CountMax").text = string.format("/%d",gameData:GetMaxDailyActionCount() + gameData:GetExtraActionCount())
    
    self.PanelWarehouse.gameObject:SetActiveEx(gameData:GetHasWarehouseNode())
    if gameData:GetHasWarehouseNode() then
        self.WarehouseCount.gameObject:SetActiveEx(not gameData:IsWarehouseOver())
        self.WarehouseFinish.gameObject:SetActiveEx(gameData:IsWarehouseOver())
        self.WarehouseCount:GetObject("Count").text = gameData:GetWarehouseFinishCount()
        self.WarehouseCount:GetObject("CountMax").text = string.format("/%d", gameData:GetMaxWarehouseFinishCount())
    end
    
    self.PanelMentor.gameObject:SetActiveEx(gameData:GetHasMentorNode())
    if gameData:GetHasMentorNode() then
        self.MentorCount.gameObject:SetActiveEx(not gameData:IsMentorOver())
        self.MentorFinish.gameObject:SetActiveEx(gameData:IsMentorOver())
        self.MentorCount:GetObject("Count").text = gameData:IsMentorOver() and 1 or 0
        self.MentorCount:GetObject("CountMax").text = string.format("/%d", MaxMentorCount)
    end
    
    for _,card in pairs(self.CardList) do
        local route = self.Base.CardRouteList[card.CurNum]
        if route then
            local node = mapNodeList[route[#route]]
            card:ShowTag(node:GetIsFight())
        end
    end
end

function XUiPanelBelow:GetNewCard()
    for _,card in pairs(self.CardList) do
        card:GetCard()
        card:ShowTag(false)
    end
end

function XUiPanelBelow:ChangeCard(oldCard, newCard, cb)
    local targetCard = nil
    for _,card in pairs(self.CardList) do
        if card.CurNum == oldCard then
            targetCard = card
        end
    end
    if not targetCard then
        XLog.Error("Card Is Not Exist Id:" .. oldCard)
        return
    end
    targetCard:Change(newCard, function ()
            for _,card in pairs(self.CardList) do
                card:GetCard()
                card:ShowTag(false)
            end
            if cb then cb() end
        end)
end

function XUiPanelBelow:DisableAllCard(IsComplete)
    if not IsComplete then
        return
    end
    for _,card in pairs(self.CardList) do
        card:SetCardState(XMaintainerActionConfigs.CardState.Disable)
        card:ShowTag(false)
    end
end

function XUiPanelBelow:StopCardTween()
    for _,card in pairs(self.CardList) do
        card:StopTween()
    end
end

return XUiPanelBelow
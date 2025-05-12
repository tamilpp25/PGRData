local XUiFubenPokerGuessingCardRecorder = XLuaUiManager.Register(XLuaUi,"UiFubenPokerGuessingCardRecorder")

function XUiFubenPokerGuessingCardRecorder:OnStart()
    self.GridList = {}
    self.PanelName.text = CS.XTextManager.GetText("PokerGuessingRecordTitle")
    self.PanelTitle.text = CS.XTextManager.GetText("PokerGuessingRecordTitle2")
    self.BtnTanchuangClose.CallBack = function() self:Close() end
    self.BtnClose.CallBack = function() self:Close() end
    self:InitButtonGroup()
end

function XUiFubenPokerGuessingCardRecorder:InitButtonGroup()
    self.TabBtnGroup = {}
    local template = XPokerGuessingConfig.GetButtonGroupConfig()
    for id, config in pairs(template) do
        ---@type UnityEngine.GameObject
        local obj = CS.UnityEngine.GameObject.Instantiate(self.BtnTab, self.PanelTabTc)
        obj.gameObject:SetActiveEx(true)
        local btn = obj.gameObject:GetComponent("XUiButton")
        btn:SetName(config.Name)
        btn.CallBack = function()
            self:RefreshPanelGrid(id)
        end
        table.insert(self.TabBtnGroup,btn)
    end
    self.ButtonGroup:Init(self.TabBtnGroup,function(index)
        self:PlayAnimation("QieHuan")
        self:RefreshPanelGrid(index)
    end)
    self.ButtonGroup:SelectIndex(1)
    self.PanelTabTc.gameObject:SetActiveEx(false)
end

function XUiFubenPokerGuessingCardRecorder:RefreshPanelGrid(type)
    local cardList = XPokerGuessingConfig.GetCardListByType(type, XDataCenter.PokerGuessingManager.GetPokerGroup())
    for i = 1, #cardList do
        local grid = self.GridList[i]
        if not grid then
            ---@type UnityEngine.GameObject
            local obj = CS.UnityEngine.GameObject.Instantiate(self.GridCard,self.PanelCardParent)
            obj.gameObject:SetActiveEx(true)
            grid = obj.gameObject:GetComponent("RawImage")
            table.insert(self.GridList, grid)
        end
        grid.gameObject:SetActiveEx(true)
        if XDataCenter.PokerGuessingManager.IsInRecordCardDic(cardList[i].Id) then
            grid:SetRawImage(cardList[i].FrontImg)
        else
            grid:SetRawImage(XDataCenter.PokerGuessingManager.GetBackAssetPath())
        end
    end
    for i = #cardList + 1, #self.GridList do
        self.GridList[i].gameObject:SetActiveEx(false)
    end
end

return XUiFubenPokerGuessingCardRecorder
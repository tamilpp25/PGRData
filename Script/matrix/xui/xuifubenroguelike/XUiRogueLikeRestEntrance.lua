local XUiRogueLikeRestEntrance = XClass(nil, "XUiRogueLikeRestEntrance")

function XUiRogueLikeRestEntrance:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot

    XTool.InitUiObject(self)
    self.OptionsList = {}
end


function XUiRogueLikeRestEntrance:UpdateByNode(node, eventNode)
    self.Node = node
    self.EventNode = (eventNode == nil) and node or eventNode

    self.NodeTemplate = XFubenRogueLikeConfig.GetNodeTemplateById(self.EventNode.Id)
    self.NodeConfig = XFubenRogueLikeConfig.GetNodeConfigteById(self.EventNode.Id)

    self.TxtName.text = self.NodeConfig.Name
    self.RImgIcon:SetRawImage(self.NodeConfig.Icon)
    self.TxtRest.text = self.NodeConfig.Description

    for i = 1, XFubenRogueLikeConfig.ClientRestCount do
        if not self.OptionsList[i] then
            local optionUi = CS.UnityEngine.Object.Instantiate(self.BtnOption)
            optionUi.transform:SetParent(self.PanelOption.transform, false)
            self.OptionsList[i] = optionUi.transform:GetComponent("XUiButton")
            self.OptionsList[i].CallBack = function() self:OnOptionsClick(i) end
        end
        self.OptionsList[i].gameObject:SetActiveEx(true)
        self.OptionsList[i]:SetNameByGroup(0, XFubenRogueLikeConfig.ClientRestClickName[i])
    end

    -- 检查强化buff
    local myBuffs = XDataCenter.FubenRogueLikeManager.GetMyBuffs()
    if not next(myBuffs) then
        self.OptionsList[XFubenRogueLikeConfig.ClientRestClickType.IntensifyBuff].gameObject:SetActiveEx(false)
    end
end

function XUiRogueLikeRestEntrance:OnOptionsClick(index)
    if index == XFubenRogueLikeConfig.ClientRestClickType.Recover then

        local needConst = XFubenRogueLikeConfig.GetRecoverCostSupportPointById(self.Node.Param[1])
        local hpPercent = XFubenRogueLikeConfig.GetRecoverHpPercentById(self.Node.Param[1])
        XUiManager.DialogTip(CS.XTextManager.GetText("TipTitle"), CS.XTextManager.GetText("RogueLikeReFreshBlood", needConst, hpPercent), XUiManager.DialogType.Normal, nil, function()
            XDataCenter.FubenRogueLikeManager.Recover(self.Node.Id, function()
                --self.UiRoot:Close()
            end)
        end, {ItemId1 = XFubenRogueLikeConfig.ChallengeCoin})
        
    elseif index == XFubenRogueLikeConfig.ClientRestClickType.IntensifyBuff then

        --self.UiRoot:Close()
        XLuaUiManager.Open("UiRogueLikeBuffStrengthen", self.Node)

    elseif index == XFubenRogueLikeConfig.ClientRestClickType.Leave then
        local title = CS.XTextManager.GetText("RogueLikeLeaveRestTitle")
        local content = CS.XTextManager.GetText("RogueLikeLeaveShopContent")
        XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, function()
        end, function()
            XDataCenter.FubenRogueLikeManager.FinishNode(self.Node.Id, function(res)
                self.UiRoot:Close()
                if res and res.RewardGoodsList and next(res.RewardGoodsList) ~= nil then
                    XUiManager.OpenUiObtain(res.RewardGoodsList or {})
                end
            end)
        end)
    end
end

return XUiRogueLikeRestEntrance
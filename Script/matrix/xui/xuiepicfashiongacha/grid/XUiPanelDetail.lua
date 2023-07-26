local XUiPanelDetail = XClass(nil, "XUiPanelDetail")

function XUiPanelDetail:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
end

function XUiPanelDetail:RefreshUiShow(gachaConfig)
    if self.GachaConfig then
        return
    end
    self.GachaConfig = gachaConfig

    local list = XDataCenter.GachaManager.GetGachaProbShowById(gachaConfig.Id)
    for i, v in ipairs(list) do
        local tempTrans = v.IsRare and self.RewardSp or self.RewardNor
        local go = CS.UnityEngine.Object.Instantiate(tempTrans, tempTrans.parent)
        go.gameObject:SetActiveEx(true)
        local gridReward = {}
        gridReward.Transform = go
        XTool.InitUiObject(gridReward)
        
        local gridIcon = XUiGridCommon.New(self.RootUi, gridReward.GridCostItem)
        gridIcon:Refresh({TemplateId = v.TemplateId})

        for k, probability in ipairs(v.ProbShow) do
            local probGo = CS.UnityEngine.Object.Instantiate(gridReward.RewardProb, gridReward.RewardProb.transform.parent)
            probGo.gameObject:SetActiveEx(true)
            local gridProb = {}
            gridProb.Transform = probGo
            XTool.InitUiObject(gridProb)
            gridProb.TxtCount.text = probability
        end
    end
end

function XUiPanelDetail:Show()
    self.GameObject:SetActiveEx(true)
end

function XUiPanelDetail:Hide()
    self.GameObject:SetActiveEx(false)
end
return XUiPanelDetail
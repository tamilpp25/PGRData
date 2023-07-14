local XUiPanelFeature = XClass(nil, "XUiPanelFeature")

function XUiPanelFeature:Ctor(uiRoot, ui)
    self.UiRoot = uiRoot
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    self:InitUi()
end

function XUiPanelFeature:InitUi()
    self.GameObject:SetActiveEx(true)
    self.PanelFeature = self.Transform:Find("PanelFeature")
    self.GridFeature = self.Transform:Find("PanelFeature/GridFeature")
    self.GridFeature.gameObject:SetActiveEx(false)
    self.GridFeatureList = {}
end

function XUiPanelFeature:Refresh(featureList, matchDic)
    if featureList and matchDic then
        self.GameObject:SetActiveEx(true)
    else
        self.GameObject:SetActiveEx(false)
        return
    end
    self.FeatureList = featureList
    for i, v in ipairs(featureList) do
        local info = XFubenCoupleCombatConfig.GetFeatureById(v)
        if not info then return end
        local item = self.GridFeatureList[i]

        if not item then
            item = CS.UnityEngine.Object.Instantiate(self.GridFeature, self.PanelFeature)  -- 复制一个item
            self.GridFeatureList[i] = item
            --CsXUiHelper.RegisterClickEvent(item:Find("BgNormal"):GetComponent("Image"), function() self:ShowInfo() end)
            CsXUiHelper.RegisterClickEvent(item:Find("RImgIcon"):GetComponent("RawImage"), function() self:ShowInfo(i) end)
        end
        item.gameObject:SetActiveEx(true)
        local isActive = matchDic[v] and matchDic[v] > 0
        item:Find("BgNormal").gameObject:SetActiveEx(not isActive)
        item:Find("BgActive").gameObject:SetActiveEx(isActive)
        item:Find("RImgIcon"):GetComponent("RawImage"):SetRawImage(info.Icon)
    end
    for i = #featureList + 1, #self.GridFeatureList do
        self.GridFeatureList[i].gameObject:SetActiveEx(false)
    end

    self.GridFeature.gameObject:SetActiveEx(false)
end

function XUiPanelFeature:ShowInfo(index)
    local info = XFubenCoupleCombatConfig.GetFeatureById(self.FeatureList[index])
    XUiManager.UiFubenDialogTip(info.Name, info.Description)
end

function XUiPanelFeature:OnDisable()
end

return XUiPanelFeature
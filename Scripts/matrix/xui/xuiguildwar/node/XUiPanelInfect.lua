local XUiPanelInfect = XClass(nil, "XUiPanelInfect")

function XUiPanelInfect:Ctor(ui)
    XUiHelper.InitUiClass(self, ui)
end

function XUiPanelInfect:SetData(node)
    local guardNodes = node:GetGuardNodes()
    local guardNode
    for i = 1, 3 do
        guardNode = guardNodes[i]
        self["PanelJinwei" .. i].gameObject:SetActiveEx(guardNode ~= nil)
        if guardNode then
            local buffData = guardNode:GetFightEventDetailConfig()
            if buffData then
                self["RImgJinweiIcon".. i]:SetRawImage(buffData.Icon)
                self["PanelPass".. i].gameObject:SetActiveEx(guardNode:GetStutesType() 
                    == XGuildWarConfig.NodeStatusType.Die)
                XUiHelper.RegisterClickEvent(self, self["PanelJinwei" .. i], function()
                    XLuaUiManager.Open("UiCommonBuffDetail", buffData.Name, buffData.Icon, buffData.Description)
                end)
            end
        end
    end
end

return XUiPanelInfect

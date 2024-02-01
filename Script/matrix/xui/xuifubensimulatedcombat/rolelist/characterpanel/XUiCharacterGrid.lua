--成员列表页面角色列表：角色控件
local XUiSimulatedCombatListCharacterGrid = XClass(nil, "XUiSimulatedCombatListCharacterGrid")
function XUiSimulatedCombatListCharacterGrid:Ctor(ui, rootUi, gridIndex, onSelectCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.RootUi = rootUi
    self.GridIndex = gridIndex
    self.SelectCb = onSelectCb
    self:AddListener()
    self.ImgInTeam.gameObject:SetActiveEx(false)
    self.PanelSelected.gameObject:SetActiveEx(false)
end

function XUiSimulatedCombatListCharacterGrid:AddListener()
    self.RootUi:RegisterClickEvent(self.BtnCharacter, function() self:OnClick() end)
end

function XUiSimulatedCombatListCharacterGrid:RefreshDatas(data)
    if not data then
        return
    end
    self.Data = data
    self.RobotId = data.RobotId
    self.CharacterId = XRobotManager.GetCharacterId(self.RobotId)
    
    
    --self.RImgMember:SetRawImage(XRobotManager.GetRobotSmallHeadIcon(self.ResInfo.RobotId))
    --self.TxtName.text = XMVCA.XCharacter:GetCharacterName()
    
    
    self.RImgHeadIcon:SetRawImage(XRobotManager.GetRobotSmallHeadIcon(self.RobotId))
    self.TxtFight.text = XRobotManager.GetRobotAbility(self.RobotId)
    self.TxtLevel.text = data.Star
    self:RefreshElements()
end

function XUiSimulatedCombatListCharacterGrid:Show()
    self.GameObject:SetActiveEx(true)
end

function XUiSimulatedCombatListCharacterGrid:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiSimulatedCombatListCharacterGrid:OnClick()
    self:SetSelect(true)
end

function XUiSimulatedCombatListCharacterGrid:SetSelect(isSelect)
    if self.IsSelected == isSelect then return end
    self.PanelSelected.gameObject:SetActiveEx(isSelect)
    self.IsSelected = isSelect
    if self.SelectCb and isSelect then
        self.RootUi:Refresh(self.CharacterId, self.RobotId)
        self.SelectCb(self.GridIndex)
    end
end

function XUiSimulatedCombatListCharacterGrid:RefreshElements()    
    local detailConfig = XMVCA.XCharacter:GetCharDetailTemplate(self.CharacterId)
    local elementList = detailConfig.ObtainElementList
    for i = 1, 3 do
        local rImg = self["RImgCharElement" .. i]
        if rImg and elementList[i] then
            rImg.transform.gameObject:SetActiveEx(true)
            local elementConfig = XMVCA.XCharacter:GetCharElement(elementList[i])
            rImg:SetRawImage(elementConfig.Icon)
        elseif rImg and not elementList[i] then
            rImg.transform.gameObject:SetActiveEx(false)
        end
    end
end

return XUiSimulatedCombatListCharacterGrid
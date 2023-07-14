--虚像地平线成员列表页面角色列表：角色控件
local XUiExpeditionRoleListCharacterGrid = XClass(nil, "XUiExpeditionRoleListCharacterGrid")
function XUiExpeditionRoleListCharacterGrid:Ctor(ui, rootUi, gridIndex, onSelectCb)
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

function XUiExpeditionRoleListCharacterGrid:AddListener()
    self.RootUi:RegisterClickEvent(self.BtnCharacter, function() self:OnClick() end)
end

function XUiExpeditionRoleListCharacterGrid:RefreshDatas(eChara)
    if not eChara then
        return
    end
    self.EChara = eChara
    self.RImgHeadIcon:SetRawImage(self.EChara:GetSmallHeadIcon())
    self.TxtFight.text = self.EChara:GetAbility()
    self.TxtLevel.text = self.EChara:GetRankStr()
    self:RefreshElements()
end

function XUiExpeditionRoleListCharacterGrid:Show()
    self.GameObject:SetActiveEx(true)
end

function XUiExpeditionRoleListCharacterGrid:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiExpeditionRoleListCharacterGrid:OnClick()
    self:SetSelect(true)
end

function XUiExpeditionRoleListCharacterGrid:SetSelect(isSelect)
    if self.IsSelected == isSelect then return end
    self.PanelSelected.gameObject:SetActiveEx(isSelect)
    self.IsSelected = isSelect
    if self.SelectCb and isSelect then
        self.RootUi:Refresh(self.EChara:GetCharacterId(), self.EChara:GetRobotId(), self.EChara:GetECharaId())
        self.SelectCb(self.GridIndex)
    end
end

function XUiExpeditionRoleListCharacterGrid:RefreshElements()
    local elementList = self.EChara:GetCharacterElements()
    for i = 1, 3 do
        local rImg = self["RImgCharElement" .. i]
        if rImg and elementList[i] then
            rImg.transform.gameObject:SetActiveEx(true)
            local elementConfig = XExpeditionConfig.GetCharacterElementById(elementList[i])
            rImg:SetRawImage(elementConfig.Icon)
        elseif rImg and not elementList[i] then
            rImg.transform.gameObject:SetActiveEx(false)
        end
    end
end

return XUiExpeditionRoleListCharacterGrid
--虚像地平线战斗准备换人界面成员列表控件
local XUiExpeditionRoomCharListGrid = XClass(nil, "XUiExpeditionRoomCharacterGrid")
function XUiExpeditionRoomCharListGrid:Ctor()

end

function XUiExpeditionRoomCharListGrid:Init(ui, rootUi)
    self.Transform = ui.transform
    self.GameObject = ui.gameObject
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self.PanelSelected.gameObject:SetActiveEx(false)
    self:SetInTeam(false)
end

function XUiExpeditionRoomCharListGrid:RefreshDatas(eChara)
    if not eChara then
        return
    end
    self.EChara = eChara
    self.BaseId = self.EChara:GetBaseId()
    self:SetIsLock()
    self.RImgHeadIcon:SetRawImage(self.EChara:GetSmallHeadIcon())
    self.TxtFight.text = self.EChara:GetAbility()
    self.TxtLevel.text = self.EChara:GetRankStr()
    self:RefreshElements()
    self:SetInTeam(XDataCenter.ExpeditionManager.GetCharacterIsInTeam(self.BaseId))
end

function XUiExpeditionRoomCharListGrid:SetSelect(isSelect)
    self.PanelSelected.gameObject:SetActiveEx(isSelect)
end

function XUiExpeditionRoomCharListGrid:SetInTeam(isInTeam)
    self.ImgInTeam.gameObject:SetActiveEx(isInTeam)
end

function XUiExpeditionRoomCharListGrid:SetIsLock()
    self.ImgLock.gameObject:SetActiveEx(false)
end

function XUiExpeditionRoomCharListGrid:RefreshElements()
    local elementList = self.EChara:GetCharacterElements()
    for i = 1, 3 do
        local rImg = self["RImgCharElement" .. i]
        if rImg and elementList[i] then
            rImg.transform.gameObject:SetActive(true)
            local elementConfig = XExpeditionConfig.GetCharacterElementById(elementList[i])
            rImg:SetRawImage(elementConfig.Icon)
        elseif rImg then
            rImg.transform.gameObject:SetActive(false)
        end
    end
end

return XUiExpeditionRoomCharListGrid
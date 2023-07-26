--虚像地平线招募界面成员列表控件
local XUiExpeditionRecruitMemberGrid = XClass(nil, "XUiExpeditionRecruitMemberGrid")

function XUiExpeditionRecruitMemberGrid:Ctor()

end

function XUiExpeditionRecruitMemberGrid:Init(ui, rootUi)
    self.Transform = ui.transform
    self.GameObject = ui.gameObject
    XTool.InitUiObject(self)
    self.Disable.gameObject:SetActiveEx(true)
    self.Normal.gameObject:SetActiveEx(false)
    self.PanelSelected.gameObject:SetActiveEx(false)
end

function XUiExpeditionRecruitMemberGrid:RefreshDatas(teamPos, index)
    if not teamPos then
        self.GameObject:SetActiveEx(false)
        return
    end
    local eChara = XDataCenter.ExpeditionManager.GetTeam():GetFetterCharaByPos(index)
    local isUnLock = teamPos:GetIsUnLock()
    self.Lock.gameObject:SetActiveEx(not isUnLock)
    self.PanelDefaultMember.gameObject:SetActiveEx(eChara and eChara:GetIsDefaultTeamMember())
    if not isUnLock then self.TxtLockCondition.text = teamPos:GetConditionDes() end
    self.Disable.gameObject:SetActiveEx(isUnLock and eChara == nil)
    self.Normal.gameObject:SetActiveEx(isUnLock and eChara ~= nil)
    if not eChara then return end
    self.EChara = eChara
    self.TxtFight.text = eChara:GetAbility()
    self.RImgHeadIcon:SetRawImage(eChara:GetSmallHeadIcon())
    local comboList = XDataCenter.ExpeditionManager.GetComboList()
    local showCombos = comboList:GetActiveComboIdsByEChara(eChara)
    for i = 1, 3 do
        local rImg = self["RImgCharElement" .. i]
        if rImg then
            if showCombos[i] then
                rImg.transform.parent.gameObject:SetActive(true)
                local combo = comboList:GetComboByComboId(showCombos[i])
                rImg:SetRawImage(combo:GetIconPath())
            else
                rImg.transform.parent.gameObject:SetActive(false)
            end
        end
    end
    self.TxtLevel.text = eChara:GetRankStr()
    if eChara:GetIsNew() then
        self.PanelEffectLvUp.gameObject:SetActiveEx(false)
        self.PanelEffectLvUp.gameObject:SetActiveEx(true)
    end
end

function XUiExpeditionRecruitMemberGrid:InitEffect()
    self.PanelEffectLvUp.gameObject:SetActiveEx(false)
end

return XUiExpeditionRecruitMemberGrid
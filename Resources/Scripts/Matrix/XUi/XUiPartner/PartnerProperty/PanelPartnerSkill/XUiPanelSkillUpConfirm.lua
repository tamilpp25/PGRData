local XUiPanelSkillUpConfirm = XClass(nil, "XUiPanelSkillUpConfirm")
local CSTextManagerGetText = CS.XTextManager.GetText
function XUiPanelSkillUpConfirm:Ctor(ui, base, root)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    self.Root = root
    XTool.InitUiObject(self)
    self.GirdSkill.gameObject:SetActiveEx(false)
    self.GirdSkillList = {}
    self:SetButtonCallBack()
end

function XUiPanelSkillUpConfirm:UpdatePanel(data, skillUpInfo)
    self.Data = data
    self.GameObject:SetActiveEx(true)
    self:UpdatePartnerInfo(data, skillUpInfo)
end

function XUiPanelSkillUpConfirm:HidePanel()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelSkillUpConfirm:PlayEnableAnime()
    XScheduleManager.ScheduleOnce(function()
            XLuaUiManager.SetMask(true)
            self.PanelSkillUpConfirmEnable.gameObject:PlayTimelineAnimation(function ()
                    XLuaUiManager.SetMask(false)
                end)
        end, 1)
end

function XUiPanelSkillUpConfirm:UpdatePartnerInfo(data, skillUpInfo)
    for index,info in pairs(skillUpInfo or {}) do
        local grid = self.GirdSkillList[index]
        if not grid then
            grid = CS.UnityEngine.Object.Instantiate(self.GirdSkill, self.PanelSkill)
            self.GirdSkillList[index] = grid
        end
        grid.gameObject:SetActiveEx(true)
        self:UpdataGridSkill(grid, data, info)
    end
    
    for i = #skillUpInfo + 1, #self.GirdSkillList do
        self.GirdSkillList[i].gameObject:SetActiveEx(false)
    end
end

function XUiPanelSkillUpConfirm:UpdataGridSkill(grid, data, info)
    local uiObj = grid.transform:GetComponent("UiObject")
    local skillEntity = data:GetSkillById(info.SkillId)
    uiObj:GetObject("SkillIcon"):SetRawImage(skillEntity:GetSkillIcon(nil, info.CurrentLevel))
    uiObj:GetObject("NameText").text = skillEntity:GetSkillName(nil, info.CurrentLevel)
    uiObj:GetObject("TxtLevel").text = CSTextManagerGetText("PartnerSkillLevelEN",info.CurrentLevel)
    uiObj:GetObject("TxtMax").gameObject:SetActiveEx(false)
end

function XUiPanelSkillUpConfirm:SetButtonCallBack()
    self.BtnClose.CallBack = function()
        self:OnBtnCloseClick()
    end
end

function XUiPanelSkillUpConfirm:OnBtnCloseClick()
    self.Base:SetSkillUpFinish(false)
    self.Base:UpdatePanel(self.Data)
end

return XUiPanelSkillUpConfirm
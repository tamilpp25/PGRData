local XUiPartnerShowSkillGrid = require("XUi/XUiPartner/PartnerShow/XUiPartnerShowSkillGrid")
local XUiPanelPartnerOverview = XClass(nil, "XUiPanelPartnerOverview")

function XUiPanelPartnerOverview:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    -- XPartner
    self.Partner = nil
    -- XUiPartnerShowSkillGrid list
    self.PassiveSkillGrids = {}
    -- XPartnerMainSkillGroup
    self.MainSkill = nil
    self.OpenPassiveSkillDetailUiFunc = nil
    XTool.InitUiObject(self)
    self:RegisterUiEvents()
end

-- partner : XPartner
function XUiPanelPartnerOverview:SetData(partner, openPassiveSkillDetailUiFunc)
    self.Partner = partner    
    self.OpenPassiveSkillDetailUiFunc = openPassiveSkillDetailUiFunc
    -- 伙伴名字
    self.TxtName.text = partner:GetName()
    -- 伙伴战力参数
    self.TxtAbility.text = partner:GetAbility()
    -- 伙伴类型
    self.TxtType.text = partner:GetDesc()
    -- 伙伴阶级
    self.ImgBreakthrough:SetSprite(partner:GetBreakthroughIcon())
    -- 主动技能
    self:RefreshMainSkill()
    -- 被动技能
    self:RefreshPassiveSkills()
end

--########################## 私有方法 ##############################

function XUiPanelPartnerOverview:RegisterUiEvents()
    self.BtnMainSkill.CallBack = function() self:OnMainSkillClicked() end
end

function XUiPanelPartnerOverview:OnMainSkillClicked()
    XLuaUiManager.Open("UiPanelPartnerShowMainSkill", self.MainSkill, self.Partner)
end

-- 刷新伙伴主技能
function XUiPanelPartnerOverview:RefreshMainSkill()
    local mainSkillList = self.Partner:GetCarryMainSkillGroupList()
    self.MainSkill = mainSkillList[1]
    if not self.MainSkill then return end
    self.TxtMainSkillName.text = self.MainSkill:GetSkillName()
    self.TxtMainSkillLevel.text = self.MainSkill:GetLevelStr()
    self.RImgMainSkillIcon:SetRawImage(self.MainSkill:GetSkillIcon())
end

-- 刷新伙伴被动技能
function XUiPanelPartnerOverview:RefreshPassiveSkills()
    local passiveSkillList = self.Partner:GetCarryPassiveSkillGroupList()
    local skillSlotCount = self.Partner:GetQualitySkillColumnCount()
    local uiShowMaxSkillCount = 6
    for index = 1, uiShowMaxSkillCount do
        local grid = self.PassiveSkillGrids[index]
        if grid == nil then
            local go = CS.UnityEngine.Object.Instantiate(self.GridPassiveSkill, self.PanelPassiveSkillContent)
            grid = XUiPartnerShowSkillGrid.New(go)
            self.PassiveSkillGrids[index] = grid
        end
        grid:SetData(passiveSkillList[index], index > skillSlotCount, index > XPartnerConfigs.PassiveSkillCount, self.OpenPassiveSkillDetailUiFunc)
    end
    self.GridPassiveSkill.gameObject:SetActiveEx(false)
end

return XUiPanelPartnerOverview
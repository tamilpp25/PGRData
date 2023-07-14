--===========================================================================
 ---@desc 技能预览详情界面
--===========================================================================
local XUiCharacterBuffDetails = XLuaUiManager.Register(XLuaUi, "UiCharacterBuffDetails")

local GetText = CS.XTextManager.GetText

function XUiCharacterBuffDetails:OnAwake()
    self:InitUI()
    self:InitCB()
end 

function XUiCharacterBuffDetails:OnStart(data)
    if not data then return end
    
    self.TxtTitle.text = GetText("SCTipBossSkillDetailName")
    self.TxtDescTitle.text = GetText("SCTipBossSkillDetailDesc")
    
    self.TxtName.text = data.Name or ""
    self.TxtLv.text = data.Level or 1
    self.TxtSkillDes.text = data.Intro or ""
    self.BuffGrid.RImgIcon:SetRawImage(data.Icon)
    local skillId = data.SkillId
    if XTool.IsNumberValid(skillId) then
        self.TxtOperatingContent.gameObject:SetActiveEx(true)
        local skillType = XCharacterConfigs.GetSkillType(skillId)
        self.TxtOperatingContent.text = XCharacterConfigs.GetSkillTypeName(skillType)
    else
        self.TxtOperatingContent.gameObject:SetActiveEx(false)
    end
    
end

function XUiCharacterBuffDetails:InitUI()
    self.BuffGrid = {}
    XTool.InitUiObjectByUi(self.BuffGrid, self.GridBuff)
    self.BuffGrid.RImgBg.gameObject:SetActiveEx(false)
end

function XUiCharacterBuffDetails:InitCB()
    self.BtnTanchuangClose.CallBack = function() self:Close() end
end


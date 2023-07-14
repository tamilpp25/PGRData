local XUiFubenMaverickSkillTips = XLuaUiManager.Register(XLuaUi, "UiFubenMaverickSkillTips")

function XUiFubenMaverickSkillTips:OnAwake()
    self:InitButtons()
end 

function XUiFubenMaverickSkillTips:OnStart(data)
    --因为是NormalPopup Ui所以不需要设置计时器
    self.Icon:SetRawImage(data.Icon)
    self.TxtDesc.text = data.Intro
    self.TxtName.text = data.Name
    
    if data.IsSkill then
        self.TxtDescTitle.text = CSXTextManagerGetText("MaverickSkillDescTitle")
        
        self.BtnUse.gameObject:SetActiveEx(false)
        self.TxtCondition.gameObject:SetActiveEx(false)
    else
        self.OnClick = data.OnClick
        self.TxtCondition.text = data.Condition
        self.BtnUse:SetNameByGroup(0, data.BtnText)
        self.TxtDescTitle.text = CSXTextManagerGetText("MaverickTalentDescTitle")
        
        self.BtnUse.gameObject:SetActiveEx(true)
        self.TxtCondition.gameObject:SetActiveEx(true)
    end
end 

function XUiFubenMaverickSkillTips:InitButtons()
    self.BtnClose.onClick:AddListener(function() self:Close() end)
    self.BtnUse.CallBack = function()
        if self.OnClick then
            self.OnClick(self)
        end
    end
end
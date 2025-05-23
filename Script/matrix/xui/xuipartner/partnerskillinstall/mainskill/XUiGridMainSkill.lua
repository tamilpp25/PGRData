local XUiGridMainSkill = XClass(nil, "XUiGridMainSkill")
local CSTextManagerGetText = CS.XTextManager.GetText
local State = {Normal = 1, Select = 2, Lock = 3}

function XUiGridMainSkill:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.GridState = State.Normal
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
end

function XUiGridMainSkill:SetButtonCallBack()
    self.BtnSelect.CallBack = function()
        self:OnBtnSelectClick()
    end
    self.BtnSelect2.CallBack = function()
        self:OnBtnSelectClick()
    end

    self.BtnDetail.CallBack = function()
        self:OnBtnDetailClick()
    end
end

function XUiGridMainSkill:OnBtnSelectClick()
    if self.Root.Partner:GetIsComposePreview() then
        return
    end
    
    if self.SkillGroup:GetIsLock() then
        XUiManager.TipMsg(self.SkillGroup:GetConditionDesc())
        return
    end

    self.Base:SelectSkill(self.SkillGroup)

    local grids = self.Base.DynamicTable:GetGrids()
    for _,grid in pairs(grids) do
        grid:ShowGrid()
    end

    self:ShowSelectEffect()

    --self:ChangeState(State.Select)
end

function XUiGridMainSkill:OnBtnDetailClick()
    self.Base:SelectPreviewSkill(self.SkillGroup)
    self.Root:GoElementView()
end

function XUiGridMainSkill:UpdateGrid(skillGroup, base, root)
    self.SkillGroup = skillGroup
    self.Base = base
    self.Root = root
    self:ShowGrid()
end

function XUiGridMainSkill:ShowGrid()
    if self.Root.Partner:GetIsComposePreview() then
        self.BtnSelect2.gameObject:SetActiveEx(false)
        self:ChangeState(State.Normal)
        return
    end
    
    if self.SkillGroup then
        local selectSkillId = self.Root.CurSkillGroup:GetId()
        local IsSelect = self.SkillGroup:GetId() == selectSkillId
        if IsSelect then
            self:ChangeState(State.Select)
        else
            if self.SkillGroup:GetIsLock() then
                self:ChangeState(State.Lock)
            else
                self:ChangeState(State.Normal)
            end
        end
    end
end

function XUiGridMainSkill:ChangeState(state)
    self.GridState = state
    self:ShowNormal(self.GridState == State.Normal)
    self:ShowSelect(self.GridState == State.Select)
    self:ShowLock(self.GridState == State.Lock)
    self:UpdateSkillInfo()
end

function XUiGridMainSkill:UpdateSkillInfo()
    local panel = {}
    if self.GridState == State.Normal then
        panel = self.Normal
        panel:GetObject("TxtContent").text = self.SkillGroup:GetSkillDesc()
    elseif self.GridState == State.Select then
        panel = self.Select
        panel:GetObject("TxtContent").text = self.SkillGroup:GetSkillDesc()
    elseif self.GridState == State.Lock then
        panel = self.Lock
        panel:GetObject("TxtUnlock").text = self.SkillGroup:GetConditionDesc()
    end

    panel:GetObject("RImgIcon"):SetRawImage(self.SkillGroup:GetSkillIcon())
    panel:GetObject("TxtName").text = self.SkillGroup:GetSkillName()
    panel:GetObject("TxtLevel").text = CSTextManagerGetText("PartnerSkillLevelEN",self.SkillGroup:GetLevelStr())
end

function XUiGridMainSkill:ShowSelect(IsShow)
    self.Select.gameObject:SetActiveEx(IsShow)
end

function XUiGridMainSkill:ShowLock(IsLock)
    self.Lock.gameObject:SetActiveEx(IsLock)
end

function XUiGridMainSkill:ShowNormal(IsNormal)
    self.Normal.gameObject:SetActiveEx(IsNormal)
end

function XUiGridMainSkill:ShowSelectEffect()
    self.Select:GetObject("SelectEffect").gameObject:SetActiveEx(true)
end

return XUiGridMainSkill
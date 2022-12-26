local XUiGridLevelSelect = XClass(nil, "XUiGridLevelSelect")
local CSTextManagerGetText = CS.XTextManager.GetText
function XUiGridLevelSelect:Ctor(ui, base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    XTool.InitUiObject(self)

    self:SetButtonCallBack()
end

function XUiGridLevelSelect:SetButtonCallBack()
    self.BtnSelect.CallBack = function()
        self:OnBtnSelectClick()
    end
end

function XUiGridLevelSelect:OnBtnSelectClick()
    if self.Data then
        self.Base.CurBossLevel = self.Data.Id
        self.Base:OnBtnCloseClick()
    end
end

function XUiGridLevelSelect:UpdateData(data)
    self.Data = data
    if data then
        --data.Icon--可能需要追加Icon显示组件
        self.TxtDamege.text = CSTextManagerGetText("WorldBossLevelDamege",data.HurtHp)
        self.TxtPower.text = CSTextManagerGetText("WorldBossLevelAdvise",data.RecommendAbility)
        self.LevelText.text = data.Desc
        self.LevelText.color = XUiHelper.Hexcolor2Color(data.DescColor)
    end
end

return XUiGridLevelSelect
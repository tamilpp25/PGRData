local XUiWorldBossTips = XLuaUiManager.Register(XLuaUi, "UiWorldBossTips")
local XUiGridTipsInfo = require("XUi/XUiWorldBoss/XUiGridTipsInfo")
local Object = CS.UnityEngine.Object

function XUiWorldBossTips:OnStart(id, IsShowCondition)
    self.Buff = XDataCenter.WorldBossManager.GetWorldBossBuffById(id)
    self.SameGroupBuff = XDataCenter.WorldBossManager.GetSameGroupBossBuffByGroupId(self.Buff:GetGroupId())
    self.SameGroupBuff = self.SameGroupBuff or {self.Buff}
    self:SetBuffInfo(IsShowCondition)
    self:SetButtonCallBack()
end

function XUiWorldBossTips:InitBuffInfo()
    self:Close()
end

function XUiWorldBossTips:SetButtonCallBack()
    self.BtnMask.CallBack = function()
        self:OnBtnMaskClick()
    end
end

function XUiWorldBossTips:SetBuffInfo(IsShowCondition)
    self.RImgBuff:SetRawImage(self.Buff:GetIcon())
    self.TxtBuffName.text = self.Buff:GetName()
    self.HintText.text = self.Buff:GetHintText()
    --self.HintText.gameObject:SetActiveEx(IsShowCondition)
    self.TxtBuffDescription.gameObject:SetActiveEx(false)
    self.BuffBg.gameObject:SetActiveEx(self.Buff:GetType() == XWorldBossConfigs.BuffType.Buff)
    for _,buff in pairs(self.SameGroupBuff) do
        local tmpObj = Object.Instantiate(self.TxtBuffDescription)
        tmpObj.gameObject:SetActiveEx(true)
        tmpObj.transform:SetParent(self.InfoContent.transform, false)
        local info = XUiGridTipsInfo.New(tmpObj)
        info:UpdateData(buff,IsShowCondition)
    end
end

function XUiWorldBossTips:OnBtnMaskClick()
    self:Close()
end
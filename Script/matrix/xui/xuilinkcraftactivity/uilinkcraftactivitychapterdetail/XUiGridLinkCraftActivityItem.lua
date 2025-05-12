local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiGridLinkCraftActivityItem = XClass(XUiGridCommon, 'XUiGridLinkCraftActivityItem')

function XUiGridLinkCraftActivityItem:Refresh(specialType,data, params, isBigIcon, hideSkipBtn, curCount)
    self.RImgBuff.gameObject:SetActiveEx(false)
    
    if not XTool.IsNumberValid(specialType) then
        self.Super.Refresh(self,data, params, isBigIcon, hideSkipBtn, curCount)
        return
    end
    self._SpecialType = specialType
    self:ResetUi()
    self._SkillId = data
    if self._SpecialType == XEnumConst.LinkCraftActivity.GoodsSpecialType.Skill then
        --设置技能图标
        self.RImgBuff.gameObject:SetActiveEx(true)
        self.RImgIcon.gameObject:SetActiveEx(false)
        self.RImgBuff:SetRawImage(XMVCA.XLinkCraftActivity:GetSkillIconById(self._SkillId))
    end
end

function XUiGridLinkCraftActivityItem:OnBtnClickClick()
    if not XTool.IsNumberValid(self._SpecialType) then
        self.Super.OnBtnClickClick(self)
    end

    if self._SpecialType == XEnumConst.LinkCraftActivity.GoodsSpecialType.Skill then
        self.RootUi:OpenSkillRewardDetail(self._SkillId)
    end
end

---@overload
function XUiGridLinkCraftActivityItem:AutoInitUi()
    self.Super.AutoInitUi(self)
    self.RImgBuff = XUiHelper.TryGetComponent(self.Transform, "RImgBuff", "RawImage")
end

return XUiGridLinkCraftActivityItem
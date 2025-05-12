--肉鸽2.0羁绊组合详细页面: 羁绊详细项控件
local XUiBiancaTheatreComboTipsItem = XClass(nil, "XUiBiancaTheatreComboTipsItem")

local UnShowTxt = "???"

function XUiBiancaTheatreComboTipsItem:Ctor(ui, rootUi, isShowDisplay)
    self.IsShowDisplay = isShowDisplay  --是否展示羁绊图鉴列表（不判断是否有角色）
    self:Init(ui, rootUi)
end

function XUiBiancaTheatreComboTipsItem:Init(ui, rootUi)
    self.Transform = ui.transform
    self.GameObject = ui.gameObject
    XTool.InitUiObject(self)
    self.RootUi = rootUi
end

--totalStarCount：羁绊已激活的总等级
function XUiBiancaTheatreComboTipsItem:RefreshDatas(eCombo, index, totalStarCount)
    -- 是否在外循环显示
    local outSideIsDecay = self.IsShowDisplay and eCombo:GetPhaseComboEffectIsDecay(index)
    local inSideIsNotDecay = (not self.IsShowDisplay) and eCombo:GetPhaseComboEffectIsDecay(index) and not eCombo:GetDisplayReferenceListIsHaveDecay()
    local isMaxLevelCount = index >= eCombo:GetPhaseNum()
    -- 合计星级达到最高等级时，判断羁绊激活条件是是否腐化
    local isActive = (not isMaxLevelCount or isMaxLevelCount and not inSideIsNotDecay) and totalStarCount >= eCombo:GetConditionLevel(index) and not self.IsShowDisplay
    local isLock = outSideIsDecay or inSideIsNotDecay
    self.Normal.gameObject:SetActiveEx(not isActive)
    self.Active.gameObject:SetActiveEx(isActive)
    if isActive then
        self.TxtTitleActive.text = CS.XTextManager.GetText("ExpeditionComboTipsPhaseTitle", index)
        self.TxtEffectActive.text = isLock and UnShowTxt or eCombo:GetPhaseComboEffectDes(index)
        self.TxtConditionTitleActive.text = XBiancaTheatreConfigs.GetBiancaTheatreComboTips(1)
        self.TxtConditionDescActive.text = isLock and UnShowTxt or eCombo:GetPhaseComboConditionDes(index)
    else
        self.TxtTitleNormal.text = CS.XTextManager.GetText("ExpeditionComboTipsPhaseTitle", index)
        self.TxtEffectNormal.text = isLock and UnShowTxt or eCombo:GetPhaseComboEffectDes(index)
        self.TxtConditionTitleNormal.text = XBiancaTheatreConfigs.GetBiancaTheatreComboTips(1)
        self.TxtConditionDescNormal.text = isLock and UnShowTxt or eCombo:GetPhaseComboConditionDes(index)
    end
end

return XUiBiancaTheatreComboTipsItem
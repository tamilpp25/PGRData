---黄金矿工通用Buff格子
---@class XUiGoldenMinerSlotScoreGrid:XUiNode
---@field _Control XGoldenMinerControl
local XUiGoldenMinerSlotScoreGrid = XClass(XUiNode, "XUiGoldenMinerSlotScoreGrid")

function XUiGoldenMinerSlotScoreGrid:OnStart()
    self._SlotScoreAnyIcon = self._Control:GetClientSlotScoreAnyIcon()

    self.RImgStone.gameObject:SetActiveEx(false)
    self.EffectSame.gameObject:SetActiveEx(false)
    self.EffectDiff.gameObject:SetActiveEx(false)
end

function XUiGoldenMinerSlotScoreGrid:RefreshIcon(stoneType)
    if XTool.IsNumberValid(stoneType) then
        local icon

        if stoneType == XEnumConst.GOLDEN_MINER.SLOT_SCORE_ANY_TYPE then
            icon = self._SlotScoreAnyIcon
        else
            icon = self._Control:GetCfgStoneTypeIcon(stoneType)
        end
        if not string.IsNilOrEmpty(icon) then
            self.RImgStone:SetRawImage(icon)
            self.RImgStone.gameObject:SetActiveEx(true)
        end
    else
        self.RImgStone.gameObject:SetActiveEx(false)
    end
end

function XUiGoldenMinerSlotScoreGrid:ShowSameEffect()
    self.EffectSame.gameObject:SetActiveEx(true)
end

function XUiGoldenMinerSlotScoreGrid:ShowDiffEffect()
    self.EffectDiff.gameObject:SetActiveEx(true)
end

function XUiGoldenMinerSlotScoreGrid:HideAllEffect()
    self.EffectSame.gameObject:SetActiveEx(false)
    self.EffectDiff.gameObject:SetActiveEx(false)
end

return XUiGoldenMinerSlotScoreGrid
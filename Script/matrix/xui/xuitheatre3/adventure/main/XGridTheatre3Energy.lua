---@class XGridTheatre3Energy : XUiNode
---@field _Control XTheatre3Control
local XGridTheatre3Energy = XClass(XUiNode, "XGridTheatre3Energy")

function XGridTheatre3Energy:OnStart(index, maxEnergy)
    self._Index = index
    self._MaxEnergy = maxEnergy
    if not self.ImgEnergyOn then
        ---@type UnityEngine.Transform
        self.ImgEnergyOn = XUiHelper.TryGetComponent(self.Transform, "ImgEnergyOn")
    end
    if not self.ImgEnergyOff then
        ---@type UnityEngine.Transform
        self.ImgEnergyOff = XUiHelper.TryGetComponent(self.Transform, "ImgEnergyOff")
    end
    if not self.ImaEnergyTip then
        ---@type UnityEngine.Transform
        self.ImaEnergyTip = XUiHelper.TryGetComponent(self.Transform, "ImaEnergyTip")
    end
    if not self.AnimImaEnergyTip then
        ---@type UnityEngine.Transform
        self.AnimImaEnergyTip = XUiHelper.TryGetComponent(self.Transform, "ImaEnergyTip/TipsLoop2")
    end
    if not self.AnimTipsLoop then
        ---@type UnityEngine.Transform
        self.AnimTipsLoop = XUiHelper.TryGetComponent(self.Transform, "Animation/TipsLoop")
    end
end

function XGridTheatre3Energy:RefreshShow(curEnergy, cacheEnergy)
    if self.ImgEnergyOn then
        self.ImgEnergyOn.gameObject:SetActiveEx(self._Index <= curEnergy)
        -- 新增的能量闪烁
        if self._Index > self._MaxEnergy - cacheEnergy and self._Index <= curEnergy then
            self:PlayEnergyAddEffect(true)
        else
            self:PlayEnergyAddEffect(false)
        end
    end
    if self.ImgEnergyOff then
        self.ImgEnergyOff.gameObject:SetActiveEx(self._Index > curEnergy)
    end
end

function XGridTheatre3Energy:PlayEnergyShiny(isPlay)
    if self.AnimTipsLoop and self.ImgEnergyOn then
        if isPlay then
            self.ImgEnergyOn.gameObject:SetActiveEx(true)
            self.AnimTipsLoop.gameObject:SetActiveEx(true)
            self.AnimTipsLoop:PlayTimelineAnimation(nil ,nil, CS.UnityEngine.Playables.DirectorWrapMode.Loop)
        else
            self.AnimTipsLoop.gameObject:SetActiveEx(false)
        end
    end
end

function XGridTheatre3Energy:PlayEnergyAddEffect(isPlay)    
    if self.AnimImaEnergyTip then
        if isPlay then
            self.ImaEnergyTip.gameObject:SetActiveEx(true)
            self.AnimImaEnergyTip:PlayTimelineAnimation()
        else
            self.ImaEnergyTip.gameObject:SetActiveEx(false)
        end
    end
end

return XGridTheatre3Energy
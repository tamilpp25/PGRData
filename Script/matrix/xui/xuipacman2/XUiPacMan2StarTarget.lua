---@class XUiPacMan2StarTarget : XUiNode
---@field _Control XPacMan2Control
local XUiPacMan2StarTarget = XClass(XUiNode, "XUiPacMan2StarTarget")

function XUiPacMan2StarTarget:OnStart()
    self._StarsOn = { self.ImgStarOn }
    self._StarsOff = { self.ImgStarOff }
end

---@param data XUiPacMan2StarTargetData
function XUiPacMan2StarTarget:Update(data)
    if data.IsOn then
        local star = data.Star
        for i = 1, star do
            local uiStar = self._StarsOn[i]
            if not uiStar then
                uiStar = CS.UnityEngine.Object.Instantiate(self.ImgStarOn, self.ImgStarOn.transform.parent)
                self._StarsOn[i] = uiStar
            end
        end
        self.TxtScoreOn.text = data.Score
        self.PanelOn.gameObject:SetActiveEx(true)
        self.PanelOff.gameObject:SetActiveEx(false)
    else
        local star = data.Star
        for i = 1, star do
            local uiStar = self._StarsOff[i]
            if not uiStar then
                uiStar = CS.UnityEngine.Object.Instantiate(self.ImgStarOff, self.ImgStarOff.transform.parent)
                self._StarsOff[i] = uiStar
            end
        end
        self.TxtScoreOff.text = data.Score
        self.PanelOn.gameObject:SetActiveEx(false)
        self.PanelOff.gameObject:SetActiveEx(true)
    end
end

return XUiPacMan2StarTarget
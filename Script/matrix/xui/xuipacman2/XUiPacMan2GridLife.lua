---@class XUiPacMan2GridLife : XUiNode
---@field _Control XPacMan2Control
local XUiPacMan2GridLife = XClass(XUiNode, "XUiPacMan2GridLife")

function XUiPacMan2GridLife:OnStart()
    self._IsEnable = nil
end

function XUiPacMan2GridLife:Update(enable, animation)
    if self._IsEnable == enable then
        return
    end
    self._IsEnable = enable
    if enable then
        self.LifeMinus.gameObject:SetActive(false)
        self.LifeAdd.gameObject:SetActive(true)
        if animation then
            self.Enable.gameObject:SetActive(true)
        else
            self.Enable.gameObject:SetActive(false)
        end
    else
        self.LifeAdd.gameObject:SetActive(false)
        if animation then
            self.LifeMinus.gameObject:SetActive(true)
        else
            self.Enable.gameObject:SetActive(false)
            self.LifeMinus.gameObject:SetActive(false)
        end
    end
end

return XUiPacMan2GridLife
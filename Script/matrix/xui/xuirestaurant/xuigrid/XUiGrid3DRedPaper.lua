
local XUiGrid3DBase = require("XUi/XUiRestaurant/XUiGrid/XUiGrid3DBase")

---@class XUiGrid3DRedPaper : XUiGrid3DBase
---@field
local XUiGrid3DRedPaper = XClass(XUiGrid3DBase, "XUiGrid3DRedPaper")

function XUiGrid3DRedPaper:InitCb()
    XUiHelper.RegisterClickEvent(self, self.Transform, self.OnRedPaperClick)
end

function XUiGrid3DRedPaper:InitUi()
    if self.Canvas then
        local component = self.GameObject:GetComponent(typeof(CS.UnityEngine.UI.GraphicRaycaster))
        if not component then
            self.GameObject:AddComponent(typeof(CS.UnityEngine.UI.GraphicRaycaster))
        end
    end
    
end

function XUiGrid3DRedPaper:OnRedPaperClick()
    -- 未在签到时间内
    if not self._Control:GetBusiness():IsSignOpen() then
        XUiManager.TipError(self._Control:GetSignNotInTimeTxt())
        return
    end
    -- 已领取
    if self._Control:GetBusiness():IsGetSignReward() then
        XUiManager.TipError(self._Control:GetSignedTxt())
        return
    end
    XLuaUiManager.Open("UiRestaurantSignIn")
end

return XUiGrid3DRedPaper
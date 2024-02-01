---@class XUiGridRogueSimLv : XUiNode
---@field private _Control XRogueSimControl
local XUiGridRogueSimLv = XClass(XUiNode, "XUiGridRogueSimLv")

function XUiGridRogueSimLv:Refresh(id)
    self.Id = id
    self.ConfigLevel = self._Control:GetMainLevelConfigLevel(id)
    -- 图片
    self.ImgBuild:SetSprite(self._Control:GetMainLevelSmallIcon(id))
    -- 等级
    self.TxtLv.text = self.ConfigLevel
    -- 当前等级
    local curLevel = self._Control:GetCurMainLevel()
    self.TxtNow.gameObject:SetActiveEx(curLevel == self.ConfigLevel)
end

function XUiGridRogueSimLv:SetSelect(isActive)
    if self.RImgSelect then
        self.RImgSelect.gameObject:SetActiveEx(isActive)
    end
end

return XUiGridRogueSimLv

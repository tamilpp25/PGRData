---@class XUiTempleSpringFestivalChapterStar:XUiNode
local XUiTempleSpringFestivalChapterStar = XClass(XUiNode, "XUiTempleSpringFestivalChapterStar")

---@param data XTempleUiControlStage
function XUiTempleSpringFestivalChapterStar:Update(value)
    if value then
        self.ImgStarOn.gameObject:SetActiveEx(true)
        self.ImgStarOff.gameObject:SetActiveEx(false)
    else
        self.ImgStarOn.gameObject:SetActiveEx(false)
        self.ImgStarOff.gameObject:SetActiveEx(true)
    end
end

return XUiTempleSpringFestivalChapterStar

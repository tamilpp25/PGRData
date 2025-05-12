---@class XUiTheatre4GeniusSubGrid : XUiNode
---@field _Control XTheatre4Control
local XUiTheatre4GeniusSubGrid = XClass(XUiNode, "XUiTheatre4GeniusSubGrid")

function XUiTheatre4GeniusSubGrid:OnStart()
    self.RImgIcon2 = self.RImgIcon2 or XUiHelper.TryGetComponent(self.Transform, "RImgIcon2", "RectTransform")
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnClick)
end

---@param data XTheatre4SetControlGeniusSubData
function XUiTheatre4GeniusSubGrid:Update(data)
    self._Data = data
    if data then
        self.RImgIcon.gameObject:SetActiveEx(true)
        
        if data.Icon then
            self.RImgIcon:SetRawImage(data.Icon)
        end
        
        if data.IsShowQuestionMark ~= nil then
            self.RImgIcon2.gameObject:SetActiveEx(data.IsShowQuestionMark)
            self.RImgIcon.gameObject:SetActiveEx(not data.IsShowQuestionMark)
        else
            self.RImgIcon2.gameObject:SetActiveEx(false)
            self.RImgIcon.gameObject:SetActiveEx(true)
        end
        
        if data.IsActive then
            self.Lock.gameObject:SetActiveEx(false)
        else
            self.Lock.gameObject:SetActiveEx(true)
        end
        if self.ImgGeniusIconLv then
            if data.LevelIcon then
                self.ImgGeniusIconLv:SetSprite(data.LevelIcon)
                self.ImgGeniusIconLv.gameObject:SetActiveEx(true)
            else
                self.ImgGeniusIconLv.gameObject:SetActiveEx(false)
            end
        end
        if data.IsSelected ~= nil then
            self.Select.gameObject:SetActiveEx(data.IsSelected)
        end
    else
        self.Select.gameObject:SetActiveEx(false)
        self.Lock.gameObject:SetActiveEx(true)
        self.RImgIcon.gameObject:SetActiveEx(false)
    end
end

function XUiTheatre4GeniusSubGrid:OnClick()
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE4_CLICK_TALENT_GRID, self._Data, self.Parent)
end

return XUiTheatre4GeniusSubGrid
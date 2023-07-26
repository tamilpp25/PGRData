local XBasePoint = require("XEntity/XColorTable/Map/XBasePoint")
local XMoviePoint = XClass(XBasePoint, "XMoviePoint")

function XMoviePoint:Ctor()
    self.IamgeNor = self.Transform:Find("IamgeNor")
    self.PanelBtn = self.Transform:Find("PanelBtn")
    if self.IamgeNor then
        XUiHelper.RegisterClickEvent(self, self.IamgeNor, self.OnBtnClick)
    end
    if self.PanelBtn then
        XUiHelper.RegisterClickEvent(self, self.PanelBtn, self.OnBtnClick)
    end
end

-- overrride
-------------------------------------------------------------------

function XMoviePoint:SetTipPanelActive(active)
    if active then
        XLuaUiManager.Open("UiColorTableEnterMovie", self._DramaId, function ()
            XDataCenter.ColorTableManager.GetGameManager():GetGameData():SetReadDrama(self._DramaId)
            if not XTool.UObjIsNil(self.GameObject) then
                self.GameObject:SetActiveEx(false)
                self.Root:RefreshMoviePoint()
            end
        end)
    end
end

function XMoviePoint:IsMoviePoint()
    return true
end

-------------------------------------------------------------------

function XMoviePoint:SetDramaId(dramaId)
    self._DramaId = dramaId
end

function XMoviePoint:GetDramaId()
    return self._DramaId
end

return XMoviePoint
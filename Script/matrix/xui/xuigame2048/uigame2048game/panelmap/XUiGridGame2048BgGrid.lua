---棋盘底部格子
---@class XUiGridGame2048BgGrid: XUiNode
---@field _GameControl XGame2048GameControl
---@field _Control XGame2048Control
local XUiGridGame2048BgGrid = XClass(XUiNode, 'XUiGridGame2048BgGrid')

function XUiGridGame2048BgGrid:OnStart(index)
    self._Index = index
    self._GameControl = self._Control:GetGameControl()

    if self.GridBtn then
        self.GridBtn.CallBack = handler(self, self.OnClickEvent)
        local row = XMath.ToMinInt((self._Index - 1) / 4)
        local rawImgPath = self._Control:GetChapterGameBoardGridBgById(self._Control:GetCurChapterId(), XMath.ToMinInt((self._Index + row) % 2) + 1)

        if not string.IsNilOrEmpty(rawImgPath) then
            self.GridBtn:SetRawImage(rawImgPath)
        end
        
    end
end

function XUiGridGame2048BgGrid:OnClickEvent()
    
end

function XUiGridGame2048BgGrid:SetIsSelect(isSelect)
    self.GridBtn:SetButtonState(isSelect and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

return XUiGridGame2048BgGrid
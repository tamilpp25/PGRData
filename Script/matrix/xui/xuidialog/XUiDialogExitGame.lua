-- 为了解决: 重复按Esc, 会重复弹出"退出游戏"提示
local XUiDialogExitGame = XLuaUiManager.Register(require("XUi/XUiDialog/XUiDialog"), "UiDialogExitGame")

function XUiDialogExitGame:OnEnable()
    self.Super.OnEnable(self)
    XDataCenter.UiPcManager.SetExitingGame(true)
    local canvas = self.GameObject:GetComponent(typeof(CS.UnityEngine.Canvas))
    if canvas then
        self.Canvas = canvas
        self.LastSortingOrder = canvas.sortingOrder
        canvas.sortingOrder = 5000
    end
end

function XUiDialogExitGame:OnDestroy()
    if self.Canvas and self.LastSortingOrder then
        self.Canvas.sortingOrder = self.LastSortingOrder
    end
    self.Super.OnDestroy(self)
    XDataCenter.UiPcManager.SetExitingGame(false)
end

return XUiDialogExitGame

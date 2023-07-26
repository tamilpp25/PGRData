---@class XUiTransfiniteMainStageFlag
local XUiTransfiniteMainStageFlag = XClass(nil, "XUiTransfiniteMainStageFlag")

function XUiTransfiniteMainStageFlag:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self._TextIndex = false
end

function XUiTransfiniteMainStageFlag:SetIndex(index)
    if index < 10 and index > 0 then
        self._TextIndex = "0" .. index
    else
        self._TextIndex = index
    end
end

function XUiTransfiniteMainStageFlag:SetEnable(value)
    if value then
        self.Press.gameObject:SetActiveEx(true)
        self.Normal.gameObject:SetActiveEx(false)
        self.TxtNumber2.text = self._TextIndex
    else
        self.Press.gameObject:SetActiveEx(false)
        self.Normal.gameObject:SetActiveEx(true)
        self.TxtNumber.text = self._TextIndex
    end
end

return XUiTransfiniteMainStageFlag

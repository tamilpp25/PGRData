local XUiGridStoryInfo = XClass(nil, "XUiGridStoryInfo")
local ArrowDown = CS.UnityEngine.Vector3.one
local ArrowUp = CS.UnityEngine.Vector3(1, -1, 1)
local GridState = {Close = false ,Open = true}

function XUiGridStoryInfo:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
end

function XUiGridStoryInfo:UpdateGrid(data, storyGridState)
    self.Data = data

    local IsLock = data:GetIsLock()
    self.InfoLock.gameObject:SetActiveEx(IsLock)
    self.InfoNor.gameObject:SetActiveEx(not IsLock)
    
    self.TxtLock.text = data:GetConditionDesc()
    self.TxtTitle.text = data:GetTitle()
    self.TxtLockTitle.text = data:GetTitle()
    self.TxtInfo.text = string.gsub(data:GetText(), "\\n", "\n")
    
    local tmpGridState = storyGridState[data:GetId()]
    self.ImgContent.gameObject:SetActiveEx(tmpGridState == GridState.Open and not IsLock)
    
    if tmpGridState == GridState.Open then
        self.ImgArrow.transform.localScale = ArrowUp
    else
        self.ImgArrow.transform.localScale = ArrowDown
    end
    
    self.ImgContentLayoutNode:SetDirty()
    self.GridLayoutNode:SetDirty()
end

return XUiGridStoryInfo
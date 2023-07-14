
local XUiSSBClearTimeGrid = XClass(nil, "XUiSSBClearTimeGrid")

function XUiSSBClearTimeGrid:Ctor()
    
end

function XUiSSBClearTimeGrid:Init(uiPrefab)
    XTool.InitUiObjectByUi(self, uiPrefab)
end

function XUiSSBClearTimeGrid:Refresh(index, lastTime, bestTime)
    self.TxtTitle.text = XUiHelper.GetText("SSBClearTimeTitle", index)
    if not lastTime then
        self.TxtLastTime.text = XUiHelper.GetText("SSBStageNotClear")
    else
        self.TxtLastTime.text = XUiHelper.GetTime(lastTime, XUiHelper.TimeFormatType.DEFAULT)
    end
    if not bestTime then
        self.TxtBestTime.text = XUiHelper.GetText("SSBStageNotClear")
    else
        self.TxtBestTime.text = XUiHelper.GetTime(bestTime, XUiHelper.TimeFormatType.DEFAULT)
    end  
end

return XUiSSBClearTimeGrid